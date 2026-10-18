import SwiftUI

@main
struct PocketAILabApp: App {
    @StateObject private var models = ModelStore.shared

    var body: some Scene {
        WindowGroup {
            PocketRoot()
                .environmentObject(models)
                .tint(Palette.purple)
                .preferredColorScheme(.light)
        }
    }
}

struct PocketRoot: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
                    .navigationDestination(for: LabTool.self) { StudioView(tool: $0) }
            }
            .tabItem { Label("Home", systemImage: "house.fill") }
            .tag(0)

            NavigationStack {
                ModelLibraryView()
                    .navigationDestination(for: LabTool.self) { StudioView(tool: $0) }
            }
            .tabItem { Label("Models", systemImage: "square.stack.3d.up.fill") }
            .tag(1)

            NavigationStack {
                PlaygroundView()
                    .navigationDestination(for: LabTool.self) { StudioView(tool: $0) }
            }
            .tabItem { Label("Studio", systemImage: "sparkles.rectangle.stack.fill") }
            .tag(2)

            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: "slider.horizontal.3") }
                .tag(3)
        }
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(Color.white, for: .tabBar)
    }
}

struct SoftBackground: View {
    var body: some View {
        ZStack {
            Palette.paper.ignoresSafeArea()
            GeometryReader { proxy in
                Circle().fill(Palette.lavender.opacity(0.47))
                    .frame(width: 280, height: 280)
                    .blur(radius: 65)
                    .position(x: proxy.size.width + 60, y: 55)
                Circle().fill(Palette.rose.opacity(0.45))
                    .frame(width: 210, height: 210)
                    .blur(radius: 55)
                    .position(x: -20, y: proxy.size.height * 0.58)
            }
            .ignoresSafeArea()
        }
    }
}

struct MascotView: View {
    var size: CGFloat = 114
    @State private var floating = false

    var body: some View {
        ZStack {
            Circle().fill(.white.opacity(0.5))
                .frame(width: size * 1.17, height: size * 1.17)
            RoundedRectangle(cornerRadius: size * 0.35, style: .continuous)
                .fill(LinearGradient(colors: [Color(red: 0.73, green: 0.64, blue: 1),
                                              Color(red: 0.94, green: 0.69, blue: 0.83)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: size * 0.84, height: size * 0.84)
                .rotationEffect(.degrees(-11))
                .shadow(color: Palette.purple.opacity(0.22), radius: 20, y: 10)
            HStack(spacing: size * 0.21) {
                Capsule().frame(width: size * 0.045, height: size * 0.12)
                Capsule().frame(width: size * 0.045, height: size * 0.12)
            }
            .foregroundStyle(Palette.ink)
            .offset(y: -size * 0.04)
            Image(systemName: "mouth")
                .font(.system(size: size * 0.18, weight: .medium))
                .foregroundStyle(Palette.ink)
                .offset(y: size * 0.11)
            HStack(spacing: size * 0.42) {
                Circle().fill(Palette.pink.opacity(0.65))
                    .frame(width: size * 0.13, height: size * 0.055)
                Circle().fill(Palette.pink.opacity(0.65))
                    .frame(width: size * 0.13, height: size * 0.055)
            }
            .offset(y: size * 0.095)
            Image(systemName: "sparkle")
                .font(.system(size: size * 0.24, weight: .bold))
                .foregroundStyle(Palette.purple)
                .offset(x: size * 0.45, y: -size * 0.44)
        }
        .frame(width: size * 1.27, height: size * 1.27)
        .offset(y: floating ? -5 : 5)
        .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: floating)
        .onAppear { floating = true }
        .accessibilityLabel("Linh vật AI màu tím đang mỉm cười")
    }
}

struct BubbleLabel: View {
    let title: String
    let systemImage: String
    var foreground: Color = Palette.purple

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(foreground)
            .padding(.horizontal, 11).padding(.vertical, 7)
            .background(foreground.opacity(0.10), in: Capsule())
    }
}

struct SectionHeading: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 22, weight: .bold, design: .rounded)).foregroundStyle(Palette.ink)
            Text(subtitle).font(.system(size: 12)).foregroundStyle(Palette.muted)
        }
    }
}

struct CuteCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(17)
            .background(.white, in: RoundedRectangle(cornerRadius: 23, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 23).stroke(Palette.purple.opacity(0.05), lineWidth: 1))
            .shadow(color: Palette.purple.opacity(0.07), radius: 17, y: 6)
    }
}

struct ToolTile: View {
    let tool: LabTool

    var body: some View {
        NavigationLink(value: tool) {
            CuteCard {
                VStack(alignment: .leading, spacing: 11) {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(tool.tint.opacity(0.14))
                        .frame(width: 48, height: 48)
                        .overlay {
                            Image(systemName: tool.icon)
                                .font(.system(size: 21, weight: .semibold))
                                .foregroundStyle(tool.tint)
                        }
                    Text(tool.name)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(Palette.ink)
                        .lineLimit(2)
                    Text(tool.sizeText)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Palette.muted)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }
}

struct HomeView: View {
    @EnvironmentObject private var models: ModelStore
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ZStack {
            SoftBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 23) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("hello, sunshine ☀️")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(Palette.muted)
                            Text("Pocket AI Lab")
                                .font(.system(size: 29, weight: .heavy, design: .rounded))
                                .foregroundStyle(Palette.ink)
                        }
                        Spacer()
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(Palette.pink)
                    }
                    hero
                    HStack {
                        SectionHeading(title: "Tiny AI, big magic ✨", subtitle: "Chạm vào một công cụ để bắt đầu")
                        Spacer()
                        BubbleLabel(title: "Offline", systemImage: "wifi.slash")
                    }
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(LabTool.allCases) { tool in
                            ToolTile(tool: tool)
                        }
                    }
                    HStack(spacing: 10) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 19))
                            .foregroundStyle(Palette.mint)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Private by design")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                            Text("Ảnh, văn bản và giọng nói được xử lý trên máy.")
                                .font(.system(size: 11))
                                .foregroundStyle(Palette.muted)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Palette.mint.opacity(0.12), in: RoundedRectangle(cornerRadius: 18))
                    Text("made with ♡ by VietHannn")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Palette.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 12)
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var hero: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 29, style: .continuous)
                .fill(LinearGradient(colors: [Palette.lavender, Palette.rose], startPoint: .topLeading, endPoint: .bottomTrailing))
            Circle().stroke(.white.opacity(0.34), lineWidth: 1)
                .frame(width: 190, height: 190).offset(x: 190, y: -80)
            HStack(spacing: 4) {
                VStack(alignment: .leading, spacing: 11) {
                    BubbleLabel(title: "your pocket buddy", systemImage: "sparkles")
                    Text("AI nhỏ xinh,\nở trong túi bạn.")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .lineSpacing(3)
                        .foregroundStyle(Palette.ink)
                        .minimumScaleFactor(0.85)
                    Text("Không tài khoản · Không API")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Palette.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Spacer(minLength: 0)
                MascotView(size: 95)
                    .frame(width: 119, height: 147)
            }
            .padding(.leading, 19)
            .padding(.trailing, 6)
            .padding(.vertical, 24)
        }
        .frame(height: 203)
        .clipShape(RoundedRectangle(cornerRadius: 29, style: .continuous))
    }
}

struct PlaygroundView: View {
    var body: some View {
        ZStack {
            SoftBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeading(title: "Creative studio 🎨", subtitle: "Chọn kiểu AI bạn muốn thử ngay trên điện thoại.")
                    ForEach(LabTool.allCases) { tool in
                        NavigationLink(value: tool) {
                            CuteCard {
                                HStack(spacing: 14) {
                                    Image(systemName: tool.icon)
                                        .font(.system(size: 22))
                                        .frame(width: 51, height: 51)
                                        .foregroundStyle(tool.tint)
                                        .background(tool.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(tool.name).font(.system(size: 16, weight: .bold, design: .rounded))
                                        Text(tool.description)
                                            .font(.system(size: 12))
                                            .foregroundStyle(Palette.muted)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .foregroundStyle(Palette.ink)
                                    Spacer(minLength: 0)
                                    Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(Palette.muted)
                                }
                            }
                        }.buttonStyle(.plain)
                    }
                }.padding(20)
            }
        }
        .navigationTitle("Studio")
        .navigationBarTitleDisplayMode(.inline)
    }
}
