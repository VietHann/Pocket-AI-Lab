import AVFoundation
import Foundation
import NaturalLanguage
import Speech
import SwiftLlama
import UIKit
import Vision

enum LocalImageAI {
    static func extractText(from image: UIImage) async throws -> String {
        guard let cg = image.cgImage else { throw ImageToolError.invalidImage }
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let request = VNRecognizeTextRequest()
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true
                request.recognitionLanguages = ["vi-VN", "en-US"]
                do {
                    try VNImageRequestHandler(cgImage: cg).perform([request])
                    let lines = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }
                    continuation.resume(returning: lines.joined(separator: "\n"))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    static func classify(from image: UIImage) async throws -> [String] {
        guard let cg = image.cgImage else { throw ImageToolError.invalidImage }
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let request = VNClassifyImageRequest()
                do {
                    try VNImageRequestHandler(cgImage: cg).perform([request])
                    let labels = (request.results ?? [])
                        .filter { $0.confidence >= 0.05 }
                        .prefix(5)
                        .map { "\($0.identifier) • \(Int($0.confidence * 100))%" }
                    continuation.resume(returning: labels)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    static func languageName(for text: String) -> String {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return "" }
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        guard let language = recognizer.dominantLanguage else { return "Chưa xác định được ngôn ngữ." }
        let localized = Locale(identifier: "vi_VN").localizedString(forLanguageCode: language.rawValue) ?? language.rawValue
        let confidence = Int((recognizer.languageHypotheses(withMaximum: 1)[language] ?? 0) * 100)
        return "\(localized.capitalized) · độ tin cậy \(confidence)%"
    }
}

enum ImageToolError: LocalizedError {
    case invalidImage
    var errorDescription: String? { "Không đọc được hình ảnh này." }
}

@MainActor
final class TinyChatEngine: ObservableObject {
    @Published var answer = ""
    @Published var isRunning = false
    @Published var error: String?

    private var generation: Task<Void, Never>?
    private var service: LlamaService?

    func generate(prompt: String, modelURL: URL) {
        guard !isRunning else { return }
        answer = ""
        error = nil
        isRunning = true
        let service = LlamaService(
            modelUrl: modelURL,
            config: LlamaConfig(batchSize: 128, maxTokenCount: 768, useGPU: false, nThreads: 2)
        )
        self.service = service
        generation = Task {
            do {
                let messages: [LlamaChatMessage] = [
                    .init(role: .system, content: "You are a friendly short-answer assistant. If possible answer in the language of the user. Be concise."),
                    .init(role: .user, content: prompt)
                ]
                let stream = try await service.streamCompletion(
                    of: messages, samplingConfig: .init(temperature: 0.6, seed: 42)
                )
                for try await token in stream {
                    if Task.isCancelled { break }
                    answer += token
                }
            } catch is CancellationError {
                // A cancelled stream is a normal user action.
            } catch {
                self.error = error.localizedDescription
            }
            isRunning = false
        }
    }

    func stop() {
        generation?.cancel()
        if let service {
            Task { await service.stopCompletion() }
        }
        isRunning = false
    }
}

@MainActor
final class VoiceSpeaker: ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    @Published private(set) var isSpeaking = false

    func speak(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "vi-VN")
            ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.49
        utterance.pitchMultiplier = 1.09
        synthesizer.speak(utterance)
        isSpeaking = true
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }
}

@MainActor
final class OfflineDictation: NSObject, ObservableObject {
    @Published private(set) var recording = false
    @Published var transcript = ""
    @Published var errorMessage: String?
    @Published private(set) var offlineSupported = false

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "vi-VN"))
    private let engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    override init() {
        super.init()
        offlineSupported = recognizer?.supportsOnDeviceRecognition ?? false
    }

    func start() {
        errorMessage = nil
        guard offlineSupported else {
            errorMessage = "Máy hoặc tiếng Việt chưa hỗ trợ nhận dạng offline. App sẽ không chuyển sang server."
            return
        }
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                guard status == .authorized else {
                    self.errorMessage = "Hãy cấp quyền Speech Recognition trong Cài đặt."
                    return
                }
                Task {
                    let allowed = await AVAudioApplication.requestRecordPermission()
                    guard allowed else {
                        self.errorMessage = "Hãy cấp quyền Microphone trong Cài đặt."
                        return
                    }
                    self.beginRecording()
                }
            }
        }
    }

    private func beginRecording() {
        guard !recording, let recognizer, recognizer.isAvailable else {
            errorMessage = "Bộ nhận dạng giọng nói hiện không sẵn sàng."
            return
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(.record, mode: .measurement, options: .duckOthers)
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            let newRequest = SFSpeechAudioBufferRecognitionRequest()
            newRequest.requiresOnDeviceRecognition = true
            newRequest.shouldReportPartialResults = true
            request = newRequest
            let node = engine.inputNode
            let format = node.outputFormat(forBus: 0)
            node.removeTap(onBus: 0)
            node.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak newRequest] buffer, _ in
                newRequest?.append(buffer)
            }
            engine.prepare()
            try engine.start()
            recognitionTask = recognizer.recognitionTask(with: newRequest) { [weak self] result, error in
                DispatchQueue.main.async {
                    if let result {
                        self?.transcript = result.bestTranscription.formattedString
                    }
                    if let error {
                        self?.errorMessage = error.localizedDescription
                        self?.stop()
                    }
                }
            }
            recording = true
        } catch {
            errorMessage = error.localizedDescription
            stop()
        }
    }

    func stop() {
        if engine.isRunning { engine.stop() }
        engine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        request = nil
        recording = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
