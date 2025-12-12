import SwiftUI

struct GoalPlanSheet: View {
    let goal: SavingsGoal

    // Expanded/collapsed state
    @State private var isExpanded: Bool = false

    // Layout
    private let cornerRadius: CGFloat = 24
    private let expandedTopInset: CGFloat = 100 // how far from top when fully expanded

    // MARK: - Computed values

    private var remaining: Double {
        max(goal.targetAmount - goal.currentSaved, 0)
    }

    private var hasSchedule: Bool {
        (goal.useSchedule ?? false)
        && (goal.intervalDays ?? 0) > 0
        && (goal.scheduleAmount ?? 0) > 0
    }

    private var scheduleSummary: String {
        guard hasSchedule else { return "No schedule set" }
        let amt = goal.scheduleAmount ?? 0
        let days = goal.intervalDays ?? 0
        let currency = amt.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
        let start = (goal.startDate ?? Date())
        let dateText = DateFormatter.localizedString(from: start, dateStyle: .medium, timeStyle: .none)
        let every = days == 1 ? "Everyday" : "Every \(days) days"
        return "\(currency) • \(every) • from \(dateText)"
    }

    // UPDATED: allocate from latest dates first so earlier (most recent) ones are “removed” first
    private func generateUpcomingPayments(limit: Int = 50) -> [(date: Date, amount: Double)] {
        guard hasSchedule else { return [] }
        let per = max(0, goal.scheduleAmount ?? 0)
        let days = max(1, goal.intervalDays ?? 1)
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: goal.startDate ?? Date())

        // Build forward dates up to limit (or until a reasonable cap)
        var dates: [Date] = []
        var cursor = start
        for _ in 0..<limit {
            dates.append(cursor)
            guard let next = calendar.date(byAdding: .day, value: days, to: cursor) else { break }
            cursor = next
        }

        // Allocate remaining from the END (latest dates) backwards
        var remainingAmount = remaining
        var result: [(Date, Double)] = []

        for d in dates.reversed() {
            guard remainingAmount > 0 else { break }
            let thisAmount = min(per, remainingAmount)
            result.append((d, thisAmount))
            remainingAmount -= thisAmount
        }

        // We built from latest to earliest; reverse so UI still shows earliest -> latest ordering
        return result.reversed()
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let screenHeight = geo.size.height
            let collapsedHeight = max(220, screenHeight * 0.28)
            let collapsedOffset = screenHeight - collapsedHeight
            let expandedOffset = expandedTopInset

            let items = generateUpcomingPayments()
            let currentOffset = isExpanded ? expandedOffset : collapsedOffset

            ZStack {
                // Dim background when expanded
                if isExpanded {
                    Color.black.opacity(0.25)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                isExpanded = false
                            }
                        }
                }

                sheetContent(items: items, geo: geo)
                    .offset(y: currentOffset)
                    .animation(.spring(response: 0.35, dampingFraction: 0.86), value: isExpanded)
                    .onAppear { isExpanded = false }
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Sheet Container

    private func sheetContent(items: [(date: Date, amount: Double)], geo: GeometryProxy) -> some View {
        VStack(spacing: 12) {
            // Handle
            Capsule()
                .fill(Color.gray.opacity(0.35))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
                .accessibilityHidden(true)

            // Header (tap to expand)
            header
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.86, blendDuration: 0.1)) {
                        isExpanded = true
                    }
                }

            // IMPORTANT:
            // When expanded -> wrap everything below in a vertical ScrollView
            if isExpanded {
                ScrollView(.vertical, showsIndicators: true) {
                    expandedBody(items: items)
                        .padding(.bottom, 12)
                }
            } else {
                collapsedBody(items: items)
            }
        }
        .padding(.bottom, 8 + geo.safeAreaInsets.bottom)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: 10)
        )
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(goal.name)
                    .font(.headline)
                Spacer()
                Text(remainingText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Goal bar
            VStack(alignment: .leading, spacing: 6) {
                let progress = progressRatio
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.gray.opacity(0.18))
                        .frame(height: 10)

                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.green)
                        .frame(width: barWidth(for: progress), height: 10)
                        .animation(.easeInOut(duration: 0.25), value: progress)
                }

                HStack {
                    Text("\(currentText) saved")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("Target \(targetText)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Collapsed (preview)

    private func collapsedBody(items: [(date: Date, amount: Double)]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            scheduleRow

            Divider().padding(.horizontal, 16)

            VStack(alignment: .leading, spacing: 10) {
                Text("Upcoming payments")
                    .font(.headline)
                    .padding(.horizontal, 16)

                if !hasSchedule {
                    Text("No schedule set. Add a schedule to see your plan.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)

                } else if items.isEmpty {
                    Text("You’ve already reached this goal.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)

                } else {
                    // show only first 3 in collapsed mode
                    let preview = Array(items.prefix(3))
                    listBlock(items: preview)
                        .padding(.bottom, 8)

                    Text("Tap to expand")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.34, dampingFraction: 0.86, blendDuration: 0.1)) {
                    isExpanded = true
                }
            }
        }
    }

    // MARK: - Expanded (scrolling)

    private func expandedBody(items: [(date: Date, amount: Double)]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            scheduleRow

            Divider().padding(.horizontal, 16)

            VStack(alignment: .leading, spacing: 10) {
                Text("Upcoming payments")
                    .font(.headline)
                    .padding(.horizontal, 16)

                if !hasSchedule {
                    Text("No schedule set. Add a schedule to see your plan.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)

                } else if items.isEmpty {
                    Text("You’ve already reached this goal.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)

                } else {
                    // FULL list scrolls (because expandedBody is inside ScrollView)
                    listBlock(items: items)
                        .padding(.bottom, 8)
                }
            }
        }
    }

    // MARK: - Shared rows

    private var scheduleRow: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "calendar.badge.clock")
                .foregroundColor(.green)
            Text(scheduleSummary)
                .font(.subheadline)
                .foregroundColor(hasSchedule ? .primary : .secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(.horizontal, 16)
    }

    private func listBlock(items: [(date: Date, amount: Double)]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { idx, entry in
                paymentRow(date: entry.date, amount: entry.amount)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                if idx != items.count - 1 {
                    Divider().padding(.horizontal, 16)
                }
            }
        }
    }

    private func paymentRow(date: Date, amount: Double) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(dateString(date))
                    .font(.subheadline.weight(.semibold))
                Text("Planned contribution")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(currency(amount))
                .font(.headline.monospacedDigit())
        }
    }

    // MARK: - Formatting / helpers

    private var progressRatio: CGFloat {
        let total = max(goal.targetAmount, 0.01)
        return CGFloat(min(max(goal.currentSaved / total, 0), 1))
    }

    private var currentText: String { currency(goal.currentSaved) }
    private var targetText: String { currency(goal.targetAmount) }

    private var remainingText: String {
        let left = max(goal.targetAmount - goal.currentSaved, 0)
        return "Left \(currency(left))"
    }

    private func barWidth(for ratio: CGFloat) -> CGFloat {
        let screenW = UIScreen.main.bounds.width
        let usable = max(0, screenW - 32)
        return usable * ratio
    }

    private func currency(_ value: Double) -> String {
        value.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
    }

    private func dateString(_ date: Date) -> String {
        DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none)
    }
}
