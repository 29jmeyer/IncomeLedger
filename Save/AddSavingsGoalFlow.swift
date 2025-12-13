import SwiftUI

struct AddSavingsGoalFlow: View {
    @Environment(\.dismiss) private var dismiss

    // We’re editing the real goals in SaveView via Binding
    @Binding var goals: [SavingsGoal]

    // Wizard steps: 0 = name, 1 = target, 2 = currently saved, 3 = summary
    @State private var step: Int = 0
    @State private var name: String = ""
    @State private var targetAmountText: String = ""
    @State private var currentSavedText: String = ""

    // Focus
    @FocusState private var isTargetFocused: Bool
    @FocusState private var isCurrentFocused: Bool
    @FocusState private var isCustomAmountFocused: Bool

    // Step 3 state (summary / optional schedule)
    @State private var useSchedule: Bool = false        // toggle yes/no
    @State private var intervalDays: Int = 7            // day interval
    @State private var startDate: Date = Date()         // first contribution date
    @State private var selectedPaymentIndex: Int = 2    // Payment Plan Sticker

    // New state for the new payment plan UI
    @State private var scheduleAmount: Double = 0
    @State private var selectedScheduleIndex: Int? = nil
    @State private var customAmountText: String = ""

    // Limits
    private let maxTargetAmount: Double = 10_000_000
    private let maxJars = 3
    @State private var showMaxReachedAlert = false

    // Today start (used to restrict DatePicker to today and later)
    private var todayStart: Date {
        Calendar.current.startOfDay(for: Date())
    }

    // MARK: - Amount helpers

    private var targetAmount: Double {
        Double(targetAmountText.filter { "0123456789.".contains($0) }) ?? 0
    }

    private var currentSaved: Double {
        Double(currentSavedText.filter { "0123456789.".contains($0) }) ?? 0
    }

    private var amountLeft: Double {
        max(targetAmount - currentSaved, 0)
    }

    private var formattedTargetAmount: String {
        targetAmount.formatted(
            .currency(code: Locale.current.currency?.identifier ?? "USD")
        )
    }

    private var formattedAmountLeft: String {
        amountLeft.formatted(
            .currency(code: Locale.current.currency?.identifier ?? "USD")
        )
    }

    private var displayName: String {
        name.isEmpty ? "Goal" : name
    }

    // Legacy bars (unused by new UI but kept to avoid touching unrelated code)
    private var paymentOptions: [Double] {
        let left = max(amountLeft, 1)
        let steps = 7
        let base = left / Double(steps)
        return (1...steps).map { Double($0) * base }
    }
    
    private var selectedPaymentAmount: Double {
        guard paymentOptions.indices.contains(selectedPaymentIndex) else {
            return paymentOptions.first ?? max(amountLeft, 1)
        }
        return paymentOptions[selectedPaymentIndex]
    }
    
    private var estimatedDurationText: String {
        let left = max(amountLeft, 0)
        guard left > 0, selectedPaymentAmount > 0 else {
            return "You’ve already reached this goal."
        }
        
        let paymentsNeeded = ceil(left / selectedPaymentAmount)
        let totalDays = paymentsNeeded * Double(max(intervalDays, 1))
        
        if totalDays < 14 {
            return "You’ll reach your goal in \(Int(totalDays)) days."
        } else if totalDays < 60 {
            let weeks = Int(round(totalDays / 7))
            return "You’ll reach your goal in about \(weeks) weeks."
        } else {
            let months = Int(round(totalDays / 30))
            return "You’ll reach your goal in about \(months) months."
        }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.white.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                Button(action: handleBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color.green)
                        .padding(12)
                }
                .padding(.top, 8)

                content
                    .padding(.horizontal, 24)

                Spacer()
            }

            // Custom overlay for limit reached
            if showMaxReachedAlert {
                LimitReachedOverlay(
                    title: "Limit reached",
                    message: "You can only have up to 3 jars.",
                    buttonTitle: "OK",
                    onDismiss: { showMaxReachedAlert = false }
                )
                .zIndex(1)
            }
        }
        // When schedule gets enabled, initialize the payment plan defaults safely
        .onChange(of: useSchedule) { enabled in
            if enabled {
                initializePaymentPlanDefaults()
            }
        }
        // Normalize when focus leaves fields
        .onChange(of: isTargetFocused) { focused in
            if !focused {
                targetAmountText = normalizeOnCommit(targetAmountText, capTo: maxTargetAmount)
                // Clamp current: must be strictly less than target; if >=, set to target - 1 (min 0)
                let target = Double(targetAmountText) ?? 0
                if let current = Double(currentSavedText), current >= target {
                    let adjusted = max(target - 1, 0)
                    currentSavedText = String(format: "%.2f", adjusted)
                }
            }
        }
        .onChange(of: isCurrentFocused) { focused in
            if !focused {
                let target = min(targetAmount, maxTargetAmount)
                // Normalize first
                var normalized = normalizeOnCommit(currentSavedText, capTo: target)
                // Enforce strictly less than target: if >=, set to target - 1 (min 0)
                if let cur = Double(normalized), cur >= target {
                    let adjusted = max(target - 1, 0)
                    normalized = String(format: "%.2f", adjusted)
                }
                if currentSavedText != normalized {
                    currentSavedText = normalized
                }
            }
        }
        // Normalize custom amount when leaving the field: enforce minimum of 1 and 2 decimals
        .onChange(of: isCustomAmountFocused) { focused in
            if !focused {
                let sanitized = sanitizedTyping(customAmountText, maxDecimals: 2, maxValue: .infinity)
                let val = Double(sanitized) ?? 0
                let finalVal = max(1, val) // enforce minimum 1 only on blur
                let formatted = String(format: "%.2f", finalVal)
                if customAmountText != formatted {
                    customAmountText = formatted
                }
                if scheduleAmount != finalVal {
                    scheduleAmount = finalVal
                }
            }
        }
    }

    // MARK: - Current step content

    @ViewBuilder
    private var content: some View {
        switch step {
        case 0:
            savingForStep
        case 1:
            savingAmountStep
        case 2:
            currentlySavedStep
        default:
            summaryStep
        }
    }

    // MARK: Step 0 – name

    private var savingForStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Saving For")
                .font(.system(size: 32, weight: .bold))

            TextField("Holiday", text: $name)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                // 13-character hard limit (counts all characters, including spaces/symbols)
                .onChange(of: name) { newValue in
                    if newValue.count > 13 {
                        name = String(newValue.prefix(13))
                    }
                }

            Button(action: { step = 1 }) {
                Text("Next")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(name.isEmpty ? Color(.systemGray5) : Color.green)
                    .foregroundColor(name.isEmpty ? Color(.systemGray3) : .white)
                    .cornerRadius(16)
            }
            .disabled(name.isEmpty)
        }
    }

    // MARK: Step 1 – target amount

    private var savingAmountStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Saving Amount")
                .font(.system(size: 32, weight: .bold))

            TextField("$0.00", text: $targetAmountText)
                .keyboardType(.decimalPad)
                .focused($isTargetFocused)
                .submitLabel(.done)
                .onSubmit {
                    isTargetFocused = false
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .onChange(of: targetAmountText) { newValue in
                    targetAmountText = sanitizedTyping(newValue, maxDecimals: 2, maxValue: maxTargetAmount)
                }

            Button(action: { step = 2 }) {
                Text("Next")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(validTarget ? Color.green : Color(.systemGray5))
                    .foregroundColor(validTarget ? .white : Color(.systemGray3))
                    .cornerRadius(16)
            }
            .disabled(!validTarget)
        }
    }

    // MARK: Step 2 – currently saved

    private var currentlySavedStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Currently Saved")
                .font(.system(size: 32, weight: .bold))

            TextField("$0.00", text: $currentSavedText)
                .keyboardType(.decimalPad)
                .focused($isCurrentFocused)
                .submitLabel(.done)
                .onSubmit {
                    isCurrentFocused = false
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .onChange(of: currentSavedText) { newValue in
                    let target = min(targetAmount, maxTargetAmount)
                    currentSavedText = sanitizedTyping(newValue, maxDecimals: 2, maxValue: target)
                }

            Text("of \(formattedTarget)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button(action: { step = 3 }) {
                Text("Next")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(validCurrent ? Color.green : Color(.systemGray5))
                    .foregroundColor(validCurrent ? .white : Color(.systemGray3))
                    .cornerRadius(16)
            }
            .disabled(!validCurrent)
        }
    }

    // MARK: Step 3 – summary + interval + payment plan

    private var summaryStep: some View {
        // Make the entire summary step scrollable so expanded content is visible
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Summary")
                    .font(.system(size: 32, weight: .bold))

                Text("\(displayName) savings goal is \(formattedTargetAmount) with \(formattedAmountLeft) to go.")
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)

                // Interval section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Add interval schedule")
                                .font(.headline)
                            Text("Optional")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button {
                            withAnimation(.spring(response: 0.25,
                                                  dampingFraction: 0.8,
                                                  blendDuration: 0.1)) {
                                useSchedule.toggle()
                            }
                        } label: {
                            ZStack(alignment: useSchedule ? .trailing : .leading) {
                                Capsule()
                                    .fill(useSchedule ? Color.green : Color(.systemGray4))
                                Circle()
                                    .fill(Color.white)
                                    .shadow(radius: 1)
                                    .padding(3)
                            }
                            .frame(width: 52, height: 30)
                        }
                        .buttonStyle(.plain)
                    }

                    if useSchedule {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                // Copy fix: "Everyday" for 1, otherwise "Every \(intervalDays) days"
                                Text(intervalDays == 1 ? "Everyday" : "Every \(intervalDays) days")
                                    .font(.body)

                                Spacer()

                                HStack(spacing: 12) {
                                    Button {
                                        if intervalDays > 1 {
                                            intervalDays -= 1
                                        }
                                    } label: {
                                        Image(systemName: "minus")
                                            .font(.system(size: 16, weight: .bold))
                                            .frame(width: 32, height: 32)
                                            .background(Color.white)
                                            .clipShape(Circle())
                                            .shadow(color: .black.opacity(0.08),
                                                    radius: 4, x: 0, y: 2)
                                    }

                                    Button {
                                        if intervalDays < 365 {
                                            intervalDays += 1
                                        }
                                    } label: {
                                        Image(systemName: "plus")
                                            .font(.system(size: 16, weight: .bold))
                                            .frame(width: 32, height: 32)
                                            .background(Color.white)
                                            .clipShape(Circle())
                                            .shadow(color: .black.opacity(0.08),
                                                    radius: 4, x: 0, y: 2)
                                    }
                                }
                            }

                            Divider()

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Start on")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                DatePicker(
                                    "",
                                    selection: $startDate,
                                    in: todayStart...,
                                    displayedComponents: .date
                                )
                                .labelsHidden()
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color(.systemGray6))
                        )
                    }
                }
                .animation(.spring(response: 0.25,
                                   dampingFraction: 0.9,
                                   blendDuration: 0.1),
                           value: useSchedule)

                // Payment plan selector appears only when schedule is enabled
                if useSchedule {
                    paymentPlanSection
                }

                // Bottom spacing so last controls aren’t clipped
                Spacer(minLength: 12)

                Button(action: finish) {
                    Text("Finish")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
                .padding(.bottom, 8)
            }
            .padding(.top, 4)
            // Tap anywhere in the scroll content to dismiss keyboard, including custom amount field
            .contentShape(Rectangle())
            .onTapGesture {
                isTargetFocused = false
                isCurrentFocused = false
                isCustomAmountFocused = false
            }
        }
        // Hide the visible scroll indicators while keeping scrolling behavior
        .scrollIndicators(.hidden)
    }

    // MARK: - New payment plan UI with 100 selectable options

    private var paymentPlanSection: some View {
        let goalAmount = max(amountLeft, 0)
        // Build evenly spaced options from $1 to goalAmount (inclusive)
        let steps = 100
        let minDollar: Double = 1
        let upper = max(goalAmount.rounded(.up), minDollar) // ensure >= 1
        let count = max(1, steps)
        let options: [Double] = {
            if count == 1 {
                return [upper]
            } else {
                let delta = (upper - minDollar) / Double(count - 1)
                return (0..<count).map { i in (minDollar + Double(i) * delta).rounded(toPlaces: 2) }
            }
        }()

        func currency(_ value: Double) -> String {
            value.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
        }

        let intervalsNeeded: Double = {
            guard scheduleAmount > 0 else { return 0 }
            return ceil(goalAmount / scheduleAmount)
        }()
        let daysNeeded = Int(intervalsNeeded) * max(intervalDays, 1)

        // Layout constants
        let pillHorizontalPadding: CGFloat = 10
        let pillVerticalPadding: CGFloat = 6
        let barWidth: CGFloat = 22
        let barHeight: CGFloat = 36
        let itemSpacing: CGFloat = 12
        let itemWidth: CGFloat = max(72, barWidth + 2 * pillHorizontalPadding + 24)

        // Helper to find matching pill index for a given amount (within cent tolerance)
        func matchingIndex(for amount: Double) -> Int? {
            let tolerance = 0.005
            return options.firstIndex(where: { abs($0 - amount) < tolerance })
        }

        return VStack(alignment: .leading, spacing: 16) {
            Text("Payment plan")
                .font(.headline)

            // Use ScrollViewReader to enable programmatic scrolling to a pill
            ScrollViewReader { proxy in
                // Simple horizontal scroll; selection only changes on tap
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: itemSpacing) {
                        ForEach(Array(options.enumerated()), id: \.offset) { idx, value in
                            let isSelected = selectedScheduleIndex == idx
                            let ratio = max(0, min(1, (value - minDollar) / max(upper - minDollar, 1)))
                            VStack(spacing: 6) {
                                Text(currency(value))
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, pillHorizontalPadding)
                                    .padding(.vertical, pillVerticalPadding)
                                    .background(
                                        Capsule()
                                            .fill(isSelected ? Color.green : Color.gray.opacity(0.18))
                                    )
                                    .foregroundColor(isSelected ? .white : .primary)

                                ZStack(alignment: .bottom) {
                                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                                        .fill(Color.gray.opacity(0.18))
                                        .frame(width: barWidth, height: barHeight)
                                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                                        .fill(isSelected ? Color.green : Color.green.opacity(0.5))
                                        .frame(width: barWidth, height: max(6, barHeight * ratio))
                                        .animation(.easeInOut(duration: 0.2), value: ratio)
                                }
                            }
                            .frame(width: itemWidth)
                            .contentShape(Rectangle())
                            .id(idx)
                            .onTapGesture {
                                // Select tapped pill and update amount; previously selected pill will unselect
                                selectedScheduleIndex = idx
                                scheduleAmount = value
                                customAmountText = scheduleAmount.formatted(.number.precision(.fractionLength(2)))
                                // Scroll to the selected pill
                                withAnimation {
                                    proxy.scrollTo(idx, anchor: .center)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }
                .frame(height: 86)
                // React to custom typing: if it matches a pill, select and scroll; otherwise clear selection
                .onChange(of: scheduleAmount) { newValue in
                    if let match = matchingIndex(for: newValue) {
                        if selectedScheduleIndex != match {
                            selectedScheduleIndex = match
                            withAnimation {
                                proxy.scrollTo(match, anchor: .center)
                            }
                        }
                    } else {
                        // No pill matches this custom amount; clear selection
                        if selectedScheduleIndex != nil {
                            selectedScheduleIndex = nil
                        }
                    }
                }
            }

            // Live summary reflecting selection
            VStack(alignment: .leading, spacing: 6) {
                Text("Pay \(currency(scheduleAmount)) per interval")
                    .font(.subheadline.weight(.semibold))

                if goalAmount <= 0 || scheduleAmount <= 0 {
                    Text("You’ve already reached this goal.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                } else {
                    Text("You’ll reach your goal in \(daysNeeded) day\(daysNeeded == 1 ? "" : "s").")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }

            // Custom amount field
            VStack(alignment: .leading, spacing: 8) {
                Text("Custom amount")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                TextField(currency(scheduleAmount), text: $customAmountText)
                    .keyboardType(.decimalPad)
                    .focused($isCustomAmountFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        isCustomAmountFocused = false
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .onChange(of: customAmountText) { newValue in
                        // Sanitize while typing (do not force min 1 here to avoid blocking inputs like 0.50)
                        let sanitized = sanitizedTyping(newValue, maxDecimals: 2, maxValue: .infinity)
                        if customAmountText != sanitized {
                            customAmountText = sanitized
                        }
                        if let typed = Double(sanitized) {
                            scheduleAmount = typed
                        } else {
                            scheduleAmount = 0
                        }
                    }
            }
        }
    }

    // Initialize defaults when schedule toggles on or when entering summary with schedule enabled
    private func initializePaymentPlanDefaults() {
        let minDollar: Double = 1
        if scheduleAmount <= 0 {
            scheduleAmount = minDollar
        }
        if selectedScheduleIndex == nil {
            selectedScheduleIndex = 0
        }
        customAmountText = scheduleAmount.formatted(.number.precision(.fractionLength(2)))
    }

    // MARK: - Validation helpers

    private var validTarget: Bool {
        if let value = Double(targetAmountText.filter { $0 != "$" }) {
            return value > 0 && value <= maxTargetAmount
        }
        return false
    }

    private var validCurrent: Bool {
        guard let current = Double(currentSavedText.filter { $0 != "$" }) else { return false }
        let target = Double(targetAmountText.filter { $0 != "$" }) ?? 0
        // Must be strictly less than target
        return current >= 0 && current < target && target <= maxTargetAmount && target > 0
    }

    private var formattedTarget: String {
        if let value = Double(targetAmountText.filter { $0 != "$" }) {
            return String(format: "$%.2f", value)
        } else {
            return "$0.00"
        }
    }

    // MARK: - Navigation / finish

    private func handleBack() {
        if step == 0 {
            dismiss()
        } else {
            step -= 1
        }
    }

    private func finish() {
        // Safety: enforce max jars here too
        if goals.count >= maxJars {
            showMaxReachedAlert = true
            return
        }

        let cleanedTarget = Double(targetAmountText.filter { $0 != "$" }) ?? 0
        let cleanedCurrent = Double(currentSavedText.filter { $0 != "$" }) ?? 0

        // Persist schedule selections into the goal (optionally)
        let shouldSaveSchedule = useSchedule
        let savedIntervalDays: Int? = shouldSaveSchedule ? intervalDays : nil
        let savedScheduleAmount: Double? = shouldSaveSchedule ? max(0, scheduleAmount) : nil
        let savedStartDate: Date? = shouldSaveSchedule ? Calendar.current.startOfDay(for: startDate) : nil

        let newGoal = SavingsGoal(
            name: displayName,
            targetAmount: cleanedTarget,
            currentSaved: cleanedCurrent,
            useSchedule: shouldSaveSchedule,
            intervalDays: savedIntervalDays,
            scheduleAmount: savedScheduleAmount,
            startDate: savedStartDate
        )

        goals.append(newGoal)
        dismiss()
    }
}

// MARK: - Typing sanitization and commit normalization

private extension AddSavingsGoalFlow {
    // Non-destructive sanitization while typing: allow digits, one dot, and up to maxDecimals digits after it.
    func sanitizedTyping(_ text: String, maxDecimals: Int, maxValue: Double) -> String {
        let decimalSep = Locale.current.decimalSeparator ?? "."
        // Normalize to dot internally
        var cleaned = text
            .replacingOccurrences(of: Locale.current.groupingSeparator ?? ",", with: "")
            .replacingOccurrences(of: decimalSep, with: ".")
            .filter { "0123456789.".contains($0) }

        // Reduce multiple dots to one and cap fractional length
        if let dot = cleaned.firstIndex(of: ".") {
            let intPart = String(cleaned[..<dot])
            var fracPart = String(cleaned[cleaned.index(after: dot)...])

            // Remove any additional dots in the fractional part
            if let extraDot = fracPart.firstIndex(of: ".") {
                fracPart = String(fracPart[..<extraDot])
            }
            if maxDecimals >= 0, fracPart.count > maxDecimals {
                fracPart = String(fracPart.prefix(maxDecimals))
            }
            cleaned = fracPart.isEmpty ? intPart : "\(intPart).\(fracPart)"
        }

        // Soft cap to maxValue: if numeric, trim down if exceeding
        if let val = Double(cleaned), val > maxValue {
            cleaned = String(format: "%.\(max(0, maxDecimals))f", maxValue)
        }

        return cleaned
    }

    // Hard normalization on commit/blur: clamp to cap and format to exactly 2 decimals.
    func normalizeOnCommit(_ text: String, capTo: Double) -> String {
        let s = sanitizedTyping(text, maxDecimals: 2, maxValue: capTo)
        let val = Double(s) ?? 0
        let clamped = min(max(0, val), capTo)
        return String(format: "%.2f", clamped)
    }
}

// MARK: - Rounding helper

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        guard places >= 0 else { return self }
        let p = pow(10.0, Double(places))
        return (self * p).rounded() / p
    }
}
