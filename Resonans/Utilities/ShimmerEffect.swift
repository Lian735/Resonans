//
//  ShimmerEffect.swift
//  Resonans
//
//  Created by Lian on 05.11.25.
//

import SwiftUI

// Shimmer Effect Custom View Modifier
extension View {
    @ViewBuilder
    func shimmer(_ config: ShimmerConfig) -> some View {
        self.modifier(ShimmerEffectHelper(config: config))
    }
}

// Shimmer Effect Helper
fileprivate struct ShimmerEffectHelper: ViewModifier {
    // Shimmer Config
    var config: ShimmerConfig
    // Animation Properties
    @State private var moveTo: CGFloat = -0.7
    
    // Use overlays to avoid layout and hit-testing side effects
    func body(content: Content) -> some View {
        // Render base content as-is to own layout & hit-testing.
        content
            // Apply visual-only tint and shimmer as overlays so they don't affect layout.
            .overlay(alignment: .center) {
                // Tint layer constrained to content via mask.
                Rectangle()
                    .fill(config.tint.opacity(min(config.baseOpacity, 1)))
                    .brightness(max(config.baseOpacity - 1, 0))
                    .mask { content }
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                    .compositingGroup()
            }
            .overlay(alignment: .center) {
                // Shimmer highlight overlay constrained to content bounds.
                GeometryReader { proxy in
                    let size = proxy.size
                    let extraOffset = size.height / 2.5
                    let bandThickness = max(config.width, 1)

                    ZStack {
                        Rectangle()
                            .fill(config.highlight)
                            .mask {
                                Rectangle()
                                    .fill(
                                        LinearGradient(colors: [
                                            .white.opacity(0),
                                            config.highlight.opacity(config.highlightOpacity),
                                            .white.opacity(0)
                                        ], startPoint: .top, endPoint: .bottom)
                                    )
                                    .frame(height: bandThickness)
                                    .blur(radius: config.blur)
                                    .rotationEffect(.degrees(-70))
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            }
                            .offset(x: (moveTo > 0 ? extraOffset : -extraOffset))
                            .offset(x: size.width * moveTo)
                    }
                    // Constrain to the original content's visible shape.
                    .mask { content }
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                    .compositingGroup()
                }
            }
            // Ensure overlay never changes hit-testing or layout of base content
            .contentShape(.rect)
            .drawingGroup(opaque: false)
            .onAppear {
                DispatchQueue.main.async {
                    moveTo = 0.7
                }
            }
            .animation(.linear(duration: config.speed).repeatForever(autoreverses: false), value: moveTo)
    }
}

// Shimmer Config
struct ShimmerConfig {
    var tint: Color
    var highlight: Color
    var baseOpacity: CGFloat = 1.5
    var blur: CGFloat = 10
    var highlightOpacity: CGFloat = 2
    var speed: CGFloat = 2
    var width: CGFloat = 100
}

struct ShimmerEffect_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
