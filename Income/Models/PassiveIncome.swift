import SwiftUI

struct PassiveIncome: Identifiable, Codable {
    let id: UUID
    var name: String
    var amountPerPeriod: Double

    // Recurrence
    var intervalDays: Int
    var startDate: Date
    var endDate: Date?

    var appliesTax: Bool
    var taxRate: Double?   // expressed as 0.20 = 20%

    init(
        id: UUID = UUID(),
        name: String,
        amountPerPeriod: Double,
        intervalDays: Int,
        startDate: Date,
        endDate: Date? = nil,
        appliesTax: Bool,
        taxRate: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.amountPerPeriod = amountPerPeriod
        self.intervalDays = intervalDays
        self.startDate = startDate
        self.endDate = endDate
        self.appliesTax = appliesTax
        self.taxRate = taxRate
    }

    // MARK: - Per-period projections

    func projectedGrossPerPeriod() -> Double {
        amountPerPeriod
    }

    func projectedNetPerPeriod() -> Double {
        let gross = projectedGrossPerPeriod()
        guard appliesTax, let t = taxRate, t > 0 else { return gross }
        return gross * (1.0 - t)
    }

    // MARK: - Month approximations (based on intervalDays)

    private var avgMonthDays: Double { 30.44 }

    func occurrencesPerMonthApprox() -> Double {
        guard intervalDays > 0 else { return 0 }
        return avgMonthDays / Double(intervalDays)
    }

    func projectedGrossPerMonth() -> Double {
        projectedGrossPerPeriod() * occurrencesPerMonthApprox()
    }

    func projectedNetPerMonth() -> Double {
        projectedNetPerPeriod() * occurrencesPerMonthApprox()
    }
}

