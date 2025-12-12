import SwiftUI

struct MoneyEditView: View {
    enum Mode: String, CaseIterable, Identifiable {
        case add = "Add"
        case remove = "Remove"
        var id: String { rawValue }
    }

    // Inputs
    let goal: SavingsGoal
    let onConfirm: (SavingsGoal) -> Void
    let onConfirmedAdd: () -> Void    // called only when a valid Add occurs

    @Environment(\.dismiss) private var dismiss

    // UI State
    @State private var mode: Mode = .add
    @State private var amountText: String = ""

    // Derived
    private var current: Double { max(0, goal.currentSaved) }
    private var target: Double { max(0, goal.targetAmount) }
    private var remaining: Double { max(0, target - current) }

    private var typedAmount: Double? {
        let cleaned = amountText
            .replacingOccurrences(of: Locale.current.groupingSeparator ?? ",", with: "")
            .replacingOccurrences(of: Locale.current.decimalSeparator ?? ".", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty, let v = Double(cleaned) else { return nil }
        return v
    }

    private var validationMessage: String? {
        guard let amt = typedAmount else { return "Enter an amount" }
        if amt <= 0 { return "Amount must be greater than 0" }

        switch mode {
        case .add:
            if remaining <= 0 { return "Goal already reached" }
            if amt > remaining { return "Cannot add more than remaining (\(currency(remaining)))" }
        case .remove:
            if current <= 0 { return "Nothing to remove" }
            if amt > current { return "Cannot remove more than current (\(currency(current)))" }
        }
        return nil
    }

    private var isConfirmDisabled: Bool { validationMessage != nil }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {

                    // Card: Goal + mode
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Edit savings")
                                .font(.headline)
                            Spacer()
                            Text("\(currency(current)) / \(currency(target))")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.green)
                        }

                        HStack {
                            Text("Goal")
                            Spacer()
                            Text(goal.name)
                                .foregroundStyle(.secondary)
                        }

                        HStack {
                            Text("Left")
                            Spacer()
                            Text(currency(remaining))
                                .foregroundStyle(.secondary)
                        }

                        Picker("Mode", selection: $mode) {
                            ForEach(Mode.allCases) { m in
                                Text(m.rawValue).tag(m)
                            }
                        }
                        .pickerStyle(.segmented)
                        .tint(.green)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 6)
                    )

                    // Amount card
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Amount")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        TextField("$0.00", text: $amountText)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)

                        if let msg = validationMessage {
                            Text(msg)
                                .font(.footnote.weight(.semibold))
                                .foregroundColor(.red)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
                    )

                    Spacer(minLength: 8)

                    Button {
                        confirm()
                    } label: {
                        Text("Confirm")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(isConfirmDisabled ? Color.gray.opacity(0.35) : Color.green)
                            )
                            .foregroundColor(.white)
                    }
                    .disabled(isConfirmDisabled)
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

    private func confirm() {
        guard let amt = typedAmount, amt > 0 else { return }

        var newGoal = goal
        switch mode {
        case .add:
            let allowed = min(amt, remaining)
            newGoal.currentSaved = min(goal.currentSaved + allowed, target)
            onConfirm(newGoal)
            onConfirmedAdd()   // trigger animation only on add
        case .remove:
            let allowed = min(amt, current)
            newGoal.currentSaved = max(goal.currentSaved - allowed, 0)
            onConfirm(newGoal)
        }

        dismiss()
    }

    private func currency(_ value: Double) -> String {
        value.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
    }
}

struct MoneyEditView_Previews: PreviewProvider {
    static var previews: some View {
        let sample = SavingsGoal(
            name: "Holiday",
            targetAmount: 1000,
            currentSaved: 250
        )
        MoneyEditView(goal: sample, onConfirm: { _ in }, onConfirmedAdd: {})
    }
}
