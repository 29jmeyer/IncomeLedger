import Foundation

struct JobPayPeriodOverride: Identifiable, Codable, Equatable {
    let id: UUID = UUID()
    let jobId: UUID
    let payDate: Date

    // If set, this amount takes precedence (interpreted as gross; net is derived if needed)
    let overrideAmount: Double?

    // If set and the job is hourly, recompute pay using this hours value
    let overrideHoursWorked: Double?

    init(
        jobId: UUID,
        payDate: Date,
        overrideAmount: Double? = nil,
        overrideHoursWorked: Double? = nil
    ) {
        self.jobId = jobId
        self.payDate = payDate
        self.overrideAmount = overrideAmount
        self.overrideHoursWorked = overrideHoursWorked
    }
}

// MARK: - Helper

/// Returns the effective per-period amount for a job on a given date, considering overrides.
/// - Parameters:
///   - job: The job to evaluate.
///   - date: The date to match against overrides (simple same-day check).
///   - overrides: A list of overrides to search.
///   - useNet: If true, return net; otherwise gross.
/// - Returns: The effective amount (gross or net) for that date.
func effectiveJobAmount(
    for job: Job,
    on date: Date,
    overrides: [JobPayPeriodOverride],
    useNet: Bool
) -> Double {

    // Simple same-day match
    func isSameDay(_ a: Date, _ b: Date) -> Bool {
        Calendar.current.isDate(a, inSameDayAs: b)
    }

    if let match = overrides.first(where: { $0.jobId == job.id && isSameDay($0.payDate, date) }) {
        // 1) Direct override amount takes precedence
        if let amount = match.overrideAmount {
            if useNet {
                // If job applies tax and has a rate, derive net from gross override
                if job.appliesTax, let t = job.taxRate, t > 0 {
                    return amount * (1.0 - t)
                } else {
                    return amount
                }
            } else {
                return amount
            }
        }

        // 2) Recompute hourly using override hours
        if let hours = match.overrideHoursWorked, job.type == .hourly {
            let rate = job.hourlyRate ?? 0
            let usesOT = job.usesOvertime
            let threshold = job.overtimeThreshold ?? 0
            let multiplier = job.overtimeMultiplier ?? 1.5

            // Compute gross using override hours with the same OT rules as Job
            let gross: Double = {
                guard rate > 0 else { return 0 }
                if usesOT, hours > threshold {
                    let baseHours = threshold
                    let overtimeHours = hours - threshold
                    let basePay = baseHours * rate
                    let otPay   = overtimeHours * rate * multiplier
                    return basePay + otPay
                } else {
                    return hours * rate
                }
            }()

            if useNet {
                if job.appliesTax, let t = job.taxRate, t > 0 {
                    return gross * (1.0 - t)
                } else {
                    return gross
                }
            } else {
                return gross
            }
        }
    }

    // 3) Fall back to the job's standard per-period projection
    return useNet ? job.projectedNetPerPeriod() : job.projectedGrossPerPeriod()
}
