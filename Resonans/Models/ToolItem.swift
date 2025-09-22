import SwiftUI

struct ToolItem: Identifiable {
    enum Identifier: String, Hashable {
        case audioExtractor
    }

    let id: Identifier
    let title: String
    let subtitle: String
    let iconName: String
    let gradientColors: [Color]
    let destination: () -> AnyView

    static let audioExtractor = ToolItem(
        id: .audioExtractor,
        title: "Audio Extractor",
        subtitle: "Pull crisp audio tracks from your videos in seconds.",
        iconName: "waveform.circle.fill",
        gradientColors: [
            Color(red: 0.49, green: 0.33, blue: 0.95),
            Color(red: 0.58, green: 0.41, blue: 0.98)
        ],
        destination: { AnyView(AudioExtractorView()) }
    )

    static let all: [ToolItem] = [
        .audioExtractor
    ]
}
