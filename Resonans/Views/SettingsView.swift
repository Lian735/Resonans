import SwiftUI

struct SettingsView: View {
    @AppStorage("appearance") private var appearanceRaw = Appearance.system.rawValue
    @AppStorage("accentColor") private var accentRaw = AccentColorOption.purple.rawValue

    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("soundsEnabled") private var soundsEnabled = true
    @AppStorage("experimentalEnabled") private var experimentalEnabled = false

    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var colorScheme

    private var appearance: Appearance {
        Appearance(rawValue: appearanceRaw) ?? .system
    }

    private var accent: AccentColorOption {
        AccentColorOption(rawValue: accentRaw) ?? .purple
    }

    private var primary: Color { AppStyle.primary(for: colorScheme) }

    private var versionDisplayString: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        if let version, !version.isEmpty {
            if let build, !build.isEmpty {
                return "\(version) (\(build))"
            }
            return version
        }
        return "—"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                sectionHeader(title: "Appearance", subtitle: "Match Resonans to your space.")
                appearanceSection

                sectionHeader(title: "Preferences", subtitle: "Tune how the app feels.")
                otherSection

                sectionHeader(title: "About", subtitle: "Details and feedback.")
                aboutSection
            }
            .padding(.horizontal, AppStyle.horizontalPadding)
            .padding(.vertical, 28)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
    }

    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(primary)
            Text(subtitle)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(primary.opacity(0.7))
        }
        .padding(.horizontal, 2)
    }

    private var appearanceSection: some View {
        settingsBox {
            Text("Theme")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(primary)

            HStack(spacing: 12) {
                ForEach(Appearance.allCases) { mode in
                    VStack(spacing: 8) {
                        themePreview(for: mode)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(
                                        accent.color.opacity(mode == appearance ? 0.8 : 0.0),
                                        lineWidth: mode == appearance ? 3 : 0
                                    )
                            )
                            .scaleEffect(mode == appearance ? 1.02 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: appearance)
                            .onTapGesture {
                                HapticsManager.shared.selection()
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    appearanceRaw = mode.rawValue
                                }
                            }

                        Text(mode.label)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(primary.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 6)

            Divider().padding(.vertical, 8)

            Text("Accent color")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(primary)

            HStack(spacing: 14) {
                ForEach(AccentColorOption.allCases) { option in
                    Circle()
                        .fill(option.color)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle()
                                .stroke(primary, lineWidth: option == accent ? 3 : 0)
                                .scaleEffect(option == accent ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.25), value: accent)
                        )
                        .onTapGesture {
                            HapticsManager.shared.pulse()
                            withAnimation(.easeInOut(duration: 0.25)) {
                                accentRaw = option.rawValue
                            }
                        }
                        .accessibilityLabel(Text(option.rawValue.capitalized))
                }
            }
        }
    }

    private var otherSection: some View {
        settingsBox {
            Toggle(isOn: $hapticsEnabled) {
                Text("Vibration feedback")
                    .foregroundStyle(primary.opacity(0.9))
            }
            .onChange(of: hapticsEnabled) { _, _ in
                HapticsManager.shared.selection()
            }

            Toggle(isOn: $soundsEnabled) {
                Text("Interface sounds")
                    .foregroundStyle(primary.opacity(0.9))
            }
            .onChange(of: soundsEnabled) { _, _ in
                HapticsManager.shared.selection()
            }

            Toggle(isOn: $experimentalEnabled) {
                Text("Experimental features")
                    .foregroundStyle(primary.opacity(0.9))
            }
            .onChange(of: experimentalEnabled) { _, _ in
                HapticsManager.shared.selection()
            }

            Divider().padding(.vertical, 8)

            Button {
                CacheManager.shared.clear()
                HapticsManager.shared.notify(.success)
            } label: {
                Label("Clear cache", systemImage: "arrow.uturn.backward")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(primary)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(accent.color.opacity(colorScheme == .dark ? 0.25 : 0.18))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(accent.color.opacity(0.35), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private var aboutSection: some View {
        settingsBox {
            HStack {
                Text("Version")
                    .foregroundStyle(primary.opacity(0.8))
                Spacer()
                Text(versionDisplayString)
                    .foregroundStyle(primary)
            }

            Divider().padding(.vertical, 8)

            Button {
                HapticsManager.shared.pulse()
                if let url = URL(string: "mailto:feedback.lian@gmail.com") {
                    openURL(url)
                }
            } label: {
                Label("Send feedback", systemImage: "paperplane.fill")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(primary)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(accent.color.opacity(colorScheme == .dark ? 0.25 : 0.18))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(accent.color.opacity(0.35), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func themePreview(for mode: Appearance) -> some View {
        switch mode {
        case .light:
            Image("white")
                .resizable()
                .scaledToFit()
                .cornerRadius(16)
        case .dark:
            Image("dark")
                .resizable()
                .scaledToFit()
                .cornerRadius(16)
        case .system:
            Image("darkandwhite")
                .resizable()
                .scaledToFit()
                .cornerRadius(16)
        }
    }

    private func settingsBox<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 18) {
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
    }
}

#Preview {
    SettingsView()
        .background(Color.black)
        .preferredColorScheme(.dark)
}
