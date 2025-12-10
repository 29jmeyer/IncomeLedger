import Foundation

struct NonRecurringIncomeOverride: Identifiable, Codable, Equatable {
    let id: UUID = UUID()
    let nonRecurringId: UUID
    let date: Date
    let overrideAmount: Double?

    init(nonRecurringId: UUID, date: Date, overrideAmount: Double? = nil) {
        self.nonRecurringId = nonRecurringId
        self.date = date
        self.overrideAmount = overrideAmount
    }
}

// MARK: - Helper

/// Returns the effective amount for a non‑recurring income on a given date, considering overrides.
/// - Parameters:
///   - item: The non‑recurring income item.
///   - date: The date to match against overrides (same‑day check).
///   - overrides: The overrides collection.
///   - useNet: If true, return net; otherwise gross.
/// - Returns: The effective amount (gross or net) for that date.
func effectiveNonRecurringAmount(
    for item: NonRecurringIncome,
    on date: Date,
    overrides: [NonRecurringIncomeOverride],
    useNet: Bool
) -> Double {
    func isSameDay(_ a: Date, _ b: Date) -> Bool {
        Calendar.current.isDate(a, inSameDayAs: b)
    }

    if let match = overrides.first(where: { $0.nonRecurringId == item.id && isSameDay($0.date, date) }),
       let amount = match.overrideAmount {
        if useNet {
            if item.appliesTax, let t = item.taxRate, t > 0 {
                return amount * (1.0 - t)
            } else {
                return amount
            }
        } else {
            return amount
        }
    }

    return useNet ? item.projectedNet() : item.projectedGross()
}
