import SwiftUI

struct AudioExtractorView: View {
    let onClose: () -> Void

    @State private var showPhotoPicker = false
    @State private var showFilePicker = false
    @State private var conversionState: ConversionLaunchState?

    @State private var recents: [RecentItem] = CacheManager.shared.loadRecentConversions()
    @State private var showAllRecents = false
    @State private var exportURLForRecent: URL?
    @State private var showRecentExporter = false

    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("accentColor") private var accentRaw = AccentColorOption.purple.rawValue

    private var accent: AccentColorOption { AccentColorOption(rawValue: accentRaw) ?? .purple }
    private var primary: Color { AppStyle.primary(for: colorScheme) }

    init(onClose: @escaping () -> Void = {}) {
        self.onClose = onClose
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 28) {
                heroSection
                sourceOptionsSection
                highlightsSection
                recentSection
            }
            .padding(.horizontal, AppStyle.horizontalPadding)
            .padding(.vertical, AppStyle.innerPadding)
        }
        .background(
            LinearGradient(
                colors: [accent.gradient.opacity(0.25), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .sheet(isPresented: $showPhotoPicker) {
            VideoPicker { url in
                launchConversion(with: url)
            }
        }
        .sheet(isPresented: $showFilePicker) {
            FilePicker { url in
                launchConversion(with: url)
            }
        }
        .sheet(item: $conversionState, onDismiss: { conversionState = nil }) { state in
            ConversionLaunchSheet(state: state, accent: accent.color, primary: primary)
        }
        .sheet(isPresented: $showRecentExporter, onDismiss: { exportURLForRecent = nil }) {
            if let url = exportURLForRecent {
                ExportPicker(url: url)
            }
        }
        .onAppear(perform: reloadRecents)
        .onReceive(NotificationCenter.default.publisher(for: .recentConversionsDidUpdate)) { notification in
            guard let items = notification.object as? [RecentItem] else { return }
            withAnimation(.easeInOut(duration: 0.25)) {
                recents = items
            }
        }
    }

    private var heroSection: some View {
        ZStack(alignment: .bottomTrailing) {
            LinearGradient(
                colors: [accent.color.opacity(0.85), accent.color.opacity(0.55), accent.color.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous))

            VStack(alignment: .leading, spacing: 16) {
                Text("Audio Extractor")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .textCase(.uppercase)
                    .kerning(1.1)
                    .foregroundStyle(Color.white.opacity(0.75))

                Text("Pull crisp audio from any clip")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.white)

                Text("Import a video and Resonans will handle the rest – trim, convert and export in seconds.")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.85))

                HStack(spacing: 16) {
                    Label("Lossless options", systemImage: "sparkles")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.9))
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(Color.white.opacity(0.14))
                        .clipShape(Capsule())

                    Label("Fast exports", systemImage: "bolt.fill")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.9))
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(Color.white.opacity(0.14))
                        .clipShape(Capsule())
                }
                .padding(.top, 4)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(26)

            Image(systemName: "waveform")
                .font(.system(size: 58, weight: .black))
                .foregroundStyle(Color.white.opacity(0.22))
                .padding(26)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(HeroCardShadow())
    }

    private var sourceOptionsSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Start a conversion")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(primary)
                Text("Bring in media from anywhere – Resonans prepares it instantly for extraction.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(primary.opacity(0.65))
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                sourceOptionCard(
                    icon: "externaldrive.fill",
                    title: "Import from Files",
                    subtitle: "Browse iCloud Drive, Dropbox and more",
                    accentColor: accent.color.opacity(0.2)
                ) {
                    showFilePicker = true
                }

                sourceOptionCard(
                    icon: "photo.on.rectangle",
                    title: "Pick from Library",
                    subtitle: "Choose a clip from your camera roll",
                    accentColor: accent.color.opacity(0.12)
                ) {
                    showPhotoPicker = true
                }
            }
        }
        .padding(AppStyle.innerPadding)
        .appCardStyle(primary: primary, colorScheme: colorScheme, shadowLevel: .medium)
    }

    private func sourceOptionCard(icon: String, title: String, subtitle: String, accentColor: Color, action: @escaping () -> Void) -> some View {
        Button {
            HapticsManager.shared.pulse()
            action()
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppStyle.iconCornerRadius, style: .continuous)
                        .fill(accentColor)
                    Image(systemName: icon)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(primary)
                }
                .frame(width: 52, height: 52)

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(primary)
                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(primary.opacity(0.65))
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 6) {
                    Text("Select")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(accent.color)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(accent.color.opacity(0.9))
                }
                .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                    .fill(primary.opacity(AppStyle.cardFillOpacity))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                            .stroke(primary.opacity(AppStyle.strokeOpacity), lineWidth: 1)
                    )
            )
            .appShadow(colorScheme: colorScheme, level: .small)
        }
        .buttonStyle(.plain)
    }

    private var highlightsSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Built for creators")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(primary)

            VStack(alignment: .leading, spacing: 14) {
                featureRow(icon: "scissors", title: "Smart trimming", description: "Choose the exact portion you need before exporting.")
                featureRow(icon: "wand.and.stars", title: "Clean output", description: "Automatic loudness balancing keeps your mix consistent.")
                featureRow(icon: "rectangle.compress.vertical", title: "Lightweight files", description: "Pick MP3, WAV or M4A with tuned presets for podcasts or reels.")
            }
        }
        .padding(AppStyle.innerPadding)
        .appCardStyle(primary: primary, colorScheme: colorScheme, shadowLevel: .small)
    }

    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: AppStyle.iconCornerRadius, style: .continuous)
                    .fill(accent.color.opacity(0.16))
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(accent.color)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(primary)
                Text(description)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(primary.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("Recent conversions")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(primary)

                Spacer()

                if !recents.isEmpty {
                    Button {
                        HapticsManager.shared.pulse()
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showAllRecents.toggle()
                        }
                    } label: {
                        Text(showAllRecents ? "Show fewer" : "Show all")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(accent.color)
                    }
                    .buttonStyle(.plain)
                }
            }

            if recents.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "waveform.path")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(primary.opacity(0.35))

                    Text("No exports yet")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(primary.opacity(0.75))

                    Text("Your most recent conversions will appear here for quick sharing and saving.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(primary.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                VStack(spacing: 12) {
                    ForEach(recents.prefix(showAllRecents ? recents.count : 3)) { item in
                        RecentRow(item: item, onSave: handleRecentExport)
                            .padding(.horizontal, 12)
                    }
                }
            }
        }
        .padding(AppStyle.innerPadding)
        .appCardStyle(primary: primary, colorScheme: colorScheme, shadowLevel: .medium)
    }

    private func reloadRecents() {
        recents = CacheManager.shared.loadRecentConversions()
    }

    private func handleRecentExport(_ item: RecentItem) {
        let url = item.fileURL
        guard FileManager.default.fileExists(atPath: url.path) else {
            reloadRecents()
            return
        }
        exportURLForRecent = url
        showRecentExporter = true
    }

    private func launchConversion(with url: URL) {
        let state = ConversionLaunchState()
        conversionState = state
        DispatchQueue.main.async {
            state.videoURL = url
            state.isLoading = false
        }
    }
}

private struct HeroCardShadow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: Color.black.opacity(0.18), radius: 32, x: 0, y: 18)
    }
}

final class ConversionLaunchState: ObservableObject, Identifiable {
    let id = UUID()
    @Published var videoURL: URL?
    @Published var isLoading: Bool

    init(videoURL: URL? = nil, isLoading: Bool = true) {
        self.videoURL = videoURL
        self.isLoading = isLoading
    }
}

private struct ConversionLaunchSheet: View {
    @ObservedObject var state: ConversionLaunchState
    let accent: Color
    let primary: Color
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if let url = state.videoURL, !state.isLoading {
                ConversionSettingsView(videoURL: url)
            } else {
                loadingPlaceholder
            }
        }
    }

    private var loadingPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [
                    accent.opacity(0.45),
                    AppStyle.background(for: colorScheme)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                    .fill(AppStyle.background(for: colorScheme).opacity(0.28))
                    .frame(width: 220, height: 140)
                    .overlay(
                        ProgressView()
                            .tint(accent)
                            .scaleEffect(1.2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                            .stroke(primary.opacity(0.15), lineWidth: 1)
                    )

                VStack(spacing: 8) {
                    Text("Preparing media…")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(primary)
                    Text("Hang tight while we ready your file for conversion.")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(primary.opacity(0.7))
                }
                .multilineTextAlignment(.center)
            }
            .padding(32)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    AudioExtractorView()
}
