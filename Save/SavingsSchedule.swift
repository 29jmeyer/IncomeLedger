import Foundation

enum SavingsSchedule {

    struct Entry: Equatable {
        let date: Date
        let amount: Double
    }

    // MARK: - Deterministic full plan builder (to completion)

    static func fullPlan(for goal: SavingsGoal, now: Date = Date()) -> [SavingsPlannedEntry] {
        guard (goal.useSchedule ?? false),
              let per = goal.scheduleAmount, per > 0,
              let interval = goal.intervalDays, interval > 0
        else { return [] }

        let cal = Calendar.current
        let start = cal.startOfDay(for: goal.startDate ?? now)

        var remaining = max(goal.targetAmount - goal.currentSaved, 0)
        guard remaining > 0 else { return [] }

        var out: [SavingsPlannedEntry] = []
        var cursor = start

        while remaining > 0 {
            let allocation = min(per, remaining)
            out.append(SavingsPlannedEntry(date: cursor, amount: allocation))
            remaining -= allocation

            if remaining <= 0 { break }
            guard let next = cal.date(byAdding: .day, value: interval, to: cursor) else { break }
            cursor = cal.startOfDay(for: next)
        }
        return out
    }

    // MARK: - Apply delta to a persisted plan
    // Positive delta = user adds money -> consume from most recent upcoming entry first (index 0 forward)
    // Negative delta = user removes money -> append new entries after the last, spaced by intervalDays

    static func applyDelta(
        _ delta: Double,
        to entries: inout [SavingsPlannedEntry],
        intervalDays: Int,
        per: Double,
        startDate: Date
    ) {
        guard intervalDays > 0, per > 0 else { return }
        let cal = Calendar.current

        if delta > 0 {
            // ADD money: consume from the most recent (front of the array) forward
            var remaining = delta
            var i = 0
            while remaining > 0, i < entries.count {
                let amt = entries[i].amount
                if remaining >= amt {
                    remaining -= amt
                    // remove this entry entirely
                    entries.remove(at: i)
                    // do not increment i, because the next item shifts into position i
                } else {
                    // partial consume
                    entries[i].amount = amt - remaining
                    remaining = 0
                }
            }
            // If remaining > 0 after loop, it means user added more than the total planned — plan can be empty now. That's acceptable.

        } else if delta < 0 {
            // REMOVE money: append new entries after the last, spaced by intervalDays
            var need = -delta

            // Determine the first date to append at
            let anchor = entries.last?.date ?? startDate
            var cursor: Date
            if entries.isEmpty {
                cursor = cal.startOfDay(for: anchor) // startDate
            } else {
                // strictly after the last existing entry
                let next = cal.date(byAdding: .day, value: intervalDays, to: anchor) ?? anchor
                cursor = cal.startOfDay(for: next)
            }

            while need > 0 {
                let allocation = min(per, need)
                entries.append(SavingsPlannedEntry(date: cursor, amount: allocation))
                need -= allocation
                if need <= 0 { break }
                if let next = cal.date(byAdding: .day, value: intervalDays, to: cursor) {
                    cursor = cal.startOfDay(for: next)
                } else {
                    break
                }
            }
        }
    }

    // MARK: - Preview-only computation (earliest-first, deterministic)
    // Kept for fallback/legacy display if a goal lacks plannedEntries.

    static func computeUpcomingPayments(
        for goal: SavingsGoal,
        maxCount: Int = 30,
        now: Date = Date()
    ) -> [Entry] {
        guard (goal.useSchedule ?? false),
              let per = goal.scheduleAmount, per > 0,
              let interval = goal.intervalDays, interval > 0
        else {
            return []
        }

        let cal = Calendar.current
        let start = cal.startOfDay(for: goal.startDate ?? now)

        var remaining = max(goal.targetAmount - goal.currentSaved, 0)
        guard remaining > 0 else { return [] }

        let neededCountExact = remaining / per
        let neededCount = Int(ceil(neededCountExact))
        let generateCount = max(neededCount, maxCount)

        var entries: [Entry] = []
        entries.reserveCapacity(generateCount)

        var cursor = start
        var i = 0

        while remaining > 0 && i < generateCount {
            let allocation = min(per, remaining)
            entries.append(Entry(date: cursor, amount: allocation))
            remaining -= allocation

            if let next = cal.date(byAdding: .day, value: interval, to: cursor) {
                cursor = cal.startOfDay(for: next)
            } else {
                break
            }

            i += 1
        }

        while remaining > 0 {
            let allocation = min(per, remaining)
            entries.append(Entry(date: cursor, amount: allocation))
            remaining -= allocation

            if let next = cal.date(byAdding: .day, value: interval, to: cursor) {
                cursor = cal.startOfDay(for: next)
            } else {
                break
            }
        }

        if entries.count > maxCount {
            return Array(entries.prefix(maxCount))
        } else {
            return entries
        }
    }
}
