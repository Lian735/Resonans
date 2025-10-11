//
//  AppCard.swift
//  Resonans
//
//  Created by Samuel Meincke on 10.10.25.
//
import SwiftUI

/// A reusable, stylized container view that presents arbitrary content inside a card-like surface,
/// automatically adapting its appearance between a glass effect and a non-glass fallback.
///
/// AppCard provides two visual styles:
/// - On supported platforms (iOS 26 and later) and when the "Glass Effect activated" setting is enabled,
///   it renders content with SwiftUI’s glassEffect, clipped to a rounded rectangle.
/// - Otherwise, it falls back to a custom rounded rectangle background with a subtle fill, stroke, and shadow.
///
/// The view also measures its intrinsic size using preferences to ensure the overlay layout
/// reserves the appropriate height for the card.
///
/// Generics:
/// - Content: The type of the content view supplied to the card.
///
/// Behavior:
/// - Uses @AppStorage("Glass Effect activated") to persist and read whether the glass effect is enabled.
/// - Uses @Environment(\.colorScheme) to choose an appropriate shadow configuration for light/dark appearance.
/// - Measures width and height via GeometryReader and PreferenceKeys to size the overlay spacer.
///
/// Platform notes:
/// - The glass effect path is gated by `#available(iOS 26, *)`. On earlier versions, the non-glass style is used.
///
/// Example:
/// ```swift
/// AppCard {
///     VStack(alignment: .leading) {
///         Text("Title")
///             .font(.headline)
///         Text("Subtitle or description goes here.")
///             .font(.subheadline)
///     }
/// }
/// ```
///
/// Accessibility:
/// - The rounded shape is preserved via contentShape for better hit testing.
/// - Visual contrast is considered via primary color opacity and adaptive shadows.
///
/// Performance:
/// - The layout measurement is lightweight and only updates when size changes.
struct AppCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @ViewBuilder var content: () -> Content
    
    @State private var measuredHeight: CGFloat = .zero
    @State private var measuredWidth: CGFloat = .zero
    
    @AppStorage("Glass Effect activated") private var glassEffectActivated: Bool = true
    
    var body: some View {
        HStack{
            if #available(iOS 26, *) {
                if glassEffectActivated{
                    glassView
                }else{
                    nonGlassView
                }
            }else{
                nonGlassView
            }
        }
        .frame(minWidth: UIScreen().bounds.width)
    }
    
    private var glassView: some View {
        content()
            .padding()
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 30))
            .padding(5)
            .background(
                GeometryReader { innerProxy in
                    Color.clear
                        .preference(key: ViewHeightKey.self, value: innerProxy.size.height)
                        .preference(key: ViewWidthKey.self, value: innerProxy.size.width)
                }
            )
            .onPreferenceChange(ViewHeightKey.self) { height in
                self.measuredHeight = height
            }
            .onPreferenceChange(ViewWidthKey.self) { width in
                self.measuredWidth = width
            }
    }
    
    private var nonGlassView: some View {
        content()
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(.primary.opacity(0.09))
                    .overlay(
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .strokeBorder(.primary.opacity(0.10), lineWidth: 1)
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .shadow(ShadowConfiguration.smallConfiguration(for: colorScheme))
            .padding(5)
            .background(
                GeometryReader { innerProxy in
                    Color.clear
                        .preference(key: ViewHeightKey.self, value: innerProxy.size.height)
                        .preference(key: ViewWidthKey.self, value: innerProxy.size.width)
                }
            )
            .onPreferenceChange(ViewHeightKey.self) { height in
                self.measuredHeight = height
            }
            .onPreferenceChange(ViewWidthKey.self) { width in
                self.measuredWidth = width
            }
    }
}

internal struct ViewHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

internal struct ViewWidthKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
