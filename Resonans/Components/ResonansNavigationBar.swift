import SwiftUI

struct ResonansNavigationBar: View {
    let title: String
    let subtitle: String
    let accentColor: Color
    let primaryColor: Color
    var onHelp: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 42, weight: .heavy, design: .rounded))
                        .foregroundStyle(primaryColor)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                        .appTextShadow(colorScheme: colorScheme)

                    Text(subtitle)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(primaryColor.opacity(0.65))
                }

                Spacer()

                if let onHelp {
                    Button(action: onHelp) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(primaryColor)
                            .padding(12)
                            .background(
                                Circle()
                                    .fill(primaryColor.opacity(AppStyle.cardFillOpacity))
                            )
                    }
                    .buttonStyle(.plain)
                    .appShadow(colorScheme: colorScheme, level: .small, opacity: 0.35)
                }
            }

            Capsule()
                .fill(accentColor.opacity(0.45))
                .frame(width: 82, height: 6)
                .shadow(color: accentColor.opacity(0.35), radius: 8, x: 0, y: 4)
        }
        .padding(.top, 16)
        .padding(.horizontal, AppStyle.horizontalPadding)
        .padding(.bottom, 12)
    }
}

#Preview {
    ResonansNavigationBar(
        title: "Resonans",
        subtitle: "Convert clips into studio-grade audio.",
        accentColor: .purple,
        primaryColor: .white,
        onHelp: {}
    )
    .background(Color.black)
}
