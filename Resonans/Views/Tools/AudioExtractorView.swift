import SwiftUI

struct AudioExtractorView: View {
    let onClose: () -> Void

    @State private var showPhotoPicker = false
    @State private var showFilePicker = false
    @State private var pendingMedia: PendingMedia?

    @State private var recents: [RecentItem] = CacheManager.shared.loadRecentConversions()
    @State private var showAllRecents = false
    @State private var exportURLForRecent: URL?
    @State private var showRecentExporter = false

    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("accentColor") private var accentRaw = AccentColorOption.purple.rawValue

    private var accent: AccentColorOption { AccentColorOption(rawValue: accentRaw) ?? .purple }
    private var primary: Color { AppStyle.primary(for: colorScheme) }

    private struct PendingMedia: Identifiable {
        let id = UUID()
        let url: URL
    }

    init(onClose: @escaping () -> Void = {}) {
        self.onClose = onClose
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                headerSection
                sourceOptionsSection
                recentSection
                Spacer(minLength: 32)
            }
            .padding(.horizontal, AppStyle.horizontalPadding)
            .padding(.vertical, AppStyle.innerPadding)
        }
        .background(.clear)
        .sheet(isPresented: $showPhotoPicker) {
            VideoPicker { url in
                pendingMedia = PendingMedia(url: url)
            }
        }
        .sheet(isPresented: $showFilePicker) {
            FilePicker { url in
                pendingMedia = PendingMedia(url: url)
            }
        }
        .sheet(item: $pendingMedia, onDismiss: { pendingMedia = nil }) { item in
            ConversionSettingsView(videoURL: item.url)
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
        sectionCard(spacing: 20) {
            HStack(alignment: .center, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Audio Extractor")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(primary)
                    Text("Pull crisp audio from your videos")
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundStyle(primary.opacity(0.75))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                RoundedRectangle(cornerRadius: AppStyle.iconCornerRadius, style: .continuous)
                    .fill(accent.color.opacity(0.18))
                    .frame(width: 64, height: 64)
                    .overlay(
                        Image(systemName: "waveform")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(accent.color)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppStyle.iconCornerRadius, style: .continuous)
                            .stroke(accent.color.opacity(0.35), lineWidth: 1)
                    )
            }
        }
    }

    private var sourceOptionsSection: some View {
        sectionCard(spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Choose a source")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(primary)
                Text("Bring in a clip to begin extracting audio.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(primary.opacity(0.65))
            }

            LazyVGrid(columns: sourceGridColumns, spacing: 14) {
                sourceOptionButton(
                    icon: "doc.fill",
                    title: "Import from Files"
                ) {
                    showFilePicker = true
                }

                sourceOptionButton(
                    icon: "photo.on.rectangle",
                    title: "Pick from Library"
                ) {
                    showPhotoPicker = true
                }
            }
        }
    }

    private var sourceGridColumns: [GridItem] {
        [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]
    }

    private func sourceOptionButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button {
            HapticsManager.shared.pulse()
            action()
        } label: {
            VStack(spacing: 12) {
                RoundedRectangle(cornerRadius: AppStyle.iconCornerRadius, style: .continuous)
                    .fill(accent.color.opacity(0.18))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(accent.color)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppStyle.iconCornerRadius, style: .continuous)
                            .stroke(accent.color.opacity(0.35), lineWidth: 1)
                    )

                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: AppStyle.compactCornerRadius, style: .continuous)
                    .fill(primary.opacity(AppStyle.cardFillOpacity))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppStyle.compactCornerRadius, style: .continuous)
                            .stroke(primary.opacity(AppStyle.strokeOpacity), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var recentSection: some View {
        sectionCard(spacing: 20) {
            Text("Recent conversions")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(primary)

            if recents.isEmpty {
                Text("No exports yet")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(primary.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 28)
            } else {
                VStack(spacing: 12) {
                    ForEach(recents.prefix(showAllRecents ? recents.count : 3)) { item in
                        RecentRow(item: item, onSave: handleRecentExport)
                    }

                    if recents.count > 3 {
                        Button {
                            HapticsManager.shared.pulse()
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showAllRecents.toggle()
                            }
                        } label: {
                            Text(showAllRecents ? "Show less" : "Show more")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(accent.color)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }
                }
            }
        }
    }

    private func sectionCard<Content: View>(
        alignment: HorizontalAlignment = .leading,
        spacing: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: alignment, spacing: spacing, content: content)
            .padding(AppStyle.innerPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
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
}

#Preview {
    AudioExtractorView()
}
