import SwiftUI

struct AudioExtractorView: View {
    let onClose: () -> Void

    private struct PendingVideoSelection: Identifiable {
        let id = UUID()
        let url: URL
    }

    @State private var showPhotoPicker = false
    @State private var showFilePicker = false
    @State private var pendingSelection: PendingVideoSelection?

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
            .padding(.horizontal, AppStyle.horizontalPadding)
            .padding(.vertical, AppStyle.innerPadding)
        }
        .background(Color.clear)
        .sheet(isPresented: $showPhotoPicker) {
            VideoPicker { url in
                presentConversion(for: url)
            }
        }
        .sheet(isPresented: $showFilePicker) {
            FilePicker { url in
                presentConversion(for: url)
            }
        }
        .sheet(item: $pendingSelection) { selection in
            ConversionSettingsView(videoURL: selection.url)
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
        sectionCard {
            HStack(alignment: .top, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Audio extractor")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(primary.opacity(0.65))

                    Text("Pull crisp audio from your videos")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(primary)
                        .multilineTextAlignment(.leading)

                    Text("Select a source to convert footage into high quality audio in just a few taps.")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(primary.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                RoundedRectangle(cornerRadius: AppStyle.iconCornerRadius, style: .continuous)
                    .fill(accent.color.opacity(0.18))
                    .frame(width: 54, height: 54)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppStyle.iconCornerRadius, style: .continuous)
                            .stroke(accent.color.opacity(0.35), lineWidth: 1)
                    )
                    .overlay(
                        Image(systemName: "waveform")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(accent.color)
                    )
                    .appShadow(colorScheme: colorScheme, level: .small, opacity: 0.35)
            }
        }
    }

    private var sourceOptionsSection: some View {
        sectionCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Choose a source")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(primary)

                HStack(spacing: 16) {
                    sourceOptionCard(icon: "doc.fill", title: "Import from Files") {
                        showFilePicker = true
                    }

                    sourceOptionCard(icon: "photo.on.rectangle", title: "Pick from Library") {
                        showPhotoPicker = true
                    }
                }
            }
        }
    }

    private func sourceOptionCard(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button {
            HapticsManager.shared.pulse()
            action()
        } label: {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(primary)
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .appCardStyle(primary: primary, colorScheme: colorScheme, shadowLevel: .medium)
        }
        .buttonStyle(.plain)
    }

    private var recentSection: some View {
        sectionCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Recent conversions")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(primary)

                    Spacer()

                    if !recents.isEmpty {
                        Button {
                            HapticsManager.shared.selection()
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showAllRecents.toggle()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text(showAllRecents ? "Show less" : "Show more")
                                Image(systemName: showAllRecents ? "chevron.up" : "chevron.down")
                            }
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(primary.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                    }
                }

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

    private func presentConversion(for url: URL) {
        pendingSelection = PendingVideoSelection(url: url)
    }

    private func sectionCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            content()
        }
        .padding(.vertical, 24)
        .padding(.horizontal, AppStyle.innerPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCardStyle(primary: primary, colorScheme: colorScheme)
    }
}

#Preview {
    AudioExtractorView()
}
