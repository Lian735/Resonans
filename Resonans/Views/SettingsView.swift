import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var viewModel: ContentViewModel
    @AppStorage(AppStorageKey.Settings.appearance) private var appearanceRaw = Appearance.system.rawValue
    @AppStorage(AppStorageKey.Settings.accentColor) private var accentRaw = AccentColorOption.purple.rawValue

    @AppStorage(AppStorageKey.Settings.hapticsEnabled) private var hapticsEnabled = true
    @AppStorage(AppStorageKey.Settings.soundsEnabled) private var soundsEnabled = true
    @AppStorage(AppStorageKey.Settings.experimentalEnabled) private var experimentalEnabled = false
    @State private var showTopBorder = false

    private var appearance: Appearance {
        Appearance(rawValue: appearanceRaw) ?? .system
    }

    private var accent: AccentColorOption {
        AccentColorOption(rawValue: accentRaw) ?? .purple
    }
    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var colorScheme

    private var versionDisplayString: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        if let version = version, !version.isEmpty {
            if let build = build, !build.isEmpty {
                return "v\(version).\(build)"
            }
            return version
        }
        return "—"
    }

    @AppStorage("Glass Effect activated") private var glassEffectActivated: Bool = true
    @AppStorage("Interactive Glass activated") private var interactiveGlassActivated: Bool = false

    
    var body: some View {
        NavigationStack{
            ScrollView {
                VStack(spacing: 24) {
                    appearanceSection
                    otherSection
                    experimentalSection
                    aboutSection
                    Spacer(minLength: 120)
                }
                .padding(.bottom, AppStyle.innerPadding)
            }
            .background(
                LinearGradient(
                    colors: [accent.gradient, .clear],
                    startPoint: .topLeading,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar(content: {
                ToolbarItem(placement: .topBarTrailing, content: {
                    Button(disableGlassEffect: true, action: {
                        HapticsManager.shared.pulse()
                        viewModel.showOnboarding = true
                    }) {
                        Image(systemName: "questionmark")
                    }
                })
            })
            .animation(.linear, value: glassEffectActivated)
        }
    }

    // MARK: - Sections

    private var appearanceSection: some View {
        settingsBox {
            Text("Appearance")
                .typography(.displaySmall, design: .rounded)

            HStack(spacing: 12) {
                ForEach(Appearance.allCases) { mode in
                    VStack(spacing: 6) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .inset(by: -4)
                                .stroke(mode == appearance ? accent.color : .clear, lineWidth: 3)
                                .scaleEffect(mode == appearance ? 1 : 0.9)
                                .animation(.easeInOut(duration: 0.2), value: appearance)
                            themePreview(for: mode)
                                .transition(.opacity)
                                .animation(.easeInOut(duration: 0.3), value: appearance)
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
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 8)

            Text("Accent color")
                .typography(.titleMedium, design: .rounded)
                .padding(.top, 20)

            HStack(spacing: 16) {
                ForEach(AccentColorOption.allCases) { option in
                    ZStack {
                        Circle()
                            .stroke(.primary, lineWidth: option == accent ? 3 : 0)
                            .frame(width: 28, height: 28)
                            .scaleEffect(option == accent ? 1.3 : 1.0)
                            .animation(.easeInOut(duration: 0.25), value: accent)
                        Circle()
                            .fill(option.color)
                            .frame(width: 28, height: 28)
                    }
                    .animation(.easeInOut(duration: 0.25), value: accent)
                    .onTapGesture {
                        HapticsManager.shared.pulse()
                        withAnimation(.easeInOut(duration: 0.3)) {
                            accentRaw = option.rawValue
                        }
                    }
                }
            }
        }
    }

    private var otherSection: some View {
        settingsBox {
            Text("Other")
                .typography(.displaySmall, design: .rounded)

            Toggle(isOn: $hapticsEnabled) {
                Text("Vibration")
                    .foregroundStyle(.primary.opacity(0.9))
            }
            .onChange(of: hapticsEnabled) { _, _ in
                HapticsManager.shared.selection()
            }

            Toggle(isOn: $soundsEnabled) {
                Text("Sounds")
                    .foregroundStyle(.primary.opacity(0.5))
            }
            .disabled(true)
            .opacity(0.5)
            .onChange(of: soundsEnabled) { _, _ in
                HapticsManager.shared.selection()
            }

            Toggle(isOn: $experimentalEnabled) {
                Text("Experimental Features")
                    .foregroundStyle(.primary.opacity(0.9))
            }
            .onChange(of: experimentalEnabled) { _, _ in
                HapticsManager.shared.selection()
            }

            Divider()
                .padding(.vertical, 4)

            Button("Clear Cache") {
                CacheManager.shared.clear()
                HapticsManager.shared.notify(.success)
            }
            .padding(.top, 4)
        }
    }
    
    @ViewBuilder private var experimentalSection: some View {
        if experimentalEnabled{
            settingsBox {
                Text("Experimental")
                    .typography(.displaySmall, design: .rounded)
                
                if #available(iOS 26, *){
                    Toggle("Glass Effect", isOn: $glassEffectActivated)
                        .disabled(true)
                        .opacity(0.5)
                    if glassEffectActivated {
                        Toggle("Interactive Glass", isOn: $interactiveGlassActivated)
                    }
                }
            }
        }
    }

    private var aboutSection: some View {
        settingsBox {
            Text("About")
                .typography(.displaySmall, design: .rounded)

            HStack {
                Text("Version")
                Spacer()
                Text(versionDisplayString)
            }
            .foregroundStyle(.primary.opacity(0.8))

            Divider()
                .padding(.vertical, 4)
            
            Button("Send Feedback") {
                HapticsManager.shared.pulse()
                if let url = URL(string: "mailto:feedback.lian@gmail.com") {
                    openURL(url)
                }
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Helpers

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

    private func settingsBox<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
        AppCard{
            VStack(alignment: .leading, spacing: 16) {
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, AppStyle.horizontalPadding)
    }
}

private extension Color {
    func rgba() -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat)? {
        #if canImport(UIKit)
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard ui.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        return (r, g, b, a)
        #else
        return nil
        #endif
    }
}

private func nearestAccentOption(for color: Color) -> AccentColorOption {
    guard let target = color.rgba() else { return AccentColorOption.purple }
    var best: (option: AccentColorOption, distance: CGFloat)?
    for option in AccentColorOption.allCases {
        if let c = option.color.rgba() {
            let dr = target.r - c.r
            let dg = target.g - c.g
            let db = target.b - c.b
            let da = target.a - c.a
            let d = dr*dr + dg*dg + db*db + da*da
            if best == nil || d < best!.distance {
                best = (option, d)
            }
        }
    }
    return best?.option ?? AccentColorOption.purple
}

#Preview {
    SettingsView()
        .background(Color.black)
        .preferredColorScheme(.dark)
}
