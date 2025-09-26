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
    @AppStorage("accentColor") private var accentRaw = AccentColorOption.purple.rawValue

    private var accent: AccentColorOption { AccentColorOption(rawValue: accentRaw) ?? .purple }
    private var primary: Color { AppStyle.primary(for: colorScheme) }

    init(onClose: @escaping () -> Void = {}) {
        self.onClose = onClose
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                headerSection
                sourceOptionsSection
                recentSection
            }
            .padding(.vertical, AppStyle.innerPadding)
            .padding(.horizontal, AppStyle.horizontalPadding)
        }
        .scrollIndicators(.hidden)
        .background(Color.clear)
        .sheet(isPresented: $showPhotoPicker) {
            VideoPicker { url in
                presentConversionSheet(with: url)
            }
        }
        .sheet(isPresented: $showFilePicker) {
            FilePicker { url in
                presentConversionSheet(with: url)
            }
        }
        .sheet(
            isPresented: $showConversionSheet,
            onDismiss: { videoURL = nil }
        ) {
            if let url = videoURL {
                ConversionSettingsView(videoURL: url)
            }
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

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: AppStyle.iconCornerRadius, style: .continuous)
                    .fill(accent.color.opacity(0.16))
                    .frame(width: 54, height: 54)
                    .overlay(
                        Image(systemName: "waveform")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(accent.color)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppStyle.iconCornerRadius, style: .continuous)
                            .stroke(accent.color.opacity(0.4), lineWidth: 1)
                    )
                    .appShadow(colorScheme: colorScheme, level: .small, opacity: 0.35)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Audio Extractor")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(primary)
                    Text("Extrahiere Tonspuren im Handumdrehen")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(primary.opacity(0.7))
                }
                Spacer()
            }
            Divider()
                .background(primary.opacity(0.12))
        }
    }

    private var sourceOptionsSection: some View {
        ToolSection(primary: primary, colorScheme: colorScheme) {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Quelle wählen")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(primary)
                    Text("Lade dein Video entweder aus Dateien oder aus deiner Mediathek.")
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundStyle(primary.opacity(0.65))
                }

                LazyVGrid(columns: sourceOptionColumns, spacing: 16) {
                    sourceOptionCard(
                        icon: "doc.fill",
                        title: "Dateien",
                        subtitle: "Von iCloud oder lokalen Ordnern"
                    ) {
                        showFilePicker = true
                    }

                    sourceOptionCard(
                        icon: "photo.on.rectangle",
                        title: "Mediathek",
                        subtitle: "Wähle Clips aus deinen Fotos"
                    ) {
                        showPhotoPicker = true
                    }
                }
            }
        }
    }

    private func sourceOptionCard(icon: String, title: String, action: @escaping () -> Void) -> some View {
        sourceOptionCard(icon: icon, title: title, subtitle: nil, action: action)
    }

    private func sourceOptionCard(icon: String, title: String, subtitle: String?, action: @escaping () -> Void) -> some View {
        Button {
            HapticsManager.shared.pulse()
            action()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                RoundedRectangle(cornerRadius: AppStyle.iconCornerRadius, style: .continuous)
                    .fill(primary.opacity(AppStyle.iconFillOpacity))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(primary)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppStyle.iconCornerRadius, style: .continuous)
                            .stroke(primary.opacity(AppStyle.iconStrokeOpacity), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(primary)
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundStyle(primary.opacity(0.65))
                            .lineLimit(2)
                    }
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
            .padding(18)
            .appCardStyle(
                primary: primary,
                colorScheme: colorScheme,
                cornerRadius: AppStyle.cornerRadius,
                fillOpacity: AppStyle.cardFillOpacity,
                shadowLevel: .medium
            )
        }
        .buttonStyle(.plain)
    }

    private var recentSection: some View {
        ToolSection(primary: primary, colorScheme: colorScheme) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Letzte Konvertierungen")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundStyle(primary)
                        Text("Schneller Zugriff auf deine letzten Audio-Exporte.")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundStyle(primary.opacity(0.65))
                    }
                    Spacer()
                    if recents.count > 3 {
                        Button {
                            HapticsManager.shared.pulse()
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showAllRecents.toggle()
                            }
                        } label: {
                            Text(showAllRecents ? "Weniger" : "Mehr")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(accent.color)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if recents.isEmpty {
                    VStack(spacing: 12) {
                        Text("Noch keine Exporte")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(primary.opacity(0.8))
                        Text("Sobald du Audio extrahierst, erscheinen die Dateien hier zum erneuten Teilen.")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundStyle(primary.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 32)
                    .frame(maxWidth: .infinity)
                } else {
                    VStack(spacing: 12) {
                        ForEach(recents.prefix(showAllRecents ? recents.count : 3)) { item in
                            RecentRow(item: item, onSave: handleRecentExport)
                        }
                    }
                }
            }
        }
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

    private func presentConversionSheet(with url: URL) {
        Task { @MainActor in
            videoURL = url
            showConversionSheet = true
        }
    }

    private var sourceOptionColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ]
    }
}

private struct ToolSection<Content: View>: View {
    let primary: Color
    let colorScheme: ColorScheme
    let content: Content

    init(primary: Color, colorScheme: ColorScheme, @ViewBuilder content: () -> Content) {
        self.primary = primary
        self.colorScheme = colorScheme
        self.content = content()
    }

    var body: some View {
        content
            .padding(AppStyle.innerPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .appCardStyle(primary: primary, colorScheme: colorScheme)
    }
}

#Preview {
    AudioExtractorView()
}
