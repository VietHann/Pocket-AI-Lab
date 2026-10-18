import PhotosUI
import SwiftUI
import UIKit

struct StudioView: View {
    let tool: LabTool

    var body: some View {
        ZStack {
            SoftBackground()
            Group {
                switch tool {
                case .scan, .describe:
                    ImageStudio(tool: tool)
                case .language:
                    LanguageStudio()
                case .speak:
                    VoiceStudio()
                case .transcribe:
                    DictationStudio()
                case .tinyChat:
                    TinyChatStudio()
                }
            }
        }
        .navigationTitle(tool.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct StudioIntro: View {
    let tool: LabTool
    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Image(systemName: tool.icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(tool.tint)
                    .frame(width: 54, height: 54)
                    .background(tool.tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 17))
                Spacer()
                BubbleLabel(title: "On-device", systemImage: "iphone")
            }
            Text(tool.englishName)
                .font(.system(size: 25, weight: .heavy, design: .rounded))
                .foregroundStyle(Palette.ink)
            Text(tool.description).font(.system(size: 13)).foregroundStyle(Palette.muted)
            if let caution = tool.caution {
                Text(caution)
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.peach)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ImageStudio: View {
    let tool: LabTool
    @State private var selectedItem: PhotosPickerItem?
    @State private var image: UIImage?
    @State private var result = ""
    @State private var busy = false
    @State private var error: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                StudioIntro(tool: tool)
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(.white)
                            .overlay {
                                RoundedRectangle(cornerRadius: 24)
                                    .strokeBorder(Palette.purple.opacity(0.18), style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
                            }
                        if let image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .padding(10)
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.system(size: 34))
                                    .foregroundStyle(Palette.purple)
                                Text("Chọn một tấm ảnh")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                Text("Từ thư viện ảnh của bạn")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Palette.muted)
                            }
                        }
                    }
                    .frame(height: 230)
                }
                .buttonStyle(.plain)
                .onChange(of: selectedItem) { _, item in
                    Task {
                        guard let data = try? await item?.loadTransferable(type: Data.self),
                              let loaded = UIImage(data: data) else {
                            error = "Không thể mở ảnh. Hãy thử file khác."
                            return
                        }
                        image = loaded
                        result = ""
                        error = nil
                    }
                }

                Button { analyze() } label: {
                    HStack {
                        if busy { ProgressView().tint(.white) }
                        else { Image(systemName: "sparkles") }
                        Text(busy ? "Đang xử lý trên iPhone..." : (tool == .scan ? "Tách chữ từ ảnh" : "Nhận diện ảnh"))
                    }.frame(maxWidth: .infinity)
                }
                .buttonStyle(FilledPillStyle())
                .disabled(image == nil || busy)
                .opacity(image == nil ? 0.55 : 1)

                if let error { Text(error).font(.caption).foregroundStyle(.red) }
                if !result.isEmpty {
                    CuteCard {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Label("Kết quả offline", systemImage: "checkmark.seal.fill")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(Palette.mint)
                                Spacer()
                                Button { UIPasteboard.general.string = result } label: {
                                    Label("Copy", systemImage: "doc.on.doc")
                                        .font(.system(size: 12, weight: .semibold))
                                }
                            }
                            Text(result)
                                .font(.system(size: 14))
                                .foregroundStyle(Palette.ink)
                                .textSelection(.enabled)
                            ShareLink(item: result) {
                                Label("Chia sẻ kết quả", systemImage: "square.and.arrow.up")
                                    .font(.system(size: 12))
                            }
                        }
                    }
                }
            }.padding(20)
        }
    }

    private func analyze() {
        guard let image else { return }
        busy = true
        result = ""
        error = nil
        Task {
            do {
                if tool == .scan {
                    let output = try await LocalImageAI.extractText(from: image)
                    result = output.isEmpty ? "Không tìm thấy chữ trong ảnh này." : output
                } else {
                    let labels = try await LocalImageAI.classify(from: image)
                    result = labels.isEmpty ? "Không tìm được nhãn phù hợp." : labels.joined(separator: "\n")
                }
            } catch {
                self.error = error.localizedDescription
            }
            busy = false
        }
    }
}

struct LanguageStudio: View {
    @State private var input = ""
    private var output: String { LocalImageAI.languageName(for: input) }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                StudioIntro(tool: .language)
                CuteCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Văn bản của bạn").font(.system(size: 14, weight: .bold, design: .rounded))
                        TextEditor(text: $input)
                            .scrollContentBackground(.hidden)
                            .frame(height: 150)
                            .font(.system(size: 15))
                            .foregroundStyle(Palette.ink)
                        HStack {
                            Text("\(input.count) ký tự").font(.caption).foregroundStyle(Palette.muted)
                            Spacer()
                            Button("Xóa") { input = "" }.font(.caption)
                        }
                    }
                }
                if !output.isEmpty {
                    CuteCard {
                        VStack(alignment: .leading, spacing: 10) {
                            BubbleLabel(title: "Detected", systemImage: "checkmark.circle", foreground: Palette.mint)
                            Text(output)
                                .font(.system(size: 19, weight: .bold, design: .rounded))
                                .foregroundStyle(Palette.ink)
                        }
                    }
                }
                Text("Sử dụng NaturalLanguage của Apple. Kết quả chỉ mang tính ước lượng.")
                    .font(.caption)
                    .foregroundStyle(Palette.muted)
            }.padding(20)
        }
    }
}

struct VoiceStudio: View {
    @StateObject private var speaker = VoiceSpeaker()
    @State private var text = "Xin chào! Mình là Pocket AI, người bạn nhỏ luôn ở trong túi của bạn. 🌷"
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                StudioIntro(tool: .speak)
                CuteCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Nhập lời bạn muốn nghe")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                        TextEditor(text: $text)
                            .frame(height: 185)
                            .scrollContentBackground(.hidden)
                            .font(.system(size: 15))
                            .foregroundStyle(Palette.ink)
                        Text("Giọng được phát bằng hệ thống giọng nói có sẵn trên iOS.")
                            .font(.caption)
                            .foregroundStyle(Palette.muted)
                    }
                }
                Button { speaker.speak(text) } label: {
                    Label("Phát giọng đọc", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(FilledPillStyle())
                Button { speaker.stop() } label: {
                    Label("Dừng phát", systemImage: "stop.circle")
                        .frame(maxWidth: .infinity)
                }
                .disabled(!speaker.isSpeaking)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Palette.purple)
            }.padding(20)
        }
        .onDisappear { speaker.stop() }
    }
}

struct DictationStudio: View {
    @StateObject private var dictation = OfflineDictation()
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                StudioIntro(tool: .transcribe)
                CuteCard {
                    VStack(spacing: 18) {
                        Image(systemName: dictation.recording ? "waveform" : "mic.circle.fill")
                            .font(.system(size: 62))
                            .foregroundStyle(dictation.recording ? Palette.pink : Palette.purple)
                            .symbolEffect(.pulse, options: .repeating, value: dictation.recording)
                        Text(dictation.recording ? "Đang lắng nghe..." : "Tap to record")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(Palette.ink)
                        Text(dictation.offlineSupported ? "Máy có hỗ trợ engine nhận dạng offline." : "Nhận dạng offline tiếng Việt không được hỗ trợ trên cấu hình này.")
                            .font(.caption)
                            .foregroundStyle(Palette.muted)
                            .multilineTextAlignment(.center)
                        Button {
                            dictation.recording ? dictation.stop() : dictation.start()
                        } label: {
                            Label(dictation.recording ? "Dừng ghi âm" : "Bắt đầu ghi âm",
                                  systemImage: dictation.recording ? "stop.fill" : "mic.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(FilledPillStyle())
                        .disabled(!dictation.offlineSupported && !dictation.recording)
                    }.frame(maxWidth: .infinity)
                }
                if let error = dictation.errorMessage {
                    Text(error).font(.caption).foregroundStyle(.red)
                }
                CuteCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Bản chép").font(.system(size: 15, weight: .bold, design: .rounded))
                            Spacer()
                            Button { UIPasteboard.general.string = dictation.transcript } label: {
                                Image(systemName: "doc.on.doc")
                            }.disabled(dictation.transcript.isEmpty)
                        }
                        Text(dictation.transcript.isEmpty ? "Lời nói được nhận dạng sẽ hiện ở đây..." : dictation.transcript)
                            .foregroundStyle(dictation.transcript.isEmpty ? Palette.muted : Palette.ink)
                            .font(.system(size: 14))
                            .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
                            .textSelection(.enabled)
                    }
                }
                Text("Không dùng Speech Recognition online làm phương án dự phòng.")
                    .font(.caption)
                    .foregroundStyle(Palette.muted)
            }.padding(20)
        }
        .onDisappear { dictation.stop() }
    }
}

struct TinyChatStudio: View {
    @EnvironmentObject private var models: ModelStore
    @StateObject private var chat = TinyChatEngine()
    @State private var prompt = ""
    @State private var lastPrompt = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 17) {
                StudioIntro(tool: .tinyChat)
                if models.isInstalled {
                    CuteCard {
                        VStack(alignment: .leading, spacing: 13) {
                            BubbleLabel(title: "Local GGUF", systemImage: "cpu", foreground: Palette.mint)
                            if !lastPrompt.isEmpty {
                                HStack {
                                    Spacer()
                                    Text(lastPrompt)
                                        .font(.system(size: 13))
                                        .foregroundStyle(Palette.ink)
                                        .padding(11)
                                        .background(Palette.lavender, in: RoundedRectangle(cornerRadius: 14))
                                }
                            }
                            if chat.isRunning && chat.answer.isEmpty {
                                ProgressView("Model đang xử lý...").tint(Palette.purple)
                            }
                            Text(chat.answer.isEmpty ? "Chào bạn! Hỏi một câu ngắn để bắt đầu ✨" : chat.answer)
                                .font(.system(size: 14))
                                .foregroundStyle(chat.answer.isEmpty ? Palette.muted : Palette.ink)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
                            if let error = chat.error { Text(error).font(.caption).foregroundStyle(.red) }
                            if !chat.answer.isEmpty {
                                Button { UIPasteboard.general.string = chat.answer } label: {
                                    Label("Copy", systemImage: "doc.on.doc").font(.caption)
                                }
                            }
                        }
                    }
                    CuteCard {
                        VStack(alignment: .leading, spacing: 12) {
                            TextField("Ask something tiny...", text: $prompt, axis: .vertical)
                                .lineLimit(2...4)
                                .font(.system(size: 15))
                                .submitLabel(.done)
                            Button {
                                if chat.isRunning { chat.stop() }
                                else {
                                    lastPrompt = prompt
                                    chat.generate(prompt: prompt, modelURL: models.modelURL)
                                    prompt = ""
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                            } label: {
                                Label(chat.isRunning ? "Stop" : "Send to Tiny Chat",
                                      systemImage: chat.isRunning ? "stop.fill" : "paperplane.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(FilledPillStyle())
                            .disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !chat.isRunning)
                        }
                    }
                } else {
                    CuteCard {
                        VStack(alignment: .leading, spacing: 13) {
                            Label("Chưa tải model", systemImage: "arrow.down.circle")
                                .font(.system(size: 16, weight: .bold))
                            Text("Tiny Chat là model tải riêng (~110 MB). Đầu tiên hãy tải ở Models.")
                                .font(.system(size: 13))
                                .foregroundStyle(Palette.muted)
                            Button { models.download() } label: {
                                Label(models.downloading ? "Đang tải..." : "Tải SmolLM2 135M", systemImage: "arrow.down")
                                    .frame(maxWidth: .infinity)
                            }
                            .disabled(models.downloading)
                            .buttonStyle(FilledPillStyle())
                            if let progress = models.progress {
                                ProgressView(value: progress).tint(Palette.purple)
                            }
                            if let error = models.message {
                                Text(error).foregroundStyle(.red).font(.caption)
                            }
                        }
                    }
                }
            }.padding(20)
        }
        .onDisappear { chat.stop() }
    }
}
