import SwiftUI

struct DummyToolView: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("accentColor") private var accentRaw = AccentColorOption.purple.rawValue

    private var accent: AccentColorOption { AccentColorOption(rawValue: accentRaw) ?? .purple }

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
                    .typography(.titleMedium, color: .primary.opacity(0.7), design: .rounded)
                Text("Experiment with tool navigation")
                    .typography(.displaySmall, design: .rounded)
            }

            Spacer()

            Image(systemName: "puzzlepiece.extension")
                .typography(.custom(size: 30, weight: .bold), color: accent.color)
        }
    }

    private var descriptionCard: some View {
        AppCard{
            VStack(alignment: .leading, spacing: 16) {
                Text("This is a simple placeholder tool designed to help you test how the multi-tool flow behaves when several entries are available.")
                    .typography(.titleSmall, color: .primary.opacity(0.8), design: .rounded)
                
                Text("Close the tool from the header or the list to return to the tool overview. Everything here is purely for demonstration purposes.")
                    .typography(.callout, color: .primary.opacity(0.7), design: .rounded)
            }
            .padding(.horizontal, AppStyle.innerPadding)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    DummyToolView()
}
