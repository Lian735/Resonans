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

    private var primary: Color { AppStyle.primary(for: colorScheme) }

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

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 24) {
                    topSpacer
                    appearanceSection
                    otherSection
                    aboutSection
                    Spacer(minLength: 120)
                }
                .padding(.bottom, AppStyle.innerPadding)
                .background(
                    GeometryReader { geometry in
                        observeTopBorder(geometry)
                    }
                )
            }
            .coordinateSpace(name: "settingsScroll")
            .overlay(alignment: .top, content: topBorder)
            .onChange(of: scrollToTopTrigger) { _, _ in
                withAnimation {
                    proxy.scrollTo("top", anchor: .top)
                }
            }
        }
    }

    private var topSpacer: some View {
        Color.clear
            .frame(height: AppStyle.innerPadding)
            .padding(.bottom, -24)
            .id("top")
    }

    private func observeTopBorder(_ geometry: GeometryProxy) -> Color {
        let offset = geometry.frame(in: .named("settingsScroll")).minY
        let shouldShow = offset < -AppStyle.innerPadding
        guard shouldShow != showTopBorder else { return .clear }
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.2)) {
                showTopBorder = shouldShow
            }
        }
        return .clear
    }

    private func topBorder() -> some View {
        Rectangle()
            .fill(Color.gray.opacity(0.5))
            .frame(height: 1)
            .opacity(showTopBorder ? 1 : 0)
            .animation(.easeInOut(duration: 0.2), value: showTopBorder)
    }

    // MARK: - Sections

    private var appearanceSection: some View {
        settingsBox {
            Text("Appearance")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(primary)

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
                            .foregroundStyle(primary.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 8)

            Text("Accent color")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(primary)
                .padding(.top, 20)

            HStack(spacing: 16) {
                ForEach(AccentColorOption.allCases) { option in
                    ZStack {
                        Circle()
                            .stroke(primary, lineWidth: option == accent ? 3 : 0)
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
                .foregroundStyle(primary)

            settingsToggle(title: "Vibration", isOn: $hapticsEnabled)
            settingsToggle(title: "Sounds", isOn: $soundsEnabled)
            settingsToggle(title: "Experimental Features", isOn: $experimentalEnabled)

            Divider().padding(.vertical, 4)

            settingsButton(title: "Clear Cache") {
                CacheManager.shared.clear()
                HapticsManager.shared.notify(.success)
            }
            .padding(.top, 4)
        }
    }

    private var aboutSection: some View {
        settingsBox {
            Text("About")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(primary)

            HStack {
                Text("Version")
                Spacer()
                Text(versionDisplayString)
            }
            .foregroundStyle(primary.opacity(0.8))

            settingsButton(title: "Send Feedback") {
                HapticsManager.shared.pulse()
                if let url = URL(string: "mailto:feedback.lian@gmail.com") {
                    openURL(url)
                }
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

    private func settingsToggle(title: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(title)
                .foregroundStyle(primary.opacity(0.9))
        }
        .onChange(of: isOn.wrappedValue) { _, _ in
            HapticsManager.shared.selection()
        }
    }

    private func settingsButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(accent.color.opacity(0.25))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .appShadow(colorScheme: colorScheme, level: .small, opacity: 0.35)
        }
        .buttonStyle(.plain)
    }

    private func settingsBox<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            content()
        }
        .padding(AppStyle.innerPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCardStyle(
            primary: primary,
            colorScheme: colorScheme,
            fillOpacity: AppStyle.subtleCardFillOpacity,
            shadowLevel: .medium
        )
        .padding(.horizontal, AppStyle.horizontalPadding)
    }
}

#Preview {
    SettingsView(scrollToTopTrigger: .constant(false))
        .background(Color.black)
        .preferredColorScheme(.dark)
}
