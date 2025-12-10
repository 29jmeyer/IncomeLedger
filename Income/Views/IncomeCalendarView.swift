import SwiftUI

struct IncomeCalendarView: View {
    let jobs: [Job]
    let passiveIncomes: [PassiveIncome]
    let nonRecurringIncomes: [NonRecurringIncome]
    @Binding var overrides: [JobPayPeriodOverride]
    @Binding var passiveOverrides: [PassiveIncomeOverride]
    @Binding var nonRecurringOverrides: [NonRecurringIncomeOverride]
    @Binding var useNet: Bool

    // Allows parent to delete a one‑time entry
    var onDeleteOneTime: (UUID) -> Void = { _ in }

    // MARK: - Month navigation state
    @State private var selectedMonth: Date = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date())) ?? Date()

    // MARK: - Override editing state (jobs)
    @State private var showingOverrideSheet: Bool = false
    @State private var selectedJobId: UUID? = nil
    @State private var selectedJobName: String = ""
    @State private var selectedPayDate: Date = Date()

    @State private var overrideHoursText: String = ""
    @State private var overrideAmountText: String = ""

    // MARK: - Passive override editing state
    @State private var showingPassiveOverrideSheet: Bool = false
    @State private var selectedPassiveId: UUID? = nil
    @State private var selectedPassiveName: String = ""
    @State private var selectedPassiveDate: Date = Date()
    @State private var passiveBaseAmount: Double = 0
    @State private var passiveOverrideAmountText: String = ""

    // MARK: - Non‑recurring override editing state
    @State private var showingOneTimeOverrideSheet: Bool = false
    @State private var selectedOneTimeId: UUID? = nil
    @State private var selectedOneTimeName: String = ""
    @State private var selectedOneTimeDate: Date = Date()
    @State private var oneTimeBaseAmount: Double = 0
    @State private var oneTimeOverrideAmountText: String = ""

    var body: some View {
        let monthStart = startOfMonth(for: selectedMonth)
        let monthEnd = endOfMonth(for: selectedMonth)

        let events = generateEvents(forMonthStart: monthStart, monthEnd: monthEnd)
        let grouped = groupEventsByWeekWithinMonth(events: events, monthStart: monthStart, monthEnd: monthEnd)

        VStack(spacing: 12) {
            // Calendar header with Gross/Net toggle
            monthHeaderCard

            ScrollView {
                VStack(spacing: 16) {
                    ForEach(grouped, id: \.key) { section in
                        VStack(alignment: .leading, spacing: 8) {
                            // Week label like "DEC 7 – DEC 13"
                            Text(uppercaseWeekRange(section.key.startOfWeek, section.key.endOfWeek))
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)

                            // Card with events
                            VStack(spacing: 0) {
                                ForEach(section.value, id: \.id) { event in
                                    WeekEventRow(
                                        event: event,
                                        currencyString: currencyString(_:),
                                        dateString: dateString(_:),
                                        onTap: {
                                            switch event.source {
                                            case let .job(jobId):
                                                presentOverrideSheet(jobId: jobId, date: event.date)
                                            case let .passive(pid):
                                                presentPassiveOverrideSheet(itemId: pid, date: event.date, displayedAmount: event.amount)
                                            case let .oneTime(oid):
                                                presentOneTimeOverrideSheet(itemId: oid, date: event.date, displayedAmount: event.amount)
                                            }
                                        }
                                    )
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)

                                    // Original behavior: divider between rows except after the last row
                                    if event.id != section.value.last?.id {
                                        Divider()
                                            .padding(.leading, 12)
                                    }
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 6)
                            )
                        }
                    }

                    // Spacer so last card clears any custom tab bar
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
        .navigationTitle("Income Calendar")
        // Job sheet
        .sheet(isPresented: $showingOverrideSheet) {
            OverrideEditorCard(
                jobName: selectedJobName,
                date: selectedPayDate,
                overrideHoursText: $overrideHoursText,
                overrideAmountText: $overrideAmountText,
                onSave: { hoursText, amountText in
                    saveOverride(hoursText: hoursText, amountText: amountText)
                },
                onClear: {
                    clearOverride()
                }
            )
            .presentationDetents([.height(420), .medium])
            .presentationDragIndicator(.hidden)
        }
        // Passive sheet
        .sheet(isPresented: $showingPassiveOverrideSheet) {
            PassiveOverrideEditorCard(
                name: selectedPassiveName,
                date: selectedPassiveDate,
                baseAmount: passiveBaseAmount,
                overrideAmountText: $passiveOverrideAmountText,
                onSave: { amountText in
                    savePassiveOverride(amountText: amountText)
                },
                onClear: {
                    clearPassiveOverride()
                }
            )
            .presentationDetents([.height(360), .medium])
            .presentationDragIndicator(.hidden)
        }
        // Non‑recurring sheet
        .sheet(isPresented: $showingOneTimeOverrideSheet) {
            OneTimeOverrideEditorCard(
                name: selectedOneTimeName,
                date: selectedOneTimeDate,
                baseAmount: oneTimeBaseAmount,
                overrideAmountText: $oneTimeOverrideAmountText,
                onSave: { amountText in
                    saveOneTimeOverride(amountText: amountText)
                },
                onClear: {
                    clearOneTimeOverride()
                },
                onDelete: {
                    deleteOneTime()
                }
            )
            .presentationDetents([.height(380), .medium])
            .presentationDragIndicator(.hidden)
        }
        .onAppear {
            // Initialize to the month that contains today
            selectedMonth = startOfMonth(for: Date())
        }
    }

    // MARK: - Month Header (with Gross/Net pills)

    private var monthHeaderCard: some View {
        VStack(spacing: 10) {
            HStack {
                Button {
                    selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color(.systemGray5))
                        )
                }
                .buttonStyle(.plain)

                Spacer()

                Text(monthYearString(selectedMonth))
                    .font(.headline.bold())
                    .foregroundColor(.primary)

                Spacer()

                Button {
                    selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color(.systemGray5))
                        )
                }
                .buttonStyle(.plain)
            }

            // Gross/Net pills for calendar mode
            HStack(spacing: 8) {
                togglePill(title: "Gross", isOn: !useNet) {
                    useNet = false
                }
                togglePill(title: "Net", isOn: useNet) {
                    useNet = true
                }
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 8)
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private func togglePill(title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isOn ? Color.green.opacity(0.9) : Color.gray.opacity(0.2))
                )
                .foregroundColor(isOn ? .white : .primary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Event generation (selected month only)

    private func generateEvents(forMonthStart monthStart: Date, monthEnd: Date) -> [IncomeEvent] {
        var events: [IncomeEvent] = []

        // Jobs
        for job in jobs {
            let dates = occurrences(inMonthStart: monthStart, monthEnd: monthEnd, start: job.startDate, end: job.endDate, intervalDays: job.intervalDays)
            for d in dates {
                let amount = effectiveJobAmount(for: job, on: d, overrides: overrides, useNet: useNet)
                // Keep events even if amount == 0 (to show $0 overrides)
                events.append(.init(
                    date: d,
                    name: job.name,
                    amount: amount,
                    source: .job(job.id)
                ))
            }
        }

        // Passive incomes
        for item in passiveIncomes {
            let dates = occurrences(inMonthStart: monthStart, monthEnd: monthEnd, start: item.startDate, end: item.endDate, intervalDays: item.intervalDays)
            for d in dates {
                let amount = effectivePassiveAmount(for: item, on: d, overrides: passiveOverrides, useNet: useNet)
                events.append(.init(
                    date: d,
                    name: item.name,
                    amount: amount,
                    source: .passive(item.id)
                ))
            }
        }

        // Non-recurring incomes (exact date if within selected month)
        for one in nonRecurringIncomes {
            let d = Calendar.current.startOfDay(for: one.date)
            if d >= monthStart && d <= monthEnd {
                let amount = effectiveNonRecurringAmount(for: one, on: d, overrides: nonRecurringOverrides, useNet: useNet)
                events.append(.init(
                    date: d,
                    name: one.name,
                    amount: amount,
                    source: .oneTime(one.id)
                ))
            }
        }

        events.sort { $0.date < $1.date }
        return events
    }

    // Generate occurrences within the selected month for a repeating series
    private func occurrences(inMonthStart monthStart: Date, monthEnd: Date, start: Date, end: Date?, intervalDays: Int) -> [Date] {
        guard intervalDays > 0 else { return [] }
        let cal = Calendar.current
        let clampedEnd = end ?? monthEnd

        // If the series ends before the month starts, no results
        if clampedEnd < monthStart { return [] }

        // Find the first occurrence on/after monthStart aligned to the series start
        var first = cal.startOfDay(for: start)
        if first < monthStart {
            let diff = cal.dateComponents([.day], from: first, to: monthStart).day ?? 0
            let steps = max(0, Int(ceil(Double(diff) / Double(intervalDays))))
            if let jumped = cal.date(byAdding: .day, value: steps * intervalDays, to: first) {
                first = jumped
            }
        }

        var dates: [Date] = []
        var cursor = first

        while cursor <= monthEnd && cursor <= clampedEnd {
            if cursor >= monthStart {
                dates.append(cal.startOfDay(for: cursor))
            }
            guard let next = cal.date(byAdding: .day, value: intervalDays, to: cursor) else { break }
            cursor = next
        }

        return dates
    }

    // MARK: - Grouping by week within month

    private func groupEventsByWeekWithinMonth(events: [IncomeEvent], monthStart: Date, monthEnd: Date) -> [(key: WeekSpan, value: [IncomeEvent])] {
        let cal = Calendar.current
        let weekStarts = allWeekStartsOverlappingMonth(monthStart: monthStart, monthEnd: monthEnd)

        var buckets: [WeekSpan: [IncomeEvent]] = [:]
        for ws in weekStarts {
            buckets[ws] = []
        }

        for e in events {
            let startOfWeek = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: e.date)) ?? e.date
            let endOfWeek = cal.date(byAdding: .day, value: 6, to: startOfWeek) ?? startOfWeek
            let clampedStart = max(startOfWeek, monthStart)
            let clampedEnd = min(endOfWeek, monthEnd)
            let span = WeekSpan(startOfWeek: clampedStart, endOfWeek: clampedEnd)

            if buckets[span] != nil {
                buckets[span]?.append(e)
            } else {
                buckets[span] = [e]
            }
        }

        let sorted = buckets
            .map { ($0.key, ($0.value.sorted { $0.date < $1.date })) }
            .sorted { $0.0.startOfWeek < $1.0.startOfWeek }

        return sorted.filter { !$0.1.isEmpty }
    }

    private func allWeekStartsOverlappingMonth(monthStart: Date, monthEnd: Date) -> [WeekSpan] {
        let cal = Calendar.current
        let startOfFirstWeek = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: monthStart)) ?? monthStart

        var spans: [WeekSpan] = []
        var cursor = startOfFirstWeek

        while cursor <= monthEnd {
            let end = cal.date(byAdding: .day, value: 6, to: cursor) ?? cursor
            let clampedStart = max(cursor, monthStart)
            let clampedEnd = min(end, monthEnd)
            spans.append(WeekSpan(startOfWeek: clampedStart, endOfWeek: clampedEnd))

            guard let next = cal.date(byAdding: .day, value: 7, to: cursor) else { break }
            cursor = next
        }

        return spans
    }

    // MARK: - Formatting

    private func currencyString(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    private func dateString(_ date: Date) -> String {
        DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none)
    }

    private func uppercaseWeekRange(_ start: Date, _ end: Date) -> String {
        let df = DateFormatter()
        df.setLocalizedDateFormatFromTemplate("MMM d")
        let s = df.string(from: start).uppercased()
        let e = df.string(from: end).uppercased()
        return "\(s) – \(e)"
    }

    private func monthYearString(_ date: Date) -> String {
        let df = DateFormatter()
        df.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return df.string(from: date)
    }

    // MARK: - Date helpers

    private func startOfMonth(for date: Date) -> Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: date)
        return cal.date(from: comps) ?? date
    }

    private func endOfMonth(for date: Date) -> Date {
        let cal = Calendar.current
        let start = startOfMonth(for: date)
        let comps = DateComponents(month: 1, day: -1)
        return cal.date(byAdding: comps, to: start) ?? start
    }

    // MARK: - Override editing helpers (Jobs)

    private func presentOverrideSheet(jobId: UUID, date: Date) {
        selectedJobId = jobId
        selectedPayDate = Calendar.current.startOfDay(for: date)

        // Look up job name
        if let job = jobs.first(where: { $0.id == jobId }) {
            selectedJobName = job.name
        } else {
            selectedJobName = "Job"
        }

        // Prefill from existing override if present
        if let existing = overrides.first(where: { $0.jobId == jobId && Calendar.current.isDate($0.payDate, inSameDayAs: selectedPayDate) }) {
            if let hrs = existing.overrideHoursWorked {
                overrideHoursText = String(hrs)
            } else {
                overrideHoursText = ""
            }
            if let amt = existing.overrideAmount {
                overrideAmountText = String(amt)
            } else {
                overrideAmountText = ""
            }
        } else {
            overrideHoursText = ""
            overrideAmountText = ""
        }

        showingOverrideSheet = true
    }

    private func saveOverride(hoursText: String, amountText: String) {
        guard let jobId = selectedJobId else { return }

        let trimmedHours = hoursText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAmount = amountText.trimmingCharacters(in: .whitespacesAndNewlines)

        func parseDouble(_ s: String) -> Double? {
            guard !s.isEmpty else { return nil }
            return Double(s.replacingOccurrences(of: ",", with: "."))
        }

        let hours = parseDouble(trimmedHours)
        let amount = parseDouble(trimmedAmount)

        // If both empty -> treat as clear
        if hours == nil && amount == nil {
            clearOverride()
            showingOverrideSheet = false
            return
        }

        // Upsert override for (jobId, selectedPayDate)
        if let idx = overrides.firstIndex(where: { $0.jobId == jobId && Calendar.current.isDate($0.payDate, inSameDayAs: selectedPayDate) }) {
            let existing = overrides[idx]
            let updated = JobPayPeriodOverride(
                jobId: existing.jobId,
                payDate: existing.payDate,
                overrideAmount: amount,
                overrideHoursWorked: hours
            )
            overrides[idx] = updated
        } else {
            let new = JobPayPeriodOverride(
                jobId: jobId,
                payDate: selectedPayDate,
                overrideAmount: amount,
                overrideHoursWorked: hours
            )
            overrides.append(new)
        }

        showingOverrideSheet = false
    }

    private func clearOverride() {
        guard let jobId = selectedJobId else { return }
        if let idx = overrides.firstIndex(where: { $0.jobId == jobId && Calendar.current.isDate($0.payDate, inSameDayAs: selectedPayDate) }) {
            overrides.remove(at: idx)
        }
        showingOverrideSheet = false
    }

    // MARK: - Override editing helpers (Passive)

    private func presentPassiveOverrideSheet(itemId: UUID, date: Date, displayedAmount: Double) {
        selectedPassiveId = itemId
        selectedPassiveDate = Calendar.current.startOfDay(for: date)
        passiveBaseAmount = displayedAmount

        if let item = passiveIncomes.first(where: { $0.id == itemId }) {
            selectedPassiveName = item.name
        } else {
            selectedPassiveName = "Passive"
        }

        if let existing = passiveOverrides.first(where: { $0.passiveIncomeId == itemId && Calendar.current.isDate($0.date, inSameDayAs: selectedPassiveDate) }) {
            if let amt = existing.overrideAmount {
                passiveOverrideAmountText = String(amt)
            } else {
                passiveOverrideAmountText = ""
            }
        } else {
            passiveOverrideAmountText = ""
        }

        showingPassiveOverrideSheet = true
    }

    private func savePassiveOverride(amountText: String) {
        guard let pid = selectedPassiveId else { return }

        let trimmed = amountText.trimmingCharacters(in: .whitespacesAndNewlines)
        let amount = trimmed.isEmpty ? nil : Double(trimmed.replacingOccurrences(of: ",", with: "."))

        // If empty -> clear
        if amount == nil {
            clearPassiveOverride()
            showingPassiveOverrideSheet = false
            return
        }

        if let idx = passiveOverrides.firstIndex(where: { $0.passiveIncomeId == pid && Calendar.current.isDate($0.date, inSameDayAs: selectedPassiveDate) }) {
            let existing = passiveOverrides[idx]
            passiveOverrides[idx] = PassiveIncomeOverride(
                passiveIncomeId: existing.passiveIncomeId,
                date: existing.date,
                overrideAmount: amount
            )
        } else {
            passiveOverrides.append(
                PassiveIncomeOverride(
                    passiveIncomeId: pid,
                    date: selectedPassiveDate,
                    overrideAmount: amount
                )
            )
        }

        showingPassiveOverrideSheet = false
    }

    private func clearPassiveOverride() {
        guard let pid = selectedPassiveId else { return }
        if let idx = passiveOverrides.firstIndex(where: { $0.passiveIncomeId == pid && Calendar.current.isDate($0.date, inSameDayAs: selectedPassiveDate) }) {
            passiveOverrides.remove(at: idx)
        }
        showingPassiveOverrideSheet = false
    }

    // MARK: - Override editing helpers (Non‑recurring)

    private func presentOneTimeOverrideSheet(itemId: UUID, date: Date, displayedAmount: Double) {
        selectedOneTimeId = itemId
        selectedOneTimeDate = Calendar.current.startOfDay(for: date)
        oneTimeBaseAmount = displayedAmount

        if let item = nonRecurringIncomes.first(where: { $0.id == itemId }) {
            selectedOneTimeName = item.name
        } else {
            selectedOneTimeName = "One‑time"
        }

        if let existing = nonRecurringOverrides.first(where: { $0.nonRecurringId == itemId && Calendar.current.isDate($0.date, inSameDayAs: selectedOneTimeDate) }) {
            if let amt = existing.overrideAmount {
                oneTimeOverrideAmountText = String(amt)
            } else {
                oneTimeOverrideAmountText = ""
            }
        } else {
            oneTimeOverrideAmountText = ""
        }

        showingOneTimeOverrideSheet = true
    }

    private func saveOneTimeOverride(amountText: String) {
        guard let oid = selectedOneTimeId else { return }

        let trimmed = amountText.trimmingCharacters(in: .whitespacesAndNewlines)
        let amount = trimmed.isEmpty ? nil : Double(trimmed.replacingOccurrences(of: ",", with: "."))

        // If empty -> clear
        if amount == nil {
            clearOneTimeOverride()
            showingOneTimeOverrideSheet = false
            return
        }

        if let idx = nonRecurringOverrides.firstIndex(where: { $0.nonRecurringId == oid && Calendar.current.isDate($0.date, inSameDayAs: selectedOneTimeDate) }) {
            let existing = nonRecurringOverrides[idx]
            nonRecurringOverrides[idx] = NonRecurringIncomeOverride(
                nonRecurringId: existing.nonRecurringId,
                date: existing.date,
                overrideAmount: amount
            )
        } else {
            nonRecurringOverrides.append(
                NonRecurringIncomeOverride(
                    nonRecurringId: oid,
                    date: selectedOneTimeDate,
                    overrideAmount: amount
                )
            )
        }

        showingOneTimeOverrideSheet = false
    }

    private func clearOneTimeOverride() {
        guard let oid = selectedOneTimeId else { return }
        if let idx = nonRecurringOverrides.firstIndex(where: { $0.nonRecurringId == oid && Calendar.current.isDate($0.date, inSameDayAs: selectedOneTimeDate) }) {
            nonRecurringOverrides.remove(at: idx)
        }
        showingOneTimeOverrideSheet = false
    }

    private func deleteOneTime() {
        guard let oid = selectedOneTimeId else { return }
        onDeleteOneTime(oid)
        showingOneTimeOverrideSheet = false
    }
}

// MARK: - Support types

private struct IncomeEvent: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let name: String
    let amount: Double
    let source: Source

    enum Source: Equatable {
        case job(UUID)
        case passive(UUID)
        case oneTime(UUID)
    }
}

private struct WeekSpan: Hashable {
    let startOfWeek: Date
    let endOfWeek: Date

    func hash(into hasher: inout Hasher) {
        hasher.combine(startOfWeek.timeIntervalSince1970)
        hasher.combine(endOfWeek.timeIntervalSince1970)
    }

    static func == (lhs: WeekSpan, rhs: WeekSpan) -> Bool {
        lhs.startOfWeek == rhs.startOfWeek && lhs.endOfWeek == rhs.endOfWeek
    }
}

// MARK: - Row view

private struct WeekEventRow: View {
    let event: IncomeEvent
    let currencyString: (Double) -> String
    let dateString: (Date) -> String
    let onTap: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(event.name)
                        .font(.body.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    sourceBadge
                }

                Text(dateString(event.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Text(currencyString(event.amount))
                .font(.headline.bold().monospacedDigit())
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }

    private var sourceBadge: some View {
        let (label, color): (String, Color) = {
            switch event.source {
            case .job:     return ("Job", Color.blue.opacity(0.15))
            case .passive: return ("Passive", Color.green.opacity(0.18))
            case .oneTime: return ("One‑off", Color.gray.opacity(0.18))
            }
        }()

        let textColor: Color = {
            switch event.source {
            case .job:     return Color.blue
            case .passive: return Color.green
            case .oneTime: return Color.gray
            }
        }()

        return Text(label)
            .font(.caption.weight(.semibold))
            .foregroundColor(textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(color)
            )
    }
}

// MARK: - Override editor sheet (jobs)

private struct OverrideEditorCard: View {
    let jobName: String
    let date: Date

    @Binding var overrideHoursText: String
    @Binding var overrideAmountText: String

    let onSave: (String, String) -> Void
    let onClear: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {

                        // Card
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Edit Override")
                                .font(.headline)

                            VStack(spacing: 10) {
                                HStack {
                                    Text("Job")
                                    Spacer()
                                    Text(jobName)
                                        .foregroundStyle(.secondary)
                                }
                                HStack {
                                    Text("Date")
                                    Spacer()
                                    Text(DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none))
                                        .foregroundStyle(.secondary)
                                }
                            }

                            VStack(alignment: .leading, spacing: 12) {
                                Text("Overrides (optional)")
                                    .font(.subheadline.bold())

                                TextField("Override hours worked", text: $overrideHoursText)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(.roundedBorder)

                                TextField("Override final amount (gross)", text: $overrideAmountText)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(.roundedBorder)

                                Text("Tip: Enter either hours to recompute using your job’s overtime rules, or a final amount to use directly for this date.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: 10)
                        )

                        // Buttons
                        VStack(spacing: 12) {
                            Button {
                                onSave(overrideHoursText, overrideAmountText)
                                dismiss()
                            } label: {
                                Text("Save override")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        Capsule().fill(Color.black)
                                    )
                                    .foregroundColor(.white)
                            }

                            Button {
                                onClear()
                                dismiss()
                            } label: {
                                Text("Revert to default")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        Capsule()
                                            .fill(Color.clear)
                                            .overlay(
                                                Capsule().stroke(Color.gray.opacity(0.35), lineWidth: 1)
                                            )
                                    )
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
            }
        }
    }
}

// MARK: - Passive override editor sheet (matches style)

private struct PassiveOverrideEditorCard: View {
    let name: String
    let date: Date
    let baseAmount: Double

    @Binding var overrideAmountText: String

    let onSave: (String) -> Void
    let onClear: () -> Void

    @Environment(\.dismiss) private var dismiss

    private func currencyString(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {

                        // Card
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Edit Override")
                                .font(.headline)

                            VStack(spacing: 10) {
                                HStack {
                                    Text("Passive")
                                    Spacer()
                                    Text(name)
                                        .foregroundStyle(.secondary)
                                }
                                HStack {
                                    Text("Date")
                                    Spacer()
                                    Text(DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none))
                                        .foregroundStyle(.secondary)
                                }
                                HStack {
                                    Text("Original amount")
                                    Spacer()
                                    Text(currencyString(baseAmount))
                                        .foregroundStyle(.secondary)
                                }
                            }

                            VStack(alignment: .leading, spacing: 12) {
                                Text("Overrides (optional)")
                                    .font(.subheadline.bold())

                                TextField("Override amount for this date (gross)", text: $overrideAmountText)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: 10)
                        )

                        // Buttons
                        VStack(spacing: 12) {
                            Button {
                                onSave(overrideAmountText)
                                dismiss()
                            } label: {
                                Text("Save override")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        Capsule().fill(Color.black)
                                    )
                                    .foregroundColor(.white)
                            }

                            Button {
                                onClear()
                                dismiss()
                            } label: {
                                Text("Revert to default")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        Capsule()
                                            .fill(Color.clear)
                                            .overlay(
                                                Capsule().stroke(Color.gray.opacity(0.35), lineWidth: 1)
                                            )
                                    )
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
            }
        }
    }
}

// MARK: - One‑time override editor sheet (new, matches style)

private struct OneTimeOverrideEditorCard: View {
    let name: String
    let date: Date
    let baseAmount: Double

    @Binding var overrideAmountText: String

    let onSave: (String) -> Void
    let onClear: () -> Void
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss

    private func currencyString(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {

                        // Card
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Edit Override")
                                .font(.headline)

                            VStack(spacing: 10) {
                                HStack {
                                    Text("One‑time")
                                    Spacer()
                                    Text(name)
                                        .foregroundStyle(.secondary)
                                }
                                HStack {
                                    Text("Date")
                                    Spacer()
                                    Text(DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none))
                                        .foregroundStyle(.secondary)
                                }
                                HStack {
                                    Text("Original amount")
                                    Spacer()
                                    Text(currencyString(baseAmount))
                                        .foregroundStyle(.secondary)
                                }
                            }

                            VStack(alignment: .leading, spacing: 12) {
                                Text("Overrides (optional)")
                                    .font(.subheadline.bold())

                                TextField("Override amount for this date (gross)", text: $overrideAmountText)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: 10)
                        )

                        // Buttons
                        VStack(spacing: 12) {
                            Button {
                                onSave(overrideAmountText)
                                dismiss()
                            } label: {
                                Text("Save override")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        Capsule().fill(Color.black)
                                    )
                                    .foregroundColor(.white)
                            }

                            Button {
                                onClear()
                                dismiss()
                            } label: {
                                Text("Revert to default")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        Capsule()
                                            .fill(Color.clear)
                                            .overlay(
                                                Capsule().stroke(Color.gray.opacity(0.35), lineWidth: 1)
                                            )
                                    )
                                    .foregroundColor(.primary)
                            }

                            Button {
                                onDelete()
                                dismiss()
                            } label: {
                                Text("Delete event")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        Capsule().fill(Color.red)
                                    )
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
            }
        }
    }
}
