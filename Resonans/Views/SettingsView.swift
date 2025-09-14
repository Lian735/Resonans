import SwiftUI

struct SettingsView: View {
    @AppStorage("appearance") private var appearanceRaw = Appearance.system.rawValue
    @AppStorage("accentColor") private var accentRaw = AccentColorOption.purple.rawValue

    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("soundsEnabled") private var soundsEnabled = true
    @AppStorage("confirmationsEnabled") private var confirmationsEnabled = true

    private var appearance: Appearance {
        Appearance(rawValue: appearanceRaw) ?? .system
    }

    private var accent: AccentColorOption {
        AccentColorOption(rawValue: accentRaw) ?? .purple
    }

    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                appearanceSection
                interactionsSection
                aboutSection
            }
            .padding(.vertical, 30)
        }
    }

    // MARK: - Sections

    private var appearanceSection: some View {
        settingsBox {
            Text("Appearance")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            HStack(spacing: 12) {
                ForEach(Appearance.allCases) { mode in
                    VStack(spacing: 6) {
                        themePreview(for: mode)
                            .frame(width: 100, height: 70)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(mode == appearance ? accent.color : .clear, lineWidth: 3)
                            )
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    appearanceRaw = mode.rawValue
                                }
                            }

                        Text(mode.label)
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 8)

            Text("Accent color")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.top, 20)

            HStack(spacing: 16) {
                ForEach(AccentColorOption.allCases) { option in
                    Circle()
                        .fill(option.color)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: option == accent ? 3 : 0)
                        )
                        .onTapGesture {
                            accentRaw = option.rawValue
                        }
                }
            }
        }
    }

    private var interactionsSection: some View {
        settingsBox {
            Text("Interactions")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Toggle(isOn: $hapticsEnabled) {
                Text("Vibration")
                    .foregroundStyle(.white.opacity(0.9))
            }

            Toggle(isOn: $soundsEnabled) {
                Text("Sounds")
                    .foregroundStyle(.white.opacity(0.9))
            }

            Toggle(isOn: $confirmationsEnabled) {
                Text("Confirmations")
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
    }

    private var aboutSection: some View {
        settingsBox {
            Text("About")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            HStack {
                Text("Version")
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
            }
            .foregroundStyle(.white.opacity(0.8))

            Button {
                if let url = URL(string: "mailto:support@example.com") {
                    openURL(url)
                }
            } label: {
                Text("Send Feedback")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(accent.color.opacity(0.25))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(.top, 12)
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func themePreview(for mode: Appearance) -> some View {
        switch mode {
        case .light:
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white)
        case .dark:
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.black)
        case .system:
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(colors: [.black, .white], startPoint: .leading, endPoint: .trailing)
                )
        }
    }

    private func settingsBox<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            content()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.55), radius: 22, x: 0, y: 14)
                .shadow(color: .white.opacity(0.05), radius: 1, x: 0, y: 1)
        )
        .padding(.horizontal, 22)
    }
}

#Preview {
    SettingsView()
        .background(Color.black)
        .preferredColorScheme(.dark)
}

