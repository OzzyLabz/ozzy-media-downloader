import Foundation

enum AnalysisError: Error, LocalizedError {
    case invalidURL
    case noFormats
    case invalidResponse
    case toolUnavailable
    case timeout
    case source(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Вставьте ссылку http или https."
        case .noFormats: return "Доступные форматы не найдены."
        case .invalidResponse: return "Не удалось прочитать ответ источника."
        case .toolUnavailable: return "Не найден встроенный yt-dlp."
        case .timeout: return "Источник не ответил за 30 секунд."
        case .source(let message): return message
        }
    }

    var isConnectionFailure: Bool {
        switch self {
        case .timeout: return true
        case .source(let message):
            let text = message.lowercased()
            return text.contains("timed out") || text.contains("connection") || text.contains("unable to download")
        default: return false
        }
    }
}

enum MediaAnalyzer {
    static let timeoutSeconds = 30
    static let maxAttempts = 2
    private static let toolsDirectory = Bundle.main.bundleURL.appendingPathComponent("Contents/Helpers", isDirectory: true)
    private static let ytDLP = toolsDirectory.appendingPathComponent("yt-dlp")
    private static let deno = toolsDirectory.appendingPathComponent("deno")

    struct Progress {
        let attempt: Int
        let phase: String
    }

    static func phase(for line: String) -> String? {
        if line.contains("Extracting URL") { return "Определяем источник" }
        if line.contains("Downloading webpage") { return "Получаем страницу" }
        if line.contains("Downloading API") || line.contains("Downloading JSON") { return "Получаем данные источника" }
        if line.contains("Downloading player") { return "Получаем данные проигрывателя" }
        return nil
    }

    static func isValidURL(_ url: URL) -> Bool {
        ["http", "https"].contains(url.scheme?.lowercased() ?? "") && url.host != nil
    }

    static func arguments(for url: URL) -> [String] {
        ["--no-config", "--no-cache-dir", "--no-playlist", "--js-runtimes", "deno:\(deno.path)", "--socket-timeout", "10", "--retries", "0", "--extractor-retries", "0", "--dump-single-json", url.absoluteString]
    }

    static func analyze(_ url: URL, progress: ((Progress) -> Void)? = nil, completion: @escaping (Result<MediaInfo, AnalysisError>) -> Void) {
        guard isValidURL(url) else {
            DispatchQueue.main.async { completion(.failure(.invalidURL)) }
            return
        }
        guard FileManager.default.isExecutableFile(atPath: ytDLP.path),
              FileManager.default.isExecutableFile(atPath: deno.path) else {
            DispatchQueue.main.async { completion(.failure(.toolUnavailable)) }
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            var result: Result<MediaInfo, AnalysisError> = .failure(.invalidResponse)
            for attempt in 1...maxAttempts {
                DispatchQueue.main.async { progress?(Progress(attempt: attempt, phase: "Соединяемся с источником")) }
                result = analyzeOnce(url) { phase in
                    DispatchQueue.main.async { progress?(Progress(attempt: attempt, phase: phase)) }
                }
                if case .failure(let error) = result, error.isConnectionFailure, attempt < maxAttempts {
                    continue
                }
                break
            }
            let finalResult = result
            DispatchQueue.main.async { completion(finalResult) }
        }
    }

    private static func analyzeOnce(_ url: URL, phaseUpdate: @escaping (String) -> Void) -> Result<MediaInfo, AnalysisError> {
        let process = Process()
        process.executableURL = ytDLP
        process.arguments = arguments(for: url)
        let output = Pipe(), error = Pipe()
        process.standardOutput = output
        process.standardError = error
        do {
            try process.run()
            let lock = NSLock()
            var timedOut = false
            let timeout = DispatchWorkItem {
                guard process.isRunning else { return }
                lock.lock()
                timedOut = true
                lock.unlock()
                process.terminate()
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(timeoutSeconds), execute: timeout)
            let errorGroup = DispatchGroup()
            errorGroup.enter()
            var errorData = Data()
            DispatchQueue.global().async {
                var pending = ""
                while true {
                    let chunk = error.fileHandleForReading.availableData
                    guard !chunk.isEmpty else { break }
                    errorData.append(chunk)
                    pending += String(decoding: chunk, as: UTF8.self)
                    while let newline = pending.firstIndex(of: "\n") {
                        let line = String(pending[..<newline])
                        pending.removeSubrange(...newline)
                        if let phase = phase(for: line) { phaseUpdate(phase) }
                    }
                }
                errorGroup.leave()
            }
            let data = output.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            timeout.cancel()
            errorGroup.wait()
            lock.lock()
            let didTimeOut = timedOut
            lock.unlock()
            if didTimeOut { return .failure(.timeout) }
            if process.terminationStatus == 0 {
                do { return .success(try decodeInfo(data, sourceURL: url)) }
                catch let analysis as AnalysisError { return .failure(analysis) }
                catch { return .failure(.invalidResponse) }
            }
            let detail = String(data: errorData, encoding: .utf8)?.split(separator: "\n").last.map(String.init) ?? "Источник не предоставил медиа."
            return .failure(.source(detail))
        } catch {
            return .failure(.source(error.localizedDescription))
        }
    }

    static func decodeInfo(_ data: Data, sourceURL: URL? = nil) throws -> MediaInfo {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { throw AnalysisError.invalidResponse }
        let title = (root["title"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = (title?.isEmpty == false) ? title! : "Без названия"
        let mediaID = (root["id"] as? String) ?? UUID().uuidString
        let formats = root["formats"] as? [[String: Any]] ?? []
        let audio = formats.filter { ($0["acodec"] as? String) != nil && ($0["acodec"] as? String) != "none" && ($0["vcodec"] as? String) == "none" }
        let bestAudio = audio.max { (($0["abr"] as? Double) ?? ($0["tbr"] as? Double) ?? 0) < (($1["abr"] as? Double) ?? ($1["tbr"] as? Double) ?? 0) }
        let combinedAudio = formats.first { ($0["acodec"] as? String) != nil && ($0["acodec"] as? String) != "none" }
        let audioFormat = bestAudio ?? combinedAudio
        let audioID = audioFormat?["format_id"] as? String
        var videoByHeight: [Int: MediaVariant] = [:]
        for format in formats {
            guard (format["ext"] as? String) == "mp4",
                  let height = format["height"] as? Int, height > 0,
                  let codec = format["vcodec"] as? String, codec != "none",
                  let id = format["format_id"] as? String else { continue }
            let hasAudio = (format["acodec"] as? String).map { $0 != "none" } ?? false
            guard hasAudio || audioID != nil else { continue }
            let width = format["width"] as? Int
            let selector = hasAudio ? id : "\(id)+\(audioID!)"
            let quality = min(width ?? height, height)
            let label = quality >= 2160 ? "MP4 2160p (4K)" : "MP4 \(quality)p"
            let videoBytes = estimatedBytes(for: format)
            let audioBytes = audioFormat.flatMap(estimatedBytes(for:))
            let totalBytes = hasAudio ? videoBytes : (videoBytes.flatMap { video in audioBytes.map { video + $0 } })
            let candidate = MediaVariant(id: id, label: label, kind: .video, extensionName: "mp4", selector: selector, height: height, width: width, estimatedBytes: totalBytes)
            if videoByHeight[height] == nil { videoByHeight[height] = candidate }
        }
        var variants = videoByHeight.values.sorted { ($0.height ?? 0) > ($1.height ?? 0) }
        if let audioID {
            variants.append(MediaVariant(id: "mp3", label: "MP3 (конвертация)", kind: .audio, extensionName: "mp3", selector: audioID, height: nil, width: nil, estimatedBytes: audioFormat.flatMap(estimatedBytes(for:))))
        }
        guard !variants.isEmpty else { throw AnalysisError.noFormats }

        var subtitles: [SubtitleChoice] = []
        for (key, automatic) in [("subtitles", false), ("automatic_captions", true)] {
            guard let table = root[key] as? [String: [[String: Any]]] else { continue }
            for language in table.keys.sorted() where !(table[language]?.isEmpty ?? true) {
                let name = (table[language]?.first?["name"] as? String) ?? language
                subtitles.append(SubtitleChoice(language: language, name: name, automatic: automatic))
            }
        }
        let thumbnail = (root["thumbnail"] as? String).flatMap(URL.init(string:))
        let page = (root["webpage_url"] as? String).flatMap(URL.init(string:)) ?? sourceURL
        return MediaInfo(id: mediaID, title: name, webpageURL: page, duration: root["duration"] as? Double, thumbnailURL: thumbnail, variants: variants, subtitles: subtitles)
    }

    private static func estimatedBytes(for format: [String: Any]) -> Double? {
        guard let bytes = (format["filesize"] as? NSNumber)?.doubleValue ?? (format["filesize_approx"] as? NSNumber)?.doubleValue,
              bytes > 0 else { return nil }
        return bytes
    }
}
