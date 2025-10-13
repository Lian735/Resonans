import SwiftUI

struct ToolMorphContext: Identifiable, Equatable {
    let tool: ToolItem
    let originFrame: CGRect

    var id: ToolItem.Identifier { tool.id }
}

struct ToolMorphOverlay<Detail: View>: View {
    let context: ToolMorphContext
    @Binding var progress: CGFloat

    private let detailContent: Detail
    private let onClose: (ToolItem) -> Void

    @State private var isClosing = false

    init(
        context: ToolMorphContext,
        progress: Binding<CGFloat>,
        @ViewBuilder detail: () -> Detail,
        onClose: @escaping (ToolItem) -> Void
    ) {
        self.context = context
        self._progress = progress
        self.detailContent = detail()
        self.onClose = onClose
    }

    var body: some View {
        GeometryReader { proxy in
            let screenRect = proxy.frame(in: .global)
            let startRect = normalizedStartRect(within: screenRect)
            let targetRect = screenRect
            let currentRect = interpolatedRect(from: startRect, to: targetRect, progress: progress)
            let currentCorner = cornerRadius(for: progress)

            ZStack(alignment: .topLeading) {
                Color.black.opacity(0.26 * progress)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                RoundedRectangle(cornerRadius: currentCorner, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: currentCorner, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.14 * (1 - progress)), lineWidth: strokeWidth(for: progress))
                    )
                    .frame(width: currentRect.width, height: currentRect.height)
                    .position(
                        x: currentRect.midX - screenRect.minX,
                        y: currentRect.midY - screenRect.minY
                    )
                    .shadow(color: Color.black.opacity(0.22 * progress), radius: 28 * progress, x: 0, y: 24 * progress)
                    .overlay(
                        containerContent(proxy: proxy, cornerRadius: currentCorner)
                            .frame(width: currentRect.width, height: currentRect.height)
                            .clipShape(RoundedRectangle(cornerRadius: currentCorner, style: .continuous))
                            .position(
                                x: currentRect.midX - screenRect.minX,
                                y: currentRect.midY - screenRect.minY
                            )
                    )
            }
            .ignoresSafeArea()
        }
        .transition(.identity)
    }

    private func containerContent(proxy: GeometryProxy, cornerRadius: CGFloat) -> some View {
        ZStack(alignment: .top) {
            ToolOverview(tool: context.tool, morphProgress: min(1, progress * 1.15))
                .opacity(max(0, 1 - progress * 1.8))
                .blur(radius: progress * 12)

            VStack(spacing: 0) {
                detailContent
                    .padding(.top, proxy.safeAreaInsets.top + 20)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 0)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .opacity(progress)
                    .blur(radius: (1 - progress) * 18)
                    .allowsHitTesting(progress > 0.95)

                Spacer(minLength: 0)

                closePill
                    .padding(.horizontal, 64)
                    .padding(.bottom, proxy.safeAreaInsets.bottom + 28)
                    .opacity(progress)
                    .allowsHitTesting(true)
            }
        }
    }

    private var closePill: some View {
        Capsule()
            .fill(.ultraThinMaterial)
            .overlay(
                HStack(spacing: 12) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Close Tool")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .foregroundStyle(Color.primary.opacity(0.9))
            )
            .shadow(color: Color.black.opacity(0.2 * progress), radius: 20 * progress, x: 0, y: 12 * progress)
            .scaleEffect(0.92 + 0.08 * progress)
            .gesture(dragGesture)
            .accessibilityLabel(Text("Close tool"))
            .allowsHitTesting(progress > 0.8)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 6, coordinateSpace: .global)
            .onChanged { value in
                guard !isClosing else { return }
                let normalized = closeProgress(for: value.translation)
                progress = max(0, min(1, 1 - normalized))
            }
            .onEnded { value in
                guard !isClosing else { return }
                let normalized = closeProgress(for: value.translation)
                if normalized > 0.45 {
                    triggerClose()
                } else {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.82, blendDuration: 0.2)) {
                        progress = 1
                    }
                }
            }
    }

    private func triggerClose() {
        guard !isClosing else { return }
        isClosing = true
        onClose(context.tool)
    }

    private func normalizedStartRect(within screenRect: CGRect) -> CGRect {
        let base = context.originFrame
        guard base != .zero else {
            let width = min(screenRect.width * 0.8, 340)
            let height = width * 0.62
            return CGRect(
                x: screenRect.midX - width / 2,
                y: screenRect.midY - height / 2,
                width: width,
                height: height
            )
        }
        return clamp(rect: base, within: screenRect)
    }

    private func interpolatedRect(from start: CGRect, to end: CGRect, progress: CGFloat) -> CGRect {
        let clamped = max(0, min(1, progress))
        let originX = start.minX + (end.minX - start.minX) * clamped
        let originY = start.minY + (end.minY - start.minY) * clamped
        let width = start.width + (end.width - start.width) * clamped
        let height = start.height + (end.height - start.height) * clamped
        return CGRect(x: originX, y: originY, width: width, height: height)
    }

    private func clamp(rect: CGRect, within bounds: CGRect) -> CGRect {
        var rect = rect
        if rect.width > bounds.width { rect.size.width = bounds.width }
        if rect.height > bounds.height { rect.size.height = bounds.height }
        rect.origin.x = max(bounds.minX, min(rect.minX, bounds.maxX - rect.width))
        rect.origin.y = max(bounds.minY, min(rect.minY, bounds.maxY - rect.height))
        return rect
    }

    private func cornerRadius(for progress: CGFloat) -> CGFloat {
        let collapsedCorner: CGFloat = 30
        let expandedCorner: CGFloat = 0
        return collapsedCorner + (expandedCorner - collapsedCorner) * progress
    }

    private func strokeWidth(for progress: CGFloat) -> CGFloat {
        let base: CGFloat = 1.0
        return max(0.4, base * (1 - progress))
    }

    private func closeProgress(for translation: CGSize) -> CGFloat {
        let vertical = max(0, -translation.height)
        let horizontal = abs(translation.width)
        let combined = vertical + horizontal * 0.7
        let normalized = combined / 160
        return max(0, min(1, normalized))
    }
}
