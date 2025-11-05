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
        self
            .modifier(ShimmerEffectHelper(config: config))
    }
}

// Shimmer Effect Helper
fileprivate struct ShimmerEffectHelper: ViewModifier {
    // Shimmer Config
    var config: ShimmerConfig
    // Animation Properties
    @State private var moveTo: CGFloat = -0.7
    func body(content: Content) -> some View {
        ZStack {
            // Keep base content visible so it never appears cropped
            content

            // Additive tint layer (optional subtle tint)
            Rectangle()
                .fill(config.tint.opacity(min(config.baseOpacity, 1)))
                .brightness(max(config.baseOpacity - 1, 0))
                .mask { content }
                .allowsHitTesting(false)

            // Shimmer highlight overlay that spans full bounds
            GeometryReader { proxy in
                let size = proxy.size
                let extraOffset = size.height / 2.5
                // Treat `width` as the band thickness, not total coverage
                let bandThickness = max(config.width, 1)

                ZStack {
                    Rectangle()
                        .fill(config.highlight)
                        .mask {
                            // Vertical gradient band (thin), then rotate to sweep diagonally
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
                                // Center in an infinite frame so its rotated bounds don't crop
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        }
                        // Sweep motion across the full width
                        .offset(x: (moveTo > 0 ? extraOffset : -extraOffset))
                        .offset(x: size.width * moveTo)
                }
                // Constrain the shimmer to the content's shape
                .mask { content }
                .allowsHitTesting(false)
            }
        }
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
    var blur: CGFloat = 0
    var highlightOpacity: CGFloat = 2
    var speed: CGFloat = 2
    var width: CGFloat = 100
}

struct ShimmerEffect_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
