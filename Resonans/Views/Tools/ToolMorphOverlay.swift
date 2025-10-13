import SwiftUI

struct ToolMorphOverlay<Content: View>: View {
    let tool: ToolItem
    let namespace: Namespace.ID
    let onProgressChange: (CGFloat) -> Void
    let onClose: () -> Void
    @ViewBuilder var content: () -> Content

    @State private var revealProgress: CGFloat = 0
    @State private var dragOffset: CGSize = .zero
    @State private var hasScheduledClose = false

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let safeInsets = proxy.safeAreaInsets
            let dragProgress = progress(from: dragOffset, in: size)
            let openFraction = clamp(revealProgress - dragProgress)
            let offset = offset(for: dragOffset, fraction: openFraction)
            let cornerRadius = max(12, 32 * (1 - openFraction))

            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color.white.opacity(0.08 * openFraction), lineWidth: openFraction > 0.95 ? 0 : 1)
                    )
                    .matchedGeometryEffect(id: ToolMorphID.card(tool.id), in: namespace)
                    .frame(width: size.width, height: size.height)
                    .shadow(color: Color.black.opacity(0.18 * openFraction), radius: 32 * openFraction, x: 0, y: 24 * openFraction)
                    .overlay(
                        VStack(spacing: 0) {
                            Spacer(minLength: safeInsets.top + 18)

                            content()
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                                .padding(.horizontal, AppStyle.horizontalPadding)
                                .padding(.bottom, 96)
                                .opacity(openFraction)
                                .blur(radius: (1 - openFraction) * 14)

                            Spacer(minLength: safeInsets.bottom + 120)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    )
                    .overlay(alignment: .bottom) {
                        ToolClosePill(openFraction: openFraction)
                            .padding(.bottom, max(24, safeInsets.bottom + 16))
                            .gesture(pillGesture(in: size))
                    }
            }
            .frame(width: size.width, height: size.height)
            .offset(offset)
            .background(
                Color.black.opacity(0.35 * openFraction)
                    .ignoresSafeArea()
            )
            .onChange(of: openFraction) { _, newValue in
                onProgressChange(clamp(newValue))
            }
            .onAppear {
                hasScheduledClose = false
                dragOffset = .zero
                onProgressChange(0)
                withAnimation(.interactiveSpring(response: 0.6, dampingFraction: 0.85)) {
                    revealProgress = 1
                }
            }
        }
        .ignoresSafeArea()
    }

    private func pillGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { value in
                dragOffset = value.translation
            }
            .onEnded { value in
                let translation = value.translation
                let progress = progress(from: translation, in: size)
                if progress > 0.33 {
                    closeOverlay()
                } else {
                    withAnimation(.interactiveSpring(response: 0.6, dampingFraction: 0.85)) {
                        dragOffset = .zero
                    }
                }
            }
    }

    private func closeOverlay() {
        guard !hasScheduledClose else { return }
        hasScheduledClose = true
        withAnimation(.interactiveSpring(response: 0.6, dampingFraction: 0.85)) {
            revealProgress = 0
            dragOffset = .zero
        }
        let delay = DispatchTime.now() + 0.45
        DispatchQueue.main.asyncAfter(deadline: delay) {
            onProgressChange(0)
            onClose()
        }
    }

    private func progress(from translation: CGSize, in size: CGSize) -> CGFloat {
        let vertical = abs(translation.height) / max(size.height, 1)
        let horizontal = abs(translation.width) / max(size.width, 1)
        return min(1, max(0, max(vertical, horizontal)))
    }

    private func offset(for translation: CGSize, fraction: CGFloat) -> CGSize {
        let dampedX = translation.width * 0.82
        let vertical = translation.height >= 0 ? translation.height : translation.height * 0.35
        let dampedY = vertical * (0.9 + (1 - fraction) * 0.1)
        return CGSize(width: dampedX, height: dampedY)
    }

    private func clamp(_ value: CGFloat) -> CGFloat {
        min(1, max(0, value))
    }
}

private struct ToolClosePill: View {
    let openFraction: CGFloat

    var body: some View {
        Capsule(style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color.white.opacity(0.18 * openFraction), lineWidth: 1)
            )
            .overlay(
                HStack(spacing: 12) {
                    Image(systemName: "chevron.compact.down")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                    Text("Close Tool")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
            )
            .shadow(color: Color.black.opacity(0.2 * openFraction), radius: 18, x: 0, y: 10)
            .scaleEffect(1 + (1 - openFraction) * 0.04)
            .offset(y: (1 - openFraction) * 52)
            .blur(radius: (1 - openFraction) * 6)
            .animation(.interactiveSpring(response: 0.6, dampingFraction: 0.85), value: openFraction)
    }
}

enum ToolMorphID {
    static func card(_ identifier: ToolItem.Identifier) -> String {
        "tool-morph-card-\(identifier.rawValue)"
    }
}

#Preview {
    struct PreviewContainer: View {
        @Namespace private var namespace
        @State private var progress: CGFloat = 1

        var body: some View {
            ToolMorphOverlay(
                tool: .audioExtractor,
                namespace: namespace,
                onProgressChange: { progress = $0 },
                onClose: {},
                content: {
                    AudioExtractorView()
                }
            )
        }
    }
    return PreviewContainer()
}
