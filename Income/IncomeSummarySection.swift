import SwiftUI

struct IncomeSummarySection: View {
    @Binding var jobs: [Job]
    @Binding var passiveIncomes: [PassiveIncome]
    @Binding var nonRecurringIncomes: [NonRecurringIncome]

    @Binding var showAddJobSheet: Bool
    @Binding var showAddPassiveIncomeSheet: Bool
    @Binding var showAddNonRecurringIncomeSheet: Bool

    @Binding var showNetInSummary: Bool
    @Binding var showCalendarMode: Bool

    @Binding var jobBeingEdited: Job?
    @Binding var jobPendingDelete: Job?
    @Binding var showDeleteJobAlert: Bool

    @Binding var passiveBeingEdited: PassiveIncome?
    @Binding var passivePendingDelete: PassiveIncome?
    @Binding var showDeletePassiveAlert: Bool

    @Binding var nonRecurringBeingEdited: NonRecurringIncome?
    @Binding var nonRecurringPendingDelete: NonRecurringIncome?
    @Binding var showDeleteNonRecurringAlert: Bool

    @Binding var passiveOverrides: [PassiveIncomeOverride]
    @Binding var nonRecurringOverrides: [NonRecurringIncomeOverride]

    @Binding var showNonRecurringToast: Bool

    let saveSnapshot: () -> Void

    // Reuse closures/views from IncomeView to avoid duplicating logic
    let deleteDialogOverlay: (_ title: String, _ message: String, _ deleteLabel: String, _ onDelete: @escaping () -> Void, _ onDismiss: @escaping () -> Void) -> AnyView
    let formattedCurrency: (Double) -> String
    let formattedDate: (Date) -> String
    let togglePill: (_ title: String, _ isOn: Bool, _ action: @escaping () -> Void) -> AnyViewConvertible
    let jobCard: (Job) -> AnyViewConvertible
    let passiveIncomeCard: (PassiveIncome) -> AnyViewConvertible
    let addJobCard: () -> AnyViewConvertible
    let addPassiveIncomeCard: () -> AnyViewConvertible
    let addNonRecurringIncomeCard: () -> AnyViewConvertible
    let summaryCard: () -> AnyViewConvertible
    let headerWithModeSwitch: () -> AnyViewConvertible
    let sectionDivider: () -> AnyViewConvertible

    init(
        jobs: Binding<[Job]>,
        passiveIncomes: Binding<[PassiveIncome]>,
        nonRecurringIncomes: Binding<[NonRecurringIncome]>,
        showAddJobSheet: Binding<Bool>,
        showAddPassiveIncomeSheet: Binding<Bool>,
        showAddNonRecurringIncomeSheet: Binding<Bool>,
        showNetInSummary: Binding<Bool>,
        showCalendarMode: Binding<Bool>,
        jobBeingEdited: Binding<Job?>,
        jobPendingDelete: Binding<Job?>,
        showDeleteJobAlert: Binding<Bool>,
        passiveBeingEdited: Binding<PassiveIncome?>,
        passivePendingDelete: Binding<PassiveIncome?>,
        showDeletePassiveAlert: Binding<Bool>,
        nonRecurringBeingEdited: Binding<NonRecurringIncome?>,
        nonRecurringPendingDelete: Binding<NonRecurringIncome?>,
        showDeleteNonRecurringAlert: Binding<Bool>,
        passiveOverrides: Binding<[PassiveIncomeOverride]>,
        nonRecurringOverrides: Binding<[NonRecurringIncomeOverride]>,
        showNonRecurringToast: Binding<Bool>,
        saveSnapshot: @escaping () -> Void,
        deleteDialogOverlay: @escaping (_ title: String, _ message: String, _ deleteLabel: String, _ onDelete: @escaping () -> Void, _ onDismiss: @escaping () -> Void) -> some View,
        formattedCurrency: @escaping (Double) -> String,
        formattedDate: @escaping (Date) -> String,
        togglePill: @escaping (_ title: String, _ isOn: Bool, _ action: @escaping () -> Void) -> some View,
        jobCard: @escaping (Job) -> some View,
        passiveIncomeCard: @escaping (PassiveIncome) -> some View,
        addJobCard: @escaping () -> some View,
        addPassiveIncomeCard: @escaping () -> some View,
        addNonRecurringIncomeCard: @escaping () -> some View,
        summaryCard: @escaping () -> some View,
        headerWithModeSwitch: @escaping () -> some View,
        sectionDivider: @escaping () -> some View
    ) {
        _jobs = jobs
        _passiveIncomes = passiveIncomes
        _nonRecurringIncomes = nonRecurringIncomes
        _showAddJobSheet = showAddJobSheet
        _showAddPassiveIncomeSheet = showAddPassiveIncomeSheet
        _showAddNonRecurringIncomeSheet = showAddNonRecurringIncomeSheet
        _showNetInSummary = showNetInSummary
        _showCalendarMode = showCalendarMode
        _jobBeingEdited = jobBeingEdited
        _jobPendingDelete = jobPendingDelete
        _showDeleteJobAlert = showDeleteJobAlert
        _passiveBeingEdited = passiveBeingEdited
        _passivePendingDelete = passivePendingDelete
        _showDeletePassiveAlert = showDeletePassiveAlert
        _nonRecurringBeingEdited = nonRecurringBeingEdited
        _nonRecurringPendingDelete = nonRecurringPendingDelete
        _showDeleteNonRecurringAlert = showDeleteNonRecurringAlert
        _passiveOverrides = passiveOverrides
        _nonRecurringOverrides = nonRecurringOverrides
        _showNonRecurringToast = showNonRecurringToast

        self.saveSnapshot = saveSnapshot
        self.deleteDialogOverlay = { title, message, deleteLabel, onDelete, onDismiss in
            AnyView(deleteDialogOverlay(title, message, deleteLabel, onDelete, onDismiss))
        }
        self.formattedCurrency = formattedCurrency
        self.formattedDate = formattedDate
        self.togglePill = { title, isOn, action in AnyViewConvertible(togglePill(title, isOn, action)) }
        self.jobCard = { job in AnyViewConvertible(jobCard(job)) }
        self.passiveIncomeCard = { item in AnyViewConvertible(passiveIncomeCard(item)) }
        self.addJobCard = { AnyViewConvertible(addJobCard()) }
        self.addPassiveIncomeCard = { AnyViewConvertible(addPassiveIncomeCard()) }
        self.addNonRecurringIncomeCard = { AnyViewConvertible(addNonRecurringIncomeCard()) }
        self.summaryCard = { AnyViewConvertible(summaryCard()) }
        self.headerWithModeSwitch = { AnyViewConvertible(headerWithModeSwitch()) }
        self.sectionDivider = { AnyViewConvertible(sectionDivider()) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerWithModeSwitch().asView

                summaryCard().asView

                if !jobs.isEmpty {
                    Text("Jobs")
                        .font(.headline)

                    VStack(spacing: 14) {
                        ForEach(jobs) { job in
                            jobCard(job).asView
                        }
                    }
                }

                addJobCard().asView
                sectionDivider().asView

                if !passiveIncomes.isEmpty {
                    Text("Passive income")
                        .font(.headline)

                    VStack(spacing: 14) {
                        ForEach(passiveIncomes) { item in
                            passiveIncomeCard(item).asView
                        }
                    }
                }

                addPassiveIncomeCard().asView
                sectionDivider().asView

                addNonRecurringIncomeCard().asView

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
}

// Small helper to erase some View without changing original builders
struct AnyViewConvertible {
    let asView: AnyView
    init<V: View>(_ view: V) { self.asView = AnyView(view) }
}
