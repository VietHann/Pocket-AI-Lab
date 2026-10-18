import Foundation
import SwiftUI
import UniformTypeIdentifiers

enum LabTool: String, Identifiable, CaseIterable {
    case scan = "scan"
    case describe = "describe"
    case language = "language"
    case speak = "speak"
    case transcribe = "transcribe"
    case tinyChat = "tinyChat"

    var id: String { rawValue }

    var name: String {
        switch self {
        case .scan: "Scan chữ"
        case .describe: "Nhận diện ảnh"
        case .language: "Nhận diện ngôn ngữ"
        case .speak: "Đọc văn bản"
        case .transcribe: "Nghe & chép"
        case .tinyChat: "Tiny Chat"
        }
    }

    var englishName: String {
        switch self {
        case .scan: "Text Scanner"
        case .describe: "Image Labels"
        case .language: "Language ID"
        case .speak: "Voice Studio"
        case .transcribe: "Offline Dictation"
        case .tinyChat: "SmolLM2 135M"
        }
    }

    var description: String {
        switch self {
        case .scan: "Chụp hoặc chọn ảnh để tách chữ, không gửi lên mạng."
        case .describe: "Tìm các nhãn nội dung phổ biến trong hình ảnh."
        case .language: "Đoán ngôn ngữ từ đoạn văn bạn nhập."
        case .speak: "Biến câu chữ thành giọng nói ngay trên iPhone."
        case .transcribe: "Ghi âm và nhận dạng chỉ khi máy hỗ trợ offline."
        case .tinyChat: "Một chatbot siêu nhỏ chạy bằng GGUF trên máy."
        }
    }

    var icon: String {
        switch self {
        case .scan: "text.viewfinder"
        case .describe: "photo.on.rectangle.angled"
        case .language: "character.bubble"
        case .speak: "waveform"
        case .transcribe: "mic.fill"
        case .tinyChat: "bubble.left.and.text.bubble.right.fill"
        }
    }

    var tint: Color {
        switch self {
        case .scan: Palette.purple
        case .describe: Palette.peach
        case .language: Palette.blue
        case .speak: Palette.pink
        case .transcribe: Palette.mint
        case .tinyChat: Palette.purple
        }
    }

    var sizeText: String {
        self == .tinyChat ? "~110 MB" : "Có sẵn trên iOS"
    }

    var caution: String? {
        switch self {
        case .transcribe: "Tính năng có thể không hỗ trợ nhận dạng offline tiếng Việt trên mọi máy."
        case .tinyChat: "135M rất nhỏ: chất lượng và tiếng Việt có giới hạn."
        case .describe: "Nhãn phân loại thường là tiếng Anh và không phải mô tả ảnh chi tiết."
        default: nil
        }
    }
}

enum Palette {
    static let purple = Color(red: 0.55, green: 0.42, blue: 0.86)
    static let pink = Color(red: 0.96, green: 0.58, blue: 0.73)
    static let peach = Color(red: 0.98, green: 0.68, blue: 0.54)
    static let blue = Color(red: 0.47, green: 0.66, blue: 0.97)
    static let mint = Color(red: 0.35, green: 0.74, blue: 0.63)
    static let ink = Color(red: 0.19, green: 0.16, blue: 0.30)
    static let muted = Color(red: 0.54, green: 0.51, blue: 0.60)
    static let paper = Color(red: 0.988, green: 0.98, blue: 1)
    static let lavender = Color(red: 0.93, green: 0.89, blue: 1)
    static let rose = Color(red: 1, green: 0.91, blue: 0.94)
}

@MainActor
final class ModelStore: ObservableObject {
    static let shared = ModelStore()
    static let ggufName = "SmolLM2-135M-Instruct-Q4_K_M.gguf"
    static let ggufURL = URL(string: "https://huggingface.co/bartowski/SmolLM2-135M-Instruct-GGUF/resolve/main/SmolLM2-135M-Instruct-Q4_K_M.gguf")!

    @Published private(set) var progress: Double?
    @Published private(set) var downloading = false
    @Published var message: String?
    @Published private(set) var isInstalled = false
    private var currentDownload: Task<Void, Never>?

    let modelsDirectory: URL

    private init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        modelsDirectory = base.appendingPathComponent("PocketModels", isDirectory: true)
        try? FileManager.default.createDirectory(at: modelsDirectory, withIntermediateDirectories: true)
        isInstalled = FileManager.default.fileExists(atPath: modelURL.path)
    }

    var modelURL: URL { modelsDirectory.appendingPathComponent(Self.ggufName) }

    var modelSize: String {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: modelURL.path),
              let bytes = attrs[.size] as? NSNumber else { return "Chưa tải" }
        return ByteCountFormatter.string(fromByteCount: bytes.int64Value, countStyle: .file)
    }

    func download() {
        guard !downloading, !isInstalled else { return }
        downloading = true
        progress = 0
        message = nil
        currentDownload = Task {
            do {
                let reporter = ModelDownloadProgress { [weak self] value in
                    Task { @MainActor in self?.progress = value }
                }
                let (temporary, response) = try await URLSession.shared.download(from: Self.ggufURL, delegate: reporter)
                try Task.checkCancellation()
                guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                    throw ModelStoreError.invalidResponse
                }
                let attributes = try FileManager.default.attributesOfItem(atPath: temporary.path)
                let size = (attributes[.size] as? NSNumber)?.int64Value ?? 0
                guard size > 20_000_000 && size < 220_000_000 else { throw ModelStoreError.badSize }
                let handle = try FileHandle(forReadingFrom: temporary)
                let header = try handle.read(upToCount: 4)
                try handle.close()
                guard header == Data([0x47, 0x47, 0x55, 0x46]) else { throw ModelStoreError.badFormat }
                if FileManager.default.fileExists(atPath: modelURL.path) {
                    try FileManager.default.removeItem(at: modelURL)
                }
                try FileManager.default.moveItem(at: temporary, to: modelURL)
                var values = URLResourceValues()
                values.isExcludedFromBackup = true
                var location = modelURL
                try? location.setResourceValues(values)
                isInstalled = true
                progress = nil
            } catch is CancellationError {
                message = "Đã dừng tải model."
                progress = nil
            } catch {
                message = "Không tải được model: \(error.localizedDescription)"
                progress = nil
            }
            downloading = false
        }
    }

    func cancel() {
        currentDownload?.cancel()
    }

    func remove() {
        guard !downloading else { return }
        do {
            try FileManager.default.removeItem(at: modelURL)
            isInstalled = false
            message = nil
        } catch {
            message = "Không xóa được: \(error.localizedDescription)"
        }
    }
}

enum ModelStoreError: LocalizedError {
    case invalidResponse, badFormat, badSize

    var errorDescription: String? {
        switch self {
        case .invalidResponse: "Máy chủ không trả về model hợp lệ."
        case .badFormat: "Tệp tải xuống không phải GGUF."
        case .badSize: "Dung lượng tải về bất thường; đã từ chối tệp."
        }
    }
}

private final class ModelDownloadProgress: NSObject, URLSessionDownloadDelegate {
    let report: @Sendable (Double) -> Void

    init(report: @escaping @Sendable (Double) -> Void) {
        self.report = report
    }

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0 else { return }
        report(min(1, Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)))
    }

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {}
}
