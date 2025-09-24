import SwiftUI

struct AudioExtractorView: View {
    let onClose: () -> Void

    @State private var videoURL: URL?
    @State private var showPhotoPicker = false
    @State private var showFilePicker = false
    @State private var showConversionSheet = false
    @State private var showExporter = false
    @State private var exporterURL: URL?

    @State private var recents: [RecentItem] = []
    @State private var showAllRecents = false

    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("accentColor") private var accentRaw = AccentColorOption.purple.rawValue

    private var accent: AccentColorOption { AccentColorOption(rawValue: accentRaw) ?? .purple }
    private var background: Color { AppStyle.background(for: colorScheme) }
    private var primary: Color { AppStyle.primary(for: colorScheme) }

    init(onClose: @escaping () -> Void = {}) {
        self.onClose = onClose
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 28) {
                Color.clear
                    .frame(height: AppStyle.innerPadding)
                    .padding(.bottom, -24)

                sourceSelectionSection
                    .padding(.horizontal, AppStyle.horizontalPadding)

                recentSection
                    .padding(.horizontal, AppStyle.horizontalPadding)

                Spacer(minLength: 40)
            }
        }
        .background(
            .clear
        )
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
                ConversionSettingsView(videoURL: url) { exportURL, duration in
                    handleConversionResult(url: exportURL, duration: duration)
                }
            }
        }
        .sheet(isPresented: $showExporter, onDismiss: { exporterURL = nil }) {
            if let exporterURL = exporterURL {
                ExportPicker(url: exporterURL)
            }
        }
        .task {
            loadRecents()
        }
    }

    private var sourceSelectionSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Extractor")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(primary.opacity(0.7))
                    Text("Pull crisp audio from any clip")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(primary)
                }
                Spacer()
                Image(systemName: "waveform")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(accent.color)
            }

            Text("Choose where to import your video from.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(primary.opacity(0.65))

            HStack(spacing: 16) {
                sourceOptionCard(icon: "doc.fill", title: "Import from Files") {
                    showFilePicker = true
                }

                sourceOptionCard(icon: "photo.on.rectangle", title: "Pick from Library") {
                    showPhotoPicker = true
                }
            }
        }
        .padding(AppStyle.innerPadding)
        .background(
            RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                .fill(primary.opacity(AppStyle.cardFillOpacity))
                .overlay(
                    RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                        .stroke(primary.opacity(AppStyle.strokeOpacity), lineWidth: 1)
                )
        )
        .appShadow(colorScheme: colorScheme, level: .large)
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
        .buttonStyle(.plain)
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
                        RecentRow(item: item, onExport: presentExporter(for:))
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

    private func loadRecents() {
        let stored = CacheManager.shared.loadRecentConversions()
        let existing = stored.filter { FileManager.default.fileExists(atPath: $0.fileURL.path) }
        recents = existing.sorted(by: { $0.createdAt > $1.createdAt })
        if existing.count != stored.count {
            CacheManager.shared.saveRecentConversions(recents)
        }
    }

    private func handleConversionResult(url: URL, duration: TimeInterval) {
        let fileName = url.deletingPathExtension().lastPathComponent
        let newItem = RecentItem(title: fileName, duration: duration, fileURL: url)

        recents.removeAll(where: { $0.fileURL == url })
        recents.insert(newItem, at: 0)

        if recents.count > 10 {
            recents = Array(recents.prefix(10))
        }

        CacheManager.shared.saveRecentConversions(recents)
    }

    private func presentExporter(for item: RecentItem) {
        exporterURL = item.fileURL
        showExporter = true
    }
}

#Preview {
    AudioExtractorView()
}
