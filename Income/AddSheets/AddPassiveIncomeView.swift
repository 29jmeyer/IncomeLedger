import SwiftUI

struct AddPassiveIncomeView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var amountPerPeriodText: String = ""

    // Recurrence
    @State private var intervalDaysText: String = "30"
    @State private var startDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var hasEndDate: Bool = false
    @State private var endDate: Date = Calendar.current.startOfDay(for: Date())

    @State private var appliesTax: Bool = false
    @State private var taxRateText: String = "20"

    @State private var showValidationError: Bool = false

    let onSave: (PassiveIncome) -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("New passive income")
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
                        saveItem()
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

    private func saveItem() {
        showValidationError = false

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty,
              let amount = Double(amountPerPeriodText.replacingOccurrences(of: ",", with: ".")),
              let intervalDays = Int(intervalDaysText), intervalDays > 0
        else {
            showValidationError = true
            return
        }

        var tax: Double? = nil
        if appliesTax {
            guard let t = Double(taxRateText.replacingOccurrences(of: ",", with: ".")) else {
                showValidationError = true
                return
            }
            tax = t / 100.0
        }

        let item = PassiveIncome(
            name: trimmedName,
            amountPerPeriod: amount,
            intervalDays: intervalDays,
            startDate: Calendar.current.startOfDay(for: startDate),
            endDate: hasEndDate ? Calendar.current.startOfDay(for: endDate) : nil,
            appliesTax: appliesTax,
            taxRate: tax
        )

        onSave(item)
        dismiss()
    }
}
