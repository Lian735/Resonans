import SwiftUI

struct ToolRowCard<Accessory: View>: View {
    let tool: ToolItem
    let primary: Color
    let colorScheme: ColorScheme
    let subtitleSpacing: CGFloat
    let subtitleColor: Color
    let shadowLevel: DefaultShadowConfiguration
    let shadowOpacity: Double?
    private let accessory: Accessory

    init(
        tool: ToolItem,
        primary: Color,
        colorScheme: ColorScheme,
        subtitleSpacing: CGFloat = 4,
        subtitleColor: Color? = nil,
        shadowLevel: DefaultShadowConfiguration = .medium,
        shadowOpacity: Double? = nil,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.tool = tool
        self.primary = primary
        self.colorScheme = colorScheme
        self.subtitleSpacing = subtitleSpacing
        self.subtitleColor = subtitleColor ?? primary.opacity(0.65)
        self.shadowLevel = shadowLevel
        self.shadowOpacity = shadowOpacity
        self.accessory = accessory()
    }

    init(
        tool: ToolItem,
        primary: Color,
        colorScheme: ColorScheme,
        subtitleSpacing: CGFloat = 4,
        subtitleColor: Color? = nil,
        shadowLevel: DefaultShadowConfiguration = .medium,
        shadowOpacity: Double? = nil
    ) where Accessory == EmptyView {
        self.init(
            tool: tool,
            primary: primary,
            colorScheme: colorScheme,
            subtitleSpacing: subtitleSpacing,
            subtitleColor: subtitleColor,
            shadowLevel: shadowLevel,
            shadowOpacity: shadowOpacity
        ) {
            EmptyView()
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            ToolIconView(tool: tool, colorScheme: colorScheme)

            VStack(alignment: .leading, spacing: subtitleSpacing) {
                Text(tool.title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(primary)

                Text(tool.subtitle)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(subtitleColor)
                    .lineLimit(2)
            }

            Spacer()

            accessory
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .appCardStyle(
            primary: primary,
            colorScheme: colorScheme,
            shadowLevel: shadowLevel,
            shadowOpacity: shadowOpacity
        )
    }
}

struct ToolIconView: View {
    let tool: ToolItem
    let colorScheme: ColorScheme

    var body: some View {
        RoundedRectangle(cornerRadius: AppStyle.iconCornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: tool.gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 52, height: 52)
            .overlay(
                RoundedRectangle(cornerRadius: AppStyle.iconCornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
            .overlay(
                Image(systemName: tool.iconName)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color.white)
            )
            .shadow(DefaultShadowConfiguration.small.configuration(for: colorScheme))
    }
}
