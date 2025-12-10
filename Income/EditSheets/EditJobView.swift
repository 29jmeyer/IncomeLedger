import SwiftUI

// MARK: - Edit Job Sheet (modern “card” layout to match AddJobView)

struct EditJobView: View {

    @Environment(\.dismiss) private var dismiss

    let job: Job
    let onSave: (Job) -> Void

    // Core fields
    @State private var name: String = ""
    @State private var type: JobType = .salary

    // Recurrence
    @State private var intervalDaysText: String = "14"
    @State private var startDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var hasEndDate: Bool = false
    @State private var endDate: Date = Calendar.current.startOfDay(for: Date())

    // Salary
    @State private var salaryPerPeriodText: String = ""

    // Hourly
    @State private var hourlyRateText: String = ""
    @State private var plannedHoursText: String = ""
    @State private var overtimeThresholdText: String = "44"
    @State private var overtimeMultiplierText: String = "1.5"
    @State private var usesOvertime: Bool = true

    // Contract
    @State private var contractRateText: String = ""
    @State private var expectedUnitsText: String = ""

    // Tax
    @State private var appliesTax: Bool = false
    @State private var taxRateText: String = "20"

    // Validation
    @State private var showValidationError: Bool = false

    // Prefill from existing job
    init(job: Job, onSave: @escaping (Job) -> Void) {
        self.job = job
        self.onSave = onSave

        _name = State(initialValue: job.name)
        _type = State(initialValue: job.type)

        _intervalDaysText = State(initialValue: String(job.intervalDays))
        _startDate = State(initialValue: job.startDate)
        _hasEndDate = State(initialValue: job.endDate != nil)
        _endDate = State(initialValue: job.endDate ?? Calendar.current.startOfDay(for: Date()))

        _salaryPerPeriodText = State(initialValue: job.salaryPerPeriod.map { String($0) } ?? "")

        _hourlyRateText = State(initialValue: job.hourlyRate.map { String($0) } ?? "")
        _plannedHoursText = State(initialValue: job.plannedHoursPerPeriod.map { String($0) } ?? "")
        _overtimeThresholdText = State(initialValue: job.overtimeThreshold.map { String($0) } ?? "44")
        _overtimeMultiplierText = State(initialValue: job.overtimeMultiplier.map { String($0) } ?? "1.5")
        _usesOvertime = State(initialValue: job.usesOvertime)

        _contractRateText = State(initialValue: job.contractRatePerUnit.map { String($0) } ?? "")
        _expectedUnitsText = State(initialValue: job.expectedUnitsPerPeriod.map { String($0) } ?? "")

        _appliesTax = State(initialValue: job.appliesTax)
        _taxRateText = State(initialValue: job.taxRate.map { String($0 * 100) } ?? "20")
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {

                    // Top “Job details” card (mirrors AddJobView)
                    jobDetailsCard

                    // Job-type specific card (salary / hourly / contract)
                    jobTypeCard

                    // Tax card
                    taxCard

                    if showValidationError {
                        Text("Please fill in the required fields for this job type.")
                            .font(.footnote)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Spacer(minLength: 20)

                    Button {
                        saveEdits()
                    } label: {
                        Text("Save")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                Capsule().fill(Color.black)
                            )
                            .foregroundColor(.white)
                    }
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Cards

    private var jobDetailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Job details")
                .font(.headline)

            TextField("Job name", text: $name)
                .textFieldStyle(.roundedBorder)

            HStack {
                Text("Type")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }

            // Segmented style for job type (pills)
            HStack(spacing: 8) {
                ForEach(JobType.allCases) { t in
                    Button {
                        type = t
                    } label: {
                        Text(t.rawValue)
                            .font(.footnote.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity)
                            .background(
                                Capsule()
                                    .fill(type == t
                                          ? Color.black.opacity(0.85)
                                          : Color.gray.opacity(0.15))
                            )
                            .foregroundColor(type == t ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Recurrence
            VStack(alignment: .leading, spacing: 8) {
                Text("Recurrence")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack {
                    Text("Interval (days)")
                    Spacer()
                    TextField("e.g. 14", text: $intervalDaysText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .textFieldStyle(.roundedBorder)
                }

                DatePicker("Start date", selection: $startDate, displayedComponents: .date)

                Toggle("Has end date", isOn: $hasEndDate)

                if hasEndDate {
                    DatePicker("End date", selection: $endDate, displayedComponents: .date)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: 10)
        )
    }

    @ViewBuilder
    private var jobTypeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch type {
            case .salary:
                Text("Salary")
                    .font(.subheadline.bold())
                TextField("Amount per pay period", text: $salaryPerPeriodText)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)

            case .hourly:
                Text("Hourly setup")
                    .font(.subheadline.bold())

                TextField("Hourly rate", text: $hourlyRateText)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)

                TextField("Planned hours per period", text: $plannedHoursText)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)

                Toggle("Use overtime rules", isOn: $usesOvertime)

                if usesOvertime {
                    TextField("Overtime after how many hours?", text: $overtimeThresholdText)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)

                    TextField("Overtime multiplier (e.g. 1.5)", text: $overtimeMultiplierText)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                }

            case .contract:
                Text("Contract / gig")
                    .font(.subheadline.bold())

                TextField("Pay per unit (gig / contract)", text: $contractRateText)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)

                TextField("Expected units per period", text: $expectedUnitsText)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08),
                        radius: 10, x: 0, y: 6)
        )
    }

    private var taxCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tax (optional)")
                .font(.subheadline.bold())

            Toggle("Apply estimated tax", isOn: $appliesTax)

            if appliesTax {
                HStack {
                    Text("Tax rate (%)")
                    Spacer()
                    TextField("e.g. 20", text: $taxRateText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08),
                        radius: 10, x: 0, y: 6)
        )
    }

    // MARK: - Save logic (unchanged validation paths)

    private func saveEdits() {
        showValidationError = false

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            showValidationError = true
            return
        }

        func parseDouble(_ text: String) -> Double? {
            let cleaned = text.replacingOccurrences(of: ",", with: ".")
            return Double(cleaned)
        }

        guard let intervalDays = Int(intervalDaysText), intervalDays > 0 else {
            showValidationError = true
            return
        }

        var updatedJob = job
        updatedJob.name = trimmedName
        updatedJob.type = type

        updatedJob.intervalDays = intervalDays
        updatedJob.startDate = Calendar.current.startOfDay(for: startDate)
        updatedJob.endDate = hasEndDate ? Calendar.current.startOfDay(for: endDate) : nil

        updatedJob.usesOvertime = usesOvertime
        updatedJob.appliesTax = appliesTax

        // Reset all type-specific fields before reapplying
        updatedJob.salaryPerPeriod = nil
        updatedJob.hourlyRate = nil
        updatedJob.plannedHoursPerPeriod = nil
        updatedJob.overtimeThreshold = nil
        updatedJob.overtimeMultiplier = nil
        updatedJob.contractRatePerUnit = nil
        updatedJob.expectedUnitsPerPeriod = nil

        switch type {
        case .salary:
            guard let salary = parseDouble(salaryPerPeriodText) else {
                showValidationError = true
                return
            }
            updatedJob.salaryPerPeriod = salary

        case .hourly:
            guard let rate = parseDouble(hourlyRateText),
                  let hours = parseDouble(plannedHoursText) else {
                showValidationError = true
                return
            }
            updatedJob.hourlyRate = rate
            updatedJob.plannedHoursPerPeriod = hours

            if usesOvertime {
                guard let threshold = parseDouble(overtimeThresholdText),
                      let multi = parseDouble(overtimeMultiplierText) else {
                    showValidationError = true
                    return
                }
                updatedJob.overtimeThreshold = threshold
                updatedJob.overtimeMultiplier = multi
            }

        case .contract:
            guard let rate = parseDouble(contractRateText),
                  let units = parseDouble(expectedUnitsText) else {
                showValidationError = true
                return
            }
            updatedJob.contractRatePerUnit = rate
            updatedJob.expectedUnitsPerPeriod = units
        }

        if appliesTax {
            if let t = parseDouble(taxRateText) {
                updatedJob.taxRate = t / 100.0
            } else {
                showValidationError = true
                return
            }
        } else {
            updatedJob.taxRate = nil
        }

        onSave(updatedJob)
        dismiss()
    }
}
