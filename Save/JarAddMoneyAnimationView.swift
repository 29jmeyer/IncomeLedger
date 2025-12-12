import SwiftUI

private struct CoinSprite: Identifiable {
    let id = UUID()
    let startTime: Date
    let duration: Double
    let delay: Double
    let rotation: Angle
    let jitterX: CGFloat
    let scale: CGFloat
}

struct JarAddMoneyAnimationView: View {
    let goalName: String

    // New: external trigger to start animation
    @Binding var animationTrigger: Int

    // Jar art size
    private let jarSize = CGSize(width: 340, height: 408)

    // Extra space above the jar so coins can be visible before entering the jar
    private let topVisualPadding: CGFloat = 0.28 * 408
    private var containerSize: CGSize {
        CGSize(width: jarSize.width, height: jarSize.height + topVisualPadding)
    }
    private var topMargin: CGFloat { topVisualPadding }

    // Crossfade jarlid -> jar2 once
    @State private var showJar2 = false
    @State private var hasCrossfaded = false

    // Lid animation: 0 = off, 1 = closed/settled
    @State private var lidProgress: CGFloat = 1.0

    // Coins
    @State private var coins: [CoinSprite] = []

    // Button debounce (kept for potential future triggers)
    @State private var disableButton = false

    // MARK: - Tunables

    // Coin visuals
    private let baseCoinRadius: CGFloat = 22
    private let visualOverdraw: CGFloat = 1.0
    private let coinScaleVariance: ClosedRange<CGFloat> = 0.96...1.06

    // Burst configuration
    private let coinsPerBurst: Int = 8
    // Slower flight time
    private let coinDuration: ClosedRange<Double> = 1.3...1.8
    // More spacing between coins
    private let coinDelayStep: Double = 0.12
    private let pathJitterRangeX: ClosedRange<CGFloat> = -10...10
    private let coinRotationRange: ClosedRange<Double> = -12...12

    // Fade timings inside path (linger a bit longer)
    private let fadeInStart: Double = 0.06
    private let fadeInLen: Double = 0.22
    private let fadeOutStart: Double = 0.90
    private let fadeOutLen: Double = 0.30

    // Lid timings (open longer, close later, slightly softer spring)
    private let lidOpenAmount: CGFloat = 0.62
    private let lidOpenDuration: Double = 0.55
    private let lidCloseDelay: Double = 1.30
    private let lidCloseSpring: Double = 0.6

    // Seam handoff padding to avoid pop at the interior top edge
    private let seamPadding: CGFloat = 2.0

    // Jar interior bounds (in jar-local space)
    private let interiorLeftInset: CGFloat = 78
    private let interiorRightInset: CGFloat = 78
    private let interiorTopInset: CGFloat = 70
    private let interiorBottomInset: CGFloat = 76

    private var jarInteriorLocal: CGRect {
        CGRect(
            x: interiorLeftInset,
            y: interiorTopInset,
            width: jarSize.width - interiorLeftInset - interiorRightInset,
            height: jarSize.height - interiorTopInset - interiorBottomInset
        )
    }

    // Jar interior rect in container coordinate space
    private var jarInteriorInContainer: CGRect {
        jarInteriorLocal.offsetBy(dx: 0, dy: topMargin)
    }

    // Mask shape for interior clipping
    @ViewBuilder
    private var interiorMask: some View {
        let rect = jarInteriorInContainer
        Path { p in
            let r: CGFloat = 16
            p.addRoundedRect(in: rect, cornerSize: CGSize(width: r, height: r))
        }
        .fill(Color.black)
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {

                // 1) Coins above interior (unmasked)
                coinsAboveLayer
                    .frame(width: containerSize.width, height: containerSize.height)
                    .allowsHitTesting(false)

                // 2) Jar art crossfade (background)
                Group {
                    if showJar2 {
                        Image("jar2")
                            .resizable()
                            .scaledToFit()
                            .transition(.opacity)
                    } else {
                        Image("jarlid")
                            .resizable()
                            .scaledToFit()
                            .transition(.opacity)
                    }
                }
                .frame(width: jarSize.width, height: jarSize.height)
                .animation(.easeInOut(duration: 0.35), value: showJar2)

                // 3) Coins inside (masked)
                coinsInsideLayer
                    .frame(width: containerSize.width, height: containerSize.height)
                    .mask(interiorMask)
                    .allowsHitTesting(false)

                // 4) Lid overlay
                lidOverlay
                    .frame(width: jarSize.width, height: jarSize.height)
                    .allowsHitTesting(false)
                    .alignmentGuide(.bottom) { d in d[.bottom] }
            }
            .frame(width: containerSize.width, height: containerSize.height)
        }
        // Add extra bottom padding equal to safe area inset + a cushion
        .padding(.bottom, safeBottomPadding)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(goalName) jar")
        // Observe external trigger to run animation on demand
        .onChange(of: animationTrigger) { _ in
            runBurst()
        }
    }

    // Compute a safe bottom padding so the layout clears custom tab bars/home indicator
    private var safeBottomPadding: CGFloat {
        #if os(iOS) || os(tvOS) || os(visionOS)
        let keyWindow = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        let inset = keyWindow?.safeAreaInsets.bottom ?? 0
        return max(20, inset + 10)
        #else
        return 20
        #endif
    }

    // MARK: - Coins layers (with seam-safe handoff)

    private var coinsAboveLayer: some View {
        TimelineView(.animation) { context in
            let now = context.date
            let interiorTop = jarInteriorInContainer.minY
            ZStack {
                ForEach(activeCoins(at: now)) { coin in
                    if let pos = position(for: coin, at: now) {
                        // Draw in ABOVE layer only when the entire coin is clearly above interior
                        if pos.y + baseCoinRadius <= interiorTop - seamPadding {
                            coinView(sprite: coin, now: now, position: pos)
                        }
                    }
                }
            }
        }
    }

    private var coinsInsideLayer: some View {
        TimelineView(.animation) { context in
            let now = context.date
            let interiorTop = jarInteriorInContainer.minY
            ZStack {
                ForEach(activeCoins(at: now)) { coin in
                    if let pos = position(for: coin, at: now) {
                        // Draw in INSIDE layer only when the entire coin is clearly inside
                        if pos.y - baseCoinRadius >= interiorTop + seamPadding {
                            coinView(sprite: coin, now: now, position: pos)
                        }
                    }
                }
            }
        }
    }

    private func activeCoins(at time: Date) -> [CoinSprite] {
        coins.filter { coin in
            let t = progress(for: coin, at: time)
            return t < 1.0
        }
    }

    // MARK: - Path

    private func progress(for coin: CoinSprite, at now: Date) -> Double {
        let elapsed = now.timeIntervalSince(coin.startTime)
        let t = max(0, elapsed - coin.delay) / coin.duration
        return min(max(t, 0), 1)
    }

    private func position(for coin: CoinSprite, at now: Date) -> CGPoint? {
        let t = progress(for: coin, at: now)
        if t <= 0 || t >= 1 { return nil }

        // Interior rect
        let interior = jarInteriorInContainer

        // Chute-like curve: start above-left, pass jar mouth, head deeper inside
        let start = CGPoint(
            x: interior.minX + interior.width * 0.22 + coin.jitterX,
            y: interior.minY - baseCoinRadius - (jarSize.height * 0.36)
        )
        let mouth = CGPoint(
            x: interior.midX + coin.jitterX * 0.45,
            y: interior.minY - baseCoinRadius - 6
        )
        // Lower the settle point slightly more so coins travel longer
        let settle = CGPoint(
            x: interior.midX + coin.jitterX * 0.25,
            y: interior.minY + interior.height * 0.68
        )

        // Smoothstep ease
        let eased = t * t * (3 - 2 * t)

        // Two linear segments blended
        let p1 = lerp(start, mouth, eased < 0.5 ? eased * 2 : 1)
        let p2 = lerp(mouth, settle, eased > 0.5 ? (eased - 0.5) * 2 : 0)

        let w2 = min(max(eased * 2 - 1, 0), 1)
        let w1 = 1 - w2
        let x = p1.x * w1 + p2.x * w2
        let y = p1.y * w1 + p2.y * w2

        return CGPoint(x: x, y: y)
    }

    private func lerp(_ a: CGPoint, _ b: CGPoint, _ t: Double) -> CGPoint {
        CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
    }

    // MARK: - Coin view

    private func coinView(sprite: CoinSprite, now: Date, position: CGPoint) -> some View {
        let t = progress(for: sprite, at: now)

        // Fade in/out around the path progress
        let fadeIn = min(max((t - fadeInStart) / fadeInLen, 0), 1)
        let fadeOut = 1 - min(max((t - fadeOutStart) / fadeOutLen, 0), 1)
        let opacity = Double(max(0, min(1, fadeIn * fadeOut)))

        let diameter = baseCoinRadius * 2 + visualOverdraw

        return Image("Coin")
            .resizable()
            .scaledToFill()
            .frame(width: diameter * sprite.scale, height: diameter * sprite.scale)
            .clipShape(Circle())
            .contentShape(Circle())
            .position(position)
            .opacity(opacity)
            .rotationEffect(sprite.rotation)
            .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)
            .transition(.opacity)
    }

    // MARK: - Lid overlay

    private var lidOverlay: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            let startOffset = CGSize(width: -w * 0.15, height: -h * 0.35)
            let endOffset = CGSize(width: 0, height: -h * 0.17)
            let rotStart: Angle = .degrees(-18)
            let rotEnd: Angle = .degrees(0)

            let t = min(max(lidProgress, 0), 1)
            let curX = startOffset.width + (endOffset.width - startOffset.width) * t
            let curY = startOffset.height + (endOffset.height - startOffset.height) * t
            let curRot = Angle.degrees(rotStart.degrees + (rotEnd.degrees - rotStart.degrees) * t)

            Image("lid")
                .resizable()
                .scaledToFit()
                .frame(width: w * 0.62)
                .rotationEffect(curRot, anchor: .center)
                .offset(x: curX, y: curY)
                .opacity(showJar2 ? 1 : 0)
                .animation(.spring(response: 0.48, dampingFraction: 0.85), value: lidProgress)
        }
    }

    // MARK: - Actions (triggered when animationTrigger changes)

    private func runBurst() {
        guard !disableButton else { return }

        // Crossfade base jar once (only now, at confirm time)
        if !hasCrossfaded {
            hasCrossfaded = true
            withAnimation(.easeInOut(duration: 0.35)) {
                showJar2 = true
            }
        }

        // Lid micro-open
        withAnimation(.easeInOut(duration: lidOpenDuration)) {
            lidProgress = lidOpenAmount
        }

        // Spawn coins
        spawnBurst()

        // Close lid after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + lidCloseDelay) {
            closeLid()
        }

        // Debounce guard
        disableButton = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            disableButton = false
        }
    }

    private func spawnBurst() {
        let now = Date()
        var newCoins: [CoinSprite] = []

        for i in 0..<coinsPerBurst {
            let dur = Double.random(in: coinDuration)
            let delay = Double(i) * coinDelayStep
            let jitter = CGFloat.random(in: pathJitterRangeX)
            let rot = Angle.degrees(Double.random(in: coinRotationRange))
            let scale = CGFloat.random(in: coinScaleVariance)

            newCoins.append(
                CoinSprite(
                    startTime: now,
                    duration: dur,
                    delay: delay,
                    rotation: rot,
                    jitterX: jitter,
                    scale: scale
                )
            )
        }

        coins.append(contentsOf: newCoins)

        // Cleanup after the longest coin finishes
        let maxLifespan = (newCoins.map { $0.duration + $0.delay }.max() ?? 1.2) + 0.3
        DispatchQueue.main.asyncAfter(deadline: .now() + maxLifespan) {
            let cutoff = Date().addingTimeInterval(-0.1)
            coins.removeAll { coin in
                let t = progress(for: coin, at: Date())
                return coin.startTime < cutoff && t >= 1.0
            }
        }
    }

    private func closeLid() {
        guard showJar2 else { return }
        withAnimation(.spring(response: lidCloseSpring, dampingFraction: 0.85)) {
            lidProgress = 1.0
        }
    }
}

struct JarAddMoneyAnimationView_Previews: PreviewProvider {
    static var previews: some View {
        // Provide a constant trigger for preview
        JarAddMoneyAnimationView(goalName: "Holiday", animationTrigger: .constant(0))
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
