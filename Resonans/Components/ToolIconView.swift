import SwiftUI

struct ToolIconView: View {
    let tool: ToolItem
    
    @Environment(\.colorScheme) private var colorScheme

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
            .shadow(ShadowConfiguration.smallConfiguration(for: colorScheme))
    }
}
