import SwiftUI

struct ToolItem: Identifiable {
    enum Identifier: String, Hashable {
        case audioExtractor
        case dummy
    }

    let id: Identifier
    let title: String
    let subtitle: String
    let iconName: String
    let gradientColors: [Color]
    
    var destination: some View{
        VStack{
            switch id{
            case .audioExtractor:
                AudioExtractorView(viewModel: AudioExtractorViewModel(cacheManager: CacheManager.shared))
            case .dummy:
                DummyToolView()
            }
        }
    }

    static let audioExtractor = ToolItem(
        id: .audioExtractor,
        title: "Extractor",
        subtitle: "Pull crisp audio tracks from your videos in seconds.",
        iconName: "waveform.circle.fill",
        gradientColors: [
            Color(red: 0.49, green: 0.33, blue: 0.95),
            Color(red: 0.58, green: 0.41, blue: 0.98)
        ]
    )

    static let dummy = ToolItem(
        id: .dummy,
        title: "Dummy",
        subtitle: "A playful sandbox to test multi-tool interactions.",
        iconName: "puzzlepiece.extension.fill",
        gradientColors: [
            Color(red: 0.98, green: 0.55, blue: 0.31),
            Color(red: 0.99, green: 0.71, blue: 0.39)
        ]
    )

    static let all: [ToolItem] = [
        .audioExtractor,
        .dummy
    ]
}
