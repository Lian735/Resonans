import SwiftUI

/// A searchable catalog view displaying all available tools in the app.
///
/// `ToolsView` presents all tools in a scrollable list with:
/// - Search functionality to filter tools by title
/// - Automatic sorting (favorites first, then alphabetically)
/// - Optional glass effect container on iOS 26+
/// - Tool overview cards with favorite toggle
///
/// The view responds to changes in favorite tools with smooth animations.
///
/// Example usage:
/// ```swift
/// ToolsView(
///     accent: .purple,
///     primary: .primary
/// )
/// .environmentObject(contentViewModel)
/// ```
///
/// - Parameters:
///   - accent: The ``AccentColorOption`` for theming
///   - primary: The primary text color
///
/// - Important: Requires a ``ContentViewModel`` to be provided via `@EnvironmentObject`.
/// - Note: Uses `@Namespace` for matched geometry effects in animations.
struct ToolsView: View {
    let accent: AccentColorOption
    let primary: Color
    @Environment(\.colorScheme) private var colorScheme
    
    @EnvironmentObject private var viewModel: ContentViewModel
    
    @Namespace private var namespace
    
    @State private var searchText = ""
    
    @State private var showSearch: Bool = false
    
    @FocusState private var isSearchFocused: Bool
    
    private var filteredAndSortedTools: [ToolItem] {
        let favorites = viewModel.favoriteToolIds
        let filtered = viewModel.toolManager.tools.filter { tool in
            searchText.isEmpty || tool.title.localizedCaseInsensitiveContains(searchText)
        }
        return filtered.sorted { lhs, rhs in
            let lFav = favorites.contains(lhs.id)
            let rFav = favorites.contains(rhs.id)
            if lFav != rFav {
                return lFav && !rFav
            }
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }
    }
    
    var body: some View {
        NavigationStack{
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 12) {
                    GlassEffectContainer {
                        HStack {
                            AppCard {
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                    TextField(
                                        "Search Tools",
                                        text: $searchText
                                    )
                                    .focused($isSearchFocused)
                                    .onTapGesture {
                                        showSearch = true
                                    }
                                    .onChange(of: isSearchFocused) { _, newValue in
                                        showSearch = newValue
                                        HapticsManager.shared.pulse()
                                    }
                                    Spacer()
                                    if isSearchFocused {
                                        Button {
                                            searchText = ""
                                            isSearchFocused = false
                                            HapticsManager.shared.pulse()
                                        } label: {
                                            Image(systemName: "keyboard.chevron.compact.down.fill")
                                                .tint(.white)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .scrollTransition(.animated) { content, phase in
                        content
                            .opacity(phase.isIdentity ? 1 : 0.3)
                            .scaleEffect(phase.isIdentity ? 1.0 : 0.98)
                            .blur(radius: phase.isIdentity ? 0 : 1)
                    }
                    
                    GlassEffectContainer {
                        ForEach(filteredAndSortedTools) { tool in
                            ToolOverview(tool: tool)
                                .environmentObject(viewModel)
                        }
                    }
                    .scrollTransition(.animated) { content, phase in
                        content
                            .opacity(phase.isIdentity ? 1 : 0.3)
                            .scaleEffect(phase.isIdentity ? 1.0 : 0.98)
                            .blur(radius: phase.isIdentity ? 0 : 1)
                    }
                }
                .padding(.horizontal, AppStyle.horizontalPadding)
                .padding(.vertical, AppStyle.innerPadding)
                .animation(
                    .spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0.2),
                    value: viewModel.favoriteToolIds
                )
            }
            .background(
                LinearGradient(
                    colors: [accent.gradient.opacity(0.7), .clear],
                    startPoint: .bottomTrailing,
                    endPoint: .top
                )
                .ignoresSafeArea()
            )
            .safeAreaBar(edge: .top) {
                HStack {
                    Text("Tools")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                }
                .padding(.horizontal)
                .frame(height: 45)
            }
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selected: ToolIdentifier? = .audioExtractor
        @State private var trigger = false

        var body: some View {
            ToolsView(
                accent: .purple,
                primary: .black
            )
        }
    }
    return PreviewWrapper()
        .environmentObject(ContentViewModel())
}
