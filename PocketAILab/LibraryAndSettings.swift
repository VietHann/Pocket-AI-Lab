import SwiftUI
import UIKit

struct ModelLibraryView: View {
    @EnvironmentObject private var models: ModelStore
    @State private var search = ""
    @State private var showDelete = false
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    private var filtered: [LabTool] {
        let input = search.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return LabTool.allCases }
        return LabTool.allCases.filter {
            $0.name.localizedCaseInsensitiveContains(input)
            || $0.englishName.localizedCaseInsensitiveContains(input)
        }
    }

    var body: some View {
        ZStack {
            SoftBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    SectionHeading(title: "Model garden 🌷", subtitle: "Bộ sưu tập AI nhỏ xinh cho iPhone của bạn.")
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundStyle(Palette.muted)
                        TextField("Tìm công cụ hoặc model...", text: $search)
                            .font(.system(size: 14))
                    }
                    .padding(15)
                    .background(.white, in: RoundedRectangle(cornerRadius: 16))

                    HStack {
                        SectionHeading(title: "Built into iPhone", subtitle: "Không phải tải model riêng")
                        Spacer()
                        BubbleLabel(title: "Free", systemImage: "checkmark.seal.fill", foreground: Palette.mint)
                    }

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(filtered.filter { $0 != .tinyChat }) { tool in ToolTile(tool: tool) }
                    }

                    if filtered.contains(.tinyChat) {
                        SectionHeading(title: "Downloadable models", subtitle: "Chỉ tải khi bạn muốn dùng.")
                        tinyModel
                    }

                    CuteCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Về hiệu năng trên iPhone 11", systemImage: "iphone.gen3")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(Palette.ink)
                            Text("Ưu tiên tác vụ AI nhẹ, model GGUF 135M tùy chọn. Kích thước file ≠ RAM khi chạy. Chat tiếng Việt có thể không chính xác; hãy thử trước khi dùng.")
                                .font(.system(size: 12))
                                .foregroundStyle(Palette.muted)
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Models")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Xóa Tiny Chat?", isPresented: $showDelete) {
            Button("Xóa model khỏi iPhone", role: .destructive) { models.remove() }
        } message: {
            Text("Thao tác chỉ xóa file model đã tải, không xóa ứng dụng.")
        }
    }

    private var tinyModel: some View {
        CuteCard {
            VStack(alignment: .leading, spacing: 13) {
                HStack(alignment: .top, spacing: 13) {
                    Image(systemName: "bubble.left.and.text.bubble.right.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Palette.purple)
                        .frame(width: 54, height: 54)
                        .background(Palette.lavender, in: RoundedRectangle(cornerRadius: 17))
                    VStack(alignment: .leading, spacing: 6) {
                        Text("SmolLM2 · 135M").font(.system(size: 17, weight: .bold, design: .rounded))
                        Text("Q4_K_M · ~110 MB · GGUF")
                            .font(.system(size: 12))
                            .foregroundStyle(Palette.muted)
                        BubbleLabel(title: models.isInstalled ? "Downloaded" : "Optional", systemImage: models.isInstalled ? "checkmark.circle" : "arrow.down.circle")
                    }
                    Spacer()
                }
                Text("Chat offline siêu nhẹ. Chất lượng có giới hạn, đặc biệt với tiếng Việt.")
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.muted)
                if let progress = models.progress {
                    ProgressView(value: progress)
                        .tint(Palette.purple)
                    Text("Đang tải \(Int(progress * 100))%")
                        .font(.system(size: 11))
                        .foregroundStyle(Palette.muted)
                }
                if let message = models.message {
                    Text(message).font(.caption).foregroundStyle(.red)
                }
                HStack(spacing: 9) {
                    if models.isInstalled {
                        NavigationLink(value: LabTool.tinyChat) {
                            Label("Mở Tiny Chat", systemImage: "sparkles")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(FilledPillStyle())
                        Button { showDelete = true } label: {
                            Image(systemName: "trash")
                                .frame(width: 44, height: 44)
                                .background(Palette.rose, in: RoundedRectangle(cornerRadius: 13))
                        }
                        .foregroundStyle(Palette.ink)
                    } else {
                        Button {
                            if models.downloading { models.cancel() }
                            else { models.download() }
                        } label: {
                            Label(models.downloading ? "Dừng tải" : "Tải model", systemImage: models.downloading ? "stop.fill" : "arrow.down")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(FilledPillStyle())
                    }
                }
            }
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var models: ModelStore
    var body: some View {
        ZStack {
            SoftBackground()
            ScrollView {
                VStack(spacing: 16) {
                    MascotView(size: 106).padding(.top, 12)
                    Text("Pocket AI Lab")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundStyle(Palette.ink)
                    Text("Your little offline universe. ✨")
                        .font(.system(size: 12)).foregroundStyle(Palette.muted)
                    CuteCard {
                        VStack(alignment: .leading, spacing: 14) {
                            info("Thiết bị", value: UIDevice.current.model)
                            Divider()
                            info("Hệ điều hành", value: UIDevice.current.systemName + " " + UIDevice.current.systemVersion)
                            Divider()
                            info("Tiny Chat", value: models.modelSize)
                            Divider()
                            info("Yêu cầu", value: "iOS 17 trở lên")
                        }
                    }
                    CuteCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Your data stays yours", systemImage: "lock.shield.fill")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(Palette.ink)
                            Text("Ảnh, văn bản và giọng nói xử lý bằng API trên thiết bị. Tiny Chat chạy trực tiếp từ GGUF đã tải. Chỉ quá trình tải file model mới cần Internet. Không có API key, tài khoản hay analytics.")
                                .font(.system(size: 12))
                                .foregroundStyle(Palette.muted)
                        }
                    }
                    Text("Made with ♡ by VietHannn")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Palette.muted)
                }
                .padding(20)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func info(_ name: String, value: String) -> some View {
        HStack {
            Text(name).font(.system(size: 13)).foregroundStyle(Palette.muted)
            Spacer()
            Text(value).font(.system(size: 13, weight: .semibold)).foregroundStyle(Palette.ink)
        }
    }
}

struct FilledPillStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.vertical, 13)
            .padding(.horizontal, 18)
            .background(Palette.purple, in: RoundedRectangle(cornerRadius: 14))
            .opacity(configuration.isPressed ? 0.78 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}
