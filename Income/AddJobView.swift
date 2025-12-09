import SwiftUI

// MARK: - Add Job Sheet (custom)

struct AddJobView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var type: JobType = .salary

    // Recurrence inputs
    @State private var intervalDaysText: String = "14"
    @State private var startDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var hasEndDate: Bool = false
    @State private var endDate: Date = Calendar.current.startOfDay(for: Date())

    @State private var salaryPerPeriodText: String = ""

    @State private var hourlyRateText: String = ""
    @State private var plannedHoursText: String = ""
    @State private var overtimeThresholdText: String = "44"
    @State private var overtimeMultiplierText: String = "1.5"
    @State private var usesOvertime: Bool = true

    @State private var contractRateText: String = ""
    @State private var expectedUnitsText: String = ""

    @State private var appliesTax: Bool = false
    @State private var taxRateText: String = "20"

    @State private var showValidationError: Bool = false

    let onSave: (Job) -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {

                    // Top “card”
                    VStack(alignment: .leading, spacing: 16) {
                        Text("New job")
                            .font(.headline)

                        TextField("Job name", text: $name)
                            .textFieldStyle(.roundedBorder)

                        HStack {
                            Text("Type")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                        }

                        // Segmented style for job type
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

                    // Job-type specific card
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
                        saveJob()
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

    // MARK: - Cards

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

    // MARK: - Save

    private func saveJob() {
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
        let chosenEndDate: Date? = hasEndDate ? endDate : nil

        var newJob = Job(
            name: trimmedName,
            type: type,
            intervalDays: intervalDays,
            startDate: Calendar.current.startOfDay(for: startDate),
            endDate: chosenEndDate.map { Calendar.current.startOfDay(for: $0) },
            salaryPerPeriod: nil,
            hourlyRate: nil,
            plannedHoursPerPeriod: nil,
            overtimeThreshold: nil,
            overtimeMultiplier: nil,
            usesOvertime: usesOvertime,
            contractRatePerUnit: nil,
            expectedUnitsPerPeriod: nil,
            appliesTax: appliesTax,
            taxRate: nil
        )

        switch type {
        case .salary:
            guard let salary = parseDouble(salaryPerPeriodText) else {
                showValidationError = true
                return
            }
            newJob.salaryPerPeriod = salary

        case .hourly:
            guard let rate = parseDouble(hourlyRateText),
                  let hours = parseDouble(plannedHoursText) else {
                showValidationError = true
                return
            }
            newJob.hourlyRate = rate
            newJob.plannedHoursPerPeriod = hours

            if usesOvertime {
                guard let threshold = parseDouble(overtimeThresholdText),
                      let multi = parseDouble(overtimeMultiplierText) else {
                    showValidationError = true
                    return
                }
                newJob.overtimeThreshold = threshold
                newJob.overtimeMultiplier = multi
            }

        case .contract:
            guard let rate = parseDouble(contractRateText),
                  let units = parseDouble(expectedUnitsText) else {
                showValidationError = true
                return
            }
            newJob.contractRatePerUnit = rate
            newJob.expectedUnitsPerPeriod = units
        }

        if appliesTax {
            if let t = parseDouble(taxRateText) {
                newJob.taxRate = t / 100.0
            } else {
                showValidationError = true
                return
            }
        }

        onSave(newJob)
        dismiss()
    }
}
