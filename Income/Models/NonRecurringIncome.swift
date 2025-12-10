import SwiftUI

struct NonRecurringIncome: Identifiable, Codable {
    let id: UUID
    var name: String
    var amount: Double
    var date: Date
    var appliesTax: Bool
    var taxRate: Double?   // expressed as 0.20 = 20%

    init(
        id: UUID = UUID(),
        name: String,
        amount: Double,
        date: Date,
        appliesTax: Bool,
        taxRate: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.date = date
        self.appliesTax = appliesTax
        self.taxRate = taxRate
    }

    // MARK: - One-time projections

    func projectedGross() -> Double {
        amount
    }

    func projectedNet() -> Double {
        let gross = projectedGross()
        guard appliesTax, let t = taxRate, t > 0 else { return gross }
        return gross * (1.0 - t)
    }
}

