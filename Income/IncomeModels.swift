import SwiftUI

// MARK: - Models

enum JobType: String, CaseIterable, Identifiable, Codable {
    case salary = "Salary"
    case hourly = "Hourly"
    case contract = "Contract"

    var id: String { rawValue }
}

struct Job: Identifiable, Codable {
    let id: UUID
    var name: String
    var type: JobType

    // Recurrence (replaces PayFrequency)
    var intervalDays: Int            // e.g., 7, 14, 30, 4, etc.
    var startDate: Date              // first payable date
    var endDate: Date?               // optional end date (nil = unbounded)

    // Salary
    var salaryPerPeriod: Double?

    // Hourly
    var hourlyRate: Double?
    var plannedHoursPerPeriod: Double?
    var overtimeThreshold: Double?
    var overtimeMultiplier: Double?
    var usesOvertime: Bool

    // Contract
    var contractRatePerUnit: Double?
    var expectedUnitsPerPeriod: Double?

    var appliesTax: Bool
    var taxRate: Double?

    init(
        id: UUID = UUID(),
        name: String,
        type: JobType,
        intervalDays: Int,
        startDate: Date,
        endDate: Date? = nil,
        salaryPerPeriod: Double? = nil,
        hourlyRate: Double? = nil,
        plannedHoursPerPeriod: Double? = nil,
        overtimeThreshold: Double? = nil,
        overtimeMultiplier: Double? = nil,
        usesOvertime: Bool,
        contractRatePerUnit: Double? = nil,
        expectedUnitsPerPeriod: Double? = nil,
        appliesTax: Bool,
        taxRate: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.intervalDays = intervalDays
        self.startDate = startDate
        self.endDate = endDate
        self.salaryPerPeriod = salaryPerPeriod
        self.hourlyRate = hourlyRate
        self.plannedHoursPerPeriod = plannedHoursPerPeriod
        self.overtimeThreshold = overtimeThreshold
        self.overtimeMultiplier = overtimeMultiplier
        self.usesOvertime = usesOvertime
        self.contractRatePerUnit = contractRatePerUnit
        self.expectedUnitsPerPeriod = expectedUnitsPerPeriod
        self.appliesTax = appliesTax
        self.taxRate = taxRate
    }

    // MARK: - Per-period projections

    func projectedGrossPerPeriod() -> Double {
        switch type {
        case .salary:
            return salaryPerPeriod ?? 0

        case .hourly:
            guard let rate = hourlyRate,
                  let hours = plannedHoursPerPeriod else { return 0 }

            if usesOvertime,
               let threshold = overtimeThreshold,
               let multi = overtimeMultiplier {

                if hours > threshold {
                    let baseHours = threshold
                    let overtimeHours = hours - threshold
                    let basePay = baseHours * rate
                    let otPay   = overtimeHours * rate * multi
                    return basePay + otPay
                } else {
                    return hours * rate
                }
            } else {
                return hours * rate
            }

        case .contract:
            guard let rate = contractRatePerUnit,
                  let units = expectedUnitsPerPeriod else { return 0 }
            return rate * units
        }
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

