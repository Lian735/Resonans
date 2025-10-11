import SwiftUI

/// A SwiftUI view that displays a rounded, gradient-filled tool icon with a symbol overlay and subtle shadow.
///
/// ToolIconView renders a square icon with a continuous rounded rectangle shape,
/// filled by a linear gradient derived from the provided `ToolItem`. It overlays
/// a system symbol (from `tool.iconName`) centered within the shape and applies
/// a light border and a small shadow that adapts to the current color scheme.
///
/// - Important: This view depends on several project-specific types and values:
///   - `ToolItem`: Supplies the gradient colors (`gradientColors`) and the SF Symbol name (`iconName`).
///   - `AppStyle.iconCornerRadius`: Controls the corner radius used for the rounded rectangle.
///   - `ShadowConfiguration.smallConfiguration(for:)`: Provides a shadow style appropriate for the current `ColorScheme`.
///
/// - Environment:
///   - `colorScheme`: Used to determine the appropriate shadow configuration for light/dark modes.
///
/// - Appearance:
///   - Size: 52x52 points.
///   - Shape: Rounded rectangle with continuous corners.
///   - Fill: Linear gradient from top-leading to bottom-trailing using `tool.gradientColors`.
///   - Border: 1pt white stroke at 18% opacity.
///   - Icon: Centered SF Symbol specified by `tool.iconName`, bold at 24pt, white foreground.
///   - Shadow: Small shadow from `ShadowConfiguration`, adaptive to color scheme.
///
/// - Parameters:
///   - tool: The `ToolItem` providing the gradient colors and system image name.
///
/// - Usage:
///   Provide a `ToolItem` to configure the icon's gradient and symbol:
///   ```swift
///   ToolIconView(tool: myToolItem)
///   ```
///
/// - See Also:
///   - `ToolItem`
///   - `AppStyle.iconCornerRadius`
///   - `ShadowConfiguration.smallConfiguration(for:)`
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
