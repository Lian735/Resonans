import SwiftUI

struct SettingsView: View {
    @Binding var scrollToTopTrigger: Bool
    @AppStorage("appearance") private var appearanceRaw = Appearance.system.rawValue
    @AppStorage("accentColor") private var accentRaw = AccentColorOption.purple.rawValue

    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("soundsEnabled") private var soundsEnabled = true
    @AppStorage("experimentalEnabled") private var experimentalEnabled = false
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
                return "\(version) (\(build))"
            }
            return version
        }
        return "—"
    }

    @AppStorage("Glass Effect activated") private var glassEffectActivated: Bool = true
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 24) {
                    Color.clear
                        .frame(height: AppStyle.innerPadding)
                        .padding(.bottom, -24)
                        .id("top")
                    appearanceSection
                    otherSection
                    aboutSection
                    if #available(iOS 26, *){
                        if experimentalEnabled{
                            settingsBox{
                                Toggle("Glass Effect", isOn: $glassEffectActivated)
                            }
                        }
                    }
                    Spacer(minLength: 120)
                }
                .padding(.bottom, AppStyle.innerPadding)
                .background(
                    GeometryReader { geo -> Color in
                        DispatchQueue.main.async {
                            let show = geo.frame(in: .named("settingsScroll")).minY < -AppStyle.innerPadding
                            if showTopBorder != show {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showTopBorder = show
                                }
                            }
                        }
                        return Color.clear
                    }
                )
            }
            .coordinateSpace(name: "settingsScroll")
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Color.gray.opacity(0.5))
                    .frame(height: 1)
                    .opacity(showTopBorder ? 1 : 0)
                    .animation(.easeInOut(duration: 0.2), value: showTopBorder)
            }
            .onChange(of: scrollToTopTrigger) { _, _ in
                withAnimation {
                    proxy.scrollTo("top", anchor: .top)
                }
            }
        }
    }

    // MARK: - Sections

    private var appearanceSection: some View {
        settingsBox {
            Text("Appearance")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

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
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundStyle(.primary.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 8)

            Text("Accent color")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
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
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Toggle(isOn: $hapticsEnabled) {
                Text("Vibration")
                    .foregroundStyle(.primary.opacity(0.9))
            }
            .onChange(of: hapticsEnabled) { _, _ in
                HapticsManager.shared.selection()
            }

            Toggle(isOn: $soundsEnabled) {
                Text("Sounds")
                    .foregroundStyle(.primary.opacity(0.9))
            }
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

            Button {
                CacheManager.shared.clear()
                HapticsManager.shared.notify(.success)
            } label: {
                Text("Clear Cache")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(accent.color.opacity(0.25))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(ShadowConfiguration.smallConfiguration(for: colorScheme))
            }
            .padding(.top, 4)
        }
    }

    private var aboutSection: some View {
        settingsBox {
            Text("About")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            HStack {
                Text("Version")
                Spacer()
                Text(versionDisplayString)
            }
            .foregroundStyle(.primary.opacity(0.8))

            Button {
                HapticsManager.shared.pulse()
                if let url = URL(string: "mailto:feedback.lian@gmail.com") {
                    openURL(url)
                }
            } label: {
                Text("Send Feedback")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(accent.color.opacity(0.25))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(ShadowConfiguration.smallConfiguration(for: colorScheme))
            }
            .padding(.top, 12)
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

#Preview {
    SettingsView(scrollToTopTrigger: .constant(false))
        .background(Color.black)
        .preferredColorScheme(.dark)
}
