import Foundation

struct PassiveIncomeOverride: Identifiable, Codable, Equatable {
    let id: UUID = UUID()
    let passiveIncomeId: UUID
    let date: Date
    let overrideAmount: Double?

    init(passiveIncomeId: UUID, date: Date, overrideAmount: Double? = nil) {
        self.passiveIncomeId = passiveIncomeId
        self.date = date
        self.overrideAmount = overrideAmount
    }
}

// MARK: - Helper

/// Returns the effective per-period amount for a passive income on a given date, considering overrides.
/// - Parameters:
///   - item: The passive income source.
///   - date: The date to match against overrides (same-day check).
///   - overrides: The passive overrides collection.
///   - useNet: If true, return net; otherwise gross.
/// - Returns: The effective amount (gross or net) for that date.
func effectivePassiveAmount(
    for item: PassiveIncome,
    on date: Date,
    overrides: [PassiveIncomeOverride],
    useNet: Bool
) -> Double {
    func isSameDay(_ a: Date, _ b: Date) -> Bool {
        Calendar.current.isDate(a, inSameDayAs: b)
    }

    if let match = overrides.first(where: { $0.passiveIncomeId == item.id && isSameDay($0.date, date) }),
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

    return useNet ? item.projectedNetPerPeriod() : item.projectedGrossPerPeriod()
}
