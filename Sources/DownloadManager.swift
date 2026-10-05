import Foundation

final class DownloadManager {
    private static let toolsDirectory = Bundle.main.bundleURL.appendingPathComponent("Contents/Helpers", isDirectory: true)
    private static let ytDLP = toolsDirectory.appendingPathComponent("yt-dlp")
    private static let ffmpeg = toolsDirectory.appendingPathComponent("ffmpeg")
    private static let deno = toolsDirectory.appendingPathComponent("deno")
    struct ProgressMeasurement {
        let downloadedBytes: Double
        let totalBytes: Double?
        let speedBytesPerSecond: Double?

        var fraction: Double? {
            guard let totalBytes, totalBytes > 0 else { return nil }
            return min(1, max(0, downloadedBytes / totalBytes))
        }
    }

    private enum TaskOutcome {
        case success
        case failure(String)
    }
    private(set) var tasks: [DownloadTask] = []
    var onChange: (() -> Void)?

    private var scheduler = DownloadScheduler(limit: 10)
    private var processes: [UUID: Process] = [:]
    private var nextNumber = 1

    var hasUnfinishedTasks: Bool {
        tasks.contains { $0.state == .queued || $0.state.isActive }
    }

    func hasUnfinishedDownload(for info: MediaInfo) -> Bool {
        Self.hasUnfinishedDownload(for: info, in: tasks)
    }

    static func hasUnfinishedDownload(for info: MediaInfo, in tasks: [DownloadTask]) -> Bool {
        tasks.contains { task in
            guard task.state == .queued || task.state.isActive else { return false }
            if let source = info.webpageURL, let other = task.selection.info.webpageURL {
                return source == other
            }
            return info.id == task.selection.info.id
        }
    }

    @discardableResult
    func enqueue(selection: DownloadSelection, destination: URL) -> UUID {
        let id = UUID()
        let task = DownloadTask(id: id, number: nextNumber, selection: selection, destination: destination, state: .queued, fraction: nil, speed: nil, expectedBytes: selection.variant.estimatedBytes, downloadedBytes: 0, completedStreamBytes: 0, currentStreamDownloadedBytes: 0, currentStreamTotalBytes: nil, lastSpeedAt: nil)
        nextNumber += 1
        tasks.append(task)
        scheduler.enqueue(id)
        notify()
        startReadyTasks()
        return id
    }

    func cancel(_ id: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        guard tasks[index].state == .queued || tasks[index].state.isActive else { return }
        let wasQueued = tasks[index].state == .queued
        tasks[index].state = .cancelled
        if wasQueued {
            scheduler.cancel(id)
        } else if let process = processes[id], process.isRunning {
            process.terminate()
        }
        notify()
        if wasQueued { startReadyTasks() }
    }

    func cancelAll() {
        for index in tasks.indices where tasks[index].state == .queued || tasks[index].state.isActive {
            tasks[index].state = .cancelled
            let id = tasks[index].id
            if let process = processes[id], process.isRunning { process.terminate() }
            processes[id] = nil
        }
        scheduler.cancelAll()
        notify()
    }

    var estimatedRemainingTime: TimeInterval? {
        Self.estimatedRemainingTime(for: tasks)
    }

    static func estimatedRemainingTime(for tasks: [DownloadTask], now: Date = Date()) -> TimeInterval? {
        let unfinished = tasks.filter { $0.state == .queued || $0.state.isActive }
        guard !unfinished.isEmpty, !unfinished.contains(where: { $0.state == .processing }) else { return nil }
        guard unfinished.allSatisfy({ ($0.expectedBytes ?? 0) > 0 }) else { return nil }
        let active = unfinished.filter { $0.state == .downloading }
        guard !active.isEmpty,
              active.allSatisfy({ ($0.speed ?? 0) > 0 && now.timeIntervalSince($0.lastSpeedAt ?? .distantPast) < 8 }) else { return nil }
        let totalSpeed = active.reduce(0) { $0 + ($1.speed ?? 0) }
        let remainingBytes = unfinished.reduce(0) { $0 + max(0, ($1.expectedBytes ?? 0) - $1.downloadedBytes) }
        return remainingBytes / totalSpeed
    }

    private func startReadyTasks() {
        for id in scheduler.active {
            guard let index = tasks.firstIndex(where: { $0.id == id }), tasks[index].state == .queued else { continue }
            startTask(at: index)
        }
    }

    private func startTask(at index: Int) {
        let task = tasks[index]
        guard FileManager.default.isExecutableFile(atPath: Self.ytDLP.path),
              FileManager.default.isExecutableFile(atPath: Self.ffmpeg.path),
              FileManager.default.isExecutableFile(atPath: Self.deno.path) else {
            finish(task.id, result: .failure("Не найдены встроенные инструменты загрузки"))
            return
        }
        let process = Process()
        process.executableURL = Self.ytDLP
        process.arguments = Self.arguments(for: task.selection, destination: task.destination, suffix: String(task.id.uuidString.prefix(8)))
        let output = Pipe()
        process.standardOutput = output
        process.standardError = output
        do { try process.run() }
        catch { finish(task.id, result: .failure(error.localizedDescription)); return }
        tasks[index].state = .downloading
        processes[task.id] = process
        notify()

        DispatchQueue.global(qos: .utility).async { [weak self] in
                let handle = output.fileHandleForReading
                var buffer = ""
                var lastError = "Ошибка загрузки"
                while true {
                    let chunk = handle.availableData
                    if chunk.isEmpty { break }
                    buffer += String(decoding: chunk, as: UTF8.self)
                    let lines = buffer.split(separator: "\n", omittingEmptySubsequences: false)
                    buffer = String(lines.last ?? "")
                    for line in lines.dropLast() {
                        let text = String(line)
                        if text.contains("ERROR:") { lastError = text }
                        DispatchQueue.main.async { self?.handleOutput(text, for: task.id) }
                    }
                }
                process.waitUntilExit()
                DispatchQueue.main.async {
                    self?.finish(task.id, result: process.terminationStatus == 0 ? .success : .failure(lastError))
                }
        }
    }

    private func handleOutput(_ line: String, for id: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == id }), tasks[index].state.isActive else { return }
        if let measurement = Self.measurement(from: line) {
            if measurement.downloadedBytes < tasks[index].currentStreamDownloadedBytes {
                tasks[index].completedStreamBytes += tasks[index].currentStreamTotalBytes ?? tasks[index].currentStreamDownloadedBytes
            }
            tasks[index].currentStreamDownloadedBytes = measurement.downloadedBytes
            tasks[index].currentStreamTotalBytes = measurement.totalBytes
            tasks[index].downloadedBytes = tasks[index].completedStreamBytes + measurement.downloadedBytes
            if let total = measurement.totalBytes {
                let observedTotal = tasks[index].completedStreamBytes + total
                if let expected = tasks[index].expectedBytes {
                    tasks[index].expectedBytes = max(expected, observedTotal)
                }
            }
            if tasks[index].expectedBytes == nil && !tasks[index].selection.variant.selector.contains("+") {
                tasks[index].expectedBytes = measurement.totalBytes
            }
            if let speed = measurement.speedBytesPerSecond, speed > 0 {
                tasks[index].speed = tasks[index].speed.map { $0 * 0.7 + speed * 0.3 } ?? speed
                tasks[index].lastSpeedAt = Date()
            }
            if let expected = tasks[index].expectedBytes, expected > 0 {
                tasks[index].fraction = min(1, max(0, tasks[index].downloadedBytes / expected))
            } else {
                tasks[index].fraction = measurement.fraction
            }
            tasks[index].state = .downloading
        } else if line.hasPrefix("postprocess:") || line.contains("[Merger]") || line.contains("[ExtractAudio]") || line.contains("[EmbedSubtitle]") {
            tasks[index].state = .processing
        }
        notify()
    }

    private func finish(_ id: UUID, result: TaskOutcome) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        processes[id] = nil
        if tasks[index].state != .cancelled {
            switch result {
            case .success: tasks[index].state = .complete; tasks[index].fraction = 1
            case .failure(let message): tasks[index].state = .failed(message)
            }
        }
        scheduler.finish(id)
        notify()
        startReadyTasks()
    }

    private func notify() { onChange?() }

    static func arguments(for selection: DownloadSelection, destination: URL, suffix: String) -> [String] {
        let safeTitle = selection.info.title
            .replacingOccurrences(of: #"[/:\\\x00-\x1F]"#, with: "_", options: .regularExpression)
            .prefix(100)
        var args = [
            "--no-config", "--no-cache-dir", "--no-playlist", "--no-overwrites",
            "--newline", "--progress-template", "download:%(progress.downloaded_bytes)s|%(progress.total_bytes)s|%(progress.total_bytes_estimate)s|%(progress.speed)s",
            "--progress-template", "postprocess:postprocess:%(progress.status)s",
            "--js-runtimes", "deno:\(deno.path)",
            "--ffmpeg-location", ffmpeg.path,
            "-f", selection.variant.selector,
            "-P", destination.path,
            "-o", "\(safeTitle)-\(suffix).%(ext)s"
        ]
        if selection.variant.kind == .video {
            args += ["--merge-output-format", "mp4", "--remux-video", "mp4"]
        } else {
            args += ["--extract-audio", "--audio-format", "mp3", "--audio-quality", "0"]
        }
        if let subtitle = selection.subtitle, selection.variant.kind == .video {
            args += [subtitle.automatic ? "--write-auto-subs" : "--write-subs", "--sub-langs", subtitle.language, "--sub-format", "srt/vtt/best"]
            if selection.embedSubtitle { args.append("--embed-subs") }
        }
        args.append(selection.info.webpageURL?.absoluteString ?? "")
        return args
    }

    static func progress(from line: String) -> Double? {
        measurement(from: line)?.fraction
    }

    static func measurement(from line: String) -> ProgressMeasurement? {
        let payload = line.hasPrefix("download:") ? String(line.dropFirst("download:".count)) : line
        let fields = payload.split(separator: "|", omittingEmptySubsequences: false)
        guard fields.count >= 4, let downloaded = Double(fields[0]) else { return nil }
        let total = Double(fields[1]) ?? Double(fields[2])
        return ProgressMeasurement(downloadedBytes: downloaded, totalBytes: total, speedBytesPerSecond: Double(fields[3]))
    }
}
