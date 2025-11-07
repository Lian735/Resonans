import SwiftUI

struct ToolItem: Identifiable {
    let id: ToolIdentifier
    let title: String
    let subtitle: String
    let iconName: String
    let gradientHex: [String]
    let beta: Bool
    let favorite: Bool
}

enum ToolIdentifier: String, Hashable {
    case audioExtractor
    case bgRemover
    case editor
    
    var tool: ToolItem {
        switch self {
        case .audioExtractor:
            return ToolItem(
                id: .audioExtractor,
                title: "Extractor",
                subtitle: "Pull crisp audio tracks from your videos in seconds.",
                iconName: "waveform",
                gradientHex: ["#B43AA6", "#FD1D1D"],
                beta: false,
                favorite: true
            )
        case .bgRemover:
            return ToolItem(
                id: .bgRemover,
                title: "Background Remover",
                subtitle: "Removes Background from your images",
                iconName: "circle.rectangle.filled.pattern.diagonalline",
                gradientHex: ["#2A7D9B", "#53EDAD"],
                beta: false,
                favorite: false
            )
        case .editor:
            return ToolItem(
                id: .editor,
                title: "Editor",
                subtitle: "Edit your videos and images",
                iconName: "scissors",
                gradientHex: ["#412A9B", "#ED53B2"],
                beta: true,
                favorite: true
            )
        }
    }
    
    @ViewBuilder
    var destination: some View {
        switch self {
        case .audioExtractor:
            AudioExtractorView(viewModel: AudioExtractorViewModel(cacheManager: CacheManager.shared))
        case .bgRemover:
            BgRemoverView(viewModel: BgRemoverViewModel())
        case .editor:
            EditorView()
        }
    }
}

