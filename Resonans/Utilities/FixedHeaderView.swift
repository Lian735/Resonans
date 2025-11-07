// this bullshit is completely ai generated, i wanted to rebuild the ios 26 nav title to be always large yeah we needa fix that

import SwiftUI

/// A custom, reusable header that mimics the iOS 26 Navigation Title style
/// with a frosted mesh gradient background, large title, and trailing action.
public struct FixedHeaderView<Trailing: View>: View {
    // MARK: - Inputs
    private let title: String
    private let subtitle: String?
    private let trailing: Trailing
    private let height: CGFloat
    private let showsSeparator: Bool
    private let safeAreaEdges: Edge.Set

    // MARK: - Init
    public init(
        _ title: String,
        subtitle: String? = nil,
        height: CGFloat = 64,
        showsSeparator: Bool = true,
        safeAreaEdges: Edge.Set = [.top],
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
        self.height = height
        self.showsSeparator = showsSeparator
        self.safeAreaEdges = safeAreaEdges
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            // Top-only blur fade that samples pixels behind (like a real header)
            TopBlurFade(height: topSafeInset + height + (showsSeparator ? 1 : 0))
                .ignoresSafeArea(edges: safeAreaEdges)

            VStack(spacing: 0) {
                // Reserve safe-area at top for devices with a notch
                Color.clear
                    .frame(height: topSafeInset)
                    .ignoresSafeArea(edges: safeAreaEdges)

                ZStack(alignment: .leading) {
                    // Empty: blur is provided by TopBlurFade behind this stack
                    Color.clear

                    // Title & subtitle in front of the blur with slight top padding
                    headerContent
                        .padding(.top, 4)
                }
                .frame(height: height)
                .padding(.horizontal, 16)
                .accessibilityElement(children: .combine)

                if showsSeparator {
                    separator
                }
            }
        }
        .accessibilityAddTraits(.isHeader)
    }

    // MARK: - Header content
    private var headerContent: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.title2, design: .rounded).weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .foregroundStyle(.primary)

                if let subtitle {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            trailing
                .alignmentGuide(.firstTextBaseline) { d in d[.firstTextBaseline] }
        }
    }

    // MARK: - Separator
    private var separator: some View {
        Rectangle()
            .fill(.separator.opacity(0.6))
            .frame(height: 0.33)
            .overlay(
                LinearGradient(colors: [
                    .black.opacity(0.05),
                    .clear
                ], startPoint: .top, endPoint: .bottom)
            )
    }

    // MARK: - Safe area helpers
    private var topSafeInset: CGFloat {
        // Use UIApplication for iOS, fallback to zero for other platforms.
        #if os(iOS)
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .keyWindow?
            .safeAreaInsets.top ?? 0
        #else
        return 0
        #endif
    }
}

// MARK: - Background: Frosted Mesh Gradient
private struct FrostedMeshBackground: View {
    // A subtle animated mesh gradient + material blur that mimics iOS 26 nav bars.
    @State private var phase: CGFloat = 0

    var body: some View {
        ZStack {
            // Mesh-like gradient using multiple radial gradients blended together.
            Canvas { ctx, size in
                // Precompute scalar values to reduce expression complexity
                let width: CGFloat = size.width
                let height: CGFloat = size.height
                let maxDim: CGFloat = max(width, height)

                // Define colors explicitly
                let colors: [Color] = [
                    Color.pink.opacity(0.6),
                    Color.purple.opacity(0.6),
                    Color.blue.opacity(0.6),
                    Color.cyan.opacity(0.6),
                    Color.indigo.opacity(0.6)
                ]

                // Helper to compute a center point for a given t
                func centerPoint(for t: CGFloat, phase: CGFloat, width: CGFloat, height: CGFloat) -> CGPoint {
                    let x = width * (t + 0.12 * sin(phase + t * 7))
                    let y = height * (0.3 + 0.15 * cos(phase * 0.8 + t * 5))
                    return CGPoint(x: x, y: y)
                }

                // Helper to create an ellipse path
                func ellipsePath(center: CGPoint, radius: CGFloat) -> Path {
                    let rect = CGRect(x: center.x - radius,
                                      y: center.y - radius,
                                      width: radius * 2,
                                      height: radius * 2)
                    return Path(ellipseIn: rect)
                }

                // Helper to create a radial gradient style
                func radialStyle(color: Color, center: CGPoint, width: CGFloat, height: CGFloat, radius: CGFloat) -> GraphicsContext.Shading {
                    let gradient = Gradient(colors: [color, .clear])
                    return .radialGradient(gradient, center: center, startRadius: 0, endRadius: radius)
                }

                // Build the list of t values explicitly to avoid stride generic complexity
                let tValues: [CGFloat] = [0, 0.25, 0.5, 0.75, 1.0]

                for (index, t) in tValues.enumerated() {
                    let center = centerPoint(for: t, phase: phase, width: width, height: height)
                    let base = 0.6 + 0.15 * sin(phase + CGFloat(index))
                    let radius = maxDim * base
                    let path = ellipsePath(center: center, radius: radius)
                    let color = colors[index % colors.count]
                    let shading = radialStyle(color: color, center: center, width: width, height: height, radius: radius)
                    ctx.fill(path, with: shading)
                }
            }
            .blur(radius: 24)
            .saturation(1.1)
            .brightness(0.02)

            // Frosted layer to emulate system materials
            Rectangle()
                .fill(.ultraThinMaterial)
                .blendMode(.plusLighter)
                .opacity(0.9)
        }
        .compositingGroup()
        .drawingGroup()
        .animation(.easeInOut(duration: 8).repeatForever(autoreverses: true), value: phase)
        .onAppear { phase = 1 }
    }
}

// MARK: - Top-only backdrop blur with gradient fade
private struct TopBlurFade: View {
    let height: CGFloat

    var body: some View {
        ZStack(alignment: .top) {
            // Backdrop blur that samples the pixels behind this view
            Rectangle()
                .fill(.regularMaterial)
                .frame(height: height)
                .overlay(
                    // Subtle tint/mesh hint to feel premium without overpowering
                    LinearGradient(colors: [
                        Color.white.opacity(0.10),
                        Color.clear
                    ], startPoint: .top, endPoint: .bottom)
                )
                .mask(
                    // Fade the blur from top to transparent downwards
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .white, location: 0.0),    // strong blur at the very top
                            .init(color: .white, location: 0.25),   // maintain strong blur near top
                            .init(color: .clear, location: 1.0)     // fade blur by the bottom
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    // Optional subtle separator at the very bottom of the blur
                    Rectangle()
                        .fill(.separator.opacity(0.6))
                        .frame(height: 0.33)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                )
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Convenience overload when no trailing view is needed
public extension FixedHeaderView where Trailing == EmptyView {
    init(_ title: String, subtitle: String? = nil, height: CGFloat = 64, showsSeparator: Bool = true, safeAreaEdges: Edge.Set = [.top]) {
        self.init(title, subtitle: subtitle, height: height, showsSeparator: showsSeparator, safeAreaEdges: safeAreaEdges) { EmptyView() }
    }
}

// MARK: - Preview
#Preview("FixedHeaderView") {
    ZStack(alignment: .top) {
        // Background image from assets
        ScrollView {
            VStack {
                Image("darkandwhite")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            }
        }

        // Header overlaid on top of the background
        VStack {
            FixedHeaderView("Discover", subtitle: "Updated just now") {
                Button(action: {}) {
                    Image(systemName: "ellipsis.circle")
                        .imageScale(.large)
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }
}

