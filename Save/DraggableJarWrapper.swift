import SwiftUI

struct DraggableJarWrapper<Content: SwiftUI.View>: SwiftUI.View {
    let id: UUID
    @Binding var positions: [UUID: CGPoint]

    let containerSize: CGSize
    let itemSize: CGSize

    let barrierRects: [CGRect]
    let minSpacing: CGFloat
    let otherItemFrames: [CGRect]

    let tapMovementThreshold: CGFloat
    let dragEnabled: Bool

    @ViewBuilder var content: () -> Content

    @State private var startCenter: CGPoint? = nil
    @State private var dragOffset: CGSize = .zero
    @State private var totalDragDistance: CGFloat = 0
    @State private var justDragged: Bool = false

    private var currentCenter: CGPoint {
        positions[id] ?? CGPoint(x: containerSize.width / 2, y: containerSize.height / 2)
    }

    var body: some SwiftUI.View {
        content()
            .frame(width: itemSize.width, height: itemSize.height)
            .position({
                if let s = startCenter {
                    return CGPoint(x: s.x + dragOffset.width, y: s.y + dragOffset.height)
                } else {
                    return currentCenter
                }
            }())
            .allowsHitTesting(!justDragged)
            .modifier(DragWhenEnabledModifier(
                enabled: dragEnabled,
                currentCenter: currentCenter,
                tapMovementThreshold: tapMovementThreshold,
                onBegin: { start in
                    startCenter = start
                    dragOffset = .zero
                    totalDragDistance = 0
                },
                onChange: { translation in
                    dragOffset = CGSize(width: translation.width, height: translation.height)
                    totalDragDistance = max(totalDragDistance, hypot(translation.width, translation.height))
                },
                onEnd: {
                    guard let start = startCenter else { return }
                    let proposed = CGPoint(x: start.x + dragOffset.width, y: start.y + dragOffset.height)

                    if totalDragDistance < tapMovementThreshold {
                        startCenter = nil
                        dragOffset = .zero
                        totalDragDistance = 0
                        return
                    }

                    justDragged = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        justDragged = false
                    }

                    positions[id] = proposed

                    startCenter = nil
                    dragOffset = .zero
                    totalDragDistance = 0
                }
            ))
            .onChange(of: positions) { _ in
                startCenter = nil
                dragOffset = .zero
                totalDragDistance = 0
            }
            .onChange(of: containerSize) { _ in
                startCenter = nil
                dragOffset = .zero
                totalDragDistance = 0
            }
    }
}

private struct DragWhenEnabledModifier: SwiftUI.ViewModifier {
    let enabled: Bool
    let currentCenter: CGPoint
    let tapMovementThreshold: CGFloat
    let onBegin: (CGPoint) -> Void
    let onChange: (CGSize) -> Void
    let onEnd: () -> Void

    @GestureState private var isActiveDrag: Bool = false

    func body(content: Content) -> some SwiftUI.View {
        if enabled {
            content.highPriorityGesture(
                DragGesture(minimumDistance: 0)
                    .updating($isActiveDrag) { _, state, _ in
                        state = true
                    }
                    .onChanged { value in
                        if value.startLocation == value.location {
                            onBegin(currentCenter)
                        }
                        onChange(value.translation)
                    }
                    .onEnded { _ in
                        onEnd()
                    }
            )
        } else {
            content
        }
    }
}
