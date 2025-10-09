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
    let destination: (@escaping () -> Void) -> AnyView

    static let audioExtractor = ToolItem(
        id: .audioExtractor,
        title: "Extractor",
        subtitle: "Pull crisp audio tracks from your videos in seconds.",
        iconName: "waveform.circle.fill",
        gradientColors: [
            Color(red: 0.49, green: 0.33, blue: 0.95),
            Color(red: 0.58, green: 0.41, blue: 0.98)
        ],
        destination: { onClose in AnyView(AudioExtractorView(onClose: onClose)) }
    )

    static let dummy = ToolItem(
        id: .dummy,
        title: "Dummy Tool",
        subtitle: "A placeholder tool to experiment with multiple tool layouts.",
        iconName: "puzzlepiece.extension",
        gradientColors: [
            Color(red: 0.22, green: 0.72, blue: 0.99),
            Color(red: 0.30, green: 0.52, blue: 0.94)
        ],
        destination: { onClose in AnyView(DummyToolView(onClose: onClose)) }
    )

    static let all: [ToolItem] = [
        .audioExtractor,
        .dummy
    ]
}
