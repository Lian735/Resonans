import SwiftUI

struct ToolCard: View {
    enum Layout {
        case large
        case compact
    }

    let tool: ToolItem
    let layout: Layout
    let primary: Color
    let colorScheme: ColorScheme
    let accent: Color
    var isFavorite: Bool = false
    var caption: String? = nil
    let action: () -> Void

    private var cornerRadius: CGFloat {
        layout == .large ? AppStyle.cornerRadius : AppStyle.compactCornerRadius
    }

    private var horizontalPadding: CGFloat {
        layout == .large ? 22 : 18
    }

    private var verticalPadding: CGFloat {
        layout == .large ? 22 : 16
    }

    private var iconSize: CGFloat {
        layout == .large ? 60 : 48
    }

    private var iconFontSize: CGFloat {
        layout == .large ? 28 : 24
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            cardBody
                .onTapGesture {
                    HapticsManager.shared.selection()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        action()
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isButton)

            if isFavorite {
                favoriteBadge
                    .padding(.trailing, 14)
                    .padding(.top, 12)
                    .transition(.scale.combined(with: .opacity))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isFavorite)
            }
        }
    }

    private var cardBody: some View {
        VStack(alignment: .leading, spacing: layout == .large ? 18 : 14) {
            icon

            VStack(alignment: .leading, spacing: 6) {
                Text(tool.title)
                    .font(.system(size: layout == .large ? 22 : 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(primary)
                    .lineLimit(1)

                Text(tool.subtitle)
                    .font(.system(size: layout == .large ? 15 : 13, weight: .medium, design: .rounded))
                    .foregroundStyle(primary.opacity(0.7))
                    .lineLimit(layout == .large ? 3 : 2)
            }

            if let caption {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(primary.opacity(0.45))
                    Text(caption)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(primary.opacity(0.65))
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(primary.opacity(AppStyle.cardFillOpacity))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(primary.opacity(AppStyle.strokeOpacity), lineWidth: 1)
                )
        )
        .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .appShadow(colorScheme: colorScheme, level: layout == .large ? .large : .medium, opacity: layout == .large ? 0.55 : 0.45)
    }

    private var icon: some View {
        RoundedRectangle(cornerRadius: AppStyle.iconCornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: tool.gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: iconSize, height: iconSize)
            .overlay(
                RoundedRectangle(cornerRadius: AppStyle.iconCornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .overlay(
                Image(systemName: tool.iconName)
                    .font(.system(size: iconFontSize, weight: .bold))
                    .foregroundStyle(Color.white)
            )
            .appShadow(colorScheme: colorScheme, level: .small, opacity: 0.45)
    }

    private var favoriteBadge: some View {
        Label("Favorite", systemImage: "heart.fill")
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(
                Capsule(style: .continuous)
                    .fill(accent.opacity(colorScheme == .dark ? 0.35 : 0.25))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(accent.opacity(0.45), lineWidth: 1)
            )
            .foregroundStyle(accent)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selected = false
        var body: some View {
            VStack(spacing: 24) {
                ToolCard(
                    tool: ToolItem.audioExtractor,
                    layout: .large,
                    primary: .black,
                    colorScheme: .light,
                    accent: .purple,
                    isFavorite: true
                ) {}

                ToolCard(
                    tool: ToolItem.audioExtractor,
                    layout: .compact,
                    primary: .black,
                    colorScheme: .light,
                    accent: .pink,
                    caption: "Open tool"
                ) {}
            }
            .padding()
            .background(Color.white)
        }
    }
    return PreviewWrapper()
}
