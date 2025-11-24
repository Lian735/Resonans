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
    @State private var isLoading: Bool = false

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
            viewModel.modelContext = modelContext
            viewModel.getAudioHistories()
        }
        .background(.clear)
        .sheet(item: $activeSheet) { sheetType in
            switch sheetType {
            case .filePicker:
                FilePicker { url in
                    withAnimation {
                        isLoading = true
                    }
                    // Defer sheet switch to next runloop to show overlay promptly
                    DispatchQueue.main.async {
                        activeSheet = .conversion(url)
                    }
                }
            case .photoPicker:
                PhotoLibraryPicker(
                    config: .init(filter: .videos) { urls in
                        guard let firstUrl = urls.first else { return }
                        withAnimation {
                            isLoading = true
                        }
                        DispatchQueue.main.async {
                            activeSheet = .conversion(firstUrl)
                        }
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
                .onAppear { withAnimation {
                    isLoading = true
                } }
                .onDisappear { withAnimation {
                    isLoading = false
                } }
            case .recents(let url):
                ExportPicker(url: url)
            case .filePreview(let url):
                FilePreviewView(fileURL: url)
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
        .overlay(
            Group {
                if isLoading {
                    ZStack {
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .ignoresSafeArea()
                    }
                }
            }
        )
        .allowsHitTesting(!isLoading)
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
            AppCard {
                VStack(alignment: .center, spacing: 12) {
                    if viewModel.histories.isEmpty {
                        Text("No exports yet")
                            .typography(.titleSmall, color: .primary.opacity(0.7), design: .rounded)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 40)
                    } else {
                        let prefixCount = showAllRecents ? viewModel.histories.count : 3
                        let histories = viewModel.histories.prefix(prefixCount)
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(histories.indices, id: \.self) { index in
                                    let history = histories[index]
                                    historyCard(history: history)
                                    
                                    if index < histories.count - 1 {
                                        Divider()
                                            .padding(.leading, 12)
                                    }
                                }
                            }
                        }
                        if viewModel.histories.count > 3 {
                            Button {
                                HapticsManager.shared.pulse()
                                withAnimation(.default) {
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
                        }
                    }
                }
                .animation(.easeInOut, value: viewModel.histories)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    private func titleBox<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private func historyCard(history: AudioHistory) -> some View {
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
            
            VStack(alignment: .leading, spacing: 2) {
                Text(history.title)
                    .typography(.titleMedium, color: .primary, design: .rounded)
                    .lineLimit(1)
                    .truncationMode(.tail)
                HStack(alignment: .center, spacing: 6) {
                    Text(formatTime(history.duration))
                        .typography(.captionBold, color: .primary)
                    Text("-")
                        .typography(.caption, color: .primary)
                    Text(history.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .typography(.caption, color: .primary)
                }
            }
            Spacer()
            if let url = history.fileUrl {
                HStack(spacing: 18) {
                    Button {
                        activeSheet = .filePreview(url)
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                            .typography(.titleMedium, color: .primary.opacity(0.9))
                    }
                    optionMenu(id: history.id, url: url)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private func optionMenu(id: UUID, url: URL) -> some View {
        Menu {
            ShareLink(item: url) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            Button {
                viewModel.deleteHistory(id: id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .typography(.titleMedium, color: .primary.opacity(0.9))
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite else { return "00:00" }
        let totalSeconds = max(Int(seconds.rounded()), 0)
        let minutes = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, secs)
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
    let memoryContainer: ModelContainer = try! ModelContainer(for: History.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let viewModel: AudioExtractorViewModel = AudioExtractorViewModel()
    let metadata: Data = {
        let dict: [String: Any] = ["duration": 100]
        let metadata = try! JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
        return metadata
    }()
    
    let mockHistories: [History] = [
        .createMock(tool: .audioExtractor, title: "History", metadata: metadata),
        .createMock(tool: .audioExtractor, title: "Another History", metadata: metadata),
        .createMock(tool: .audioExtractor, title: "History", metadata: metadata),
        .createMock(tool: .audioExtractor, title: "Another History", metadata: metadata)
    ]
    
    mockHistories.forEach { memoryContainer.mainContext.insert($0) }
    
    return AudioExtractorView(
        viewModel: viewModel
    )
    .accentColor(.purple)
    .modelContainer(memoryContainer)
}

