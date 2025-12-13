import SwiftUI

// A reusable draggable canvas that enforces an invisible "bubble" area
// and stores positions normalized to that bubble (0...1). This makes
// positions stable across layout/safe-area changes and page transitions.
//
// Public API (unchanged usage, except positions are now normalized):
// - ids: item identifiers
// - positions: Binding<[UUID: CGPoint]> where x,y are 0...1 within the bubble
// - itemSize, bubbleInsets, dragEnabled, tapMovementThreshold, bubbleCornerRadius
// - content: view for each item
//
// Internally:
// - Converts normalized -> absolute using current bubble rect to render
// - Converts absolute -> normalized on drag end and writes back to binding
// - Seeds missing entries to bubble center (0.5, 0.5)
// - Clamps normalized to 0...1; absolute clamped by construction
struct DraggableCanvas<Content: View>: View {
    let ids: [UUID]
    @Binding var positions: [UUID: CGPoint]   // normalized (0...1 in bubble)

    let itemSize: CGSize
    let bubbleInsets: UIEdgeInsets
    let dragEnabled: Bool
    let tapMovementThreshold: CGFloat
    let bubbleCornerRadius: CGFloat

    @ViewBuilder var content: (UUID) -> Content

    @State private var canvasSize: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let bubble = allowedBubbleRect(in: size)

            ZStack {
                // Items (convert normalized -> absolute for display/interaction)
                ForEach(ids, id: \.self) { id in
                    let absCenter = absoluteCenter(for: id, in: bubble)
                    DraggableJarWrapper(
                        id: id,
                        positions: Binding<[UUID: CGPoint]>(
                            get: { absolutePositions(in: bubble) },
                            set: { newAbs in
                                // Only one id changes at a time, but we accept the full map.
                                // Convert changed absolute center(s) back to normalized and write to binding.
                                var newNormalized = positions
                                for (k, vAbs) in newAbs {
                                    let n = normalize(vAbs, in: bubble)
                                    newNormalized[k] = n
                                }
                                positions = newNormalized
                            }
                        ),
                        containerSize: size,
                        itemSize: itemSize,
                        barrierRects: [],
                        minSpacing: 0,
                        otherItemFrames: [],
                        tapMovementThreshold: tapMovementThreshold,
                        dragEnabled: dragEnabled
                    ) {
                        content(id)
                            .frame(width: itemSize.width, height: itemSize.height)
                    }
                    // Ensure when the absolute position for this id changes (due to normalized change),
                    // it stays within the bubble after conversion (normalize clamps anyway).
                    .onChange(of: positions[id]) { _ in
                        // No-op: clamping is handled by normalize()/denormalize() and the display conversion.
                    }
                }
            }
            .onAppear {
                canvasSize = size
                seedIfNeeded()
                clampAllNormalized()
            }
            .onChange(of: size) { newSize in
                canvasSize = newSize
                // No rescale needed; normalized stays valid. Just clamp to be safe.
                clampAllNormalized()
            }
        }
    }

    // MARK: - Bubble geometry

    private func allowedBubbleRect(in size: CGSize) -> CGRect {
        let x = bubbleInsets.left
        let y = bubbleInsets.top
        let w = max(0, size.width - bubbleInsets.left - bubbleInsets.right)
        let h = max(0, size.height - bubbleInsets.top - bubbleInsets.bottom)
        return CGRect(x: x, y: y, width: w, height: h)
    }

    // MARK: - Normalized <-> Absolute

    private func denormalize(_ n: CGPoint, in bubble: CGRect) -> CGPoint {
        let nx = min(max(n.x, 0), 1)
        let ny = min(max(n.y, 0), 1)
        let x = bubble.minX + nx * bubble.width
        let y = bubble.minY + ny * bubble.height
        // Clamp to keep the item center within bubble edges considering item size
        return clampPoint(CGPoint(x: x, y: y), to: bubble, itemSize: itemSize)
    }

    private func normalize(_ p: CGPoint, in bubble: CGRect) -> CGPoint {
        // First clamp absolute to bubble considering item size
        let clamped = clampPoint(p, to: bubble, itemSize: itemSize)
        let nx = bubble.width > 0 ? (clamped.x - bubble.minX) / bubble.width : 0.5
        let ny = bubble.height > 0 ? (clamped.y - bubble.minY) / bubble.height : 0.5
        // Clamp normalized to 0...1
        return CGPoint(x: min(max(nx, 0), 1), y: min(max(ny, 0), 1))
    }

    // Build absolute positions map for wrappers
    private func absolutePositions(in bubble: CGRect) -> [UUID: CGPoint] {
        var out: [UUID: CGPoint] = [:]
        for id in ids {
            out[id] = absoluteCenter(for: id, in: bubble)
        }
        return out
    }

    private func absoluteCenter(for id: UUID, in bubble: CGRect) -> CGPoint {
        if let n = positions[id] {
            return denormalize(n, in: bubble)
        } else {
            // Seed to center if missing
            return denormalize(CGPoint(x: 0.5, y: 0.5), in: bubble)
        }
    }

    // MARK: - Position management

    private func seedIfNeeded() {
        var changed = false
        for id in ids where positions[id] == nil {
            positions[id] = CGPoint(x: 0.5, y: 0.5)
            changed = true
        }
        if changed {
            clampAllNormalized()
        }
    }

    private func clampAllNormalized() {
        var new = positions
        for id in ids {
            if let n = positions[id] {
                // Clamp normalized to 0...1 (already ensured in normalize/denormalize pipeline)
                let nx = min(max(n.x, 0), 1)
                let ny = min(max(n.y, 0), 1)
                new[id] = CGPoint(x: nx, y: ny)
            }
        }
        positions = new
    }

    private func clampPoint(_ p: CGPoint, to bubble: CGRect, itemSize: CGSize) -> CGPoint {
        let halfW = itemSize.width / 2
        let halfH = itemSize.height / 2

        let minX = bubble.minX + halfW
        let maxX = bubble.maxX - halfW
        let minY = bubble.minY + halfH
        let maxY = bubble.maxY - halfH

        let x = min(max(p.x, minX), maxX)
        let y = min(max(p.y, minY), maxY)
        return CGPoint(x: x, y: y)
    }
}

