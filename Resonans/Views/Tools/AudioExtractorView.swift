import SwiftUI

struct AudioExtractorView: View {
    let onClose: () -> Void

    @State private var showPhotoPicker = false
    @State private var showFilePicker = false
    @State private var conversionSource: IdentifiedURL?

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
                heroSection
                sourceOptionsSection
                recentSection
            }
            .padding(.top, AppStyle.innerPadding + 12)
            .padding(.bottom, 80)
            .padding(.horizontal, AppStyle.horizontalPadding)
        }
        .background(.clear)
        .sheet(isPresented: $showPhotoPicker) {
            VideoPicker { url in
                conversionSource = IdentifiedURL(url: url)
            }
        }
        .sheet(isPresented: $showFilePicker) {
            FilePicker { url in
                conversionSource = IdentifiedURL(url: url)
            }
        }
        .sheet(item: $conversionSource) { context in
            ConversionSettingsView(videoURL: context.url)
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
        sectionContainer {
            HStack(alignment: .center, spacing: 18) {
                RoundedRectangle(cornerRadius: AppStyle.iconCornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                accent.color.opacity(0.85),
                                accent.color.opacity(colorScheme == .dark ? 0.55 : 0.45)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .overlay(
                        Image(systemName: "waveform")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(Color.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppStyle.iconCornerRadius, style: .continuous)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 8) {
                    Text("Audio Extractor")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundStyle(primary)

                    Text("Pull crisp audio from your videos in seconds.")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(primary.opacity(0.75))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            Divider()
                .background(primary.opacity(0.08))

            VStack(alignment: .leading, spacing: 10) {
                Label("Fast conversions with pristine quality", systemImage: "bolt.fill")
                    .labelStyle(.titleAndIcon)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(primary.opacity(0.8))

                Label("Works with files and your photo library", systemImage: "folder.badge.plus")
                    .labelStyle(.titleAndIcon)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(primary.opacity(0.8))
            }
        }
    }

    private var sourceOptionsSection: some View {
        sectionContainer {
            Text("Choose a source")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(primary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                sourceOptionCard(icon: "doc.fill", title: "Import from Files") { showFilePicker = true }
                sourceOptionCard(icon: "photo.on.rectangle", title: "Pick from Library") { showPhotoPicker = true }
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
        sectionContainer {
            HStack(alignment: .firstTextBaseline) {
                Text("Recent conversions")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(primary)

                Spacer()

                if recents.count > 3 {
                    Button {
                        HapticsManager.shared.pulse()
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showAllRecents.toggle()
                        }
                    } label: {
                        Text(showAllRecents ? "Show less" : "Show more")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(primary.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
            }

            if recents.isEmpty {
                Text("No exports yet")
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundStyle(primary.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 36)
            } else {
                VStack(spacing: 12) {
                    ForEach(recents.prefix(showAllRecents ? recents.count : 3)) { item in
                        RecentRow(item: item, onSave: handleRecentExport)
                    }
                }
                .padding(.top, 4)
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

    private func sectionContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            content()
        }
        .padding(AppStyle.innerPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                .fill(primary.opacity(AppStyle.cardFillOpacity))
                .overlay(
                    RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                        .stroke(primary.opacity(AppStyle.strokeOpacity), lineWidth: 1)
                )
        )
        .appShadow(colorScheme: colorScheme, level: .medium)
    }
}

#Preview {
    AudioExtractorView()
}

private struct IdentifiedURL: Identifiable {
    let id = UUID()
    let url: URL
}
