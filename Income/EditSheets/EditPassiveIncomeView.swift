import SwiftUI

struct EditPassiveIncomeView: View {

    @Environment(\.dismiss) private var dismiss

    let item: PassiveIncome
    let onSave: (PassiveIncome) -> Void

    // Fields (prefilled)
    @State private var name: String = ""
    @State private var amountPerPeriodText: String = ""

    // Recurrence
    @State private var intervalDaysText: String = "30"
    @State private var startDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var hasEndDate: Bool = false
    @State private var endDate: Date = Calendar.current.startOfDay(for: Date())

    // Tax
    @State private var appliesTax: Bool = false
    @State private var taxRateText: String = "20"

    // Validation
    @State private var showValidationError: Bool = false

    init(item: PassiveIncome, onSave: @escaping (PassiveIncome) -> Void) {
        self.item = item
        self.onSave = onSave

        _name = State(initialValue: item.name)
        _amountPerPeriodText = State(initialValue: String(item.amountPerPeriod))

        _intervalDaysText = State(initialValue: String(item.intervalDays))
        _startDate = State(initialValue: item.startDate)
        _hasEndDate = State(initialValue: item.endDate != nil)
        _endDate = State(initialValue: item.endDate ?? Calendar.current.startOfDay(for: Date()))

        _appliesTax = State(initialValue: item.appliesTax)
        _taxRateText = State(initialValue: item.taxRate.map { String($0 * 100) } ?? "20")
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Top card (mirrors AddPassiveIncomeView)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Edit passive income")
                            .font(.headline)

                        TextField("Name", text: $name)
                            .textFieldStyle(.roundedBorder)

                        // Recurrence
                        Text("Recurrence")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        HStack {
                            Text("Interval (days)")
                            Spacer()
                            TextField("e.g. 30", text: $intervalDaysText)
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

                        TextField("Amount per period", text: $amountPerPeriodText)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: 10)
                    )

                    // Tax card (matches Add)
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

                    if showValidationError {
                        Text("Please fill in all required fields.")
                            .font(.footnote)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button {
                        saveEdits()
                    } label: {
                        Text("Save")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Capsule().fill(Color.black))
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

    private func saveEdits() {
        showValidationError = false

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty,
              let amount = Double(amountPerPeriodText.replacingOccurrences(of: ",", with: ".")),
              let intervalDays = Int(intervalDaysText), intervalDays > 0
        else {
            showValidationError = true
            return
        }

        var updated = item
        updated.name = trimmedName
        updated.amountPerPeriod = amount
        updated.intervalDays = intervalDays
        updated.startDate = Calendar.current.startOfDay(for: startDate)
        updated.endDate = hasEndDate ? Calendar.current.startOfDay(for: endDate) : nil
        updated.appliesTax = appliesTax

        if appliesTax {
            guard let t = Double(taxRateText.replacingOccurrences(of: ",", with: ".")) else {
                showValidationError = true
                return
            }
            updated.taxRate = t / 100.0
        } else {
            updated.taxRate = nil
        }

        onSave(updated)
        dismiss()
    }
}
