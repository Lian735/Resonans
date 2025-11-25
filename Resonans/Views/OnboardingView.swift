import SwiftUI

/// A multi-step onboarding flow introducing new users to the app.
///
/// `OnboardingFlowView` presents a paginated onboarding experience with three steps:
/// 1. **Introduction**: App overview and basic tips
/// 2. **Favorites**: Tool selection for the home screen
/// 3. **Workflow**: Workflow preference and guided tips toggle
///
/// The view collects user preferences and returns them via the completion handler:
/// - Selected favorite tools (defaults to first tool if none selected)
/// - Whether to show guided tips
///
/// Example usage:
/// ```swift
/// .fullScreenCover(isPresented: $showOnboarding) {
///     OnboardingFlowView(
///         accent: accentColor,
///         primary: .primary
///     ) { favorites, showTips in
///         saveFavorites(favorites)
///         userDefaults.set(showTips, forKey: "showTips")
///     }
/// }
/// ```
///
/// - Parameters:
///   - accent: The accent color for theming
///   - primary: The primary text color
///   - onComplete: Closure called when onboarding finishes or is skipped, passing selected favorites and tips preference
///
/// - Note: Users can skip onboarding at any time using the "Skip" button.
/// - Important: Uses ``HapticsManager`` for tactile feedback during navigation.
struct OnboardingFlowView: View {
    /// Predefined workflow scenarios presented during onboarding.
    ///
    /// Each workflow provides context-specific descriptions to help users understand how to use the app.

    let accent: Color
    let primary: Color
    let onComplete: (Set<ToolIdentifier>, Bool) -> Void
    let toolManager: ToolManager = ToolManager.shared
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: ContentViewModel

    @State private var currentStep = 0
    @State private var selectedFavorites: Set<ToolIdentifier>
    @State private var showTips = true
    
    @State private var favouritedemo: Bool = false
    @State private var favouritedemocompleted: Bool = false
    @State private var handOffset: CGSize = .zero
    @State private var handScale: CGFloat = 1.0
    @State private var isDragging: Bool = false
    @State private var logoRotation: CGFloat = .zero

    // Backing state for appearance and accent selections
    @AppStorage("appearance") private var appearanceRaw: String = Appearance.system.rawValue
    @AppStorage("accent") private var accentRaw: String = AccentColorOption.purple.rawValue

    // Convenience computed properties
    private var appearance: Appearance {
        Appearance(rawValue: appearanceRaw) ?? .system
    }
    private var accentOption: AccentColorOption {
        AccentColorOption(rawValue: accentRaw) ?? .purple
    }


    init(
        accent: Color,
        primary: Color,
        onComplete: @escaping (Set<ToolIdentifier>, Bool) -> Void
    ) {
        self.accent = accent
        self.primary = primary
        self.onComplete = onComplete
        _selectedFavorites = State(initialValue: Set())
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [accent.opacity(0.3), .clear],
                startPoint: .bottomTrailing,
                endPoint: .top
            )
            .ignoresSafeArea()

            VStack(spacing: 12) {
                header
                    .padding(.horizontal, AppStyle.innerPadding)
                TabView(selection: $currentStep) {
                    Group {
                        introStep.tag(0)
                        favoritesStep.tag(1)
                        adjustments.tag(2)
                    }
                    .padding(.horizontal, AppStyle.innerPadding)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                Spacer()
                
                Group {
                    progressIndicators
                    footerButtons
                }
                .padding(.horizontal, AppStyle.innerPadding)
            }
            .padding(.top, 36)
            .padding(.bottom, 32)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome to Resonans!")
                    .typography(.displaySmall, color: primary, design: .rounded)
                HStack {
                    Text(stepSubtitle)
                        .typography(.body, color: primary.opacity(0.7), design: .rounded)
                    Spacer()
//                    Button("Skip") {
//                        finish()
//                    }
//                    .typography(.captionBold, color: primary.opacity(0.8), design: .rounded)
//                    .padding(5)
//                    .background {
//                        RoundedRectangle(cornerRadius: 9)
//                            .opacity(0.3)
//                            .foregroundColor(.yellow)
//                    }
                }
            }
        }
    }

    private var introStep: some View {
        VStack(spacing: 18) {
            AppCard {
                VStack(spacing: 18) {
                    Image("resonanslogo.SFSymbol")
                        .typography(.custom(size: 64, weight: .bold), color: accent)
                        .shadow(color: accent.opacity(0.35), radius: 14, x: 0, y: 0)
                        .symbolEffect(.breathe, options: .nonRepeating)
                        .scaleEffect(logoRotation / 50 + 1)
                        .rotationEffect(.degrees(logoRotation))
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                                        logoRotation = value.translation.width / 4 + value.translation.height / 4
                                        HapticsManager.shared.pulse()
                                    }
                                }
                                .onEnded { _ in
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                                        logoRotation = .zero
                                        HapticsManager.shared.pulse()
                                    }
                                }
                        )
                    Text("Multiple Editing Tools")
                        .typography(.titleLarge, color: primary, design: .rounded)
                        .multilineTextAlignment(.center)
                    Text("Resonans keeps all of your media tools organised. Pin favourites, pick up where you left off.")
                        .typography(.caption, color: primary.opacity(0.75), design: .rounded)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
        
            VStack(spacing: 18) {
                AppCard {
                    HStack {
                        if favouritedemocompleted {
                            Text("Tap the star icon to favourite tools you love, great!")
                                .typography(.callout, color: primary, design: .rounded)
                        } else {
                            Text("Tap the star icon to favourite tools you love")
                                .typography(.callout, color: primary, design: .rounded)
                        }
                        Spacer()
                        Button {
                            if favouritedemo {
                                // turning off
                                favouritedemo = false
                            } else {
                                // turning on
                                favouritedemo = true
                                favouritedemocompleted = true
                            }
                            HapticsManager.shared.selection()
                        } label: {
                            Group {
                                Image(systemName: favouritedemo ? "star.fill" : "star")
                                    .foregroundStyle(favouritedemo ? .yellow : Color(.gray))
                            }
                            .modifier(ConditionalSymbolBounce(apply: favouritedemo))
                        }
                    }
                    .padding(.horizontal, 5)
                }
                AppCard {
                    HStack {
                        Text("Swipe through onboarding to learn the essentials")
                            .typography(.callout, color: primary, design: .rounded)
                        Spacer()
                        Image(systemName: "hand.draw.fill")
                            .foregroundStyle(Color(isDragging ? accent.opacity(0.35) : .gray))
                            .scaleEffect(handScale)
                            .offset(handOffset)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                                            handOffset = value.translation
                                            handScale = 1.5
                                            HapticsManager.shared.pulse()
                                            isDragging = true
                                        }
                                    }
                                    .onEnded { _ in
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                                            handOffset = .zero
                                            handScale = 1.0
                                            HapticsManager.shared.pulse()
                                            isDragging = false
                                        }
                                    }
                            )
                    }
                    .padding(.horizontal, 5)
                }
            }

            Spacer()
        }
        .padding(.vertical, AppStyle.innerPadding)

    }

    private var favoritesStep: some View {
        VStack(spacing: 18) {
            ScrollView(.vertical, showsIndicators: false) {
                GlassEffectContainer {
                    LazyVStack(spacing: 18) {
                        ForEach(toolManager.tools) { tool in
                            ToolOverview(tool: tool)
                        }
                        .onAppear { selectedFavorites = viewModel.favoriteToolIds }
                        .onChange(of: viewModel.favoriteToolIds) { _, newValue in
                            selectedFavorites = newValue
                        }
                    }
                }
                .scrollTransition(.animated) { content, phase in
                    content
                        .opacity(phase.isIdentity ? 1 : 0.3)
                        .scaleEffect(phase.isIdentity ? 1.0 : 0.98)
                        .blur(radius: phase.isIdentity ? 0 : 1)
                }
            }
        }
        .padding(.vertical, AppStyle.innerPadding)
    }

    private var adjustments: some View {
        VStack {
            HStack {
                Text("Choose Appearance")
                    .typography(.titleLarge, color: primary, design: .rounded)
                Spacer()
            }
            HStack(spacing: 12) {
                ForEach(Appearance.allCases) { mode in
                    VStack(spacing: 6) {
                        ZStack {
                            themePreview(for: mode)
                                .transition(.opacity)
                                .animation(.easeInOut(duration: 0.3), value: appearance)
                                .background {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .inset(by: -4)
                                        .stroke(mode == appearance ? accent : .clear, lineWidth: 3)
                                        .scaleEffect(mode == appearance ? 1 : 0.9)
                                        .animation(.easeInOut(duration: 0.2), value: appearance)
                                }
                        }
                        .onTapGesture {
                            HapticsManager.shared.pulse()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                appearanceRaw = mode.rawValue
                            }
                        }
                        Text(mode.label)
                            .typography(.callout, color: .primary.opacity(0.8), design: .rounded)
                    }
                }
            }
                    
            HStack {
                Text("Choose Accent Color")
                    .typography(.titleLarge, color: primary, design: .rounded)
                Spacer()
            }
            .padding(.top, AppStyle.innerPadding)
            
            HStack(spacing: 16) {
                ForEach(AccentColorOption.allCases) { option in
                    ZStack {
                        Circle()
                            .stroke(.primary, lineWidth: option == accentOption ? 3 : 0)
                            .frame(width: 28, height: 28)
                            .scaleEffect(option == accentOption ? 1.3 : 1.0)
                            .animation(.easeInOut(duration: 0.25), value: accentOption)
                        Circle()
                            .fill(option.color)
                            .frame(width: 28, height: 28)
                    }
                    .animation(.easeInOut(duration: 0.25), value: accentOption)
                    .onTapGesture {
                        HapticsManager.shared.pulse()
                        withAnimation(.easeInOut(duration: 0.3)) {
                            accentRaw = option.rawValue
                        }
                    }
                }
                Spacer()
            }
            
            Spacer()
        }
        .padding(.vertical, AppStyle.innerPadding)
    }

    private var progressIndicators: some View {
        HStack(spacing: 10) {
            ForEach(0..<3) { index in
                Capsule()
                    .fill(index == currentStep ? accent : primary.opacity(0.25))
                    .frame(width: index == currentStep ? 42 : 16, height: 6)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentStep)
            }
        }
    }

    private var footerButtons: some View {
        HStack(spacing: 16) {
            if currentStep > 0 {
                Button {
                    HapticsManager.shared.selection()
                    currentStep -= 1
                } label: {
                    Label("Back", systemImage: "chevron.left")
                        .typography(.callout, design: .rounded)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 18)
                        .background(primary.opacity(AppStyle.cardFillOpacity))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            Spacer()

            Button {
                HapticsManager.shared.selection()
                if currentStep < 2 {
                    currentStep += 1
                } else {
                    finish()
                }
            } label: {
                Label(currentStep < 2 ? "Next" : "Let's go", systemImage: currentStep < 2 ? "chevron.right" : "checkmark.circle.fill")
                    .typography(.callout, color: accent, design: .rounded)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 22)
                    .background(accent.opacity(colorScheme == .dark ? 0.3 : 0.18))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private var stepSubtitle: String {
        switch currentStep {
        case 0: return "The Video-Editing Tools App"
        case 1: return "Pick your favorites to pin on Home"
        default: return "Make it your own!"
        }
    }

    private func finish() {
        let favorites = selectedFavorites.isEmpty ? Set(toolManager.tools.prefix(1).map { $0.id }) : selectedFavorites
        onComplete(favorites, showTips)
        dismiss()
    }
}

private struct FavoriteSelectionCard: View {
    let tool: ToolItem
    let isSelected: Bool
    let accent: Color
    let primary: Color
    let colorScheme: ColorScheme
    let action: () -> Void

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    ZStack {
                        RoundedRectangle(cornerRadius: AppStyle.iconCornerRadius, style: .continuous)
                            .fill(LinearGradient(colors: tool.gradientHex.compactMap { Color(hex: $0) }, startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 54, height: 54)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppStyle.iconCornerRadius, style: .continuous)
                                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
                            )
                            .glassEffect(.regular)
                        Image(systemName: tool.iconName)
                            .typography(.titleLarge, color: .white)
                    }
                    
                    Spacer()
                    Button(action: action) {
                        Group {
                            Image(systemName: isSelected ? "star.fill" : "star")
                                .foregroundStyle(isSelected ? .yellow : Color(.gray))
                        }
                        .modifier(ConditionalSymbolBounce(apply: isSelected))
                    }

                }
                
                Text(tool.title)
                    .typography(.bodyBold, color: primary, design: .rounded)
                Text(tool.subtitle)
                    .typography(.caption, color: primary.opacity(0.7), design: .rounded)
            }
        }
    }
}

private struct ConditionalSymbolBounce: ViewModifier {
    let apply: Bool
    func body(content: Content) -> some View {
        if apply {
            content.symbolEffect(.bounce, options: .nonRepeating)
        } else {
            content
        }
    }
}

@ViewBuilder
private func themePreview(for mode: Appearance) -> some View {
    switch mode {
    case .light:
        Image("white")
            .resizable()
            .scaledToFit()
            .cornerRadius(12)
            .transition(.opacity)
    case .dark:
        Image("dark")
            .resizable()
            .scaledToFit()
            .cornerRadius(12)
            .transition(.opacity)
    case .system:
        Image("darkandwhite")
            .resizable()
            .scaledToFit()
            .cornerRadius(12)
            .transition(.opacity)
    }
}

#Preview {
    OnboardingFlowView(
        accent: Color.purple,
        primary: .black
    ) { _, _ in }
    .environmentObject(ContentViewModel())
}

