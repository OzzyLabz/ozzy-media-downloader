import Foundation

enum MediaKind: String {
    case video
    case audio
}

struct MediaVariant: Equatable {
    let id: String
    let label: String
    let kind: MediaKind
    let extensionName: String
    let selector: String
    let height: Int?
    let width: Int?
    let estimatedBytes: Double?
}

struct SubtitleChoice: Equatable {
    let language: String
    let name: String
    let automatic: Bool

    var label: String { automatic ? "\(name) (авто)" : name }
}

struct MediaInfo {
    let id: String
    let title: String
    let webpageURL: URL?
    let duration: TimeInterval?
    let thumbnailURL: URL?
    let variants: [MediaVariant]
    let subtitles: [SubtitleChoice]
}

struct DownloadSelection {
    let info: MediaInfo
    let variant: MediaVariant
    let subtitle: SubtitleChoice?
    let embedSubtitle: Bool
}

enum DownloadState: Equatable {
    case queued
    case downloading
    case processing
    case complete
    case failed(String)
    case cancelled

    var label: String {
        switch self {
        case .queued: return "Ожидает"
        case .downloading: return "Загружается"
        case .processing: return "Обработка"
        case .complete: return "Готово"
        case .failed(let message): return "Ошибка: \(message)"
        case .cancelled: return "Отменено"
        }
    }

    var isActive: Bool {
        self == .downloading || self == .processing
    }
}

struct DownloadTask {
    let id: UUID
    let number: Int
    let selection: DownloadSelection
    let destination: URL
    var state: DownloadState
    var fraction: Double?
    var speed: Double?
    var expectedBytes: Double?
    var downloadedBytes: Double
    var completedStreamBytes: Double
    var currentStreamDownloadedBytes: Double
    var currentStreamTotalBytes: Double?
    var lastSpeedAt: Date?
}

struct DownloadScheduler {
    let limit: Int
    private(set) var active: [UUID] = []
    private(set) var pending: [UUID] = []

    mutating func enqueue(_ id: UUID) {
        guard !active.contains(id), !pending.contains(id) else { return }
        if active.count < limit { active.append(id) }
        else { pending.append(id) }
    }

    mutating func finish(_ id: UUID) {
        active.removeAll { $0 == id }
        pending.removeAll { $0 == id }
        promote()
    }

    mutating func cancel(_ id: UUID) { finish(id) }

    mutating func cancelAll() {
        active.removeAll()
        pending.removeAll()
    }

    private mutating func promote() {
        while active.count < limit && !pending.isEmpty {
            active.append(pending.removeFirst())
        }
    }
}
