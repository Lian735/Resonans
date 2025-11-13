import SwiftUI
import PhotosUI
import SwiftData

/// The main view for the Audio Extractor tool.
///
/// `AudioExtractorView` provides a full-screen interface for extracting audio from video files.
/// It displays:
/// - Header section with tool title and description
/// - Source selection options (Files, Library)
/// - History section showing recent conversions
///
/// The view manages multiple sheet presentations for:
/// - File picker (``FilePicker``)
/// - Photo library picker (``PhotoLibraryPicker``)
/// - Audio conversion interface (``AudioConversionView``)
/// - Export picker (``ExportPicker``)
///
/// The view automatically reloads recent conversions when notified via ``NotificationCenter``.
///
/// Example usage:
/// ```swift
/// AudioExtractorView(
///     viewModel: AudioExtractorViewModel(cacheManager: CacheManager.shared)
/// )
/// ```
///
/// - Important: Uses ``HapticsManager`` for tactile feedback on user interactions.
/// - Note: The background features an animated gradient based on the selected accent color.
struct AudioExtractorView: View {
    @StateObject var viewModel: AudioExtractorViewModel
    @State private var showAllRecents = false
    @State private var activeSheet: ActiveSheet?

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @AppStorage(AppStorageKey.Settings.accentColor) private var accentRaw = AccentColorOption.purple.rawValue

    private var accent: AccentColorOption { AccentColorOption(rawValue: accentRaw) ?? .purple }

    init(viewModel: AudioExtractorViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                    .padding(.horizontal, 24)
                
                Divider()
                
                VStack {
                    sourceSection
                    
                    recentSection
                }
                .padding(.horizontal, 24)
            }
        }
        .onAppear {
            viewModel.getAudioHistories(modelContext: modelContext)
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
                        videoConverter: VideoToAudioConverter(),
                        modelContext: modelContext
                    ),
                    videoUrl: url
                )
            case .recents(let url):
                ExportPicker(url: url)
            case .filePreview(let url):
                FilePreviewView(fileURL: url)
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
                colors: [accent.gradient.opacity(0.7), .clear],
                startPoint: .bottomTrailing,
                endPoint: .top
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
                    Text("Extract audio from your videos")
                        .typography(.titleMedium, color: .primary.opacity(0.7), design: .rounded)
                        .padding(.top, 4)
                }
                Spacer()
                Image(systemName: "waveform")
                    .typography(.custom(size: 35, weight: .medium), color: .primary)
            }
        }
    }

    private var sourceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Choose a source")
                    .typography(.titleLarge, color: .primary, design: .rounded)
                Spacer()
            }
            HStack(spacing: 16) {
                sourceOptionCard(icon: "doc.fill", title: "Files") {
                    activeSheet = .filePicker
                }

                sourceOptionCard(icon: "photo.on.rectangle.fill", title: "Library") {
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
                .padding(.vertical, 12)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("History")
                .typography(.titleLarge, color: .primary, design: .rounded)
            AppCard{
                VStack(alignment: .leading, spacing: 12) {
                    VStack(spacing: 12) {
                        if viewModel.histories.isEmpty {
                            Text("No exports yet")
                                .typography(.titleSmall, color: .primary.opacity(0.7), design: .rounded)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 40)
                        } else {
                            let prefixCount = showAllRecents ? viewModel.histories.count : 3
                            let histories = viewModel.histories.prefix(prefixCount)
                            ForEach(histories.indices, id: \.self) { index in
                                let history = histories[index]
                                VStack(spacing: 12) {
                                    historyCard(history: history)
                                    if index < histories.count - 1 {
                                        Divider()
                                            .padding(.leading, 12)
                                    }
                                }
                            }
                            if viewModel.histories.count > 3 {
                                Button {
                                    HapticsManager.shared.pulse()
                                    withAnimation(.bouncy) {
                                        showAllRecents.toggle()
                                    }
                                } label: {
                                    HStack {
                                        Text(showAllRecents ? "Show less" : "Show more")
                                            .typography(.bodyBold, color: .primary, design: .rounded)
                                        Image(systemName: showAllRecents ? "chevron.up" : "chevron.down")
                                            .typography(.bodyBold, color: .primary)
                                    }
                                }
                                .padding(.top, 6)
                            }
                        }
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 18)
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
    
    @ViewBuilder
    private func historyCard(history: History) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: AppStyle.iconCornerRadius, style: .continuous)
                .fill(.primary.opacity(AppStyle.iconFillOpacity))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: "waveform")
                        .typography(.titleMedium, color: .primary.opacity(0.9))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppStyle.iconCornerRadius, style: .continuous)
                        .stroke(.primary.opacity(AppStyle.iconStrokeOpacity), lineWidth: 1)
                )
                .shadow(ShadowConfiguration.smallConfiguration(for: colorScheme))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(history.title)
                    .typography(.titleMedium, color: .primary, design: .rounded)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(history.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .typography(.caption, color: .primary)
            }
            Spacer()
            if let url = history.fileUrl {
                HStack(spacing: 12) {
                    Button {
                        activeSheet = .filePreview(url)
                    } label: {
                        Image(systemName: "folder")
                            .typography(.titleMedium, color: .primary.opacity(0.9))
                    }
                    
                    ShareLink(item: url) {
                        Image(systemName: "square.and.arrow.up")
                            .typography(.titleMedium, color: .primary.opacity(0.9))
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        HapticsManager.shared.selection()
                    })
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

}

// MARK: - Sheet Handler
extension AudioExtractorView {
    /// Identifies which sheet is currently being presented in ``AudioExtractorView``.
    ///
    /// Cases:
    /// - ``photoPicker``: Shows the photo library picker
    /// - ``filePicker``: Shows the file picker
    /// - ``recents``: Shows the export picker for a recent conversion
    /// - ``conversion``: Shows the audio conversion interface for a selected video
    enum ActiveSheet: Identifiable {
        case photoPicker, filePicker, recents(URL), conversion(URL), filePreview(URL)
        var id: String { String(describing: self) }
    }
}

#Preview {
    let memoryContainer = try! ModelContainer(
        for: History.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let viewModel: AudioExtractorViewModel = AudioExtractorViewModel(cacheManager: CacheManager.shared)
    let mockHistories: [History] = [
        History(
            title: "History",
            tool: ToolIdentifier.audioExtractor.rawValue,
            fileUrl: URL(fileURLWithPath: "")
        ),
        History(
            title: "Audio History",
            tool: ToolIdentifier.audioExtractor.rawValue,
            fileUrl: URL(fileURLWithPath: "")
        ),
        History(
            title: "Audio History",
            tool: ToolIdentifier.audioExtractor.rawValue,
            fileUrl: URL(fileURLWithPath: "")
        ),
        History(
            title: "Audio History",
            tool: ToolIdentifier.audioExtractor.rawValue,
            fileUrl: URL(fileURLWithPath: "")
        )
    ]
    
    mockHistories.forEach { memoryContainer.mainContext.insert($0) }
    
    return AudioExtractorView(
        viewModel: viewModel
    )
    .accentColor(.purple)
    .modelContainer(memoryContainer)
}

