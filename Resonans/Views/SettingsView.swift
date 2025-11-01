import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var viewModel: ContentViewModel

    @AppStorage("appearance") private var appearanceRaw = Appearance.system.rawValue
    @AppStorage("accentColor") private var accentRaw = AccentColorOption.purple.rawValue
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("soundsEnabled") private var soundsEnabled = true
    @AppStorage("experimentalEnabled") private var experimentalEnabled = false
    @AppStorage("Glass Effect activated") private var glassEffectActivated = true

    @Environment(\.openURL) private var openURL

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
        NavigationStack {
            Form {
                appearanceSection
                preferencesSection
                experimentalSection
                supportSection
                aboutSection
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticsManager.shared.pulse()
                        viewModel.showOnboarding = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                    }
                    .accessibilityLabel("Show onboarding")
                }
            }
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Appearance", selection: $appearanceRaw) {
                ForEach(Appearance.allCases) { mode in
                    Text(mode.label)
                        .tag(mode.rawValue)
                }
            }

            Picker("Accent color", selection: $accentRaw) {
                ForEach(AccentColorOption.allCases) { option in
                    Text(option.rawValue.capitalized)
                        .tag(option.rawValue)
                }
            }
        }
    }

    private var preferencesSection: some View {
        Section("Preferences") {
            Toggle("Vibration", isOn: $hapticsEnabled)
                .onChange(of: hapticsEnabled) { _, _ in
                    HapticsManager.shared.selection()
                }

            Toggle("Sounds", isOn: $soundsEnabled)
                .onChange(of: soundsEnabled) { _, _ in
                    HapticsManager.shared.selection()
                }

            Toggle("Experimental features", isOn: $experimentalEnabled)
                .onChange(of: experimentalEnabled) { _, _ in
                    HapticsManager.shared.selection()
                }
        }
    }

    @ViewBuilder
    private var experimentalSection: some View {
        if experimentalEnabled {
            Section("Experimental") {
                Toggle("Glass effect", isOn: $glassEffectActivated)
            }
        }
    }

    private var supportSection: some View {
        Section("Support") {
            Button {
                CacheManager.shared.clear()
                HapticsManager.shared.notify(.success)
            } label: {
                Text("Clear cache")
            }
            .tint(.red)

            Button("Send feedback") {
                HapticsManager.shared.pulse()
                if let url = URL(string: "mailto:feedback.lian@gmail.com") {
                    openURL(url)
                }
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text(versionDisplayString)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(ContentViewModel())
}
