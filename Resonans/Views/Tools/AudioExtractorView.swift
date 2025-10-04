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
    private var theme: AppTheme { AppTheme(accent: accent, colorScheme: colorScheme) }

    init(onClose: @escaping () -> Void = {}) {
        self.onClose = onClose
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                sourceOptionsSection
                recentsSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 28)
        }
        .background(theme.background.ignoresSafeArea())
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
        .onDisappear(perform: onClose)
    }

    private var headerSection: some View {
        SurfaceCard(theme: theme) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Extractor")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(theme.foreground)
                        Text("Pull crisp audio from any video clip")
                            .font(.callout)
                            .foregroundStyle(theme.secondary)
                    }

                    Spacer()

                    Image(systemName: "waveform")
                        .font(.title.weight(.bold))
                        .foregroundStyle(theme.accentColor)
                }

                Text("Import a clip from Files or your photo library and we'll extract a clean audio track that's ready to share or archive.")
                    .font(.callout)
                    .foregroundStyle(theme.tertiary)
            }
        }
    }

    private var sourceOptionsSection: some View {
        SurfaceCard(theme: theme) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Choose a source")
                    .font(.headline)
                    .foregroundStyle(theme.foreground)

                let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
                LazyVGrid(columns: columns, spacing: 16) {
                    sourceOptionCard(
                        title: "Import from Files",
                        subtitle: "Browse iCloud Drive and other providers",
                        systemImage: "doc"
                    ) {
                        showFilePicker = true
                    }

                    sourceOptionCard(
                        title: "Pick from Library",
                        subtitle: "Choose videos from your camera roll",
                        systemImage: "photo.on.rectangle"
                    ) {
                        showPhotoPicker = true
                    }
                }
            }
        }
    }

    private func sourceOptionCard(title: String, subtitle: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button {
            HapticsManager.shared.selection()
            action()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(theme.accentColor)
                    .padding(12)
                    .background(theme.buttonBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(theme.foreground)
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(theme.secondary)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(theme.border, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var recentsSection: some View {
        SurfaceCard(theme: theme) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Recent conversions")
                            .font(.headline)
                            .foregroundStyle(theme.foreground)
                        Text("Access exported audio files")
                            .font(.footnote)
                            .foregroundStyle(theme.secondary)
                    }

                    Spacer()

                    if !recents.isEmpty {
                        Button(showAllRecents ? "Show fewer" : "Show all") {
                            HapticsManager.shared.selection()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showAllRecents.toggle()
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(theme.accentColor)
                    }
                }

                if recents.isEmpty {
                    Text("Your conversions will appear here once you export audio.")
                        .font(.callout)
                        .foregroundStyle(theme.tertiary)
                        .padding(.vertical, 8)
                } else {
                    VStack(spacing: 12) {
                        ForEach(displayedRecents) { item in
                            RecentRow(item: item, theme: theme, onSave: handleRecentExport)
                        }
                    }
                }
            }
        }
    }

    private var displayedRecents: [RecentItem] {
        if showAllRecents {
            return recents
        }
        return Array(recents.prefix(3))
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

#Preview {
    AudioExtractorView()
        .preferredColorScheme(.light)
}
