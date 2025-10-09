import SwiftUI

struct DummyToolView: View {
    let onClose: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var primary: Color { AppStyle.primary(for: colorScheme) }

    init(onClose: @escaping () -> Void = {}) {
        self.onClose = onClose
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 32) {
                Color.clear
                    .frame(height: AppStyle.innerPadding)
                    .padding(.bottom, -24)

                VStack(alignment: .leading, spacing: 16) {
                    Text("Nothing to see here")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(primary)

                    Text("This is just a placeholder view to help you test how multiple tools behave in the interface.")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(primary.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Feel free to close this tool whenever you like—it's happy to step aside.")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(primary.opacity(0.65))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, AppStyle.innerPadding)
                .padding(.vertical, 28)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                        .fill(primary.opacity(AppStyle.subtleCardFillOpacity))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                                .stroke(primary.opacity(AppStyle.strokeOpacity), lineWidth: 1)
                        )
                )
                .appShadow(colorScheme: colorScheme, level: .medium)
                .padding(.horizontal, AppStyle.horizontalPadding)

                Button {
                    HapticsManager.shared.selection()
                    onClose()
                } label: {
                    Text("Close dummy tool")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(primary)
                        .padding(.vertical, 18)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                                .fill(primary.opacity(AppStyle.cardFillOpacity))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                                        .stroke(primary.opacity(AppStyle.strokeOpacity), lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
                .appShadow(colorScheme: colorScheme, level: .medium)
                .padding(.horizontal, AppStyle.horizontalPadding)

                Spacer(minLength: 80)
            }
        }
        .background(.clear)
    }
}

#Preview {
    DummyToolView()
}
