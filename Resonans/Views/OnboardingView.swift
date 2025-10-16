import SwiftUI

struct OnboardingFlowView: View {
    enum WorkflowOption: String, CaseIterable, Identifiable {
        case contentCreator = "Content creator"
        case lecture = "Lecture notes"
        case podcast = "Podcast cleanup"

        var id: String { rawValue }

        var description: String {
            switch self {
            case .contentCreator:
                return "Extract audio from your latest shoot and repurpose it for shorts, reels or voiceovers."
            case .lecture:
                return "Pull crisp audio from recorded talks to build searchable study notes."
            case .podcast:
                return "Split video interviews into clean audio tracks ready for your feed."
            }
        }
    }

    let accent: Color
    let primary: Color
    let onComplete: (Set<ToolItem.Identifier>, Bool) -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var currentStep = 0
    @State private var selectedFavorites: Set<ToolItem.Identifier>
    @State private var selectedWorkflow: WorkflowOption = .contentCreator
    @State private var showTips = true

    init(
        accent: Color,
        primary: Color,
        onComplete: @escaping (Set<ToolItem.Identifier>, Bool) -> Void
    ) {
        self.accent = accent
        self.primary = primary
        self.onComplete = onComplete
        _selectedFavorites = State(initialValue: Set(ToolItem.all.prefix(1).map { $0.id }))
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [accent.opacity(colorScheme == .dark ? 0.3 : 0.2), AppStyle.background(for: colorScheme)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                header

                TabView(selection: $currentStep) {
                    introStep.tag(0)
                    favoritesStep.tag(1)
                    workflowStep.tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentStep)

                progressIndicators

                footerButtons
            }
            .padding(.horizontal, 28)
            .padding(.top, 36)
            .padding(.bottom, 32)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome to Resonans")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(primary)
                Text(stepSubtitle)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(primary.opacity(0.7))
            }
            Spacer()
            Button("Skip") {
                finish()
            }
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(primary.opacity(0.8))
        }
    }

    private var introStep: some View {
        VStack(spacing: 26) {
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .fill(primary.opacity(AppStyle.cardFillOpacity))
                    .frame(height: 240)
                    .overlay(
                        RoundedRectangle(cornerRadius: 36, style: .continuous)
                            .stroke(primary.opacity(AppStyle.strokeOpacity), lineWidth: 1)
                    )
                    .shadow(ShadowConfiguration.largeConfiguration(for: colorScheme))

                VStack(spacing: 18) {
                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 64, weight: .bold))
                        .foregroundStyle(accent)
                    Text("One workspace for every creative routine")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(primary)
                        .multilineTextAlignment(.center)
                    Text("Resonans keeps all of your media tools organised. Pin favourites, pick up where you left off and stay in the loop with app news.")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(primary.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                }
                .padding(.horizontal, 22)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 18) {
                Label("Tap the heart icon to favourite tools you love", systemImage: "heart.circle.fill")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(primary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(primary.opacity(AppStyle.cardFillOpacity))
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                Label("Swipe through onboarding to learn the essentials", systemImage: "hand.draw.fill")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(primary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(primary.opacity(AppStyle.cardFillOpacity))
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            }

            Spacer()
        }
    }

    private var favoritesStep: some View {
        VStack(spacing: 24) {
            Text("Choose your go-to tools")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(primary)

            Text("Tap to pin tools you use the most. We'll show them right on the home screen so they’re always ready.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(primary.opacity(0.75))
                .multilineTextAlignment(.center)

            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 18) {
                    ForEach(ToolItem.all) { tool in
                        FavoriteSelectionCard(
                            tool: tool,
                            isSelected: selectedFavorites.contains(tool.id),
                            accent: accent,
                            primary: primary,
                            colorScheme: colorScheme
                        ) {
                            if selectedFavorites.contains(tool.id) {
                                selectedFavorites.remove(tool.id)
                            } else {
                                selectedFavorites.insert(tool.id)
                            }
                        }
                    }
                }
                .padding(.top, 12)
            }
        }
    }

    private var workflowStep: some View {
        VStack(spacing: 26) {
            Text("Plan your first session")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(primary)

            Text("Tell us what you’re working on and we'll highlight the best starting point.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(primary.opacity(0.75))
                .multilineTextAlignment(.center)

            Picker("Workflow", selection: $selectedWorkflow) {
                ForEach(WorkflowOption.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: 18) {
                Label(selectedWorkflow.rawValue, systemImage: "sparkles")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(primary)
                Text(selectedWorkflow.description)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(primary.opacity(0.75))

                Toggle(isOn: $showTips) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Show guided tips")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(primary)
                        Text("We'll highlight useful gestures and shortcuts while you explore.")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(primary.opacity(0.6))
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: accent))
                .padding(.top, 8)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(primary.opacity(AppStyle.cardFillOpacity))
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(primary.opacity(AppStyle.strokeOpacity), lineWidth: 1)
            )
            .shadow(ShadowConfiguration.mediumConfiguration(for: colorScheme))
            Spacer()
        }
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
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
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
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .padding(.vertical, 12)
                    .padding(.horizontal, 22)
                    .background(accent.opacity(colorScheme == .dark ? 0.3 : 0.18))
                    .clipShape(Capsule())
                    .foregroundStyle(accent)
            }
            .buttonStyle(.plain)
        }
    }

    private var stepSubtitle: String {
        switch currentStep {
        case 0: return "Swipe to explore the essentials"
        case 1: return "Pick your favourites to pin on Home"
        default: return "Get personalised tips before you start"
        }
    }

    private func finish() {
        let favorites = selectedFavorites.isEmpty ? Set(ToolItem.all.prefix(1).map { $0.id }) : selectedFavorites
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
        Button(action: action) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    ZStack {
                        RoundedRectangle(cornerRadius: AppStyle.iconCornerRadius, style: .continuous)
                            .fill(LinearGradient(colors: tool.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 54, height: 54)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppStyle.iconCornerRadius, style: .continuous)
                                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
                            )
                        Image(systemName: tool.iconName)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(isSelected ? accent : primary.opacity(0.35))
                }

                Text(tool.title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(primary)
                Text(tool.subtitle)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(primary.opacity(0.7))
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                    .fill(primary.opacity(AppStyle.cardFillOpacity))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                            .stroke(primary.opacity(isSelected ? 0.35 : AppStyle.strokeOpacity), lineWidth: isSelected ? 2 : 1)
                    )
            )
            .shadow(ShadowConfiguration.mediumConfiguration(for: colorScheme))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    OnboardingFlowView(
        accent: Color.purple,
        primary: .black,
    ) { _, _ in }
}
