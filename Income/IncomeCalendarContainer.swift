import SwiftUI

struct IncomeCalendarContainer: View {
    let jobs: [Job]
    let passiveIncomes: [PassiveIncome]
    let nonRecurringIncomes: [NonRecurringIncome]
    @Binding var overrides: [JobPayPeriodOverride]
    @Binding var passiveOverrides: [PassiveIncomeOverride]
    @Binding var nonRecurringOverrides: [NonRecurringIncomeOverride]
    @Binding var useNet: Bool
    @Binding var showCalendarMode: Bool

    var onDeleteOneTime: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerWithModeSwitch
            IncomeCalendarView(
                jobs: jobs,
                passiveIncomes: passiveIncomes,
                nonRecurringIncomes: nonRecurringIncomes,
                overrides: $overrides,
                passiveOverrides: $passiveOverrides,
                nonRecurringOverrides: $nonRecurringOverrides,
                useNet: $useNet,
                onDeleteOneTime: onDeleteOneTime
            )
        }
        .padding(.horizontal, 20)
    }

    private var headerWithModeSwitch: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                togglePill(title: "Summary", isOn: !showCalendarMode) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showCalendarMode = false
                    }
                }
                togglePill(title: "Calendar", isOn: showCalendarMode) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showCalendarMode = true
                    }
                }
                Spacer()
            }
        }
    }

    private func togglePill(title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isOn ? Color.green.opacity(0.9) : Color.gray.opacity(0.2))
                )
                .foregroundColor(isOn ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}
