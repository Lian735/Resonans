import SwiftUI
import PhotosUI

struct AudioExtractorView: View {
    @StateObject var viewModel: AudioExtractorViewModel
    @State private var showAllRecents = false
    @State private var activeSheet: ActiveSheet?

    @Environment(\.colorScheme) private var colorScheme
    @AppStorage(AppStorageKey.Settings.accentColor) private var accentRaw = AccentColorOption.purple.rawValue

    private var accent: AccentColorOption { AccentColorOption(rawValue: accentRaw) ?? .purple }

    init(viewModel: AudioExtractorViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 28) {

                headerSection
                
                Divider()

                sourceOptionsSection

                recentSection

                Spacer(minLength: 60)
            }
            .padding(.horizontal, AppStyle.horizontalPadding)
        }
        .background(.clear)
        .sheet(item: $activeSheet) { sheetType in
            switch sheetType {
            case .filePicker:
                FilePicker { url in
                    activeSheet = .conversion(url)
                }
            case .photoPicker:
                PhotoLibraryPicker(
                    config: .init(filter: .videos) { urls in
                        guard let firstUrl = urls.first else { return }
                        activeSheet = .conversion(firstUrl)
                    }
                )
            case .conversion(let url):
                AudioConversionView(
                    viewModel: AudioConversionViewModel(
                        videoConverter: VideoToAudioConverter()
                    ),
                    videoUrl: url
                )
            case .recents(let url):
                ExportPicker(url: url)
            }
        }
        .onAppear(perform: viewModel.reloadRecents)
        .onReceive(NotificationCenter.default.publisher(for: .recentConversionsDidUpdate)) { notification in
            guard let items = notification.object as? [RecentItem] else { return }
            withAnimation(.easeInOut(duration: 0.25)) {
                viewModel.recents = items
            }
        }
        .background(
            LinearGradient(
                colors: [accent.gradient, .clear],
                startPoint: .topLeading,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    private var headerSection: some View {
        titleBox {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Audio Extractor")
                        .typography(.displaySmall, design: .rounded)
                    Text("Pull crisp audio from your videos")
                        .typography(.titleMedium, color: .primary.opacity(0.7), design: .rounded)
                        .padding(.top, 4)
                }

                Spacer()

                Image(systemName: "waveform")
                    .typography(.custom(size: 35, weight: .medium), color: .primary)
            }
        }
    }

    private var sourceOptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Choose a source")
                    .typography(.titleLarge, color: .primary, design: .rounded)
                Spacer()
            }
            HStack(spacing: 16) {
                sourceOptionCard(icon: "doc.fill", title: "Import from Files") {
                    activeSheet = .filePicker
                }

                sourceOptionCard(icon: "photo.on.rectangle", title: "Pick from Library") {
                    activeSheet = .photoPicker
                }
            }
        }
    }

    private func sourceOptionCard(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button {
            HapticsManager.shared.pulse()
            action()
        } label: {
            AppCard {
                VStack(spacing: 12) {
                    Image(systemName: icon)
                        .typography(.custom(size: 30, weight: .semibold))
                    Text(title)
                        .typography(.titleSmall, design: .rounded)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }
        }
        .buttonStyle(.plain)
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("History")
                    .typography(.titleLarge, color: .primary, design: .rounded)
                Spacer()
            }
            AppCard{
                VStack(alignment: .leading, spacing: 12) {
                    VStack(spacing: 12) {
                        if viewModel.recents.isEmpty {
                            Text("No exports yet")
                                .typography(.titleSmall, color: .primary.opacity(0.7), design: .rounded)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 40)
                        } else {
                            let prefixCount = showAllRecents ? viewModel.recents.count : 3
                            let recents = Array(viewModel.recents.prefix(prefixCount))
                            
                            ForEach(recents.indices, id: \.self) { index in
                                let item = recents[index]
                                VStack(spacing: 12) {
                                    RecentRow(item: item, onSave: handleRecentExport)
                                        .padding(.horizontal, 12)
                                    
                                    if index < recents.count - 1 {
                                        Divider()
                                            .padding(.leading, 12)
                                    }
                                }
                            }
                            
                            if viewModel.recents.count > 3 {
                                GlassButton {
                                    HapticsManager.shared.pulse()
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        showAllRecents.toggle()
                                    }
                                } label: {
                                    Text(showAllRecents ? "Show less" : "Show more")
                                        .typography(.bodyBold, color: .primary.opacity(0.75), design: .rounded)
                                }
                                .padding(.top, 6)
                            }
                        }
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 18)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func handleRecentExport(_ item: RecentItem) {
        let url = item.fileURL
        guard FileManager.default.fileExists(atPath: url.path) else {
            viewModel.reloadRecents()
            return
        }
        activeSheet = .recents(url)
    }
    private func titleBox<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
            VStack(alignment: .leading, spacing: 16) {
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
    }

}

// MARK: - Sheet Handler
extension AudioExtractorView {
    enum ActiveSheet: Identifiable {
        case photoPicker, filePicker, recents(URL), conversion(URL)
        var id: String { String(describing: self) }
    }
}

#Preview {
    let viewModel: AudioExtractorViewModel = AudioExtractorViewModel(cacheManager: CacheManager.shared)
    viewModel.recents = [
        .init(title: "Conversion Hahahahahahha", duration: "20 Minutes", fileURL: URL(string: "hello.com")!),
        .init(title: "Modar", duration: "29 Minutes", fileURL: URL(string: "hello.com")!)
    ]
    return AudioExtractorView(
        viewModel: viewModel
    )
}

