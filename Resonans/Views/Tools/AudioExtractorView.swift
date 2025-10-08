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
            VStack(spacing: 28) {
                topSpacer
                headerSection
                sourceOptionsSection
                recentSection
                Spacer(minLength: 60)
            }
            .padding(.horizontal, AppStyle.horizontalPadding)
        }
        .background(Color.clear)
        .modifier(VideoSourceSheets(
            showPhotoPicker: $showPhotoPicker,
            showFilePicker: $showFilePicker,
            showConversionSheet: $showConversionSheet,
            videoURL: $videoURL
        ))
        .sheet(isPresented: $showRecentExporter, onDismiss: { exportURLForRecent = nil }) {
            if let url = exportURLForRecent {
                ExportPicker(url: url)
            }
        }
        .onAppear(perform: reloadRecents)
        .onReceive(NotificationCenter.default.publisher(for: .recentConversionsDidUpdate), perform: handleRecentUpdate)
    }

    private var topSpacer: some View {
        Color.clear
            .frame(height: AppStyle.innerPadding)
            .padding(.bottom, -24)
    }

    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Extractor")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(primary.opacity(0.7))
                Text("Pull crisp audio from your videos")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(primary)
            }

            Spacer()

            Image(systemName: "waveform")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(accent.color)
        }
    }

    private var sourceOptionsSection: some View {
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

    private func sourceOptionCard(icon: String, title: String, action: @escaping () -> Void) -> some View {
        SourceOptionButton(
            icon: icon,
            title: title,
            primary: primary,
            colorScheme: colorScheme,
            action: action
        )
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Recent conversions")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(primary)
                .padding(.top, 16)
                .padding(.horizontal, AppStyle.innerPadding)

            VStack(spacing: 12) {
                if recents.isEmpty {
                    Text("No exports yet")
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundStyle(primary.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 40)
                } else {
                    ForEach(recents.prefix(showAllRecents ? recents.count : 3)) { item in
                        RecentRow(item: item, onSave: handleRecentExport)
                            .padding(.horizontal, 12)
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
                                .foregroundStyle(primary.opacity(0.75))
                        }
                        .padding(.top, 6)
                    }
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 18)
        }
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

    private func handleRecentUpdate(_ notification: Notification) {
        guard let items = notification.object as? [RecentItem] else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            recents = items
        }
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

private struct VideoSourceSheets: ViewModifier {
    @Binding var showPhotoPicker: Bool
    @Binding var showFilePicker: Bool
    @Binding var showConversionSheet: Bool
    @Binding var videoURL: URL?

    func body(content: Content) -> some View {
        content
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
            .sheet(isPresented: $showConversionSheet, onDismiss: { videoURL = nil }) {
                if let url = videoURL {
                    ConversionSettingsView(videoURL: url)
                }
            }
    }
}

private struct SourceOptionButton: View {
    let icon: String
    let title: String
    let primary: Color
    let colorScheme: ColorScheme
    let action: () -> Void

    var body: some View {
        Button(action: performAction) {
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

    private func performAction() {
        HapticsManager.shared.pulse()
        action()
    }
}

#Preview {
    AudioExtractorView()
}
