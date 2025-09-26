import SwiftUI

struct AudioExtractorView: View {
    let onClose: () -> Void

    @State private var videoURL: URL?
    @State private var showPhotoPicker = false
    @State private var showFilePicker = false
    @State private var showConversionSheet = false

    @State private var recents: [RecentItem] = CacheManager.shared.loadRecentConversions()
    @State private var showAllRecents = false
    @State private var exportURLForRecent: URL?
    @State private var showRecentExporter = false

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage("accentColor") private var accentRaw = AccentColorOption.purple.rawValue

    private var accent: AccentColorOption { AccentColorOption(rawValue: accentRaw) ?? .purple }
    private var primary: Color { AppStyle.primary(for: colorScheme) }
    private var shouldStackActionsVertically: Bool { horizontalSizeClass == .compact || horizontalSizeClass == nil }

    private let highlightMessages: [String] = [
        "Choose MP3, WAV or M4A for the perfect export",
        "Keep your conversions ready to share in Files",
        "Recent sessions stay at hand for quick re-use"
    ]

    init(onClose: @escaping () -> Void = {}) {
        self.onClose = onClose
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 32) {
                Color.clear
                    .frame(height: AppStyle.innerPadding)
                    .padding(.bottom, -24)

                heroSection

                quickImportSection

                highlightsSection

                recentSection

                Spacer(minLength: 60)
            }
            .padding(.horizontal, AppStyle.horizontalPadding)
            .padding(.bottom, AppStyle.innerPadding)
        }
        .background(.clear)
        .sheet(isPresented: $showPhotoPicker) {
            VideoPicker { url in
                videoURL = url
                showConversionSheet = true
            }
        }
        .sheet(isPresented: $showFilePicker) {
            FilePicker { url in
                videoURL = url
                showConversionSheet = true
            }
        }
        .sheet(
            isPresented: $showConversionSheet,
            onDismiss: { videoURL = nil }
        ) {
            ConversionSheetContainer(videoURL: videoURL)
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
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            accent.color.opacity(colorScheme == .dark ? 0.9 : 0.95),
                            accent.color.opacity(0.55)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.2), lineWidth: 1)
                )

            Image(systemName: "waveform")
                .font(.system(size: 46, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.75))
                .padding(24)

            VStack(alignment: .leading, spacing: 18) {
                Text("Audio Extractor")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.85))
                    .textCase(.uppercase)

                Text("Pull crisp audio from any clip")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)

                Text("Start with a file from Files or your photo library. Resonans keeps your exports fast, clean and ready to share.")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.9))

                heroActionButtons
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity)
        .appShadow(colorScheme: colorScheme, level: .large, opacity: 0.35)
    }

    @ViewBuilder
    private var heroActionButtons: some View {
        if shouldStackActionsVertically {
            VStack(spacing: 12) {
                heroButton(
                    icon: "doc.fill",
                    title: "Import from Files",
                    subtitle: "Browse iCloud Drive or local storage",
                    isPrimary: true
                ) {
                    showFilePicker = true
                }

                heroButton(
                    icon: "photo.on.rectangle",
                    title: "Pick from Library",
                    subtitle: "Select a video from Photos",
                    isPrimary: false
                ) {
                    showPhotoPicker = true
                }
            }
        } else {
            HStack(spacing: 12) {
                heroButton(
                    icon: "doc.fill",
                    title: "Import from Files",
                    subtitle: "Browse iCloud Drive or local storage",
                    isPrimary: true
                ) {
                    showFilePicker = true
                }

                heroButton(
                    icon: "photo.on.rectangle",
                    title: "Pick from Library",
                    subtitle: "Select a video from Photos",
                    isPrimary: false
                ) {
                    showPhotoPicker = true
                }
            }
        }
    }

    private func heroButton(icon: String, title: String, subtitle: String, isPrimary: Bool, action: @escaping () -> Void) -> some View {
        Button {
            HapticsManager.shared.pulse()
            action()
        } label: {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.white)
                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.85))
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.9))
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                    .fill(Color.white.opacity(isPrimary ? 0.22 : 0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                            .stroke(Color.white.opacity(isPrimary ? 0.35 : 0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous))
    }

    private var quickImportSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick actions")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(primary)

            Group {
                if shouldStackActionsVertically {
                    VStack(spacing: 16) {
                        quickImportCard(
                            icon: "sparkles",
                            title: "One-tap conversion",
                            description: "Choose a clip and Resonans opens the converter instantly.",
                            accent: accent.color.opacity(0.6)
                        )

                        quickImportCard(
                            icon: "clock.arrow.circlepath",
                            title: "Resume where you left off",
                            description: "Your recent sessions stay pinned for easy exporting.",
                            accent: primary.opacity(0.25)
                        )
                    }
                } else {
                    HStack(spacing: 16) {
                        quickImportCard(
                            icon: "sparkles",
                            title: "One-tap conversion",
                            description: "Choose a clip and Resonans opens the converter instantly.",
                            accent: accent.color.opacity(0.6)
                        )

                        quickImportCard(
                            icon: "clock.arrow.circlepath",
                            title: "Resume where you left off",
                            description: "Your recent sessions stay pinned for easy exporting.",
                            accent: primary.opacity(0.25)
                        )
                    }
                }
            }
        }
    }

    private func quickImportCard(icon: String, title: String, description: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(accent)
                        .frame(width: 42, height: 42)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(colorScheme == .dark ? .black.opacity(0.8) : .white)
                }

                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(primary)
            }

            Text(description)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(primary.opacity(0.75))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCardStyle(primary: primary, colorScheme: colorScheme, shadowLevel: .medium)
    }

    private var highlightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Why creators love it")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(primary)

            VStack(alignment: .leading, spacing: 12) {
                ForEach(highlightMessages, id: \.self) { message in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(accent.color)
                        Text(message)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(primary.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .appCardStyle(primary: primary, colorScheme: colorScheme, shadowLevel: .light)
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center) {
                Text("Recent conversions")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(primary)

                Spacer()

                if recents.count > 3 {
                    Button {
                        HapticsManager.shared.pulse()
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showAllRecents.toggle()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(showAllRecents ? "Show less" : "Show all")
                            Image(systemName: showAllRecents ? "chevron.up" : "chevron.down")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(primary.opacity(0.75))
                    }
                    .buttonStyle(.plain)
                }
            }

            if recents.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "music.quarternote.3")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(primary.opacity(0.45))
                    Text("No exports yet")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(primary.opacity(0.7))
                    Text("Converted files will appear here so you can share them again in seconds.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(primary.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 36)
            } else {
                VStack(spacing: 12) {
                    ForEach(recents.prefix(showAllRecents ? recents.count : 3)) { item in
                        RecentRow(item: item, onSave: handleRecentExport)
                            .padding(.horizontal, 12)
                    }
                }
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                .fill(primary.opacity(AppStyle.subtleCardFillOpacity))
                .overlay(
                    RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                        .stroke(primary.opacity(AppStyle.strokeOpacity), lineWidth: 1)
                )
        )
        .appShadow(colorScheme: colorScheme, level: .medium)
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
}

private struct ConversionSheetContainer: View {
    let videoURL: URL?

    @Environment(\.colorScheme) private var colorScheme
    private var placeholderBackground: Color {
        colorScheme == .dark ? .black : Color(.systemGray6)
    }

    var body: some View {
        if let url = videoURL {
            ConversionSettingsView(videoURL: url)
        } else {
            ZStack {
                placeholderBackground
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(AppStyle.primary(for: colorScheme))
                    Text("Preparing media…")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppStyle.primary(for: colorScheme).opacity(0.8))
                }
            }
        }
    }
}

#Preview {
    AudioExtractorView()
}
