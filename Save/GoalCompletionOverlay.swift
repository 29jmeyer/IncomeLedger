import SwiftUI

struct GoalCompletionOverlay: View {
    // Public API expected by SaveView overlay usage
    var message: String = ""
    let duration: Double
    var onDismiss: (() -> Void)? = nil

    // Internal particle model (file‑private to this file)
    struct Particle: Identifiable {
        let id = UUID()
        let startX: CGFloat    // 0...1
        let endX: CGFloat      // 0...1
        let startY: CGFloat    // 0...1 (typically 0 at top)
        let endY: CGFloat      // 0...1 (typically 1 at bottom)
        let size: CGFloat
        let color: Color
        let delay: Double
        let lifetime: Double
        let rotationSpeed: Double
    }

    @State private var particles: [Particle] = []
    @State private var isRunning = false
    @State private var startRef: TimeInterval = 0

    var body: some View {
        ZStack {
            // Optional message label (kept invisible by default; caller can pass a string)
            if !message.isEmpty {
                Text(message)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.black.opacity(0.6))
                    )
                    .padding(.top, 40)
                    .transition(.opacity)
                    .zIndex(1)
            }

            TimelineView(.animation) { context in
                let now = context.date.timeIntervalSinceReferenceDate
                GeometryReader { geo in
                    let w = geo.size.width
                    let h = geo.size.height

                    Canvas { ctx, _ in
                        for p in particles {
                            let t = progress(now: now, delay: p.delay, lifetime: p.lifetime)
                            guard t > 0, t < 1 else { continue }

                            // Interpolate position
                            let dx = p.endX - p.startX
                            let dy = p.endY - p.startY
                            let xNorm = p.startX + dx * t
                            let yNorm = p.startY + dy * t
                            let x = xNorm * w
                            let y = yNorm * h
                            let pos = CGPoint(x: x, y: y)

                            // Rotation (turns per lifetime -> radians)
                            let angleTurns = p.rotationSpeed * t
                            let angleRadians = CGFloat(angleTurns * 2 * .pi)

                            // Base rect and rounded path
                            let rectWidth = p.size
                            let rectHeight = p.size * 1.4
                            let rect = CGRect(x: pos.x, y: pos.y, width: rectWidth, height: rectHeight)
                            let corner = CGSize(width: rectWidth * 0.2, height: rectWidth * 0.2)
                            var path = Path(roundedRect: rect, cornerSize: corner, style: .circular)

                            // Rotate around the rect center
                            let cx = pos.x + rectWidth / 2
                            let cy = pos.y + rectHeight / 2

                            let toCenter = CGAffineTransform(translationX: cx, y: cy)
                            let rotate = CGAffineTransform(rotationAngle: angleRadians)
                            let fromCenter = CGAffineTransform(translationX: -cx, y: -cy)

                            let transform = toCenter.concatenating(rotate).concatenating(fromCenter)
                            path = path.applying(transform)

                            let opac = opacity(for: t)
                            let fillColor = p.color.opacity(opac)
                            ctx.fill(path, with: .color(fillColor))
                        }
                    }
                }
            }
        }
        .allowsHitTesting(false) // don’t block taps
        .onAppear {
            startRef = Date().timeIntervalSinceReferenceDate
            spawnConfetti()
            isRunning = true

            // Auto-stop after duration
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                isRunning = false
                particles.removeAll()
                onDismiss?()
            }
        }
    }

    private func spawnConfetti() {
        let colors: [Color] = [.green, .yellow, .orange, .pink, .blue, .purple, .mint, .teal, .red, .cyan]
        var out: [Particle] = []
        let count = 120
        for i in 0..<count {
            let startX = CGFloat.random(in: 0.0...1.0)
            let rawEndX = startX + CGFloat.random(in: -0.25...0.25)
            let endX = min(max(rawEndX, 0.0), 1.0)
            let size = CGFloat.random(in: 6...12)
            let color = colors[i % colors.count]
            let delay = Double.random(in: 0.0...0.6)
            let lifetime = Double.random(in: 1.0...1.8)
            let rotSpeed = Double.random(in: 0.5...2.0)
            let p = Particle(
                startX: startX,
                endX: endX,
                startY: -0.1,   // slightly above top
                endY: 1.1,      // slightly below bottom
                size: size,
                color: color,
                delay: delay,
                lifetime: lifetime,
                rotationSpeed: rotSpeed
            )
            out.append(p)
        }
        particles = out
    }

    private func progress(now: TimeInterval, delay: Double, lifetime: Double) -> Double {
        // t = (elapsed - delay) / lifetime, clamped
        let elapsed = now - startRef
        let raw = (elapsed - delay) / lifetime
        return raw
    }

    private func opacity(for t: Double) -> Double {
        if t < 0.1 {
            return max(0, t / 0.1)
        }
        if t > 0.9 {
            return max(0, (1 - t) / 0.1)
        }
        return 1
    }
}
