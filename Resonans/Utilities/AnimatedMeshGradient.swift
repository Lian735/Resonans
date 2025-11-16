import SwiftUI
import CoreGraphics
//
//  AnimatedMeshGradient.swift
//  Resonans
//
//  Created by Lian on 07.11.25.
//

/// Animated mesh gradient used for decorative backgrounds.
struct AnimatedMeshGradient: View {
    // Tunable parameters
    private let period: TimeInterval = 12 // slower, smoother loop
    private let frameRate: Double = 60    // smoother timeline

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / frameRate)) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            let phase = time.truncatingRemainder(dividingBy: period)
            let progress = CGFloat(phase / period)

            Canvas { ctx, size in
                // Paint a soft background first to avoid black gaps
                let bgPath = Rectangle().path(in: CGRect(origin: .zero, size: size))
                ctx.fill(bgPath, with: .color(Color(hue: 2, saturation: 0.22, brightness: 0.18)))

                // Precompute some constants
                let twoPi = CGFloat.pi * 2
                let w = size.width
                let h = size.height

                // Helper functions to keep expressions simple
                func c(_ x: CGFloat) -> CGFloat { cos(twoPi * x) }
                func s(_ x: CGFloat) -> CGFloat { sin(twoPi * x) }

                // Use more points and larger radii to avoid black gaps
                let x0 = w * (0.20 + 0.16 * c(progress + 0.00))
                let x1 = w * (0.80 + 0.14 * s(progress + 0.20))
                let x2 = w * (0.50 + 0.18 * s(progress + 0.40))
                let x3 = w * (0.10 + 0.18 * c(progress + 0.60))
                let x4 = w * (0.60 + 0.16 * c(progress + 0.30))
                let x5 = w * (0.35 + 0.14 * s(progress + 0.85))

                let y0 = h * (0.25 + 0.14 * s(progress + 0.15))
                let y1 = h * (0.70 + 0.14 * c(progress + 0.35))
                let y2 = h * (0.40 + 0.16 * c(progress + 0.55))
                let y3 = h * (0.85 + 0.12 * s(progress + 0.75))
                let y4 = h * (0.55 + 0.14 * s(progress + 0.10))
                let y5 = h * (0.15 + 0.16 * c(progress + 0.90))

                let points: [CGPoint] = [
                    CGPoint(x: x0, y: y0),
                    CGPoint(x: x1, y: y1),
                    CGPoint(x: x2, y: y2),
                    CGPoint(x: x3, y: y3),
                    CGPoint(x: x4, y: y4),
                    CGPoint(x: x5, y: y5)
                ]

                // Blue, cyan, and purple palette with more saturation and brightness including accents
                let baseColors: [Color] = [
                    Color(hue: 0.55, saturation: 0.55, brightness: 0.92), // cyan
                    Color(hue: 0.60, saturation: 0.52, brightness: 0.90), // blue
                    Color(hue: 0.66, saturation: 0.50, brightness: 0.90), // indigo
                    Color(hue: 0.72, saturation: 0.50, brightness: 0.92), // purple
                    Color(hue: 0.58, saturation: 0.58, brightness: 0.94), // cyan-blue
                    Color(hue: 0.68, saturation: 0.52, brightness: 0.92)  // blue-purple
                ]

                // Reduced radius and blur for visible motion
                let maxDim = max(w, h)
                let radius = maxDim * 0.75

                // Soften edges, avoid harsh multiply that can darken
                let blur = GraphicsContext.Filter.blur(radius: radius * 0.08)
                ctx.addFilter(blur)
                ctx.opacity = 1.0

                for (i, p) in points.enumerated() {
                    let rect = CGRect(x: p.x - radius/2, y: p.y - radius/2, width: radius, height: radius)
                    let path = Path(ellipseIn: rect)

                    let c = baseColors[i % baseColors.count]
                    let gradient = Gradient(stops: [
                        .init(color: c.opacity(0.75), location: 0.0),
                        .init(color: c.opacity(0.50), location: 0.30),
                        .init(color: c.opacity(0.22), location: 0.65),
                        .init(color: c.opacity(0.00), location: 1.0)
                    ])

                    ctx.fill(
                        path,
                        with: .radialGradient(
                            gradient,
                            center: p,
                            startRadius: 0,
                            endRadius: radius
                        )
                    )
                }
            }
        }
    }
}
