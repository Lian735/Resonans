import SwiftUI

struct ToolItem: Identifiable {
    let id: ToolIdentifier
    let title: String
    let subtitle: String
    let iconName: String
    let gradientHex: [String]
}

enum ToolIdentifier: String, Hashable {
    case audioExtractor
    case dummy
    
    var tool: ToolItem {
        switch self {
        case .audioExtractor:
            ToolItem(
                id: .audioExtractor,
                title: "Extractor",
                subtitle: "Pull crisp audio tracks from your videos in seconds.",
                iconName: "waveform.circle.fill",
                gradientHex: ["#7D55F3", "#9568FA"]
            )
        case .dummy:
            ToolItem(
                id: .dummy,
                title: "Dummy",
                subtitle: "A playful sandbox to test multi-tool interactions.",
                iconName: "puzzlepiece.extension.fill",
                gradientHex: ["#FA8C4F", "#FDB560"]
            )
        }
    }
    
    var destination: some View {
        Group {
            switch self {
            case .audioExtractor:
                AudioExtractorView(viewModel: AudioExtractorViewModel(cacheManager: CacheManager.shared))
            case .dummy:
                DummyToolView()
            }
        }
    }
}
