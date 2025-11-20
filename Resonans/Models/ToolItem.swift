import SwiftUI

/// Represents a tool available in the app with display metadata.
///
/// `ToolItem` contains all the information needed to display and identify a tool:
/// - Unique identifier (``ToolIdentifier``)
/// - Display title and subtitle
/// - Icon name (SF Symbol)
/// - Gradient colors for the icon background (hex strings)
/// - Beta and favorite flags
///
/// - Note: Tool items are typically created through the ``ToolIdentifier`` enum's `tool` property.
///
/// Example:
/// ```swift
/// let tool = ToolIdentifier.audioExtractor.tool
/// print(tool.title) // "Extractor"
/// ```
struct ToolItem: Identifiable {
    let id: ToolIdentifier
    let title: String
    let subtitle: String
    let iconName: String
    let gradientHex: [String]
    let beta: Bool
    let favorite: Bool
}

/// Identifies available tools in the app and provides their configuration.
///
/// `ToolIdentifier` is used as a stable identifier for tools throughout the app.
/// Each case provides:
/// - A unique raw string value for persistence
/// - A configured ``ToolItem`` with display metadata
/// - A SwiftUI view destination for navigation
///
/// Example usage:
/// ```swift
/// // Get tool metadata
/// let tool = ToolIdentifier.audioExtractor.tool
///
/// // Navigate to tool
/// NavigationLink(destination: ToolIdentifier.audioExtractor.destination) {
///     Text(tool.title)
/// }
///
/// // Store as preference
/// @AppStorage("favoriteTools") private var favoriteIds: Set<ToolIdentifier>
/// ```
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
    
    @ViewBuilder
    var destination: some View {
        switch self {
        case .audioExtractor:
            AudioExtractorView(viewModel: AudioExtractorViewModel(cacheManager: CacheManager.shared))
        case .bgRemover:
            BgRemoverView(viewModel: BgRemoverViewModel())
        case .editor:
            EditorDetailView()
        }
    }
}

