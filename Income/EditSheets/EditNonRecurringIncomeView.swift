import SwiftUI

struct EditNonRecurringIncomeView: View {

    @Environment(\.dismiss) private var dismiss

    let item: NonRecurringIncome
    let onSave: (NonRecurringIncome) -> Void

    @State private var name: String = ""
    @State private var amountText: String = ""
    @State private var date: Date = Date()
    @State private var appliesTax: Bool = false
    @State private var taxRateText: String = "20"

    @State private var showValidationError: Bool = false

    init(item: NonRecurringIncome, onSave: @escaping (NonRecurringIncome) -> Void) {
        self.item = item
        self.onSave = onSave

        _name = State(initialValue: item.name)
        _amountText = State(initialValue: String(item.amount))
        _date = State(initialValue: item.date)
        _appliesTax = State(initialValue: item.appliesTax)
        _taxRateText = State(initialValue: item.taxRate.map { String($0 * 100) } ?? "20")
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Edit non‑recurring income")
                            .font(.headline)

                        TextField("Name", text: $name)
                            .textFieldStyle(.roundedBorder)

                        DatePicker("Date", selection: $date, displayedComponents: .date)
                            .datePickerStyle(.compact)

                        TextField("Amount", text: $amountText)
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
              let amount = Double(amountText.replacingOccurrences(of: ",", with: ".")) else {
            showValidationError = true
            return
        }

        var updated = item
        updated.name = trimmedName
        updated.amount = amount
        updated.date = date
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
