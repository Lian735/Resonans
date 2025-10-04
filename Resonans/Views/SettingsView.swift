import SwiftUI

struct SettingsView: View {
    let theme: AppTheme
    let onShowOnboarding: () -> Void

    @AppStorage("appearance") private var appearanceRaw = Appearance.system.rawValue
    @AppStorage("accentColor") private var accentRaw = AccentColorOption.purple.rawValue
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("soundsEnabled") private var soundsEnabled = true
    @AppStorage("experimentalEnabled") private var experimentalEnabled = false

    @Environment(\.openURL) private var openURL

    private var accent: AccentColorOption { AccentColorOption(rawValue: accentRaw) ?? .purple }

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
        List {
            Section("Appearance") {
                Picker("Appearance", selection: $appearanceRaw) {
                    ForEach(Appearance.allCases) { mode in
                        Text(mode.label).tag(mode.rawValue)
                    }
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Accent colour")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(theme.foreground)

                    let columns = [GridItem(.adaptive(minimum: 36, maximum: 56))]
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(AccentColorOption.allCases) { option in
                            Button {
                                accentRaw = option.rawValue
                                HapticsManager.shared.selection()
                            } label: {
                                Circle()
                                    .fill(option.color)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                option == accent ? theme.accentColor : theme.border,
                                                lineWidth: option == accent ? 3 : 1
                                            )
                                            .scaleEffect(option == accent ? 1.2 : 1)
                                    )
                                    .animation(.easeInOut(duration: 0.2), value: accentRaw)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.top, 4)
            }
            .textCase(nil)

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
            .textCase(nil)

            Section("Utilities") {
                Button {
                    CacheManager.shared.clear()
                    HapticsManager.shared.notify(.success)
                } label: {
                    Label("Clear cache", systemImage: "trash")
                        .foregroundStyle(theme.foreground)
                }
            }
            .textCase(nil)

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(versionDisplayString)
                        .foregroundStyle(theme.secondary)
                }

                Button {
                    if let url = URL(string: "mailto:feedback.lian@gmail.com") {
                        openURL(url)
                    }
                } label: {
                    Label("Send feedback", systemImage: "envelope")
                        .foregroundStyle(theme.accentColor)
                }
            }
            .textCase(nil)

            Section {
                Button("View onboarding again", action: onShowOnboarding)
                    .foregroundStyle(theme.accentColor)
            }
        }
        .listStyle(.insetGrouped)
        .listRowSeparator(.hidden)
        .scrollContentBackground(.hidden)
        .background(theme.background)
    }
}

#Preview {
    NavigationStack {
        SettingsView(theme: AppTheme(accent: .purple, colorScheme: .light)) {}
    }
}
