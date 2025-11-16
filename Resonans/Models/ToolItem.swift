import SwiftUI

/// Describes a single tool surfaced in the app, including metadata for UI rendering.
///
/// Each tool is backed by a ``ToolIdentifier`` and provides the display title,
/// subtitle, symbol name, and gradient colors used for its card. Flags indicate
/// whether the tool is in beta and if it should appear as a default favorite.
struct ToolItem: Identifiable {
    /// Stable identifier used for lookups and navigation.
    let id: ToolIdentifier
    /// Primary label shown on the tool tile.
    let title: String
    /// Supporting description that clarifies the tool’s purpose.
    let subtitle: String
    /// SF Symbol name rendered in the tool card.
    let iconName: String
    /// Two-color gradient expressed as hex strings.
    let gradientHex: [String]
    /// Indicates the feature is still in beta.
    let beta: Bool
    /// Marks the tool as a pinned favorite on first launch.
    let favorite: Bool
}

/// Known tools that the app ships with and their associated navigation targets.
enum ToolIdentifier: String, Hashable {
    case audioExtractor
    case bgRemover
    case editor
    
    /// Builds the ``ToolItem`` metadata associated with the identifier.
    var tool: ToolItem {
        switch self {
        case .audioExtractor:
            return ToolItem(
                id: .audioExtractor,
                title: "Extractor",
                subtitle: "Extract audio from your videos",
                iconName: "waveform",
                gradientHex: ["#B43AA6", "#FD1D1D"],
                beta: false,
                favorite: true
            )
        case .bgRemover:
            return ToolItem(
                id: .bgRemover,
                title: "Background Remover",
                subtitle: "Remove Background from your images",
                iconName: "person.and.background.dotted",
                gradientHex: ["#2A7D9B", "#53EDAD"],
                beta: false,
                favorite: false
            )
        case .editor:
            return ToolItem(
                id: .editor,
                title: "Editor",
                subtitle: "Edit your photos and videos",
                iconName: "scissors",
                gradientHex: ["#412A9B", "#ED53B2"],
                beta: true,
                favorite: true
            )
        }
    }
    
    /// Resolves the SwiftUI destination for the tool.
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

