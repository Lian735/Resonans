import SwiftUI

struct DummyToolView: View {
    let onClose: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("accentColor") private var accentRaw = AccentColorOption.purple.rawValue

    private var accent: AccentColorOption { AccentColorOption(rawValue: accentRaw) ?? .purple }
    @available(*, deprecated)
    private var primary: Color { AppStyle.primary(for: colorScheme) }

    init(onClose: @escaping () -> Void = {}) {
        self.onClose = onClose
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 28) {
                Color.clear
                    .frame(height: AppStyle.innerPadding)
                    .padding(.bottom, -24)

                header

                descriptionCard

                Spacer(minLength: 60)
            }
            .padding(.horizontal, AppStyle.horizontalPadding)
        }
        .background(.clear)
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Dummy Playground")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(primary.opacity(0.7))
                Text("Experiment with tool navigation")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(primary)
            }

            Spacer()

            Image(systemName: "puzzlepiece.extension")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(accent.color)
        }
    }

    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("This is a simple placeholder tool designed to help you test how the multi-tool flow behaves when several entries are available.")
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(primary.opacity(0.8))

            Text("Close the tool from the header or the list to return to the tool overview. Everything here is purely for demonstration purposes.")
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundStyle(primary.opacity(0.7))
        }
        .padding(.horizontal, AppStyle.innerPadding)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCardStyle(primary: primary, colorScheme: colorScheme, shadowLevel: .medium)
    }
}

#Preview {
    DummyToolView()
}
