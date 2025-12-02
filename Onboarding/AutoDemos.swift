//  AutoDemos.swift
//  APP

import SwiftUI

// MARK: - Auto Demo (Slide 1)

struct EarningsAutoDemo: View {
    let hourlyRate: Double
    let targetHours: Double
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    @State private var animatedHours: Double = 0
    @State private var isAnimating: Bool = false
    
    private let animationDuration: Double = 3.5
    private let holdDuration: Double = 1.5
    private let downDuration: Double = 1.0
    private let betweenLoopsPause: Double = 0.6
    
    private var total: Double { animatedHours * hourlyRate }
    
    private var hoursText: String {
        let rounded = (animatedHours * 2).rounded() / 2
        return "\(rounded.formatted(.number.precision(.fractionLength(0...1))))h"
    }
    
    private var rateText: String {
        hourlyRate.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD")) + "/hr"
    }
    
    private var totalText: String {
        total.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
    }
    
    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "dollarsign.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white)
                    .font(.system(size: 22, weight: .semibold))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Estimated Earnings")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.9))
                    Text(totalText)
                        .font(.title2.monospacedDigit().weight(.bold))
                        .foregroundStyle(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(rateText)
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.85))
                    Text(hoursText)
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.white.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(.white.opacity(0.15), lineWidth: 1)
                    )
            )
            
            ProgressView(value: min(animatedHours / max(targetHours, 0.01), 1.0))
                .tint(.white)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 6)
        }
        .onAppear { startLoopIfNeeded() }
        .onDisappear { isAnimating = false }
        .animation(.easeInOut(duration: 0.15), value: total)
    }
    
    private func startLoopIfNeeded() {
        guard !reduceMotion else {
            // Jump to the end state if user prefers less motion
            animatedHours = targetHours
            return
        }
        startLoop()
    }
    
    private func startLoop() {
        guard !isAnimating else { return }
        isAnimating = true
        animateUp()
    }
    
    private func animateUp() {
        guard isAnimating else { return }
        animatedHours = 0
        withAnimation(.easeInOut(duration: animationDuration)) {
            animatedHours = targetHours
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration + holdDuration) {
            animateDown()
        }
    }
    
    private func animateDown() {
        guard isAnimating else { return }
        withAnimation(.easeInOut(duration: downDuration)) {
            animatedHours = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + downDuration + betweenLoopsPause) {
            animateUp()
        }
    }
}

// MARK: - Auto Demo (Slide 2)

struct ShiftListAutoDemo: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    @State private var showLine1 = false
    @State private var showLine2 = false
    @State private var isAnimating = false
    
    private let line2Delay: Double = 1.0
    private let holdDuration: Double = 1.5
    private let fadeDuration: Double = 0.5
    private let betweenLoopsPause: Double = 0.6
    private let currencyCode = Locale.current.currency?.identifier ?? "USD"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            shiftRow(start: "8:00 AM", end: "4:00 PM", hours: 8.0, amount: 216)
                .opacity(showLine1 ? 1 : 0)
                .animation(.easeInOut(duration: fadeDuration), value: showLine1)
            
            shiftRow(start: "5:00 PM", end: "9:00 PM", hours: 4.0, amount: 108)
                .opacity(showLine2 ? 1 : 0)
                .animation(.easeInOut(duration: fadeDuration), value: showLine2)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(0.15), lineWidth: 1)
                )
        )
        .onAppear { startLoopIfNeeded() }
        .onDisappear { isAnimating = false }
    }
    
    @ViewBuilder
    private func shiftRow(start: String, end: String, hours: Double, amount: Double) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "clock")
                .foregroundStyle(.white.opacity(0.9))
                .font(.system(size: 16, weight: .semibold))
            
            Text("\(start) – \(end)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            
            Spacer(minLength: 8)
            
            Text("\(hours.formatted(.number.precision(.fractionLength(1))))h")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.white.opacity(0.95))
            
            Text(amount.formatted(.currency(code: currencyCode)))
                .font(.subheadline.monospacedDigit().weight(.semibold))
                .foregroundStyle(.white)
        }
    }
    
    private func startLoopIfNeeded() {
        guard !reduceMotion else {
            showLine1 = true
            showLine2 = true
            return
        }
        startLoop()
    }
    
    private func startLoop() {
        guard !isAnimating else { return }
        isAnimating = true
        animateSequence()
    }
    
    private func animateSequence() {
        guard isAnimating else { return }
        showLine1 = false
        showLine2 = false
        
        withAnimation(.easeInOut(duration: fadeDuration)) {
            showLine1 = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + line2Delay) {
            withAnimation(.easeInOut(duration: fadeDuration)) {
                showLine2 = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + line2Delay + holdDuration) {
            withAnimation(.easeInOut(duration: fadeDuration)) {
                showLine1 = false
                showLine2 = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + fadeDuration + betweenLoopsPause) {
                animateSequence()
            }
        }
    }
}

// MARK: - Auto Demo (Slide 3)

struct PaycheckAutoDemo: View {
    let totalTarget: Double       // e.g., 1742.00
    let startDays: Int            // e.g., 5
    let dateLabel: String         // e.g., "Nov 28" (final payday date)
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    private let increment: Double = 5.0
    private let tickInterval: Double = 0.01
    
    @State private var currentTotal: Double = 0
    @State private var remainingDays: Int
    @State private var hasFinished: Bool = false
    @State private var tickCount: Int = 0
    @State private var totalTicksNeeded: Int = 0
    
    // Derived: final payday date parsed from dateLabel
    private let finalPaydayDate: Date?
    
    // Formatter for "MMM d"
    private static let displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = .current
        f.setLocalizedDateFormatFromTemplate("MMM d")
        return f
    }()
    
    init(totalTarget: Double, startDays: Int, dateLabel: String) {
        self.totalTarget = totalTarget
        self.startDays = max(1, startDays)
        self.dateLabel = dateLabel
        _remainingDays = State(initialValue: max(1, startDays))
        
        // Parse "MMM d" using current year
        let year = Calendar.current.component(.year, from: Date())
        let parseFormatter = DateFormatter()
        parseFormatter.locale = .current
        parseFormatter.setLocalizedDateFormatFromTemplate("MMM d")
        
        if let parsed = parseFormatter.date(from: dateLabel) {
            var comps = Calendar.current.dateComponents([.month, .day], from: parsed)
            comps.year = year
            self.finalPaydayDate = Calendar.current.date(from: comps)
        } else {
            self.finalPaydayDate = nil
        }
    }
    
    private var currencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }
    
    private var progress: Double {
        guard totalTarget > 0 else { return 0 }
        return min(max(currentTotal / totalTarget, 0), 1)
    }
    
    // Compute the date to show based on remainingDays
    private var displayedDateString: String {
        guard let final = finalPaydayDate else { return dateLabel }
        if hasFinished { return Self.displayFormatter.string(from: final) }
        if let shown = Calendar.current.date(byAdding: .day, value: -remainingDays, to: final) {
            return Self.displayFormatter.string(from: shown)
        }
        return dateLabel
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Advancing date on the left
                Label(displayedDateString, systemImage: "calendar")
                    .labelStyle(.titleAndIcon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.95))
                
                Spacer()
                
                // Payday badge on the right (counts down)
                Text(paydayText)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(.white.opacity(0.16))
                            .overlay(
                                Capsule(style: .continuous)
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                    )
            }
            
            // Big total (rises in $5 increments)
            ZStack {
                Text(currentTotal.formatted(.currency(code: currencyCode)))
                    .font(
                        .system(
                            size: 36,
                            weight: .bold,
                            design: .default
                        ).monospacedDigit()
                    )
                    .foregroundStyle(.white)
                    .animation(.easeInOut(duration: 0.12), value: currentTotal)
            }
            .transaction { t in t.disablesAnimations = true }
            .transition(.identity)
            
            // Subtle progress bar aligned with the rise
            ProgressView(value: progress)
                .tint(.white)
                .frame(maxWidth: .infinity)
                .padding(.trailing, 2)
                .padding(.top, 2)
            
            Text("Pay period total")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(0.15), lineWidth: 1)
                )
        )
        .onAppear { startOrJump() }
    }
    
    private var paydayText: String {
        if hasFinished { return "Payday" }
        return remainingDays == 1 ? "Payday in 1 day" : "Payday in \(remainingDays) days"
    }
    
    private func startOrJump() {
        if reduceMotion {
            currentTotal = totalTarget
            remainingDays = 0
            hasFinished = true
        } else {
            startTicking()
        }
    }
    
    private func startTicking() {
        let exactTicks = totalTarget / increment
        totalTicksNeeded = Int(ceil(exactTicks))
        tickCount = 0
        remainingDays = max(1, startDays)
        hasFinished = false
        currentTotal = 0
        tick()
    }
    
    private func tick() {
        guard tickCount < totalTicksNeeded else {
            currentTotal = totalTarget
            remainingDays = 0
            hasFinished = true
            return
        }
        tickCount += 1
        currentTotal = min(totalTarget, currentTotal + increment)
        
        // Countdown logic: split ticks into (startDays) segments to reduce by 1 day each segment.
        let segments = max(1, startDays)
        let ticksPerDay = max(1, totalTicksNeeded / segments)
        if tickCount % ticksPerDay == 0, remainingDays > 1 {
            remainingDays -= 1
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + tickInterval) {
            tick()
        }
    }
}

// MARK: - Auto Demo (Slide 4)

struct OvertimeSplitDemo: View {
    let hourlyRate: Double
    let thresholdHours: Double
    let otMultiplier: Double
    let weeklyHoursAtStart: Double
    let shiftLength: Double
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    @State private var fillProgress: CGFloat = 0 // 0...1 across the shift timeline
    @State private var isAnimating = false
    @State private var crossed = false
    @State private var showBadges = false
    @State private var pulse = false
    
    private let upDuration: Double = 2.8
    private let holdDuration: Double = 1.1
    private let downDuration: Double = 0.8
    private let pauseDuration: Double = 0.6
    
    private var otRate: Double { hourlyRate * otMultiplier }
    
    // How many hours into the shift does the threshold get crossed?
    private var hoursUntilThresholdFromStart: Double {
        max(0, thresholdHours - weeklyHoursAtStart)
    }
    
    private var crossesThreshold: Bool {
        weeklyHoursAtStart < thresholdHours && weeklyHoursAtStart + shiftLength > thresholdHours
    }
    
    // Split of this shift between regular and OT
    private var regularHoursInShift: Double {
        guard crossesThreshold else { return min(shiftLength, max(0, thresholdHours - weeklyHoursAtStart)) }
        return max(0, hoursUntilThresholdFromStart)
    }
    
    private var otHoursInShift: Double {
        guard crossesThreshold else { return max(0, shiftLength - regularHoursInShift) }
       return max(0, shiftLength - hoursUntilThresholdFromStart)
    }
    
    private var regularBadgeText: String {
        let hrs = regularHoursInShift.formatted(.number.precision(.fractionLength(1)))
        return "\(hrs)h Regular @ " + hourlyRate.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
    }
    
    private var otBadgeText: String {
        let hrs = otHoursInShift.formatted(.number.precision(.fractionLength(1)))
        return "\(hrs)h OT @ " + otRate.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.triangle.switch")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white)
                    .font(.system(size: 20, weight: .semibold))
                Text("Rate switches mid-shift")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
                Spacer()
            }
            
            // Shift timeline with threshold gate
            GeometryReader { geo in
                let width = geo.size.width
                let height: CGFloat = 12
                
                let gateX = width * CGFloat(
                    min(
                        max(hoursUntilThresholdFromStart / max(shiftLength, 0.001), 0),
                        1
                    )
                )
                let currentWidth = min(width, max(0, width * fillProgress))
                let regularWidth = min(currentWidth, gateX)
                let otWidth = max(0, currentWidth - gateX)
                
                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(.white.opacity(0.12))
                        .frame(height: height)
                    
                    // Regular portion
                    if regularWidth > 0 {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(.white.opacity(0.95))
                            .frame(width: regularWidth, height: height)
                    }
                    
                    // OT portion
                    if crossesThreshold && otWidth > 0 {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.yellow.opacity(0.95))
                            .frame(width: otWidth, height: height)
                            .offset(x: gateX)
                            .shadow(
                                color: pulse ? Color.yellow.opacity(0.45) : .clear,
                                radius: pulse ? 8 : 0
                            )
                            .scaleEffect(pulse ? 1.01 : 1.0, anchor: .leading)
                            .animation(.easeInOut(duration: 0.45), value: pulse)
                    }
                    
                    // Threshold gate line
                    if crossesThreshold {
                        Rectangle()
                            .fill(Color.yellow.opacity(0.9))
                            .frame(width: 2, height: height + 10)
                            .overlay(
                                Rectangle()
                                    .stroke(.white.opacity(0.6), lineWidth: 0.5)
                            )
                            .shadow(
                                color: Color.yellow.opacity(crossed ? 0.4 : 0.0),
                                radius: crossed ? 8 : 0
                            )
                            .scaleEffect(crossed ? 1.06 : 1.0, anchor: .center)
                            .animation(
                                .spring(response: 0.35, dampingFraction: 0.75),
                                value: crossed
                            )
                            .offset(x: gateX - 1)
                    }
                }
            }
            .frame(height: 20)
            
            // Badges
            if crossesThreshold {
                HStack(spacing: 8) {
                    Text(regularBadgeText)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule(style: .continuous)
                                .fill(.white)
                                .opacity(0.95)
                        )
                        .offset(y: showBadges ? 0 : 8)
                        .opacity(showBadges ? 1 : 0)
                        .animation(.easeOut(duration: 0.25).delay(0.05), value: showBadges)
                    
                    Text(otBadgeText)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color.yellow.opacity(0.95))
                        )
                        .offset(y: showBadges ? 0 : 10)
                        .opacity(showBadges ? 1 : 0)
                        .animation(
                            .spring(response: 0.35, dampingFraction: 0.8).delay(0.12),
                            value: showBadges
                        )
                }
            } else {
                Text(regularBadgeText)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(.white)
                            .opacity(0.95)
                    )
            }
            
            // Thin weekly context meter
            HStack(spacing: 6) {
                Text("Weekly hours")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.85))
                Spacer()
                let endWeekly = weeklyHoursAtStart + Double(fillProgress) * shiftLength
                Text("\(endWeekly.formatted(.number.precision(.fractionLength(1))))h")
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.85))
            }
            
            GeometryReader { geo in
                let width = geo.size.width
                let height: CGFloat = 6
                let weeklySpan = thresholdHours + shiftLength
                let thresholdX = width * CGFloat(
                    min(
                        max(thresholdHours / max(weeklySpan, 0.001), 0),
                        1
                    )
                )
                
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(.white.opacity(0.12))
                        .frame(height: height)
                    
                    let startX = width * CGFloat(weeklyHoursAtStart / max(weeklySpan, 0.001))
                    let currentX = width * CGFloat(
                        min(
                            (weeklyHoursAtStart + Double(fillProgress) * shiftLength) / max(weeklySpan, 0.001),
                            1
                        )
                    )
                    
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(.white.opacity(0.9))
                        .frame(width: max(0, currentX - startX), height: height)
                        .offset(x: startX)
                    
                    Rectangle()
                        .fill(.white.opacity(0.6))
                        .frame(width: 1, height: height + 6)
                        .offset(x: thresholdX)
                }
            }
            .frame(height: 14)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(0.15), lineWidth: 1)
                )
        )
        .onAppear { startLoopIfNeeded() }
        .onDisappear { isAnimating = false }
    }
    
    private func startLoopIfNeeded() {
        guard !reduceMotion else {
            // Static “finished” state if user prefers less motion
            fillProgress = 1
            crossed = crossesThreshold
            showBadges = crossesThreshold
            pulse = false
            return
        }
        startLoop()
    }
    
    private func startLoop() {
        guard !isAnimating else { return }
        isAnimating = true
        animateUp()
    }
    
    private func animateUp() {
        // Reset
        fillProgress = 0
        crossed = false
        showBadges = false
        pulse = false
        
        withAnimation(.linear(duration: upDuration)) {
            fillProgress = 1.0
        }
        
        if crossesThreshold {
            let gateProgress = hoursUntilThresholdFromStart / max(shiftLength, 0.001)
            let timeToGate = upDuration * gateProgress
            
            DispatchQueue.main.asyncAfter(deadline: .now() + timeToGate) {
                guard isAnimating else { return }
                crossed = true
                pulse = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    pulse = false
                    showBadges = true
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + upDuration + holdDuration) {
            animateDown()
        }
    }
    
    private func animateDown() {
        withAnimation(.easeInOut(duration: downDuration)) {
            fillProgress = 0
            crossed = false
            showBadges = false
            pulse = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + downDuration + pauseDuration) {
            if isAnimating { animateUp() }
        }
    }
}

