import SwiftUI

// MARK: - Income View

struct IncomeView: View {

    // Core data
    @State private var jobs: [Job] = []
    @State private var passiveIncomes: [PassiveIncome] = []
    @State private var nonRecurringIncomes: [NonRecurringIncome] = []

    // Sheets
    @State private var showAddJobSheet = false
    @State private var showAddPassiveIncomeSheet = false
    @State private var showAddNonRecurringIncomeSheet = false

    // Gross / Net toggles (split)
    @State private var showNetInSummary = false
    @State private var showNetInCalendar = false

    // Summary vs Calendar mode
    @State private var showCalendarMode = false

    // Overrides for calendar
    @State private var overrides: [JobPayPeriodOverride] = []
    @State private var passiveOverrides: [PassiveIncomeOverride] = []
    @State private var nonRecurringOverrides: [NonRecurringIncomeOverride] = []

    // Edit + delete state (Jobs)
    @State private var jobBeingEdited: Job? = nil
    @State private var jobPendingDelete: Job? = nil
    @State private var showDeleteJobAlert = false

    // Edit + delete state (Passive)
    @State private var passiveBeingEdited: PassiveIncome? = nil
    @State private var passivePendingDelete: PassiveIncome? = nil
    @State private var showDeletePassiveAlert = false

    // Edit + delete state (Non-recurring)
    @State private var nonRecurringBeingEdited: NonRecurringIncome? = nil
    @State private var nonRecurringPendingDelete: NonRecurringIncome? = nil
    @State private var showDeleteNonRecurringAlert = false

    // Toast for non-recurring added
    @State private var showNonRecurringToast = false

    var body: some View {
        NavigationView {
            contentSwitcher
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Income")
                            .font(.headline)
                    }
                }
        }
        // MARK: - Job Sheets / Overlays
        .sheet(isPresented: $showAddJobSheet) {
            AddJobView { newJob in
                jobs.append(newJob)
                saveSnapshot()
            }
        }
        .sheet(item: $jobBeingEdited) { job in
            EditJobView(job: job) { updatedJob in
                if let index = jobs.firstIndex(where: { $0.id == updatedJob.id }) {
                    jobs[index] = updatedJob
                    saveSnapshot()
                }
            }
        }
        .overlay {
            if showDeleteJobAlert, let job = jobPendingDelete {
                deleteDialogOverlay(
                    title: "Delete job?",
                    message: "This will remove \"\(job.name)\" from your income projections.",
                    deleteLabel: "Delete job",
                    onDelete: {
                        if let index = jobs.firstIndex(where: { $0.id == job.id }) {
                            jobs.remove(at: index)
                            saveSnapshot()
                        }
                    },
                    onDismiss: {
                        showDeleteJobAlert = false
                        jobPendingDelete = nil
                    }
                )
            }
        }

        // MARK: - Passive Sheets / Overlays
        .sheet(isPresented: $showAddPassiveIncomeSheet) {
            AddPassiveIncomeView { newItem in
                passiveIncomes.append(newItem)
                saveSnapshot()
            }
        }
        .sheet(item: $passiveBeingEdited) { item in
            EditPassiveIncomeView(item: item) { updated in
                if let index = passiveIncomes.firstIndex(where: { $0.id == updated.id }) {
                    passiveIncomes[index] = updated
                    saveSnapshot()
                }
            }
        }
        .overlay {
            if showDeletePassiveAlert, let item = passivePendingDelete {
                deleteDialogOverlay(
                    title: "Delete passive income?",
                    message: "This will remove \"\(item.name)\" from your income projections.",
                    deleteLabel: "Delete passive income",
                    onDelete: {
                        if let index = passiveIncomes.firstIndex(where: { $0.id == item.id }) {
                            passiveIncomes.remove(at: index)
                            saveSnapshot()
                        }
                    },
                    onDismiss: {
                        showDeletePassiveAlert = false
                        passivePendingDelete = nil
                    }
                )
            }
        }

        // MARK: - Non-recurring Sheets / Overlays
        .sheet(isPresented: $showAddNonRecurringIncomeSheet) {
            AddNonRecurringIncomeView { newItem in
                nonRecurringIncomes.append(newItem)
                // Non-recurring only lives in calendar, but we still snapshot so it persists
                saveSnapshot()
                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                    showNonRecurringToast = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showNonRecurringToast = false
                    }
                }
            }
        }
        .sheet(item: $nonRecurringBeingEdited) { item in
            EditNonRecurringIncomeView(item: item) { updated in
                if let index = nonRecurringIncomes.firstIndex(where: { $0.id == updated.id }) {
                    nonRecurringIncomes[index] = updated
                    saveSnapshot()
                }
            }
        }
        .overlay {
            if showDeleteNonRecurringAlert, let item = nonRecurringPendingDelete {
                deleteDialogOverlay(
                    title: "Delete non-recurring income?",
                    message: "This will remove \"\(item.name)\" from your calendar.",
                    deleteLabel: "Delete non-recurring",
                    onDelete: {
                        if let index = nonRecurringIncomes.firstIndex(where: { $0.id == item.id }) {
                            nonRecurringIncomes.remove(at: index)
                            nonRecurringOverrides.removeAll { $0.nonRecurringId == item.id }
                            saveSnapshot()
                        }
                    },
                    onDismiss: {
                        showDeleteNonRecurringAlert = false
                        nonRecurringPendingDelete = nil
                    }
                )
            }
        }

        // MARK: - Toast overlay
        .overlay(alignment: .top) {
            if showNonRecurringToast {
                FloatingToastBubble(text: "Non-recurring income added to calendar")
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 80)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showNonRecurringToast)

        // MARK: - Persistence hooks
        .onAppear {
            if let snapshot = IncomeStorage.load() {
                jobs = snapshot.jobs
                passiveIncomes = snapshot.passiveIncomes
                nonRecurringIncomes = snapshot.nonRecurringIncomes
                overrides = snapshot.jobOverrides
                passiveOverrides = snapshot.passiveOverrides
                nonRecurringOverrides = snapshot.nonRecurringOverrides
            } else {
                saveSnapshot()
            }
        }
        .onChange(of: overrides) { _ in saveSnapshot() }
        .onChange(of: passiveOverrides) { _ in saveSnapshot() }
        .onChange(of: nonRecurringOverrides) { _ in saveSnapshot() }
    }

    // MARK: - Header (Summary / Calendar)

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

    // MARK: - Summary Card (Jobs + Passive only)

    private var summaryCard: some View {
        let jobsGrossMonth = jobs.reduce(0) { $0 + $1.projectedGrossPerMonth() }
        let jobsNetMonth   = jobs.reduce(0) { $0 + $1.projectedNetPerMonth() }
        let passiveGrossMonth = passiveIncomes.reduce(0) { $0 + $1.projectedGrossPerMonth() }
        let passiveNetMonth   = passiveIncomes.reduce(0) { $0 + $1.projectedNetPerMonth() }

        let totalGrossMonth = jobsGrossMonth + passiveGrossMonth
        let totalNetMonth   = jobsNetMonth   + passiveNetMonth

        let displayValue = showNetInSummary ? totalNetMonth : totalGrossMonth

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Projected this month")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(formattedCurrency(displayValue))
                        .font(.title2.bold())
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("View as")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    HStack(spacing: 6) {
                        togglePill(title: "Gross", isOn: !showNetInSummary) {
                            showNetInSummary = false
                        }
                        togglePill(title: "Net", isOn: showNetInSummary) {
                            showNetInSummary = true
                        }
                    }
                }
            }

            Text("\(jobs.count) job\(jobs.count == 1 ? "" : "s"), \(passiveIncomes.count) passive")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }

    // MARK: - Cards

    private func jobCard(_ job: Job) -> some View {
        let perPeriod = showNetInSummary ? job.projectedNetPerPeriod()
                                         : job.projectedGrossPerPeriod()
        let perMonth  = showNetInSummary ? job.projectedNetPerMonth()
                                         : job.projectedGrossPerMonth()

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(job.name)
                    .font(.body.bold())

                Spacer()

                Text(job.type.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.gray.opacity(0.15))
                    )

                Button {
                    jobBeingEdited = job
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .semibold))
                }
                .buttonStyle(.plain)
                .foregroundColor(.blue)

                Button {
                    jobPendingDelete = job
                    showDeleteJobAlert = true
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .semibold))
                }
                .buttonStyle(.plain)
                .foregroundColor(.red)
            }

            // Replaced deprecated payFrequency reference with current recurrence description
            Text("Every \(job.intervalDays) day\(job.intervalDays == 1 ? "" : "s") from \(formattedDate(job.startDate))" + (job.endDate != nil ? " to \(formattedDate(job.endDate!))" : ""))
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Per period")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(formattedCurrency(perPeriod))
                        .font(.subheadline.bold())
                }

                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Per month (approx)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(formattedCurrency(perMonth))
                        .font(.subheadline.bold())
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
        )
    }

    private func passiveIncomeCard(_ passive: PassiveIncome) -> some View {
        let perPeriod = showNetInSummary ? passive.projectedNetPerPeriod()
                                         : passive.projectedGrossPerPeriod()
        let perMonth  = showNetInSummary ? passive.projectedNetPerMonth()
                                         : passive.projectedGrossPerMonth()

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(passive.name)
                    .font(.body.bold())

                Spacer()

                Button {
                    passiveBeingEdited = passive
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .semibold))
                }
                .buttonStyle(.plain)
                .foregroundColor(.blue)

                Button {
                    passivePendingDelete = passive
                    showDeletePassiveAlert = true
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .semibold))
                }
                .buttonStyle(.plain)
                .foregroundColor(.red)
            }

            // Replaced missing frequencyDescription with current recurrence description
            Text("Every \(passive.intervalDays) day\(passive.intervalDays == 1 ? "" : "s") from \(formattedDate(passive.startDate))" + (passive.endDate != nil ? " to \(formattedDate(passive.endDate!))" : ""))
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Per period")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(formattedCurrency(perPeriod))
                        .font(.subheadline.bold())
                }

                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Per month (approx)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(formattedCurrency(perMonth))
                        .font(.subheadline.bold())
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
        )
    }

    private func nonRecurringIncomeCard(_ item: NonRecurringIncome) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(item.name)
                    .font(.body.bold())

                Spacer()

                Button {
                    nonRecurringBeingEdited = item
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .semibold))
                }
                .buttonStyle(.plain)
                .foregroundColor(.blue)

                Button {
                    nonRecurringPendingDelete = item
                    showDeleteNonRecurringAlert = true
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .semibold))
                }
                .buttonStyle(.plain)
                .foregroundColor(.red)
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("On \(formattedDate(item.date))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(formattedCurrency(item.amount))
                        .font(.subheadline.bold())
                }

                Spacer()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
        )
    }

    // MARK: - Add cards

    private var addJobCard: some View {
        Button {
            showAddJobSheet = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.green)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Add job")
                        .font(.body.weight(.semibold))
                    Text("Set up a salary, hourly, or contract job to start tracking projected pay.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
            )
        }
        .buttonStyle(.plain)
    }

    private var addPassiveIncomeCard: some View {
        Button {
            showAddPassiveIncomeSheet = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.green)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Add passive income")
                        .font(.body.weight(.semibold))
                    Text("Recurring income like interest, dividends, or rental.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
            )
        }
        .buttonStyle(.plain)
    }

    private var addNonRecurringIncomeCard: some View {
        Button {
            showAddNonRecurringIncomeSheet = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.green)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Add non-recurring income")
                        .font(.body.weight(.semibold))
                    Text("One-time payments like bonuses, gifts, or refunds.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func formattedCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    private func formattedDate(_ d: Date) -> String {
        DateFormatter.localizedString(from: d, dateStyle: .medium, timeStyle: .none)
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

    // Reusable delete dialog overlay
    @ViewBuilder
    private func deleteDialogOverlay(
        title: String,
        message: String,
        deleteLabel: String,
        onDelete: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) -> some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        onDismiss()
                    }
                }

            VStack(spacing: 14) {
                Text(title)
                    .font(.headline)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                VStack(spacing: 10) {
                    Button {
                        onDelete()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            onDismiss()
                        }
                    } label: {
                        Text(deleteLabel)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.red)
                            )
                            .foregroundColor(.white)
                    }

                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            onDismiss()
                        }
                    } label: {
                        Text("Cancel")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.gray.opacity(0.35), lineWidth: 1)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(Color.white)
                                    )
                            )
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding(18)
            .frame(minWidth: 260, maxWidth: 360)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: 10)
            )
            .padding(.horizontal, 24)
            .transition(.scale(scale: 0.95).combined(with: .opacity))
        }
        .animation(
            .spring(response: 0.35, dampingFraction: 0.85),
            value: showDeleteJobAlert || showDeletePassiveAlert || showDeleteNonRecurringAlert
        )
    }

    // Section divider for Summary layout
    private var sectionDivider: some View {
        Divider()
            .frame(height: 1)
            .background(Color.black.opacity(0.12))
            .padding(.vertical, 8)
    }

    // MARK: - Persistence helper

    private func saveSnapshot() {
        let snapshot = IncomeSnapshot(
            jobs: jobs,
            passiveIncomes: passiveIncomes,
            nonRecurringIncomes: nonRecurringIncomes,
            jobOverrides: overrides,
            passiveOverrides: passiveOverrides,
            nonRecurringOverrides: nonRecurringOverrides
        )
        IncomeStorage.save(snapshot)
    }

    // MARK: - Split sections (Summary vs Calendar)

    @ViewBuilder
    private var contentSwitcher: some View {
        if showCalendarMode {
            calendarSection
        } else {
            summarySection
        }
    }

    @ViewBuilder
    private var calendarSection: some View {
        Group {
            IncomeCalendarContainer(
                jobs: jobs,
                passiveIncomes: passiveIncomes,
                nonRecurringIncomes: nonRecurringIncomes,
                overrides: $overrides,
                passiveOverrides: $passiveOverrides,
                nonRecurringOverrides: $nonRecurringOverrides,
                useNet: $showNetInCalendar,
                showCalendarMode: $showCalendarMode,
                onDeleteOneTime: { id in
                    if let idx = nonRecurringIncomes.firstIndex(where: { $0.id == id }) {
                        nonRecurringIncomes.remove(at: idx)
                    }
                    nonRecurringOverrides.removeAll { $0.nonRecurringId == id }
                    saveSnapshot()
                }
            )
        }
        .background(Color.clear)
    }

    @ViewBuilder
    private var summarySection: some View {
        Group {
            IncomeSummarySection(
                jobs: $jobs,
                passiveIncomes: $passiveIncomes,
                nonRecurringIncomes: $nonRecurringIncomes,
                showAddJobSheet: $showAddJobSheet,
                showAddPassiveIncomeSheet: $showAddPassiveIncomeSheet,
                showAddNonRecurringIncomeSheet: $showAddNonRecurringIncomeSheet,
                showNetInSummary: $showNetInSummary,
                showCalendarMode: $showCalendarMode,
                jobBeingEdited: $jobBeingEdited,
                jobPendingDelete: $jobPendingDelete,
                showDeleteJobAlert: $showDeleteJobAlert,
                passiveBeingEdited: $passiveBeingEdited,
                passivePendingDelete: $passivePendingDelete,
                showDeletePassiveAlert: $showDeletePassiveAlert,
                nonRecurringBeingEdited: $nonRecurringBeingEdited,
                nonRecurringPendingDelete: $nonRecurringPendingDelete,
                showDeleteNonRecurringAlert: $showDeleteNonRecurringAlert,
                passiveOverrides: $passiveOverrides,
                nonRecurringOverrides: $nonRecurringOverrides,
                showNonRecurringToast: $showNonRecurringToast,
                saveSnapshot: saveSnapshot,
                deleteDialogOverlay: deleteDialogOverlay,
                formattedCurrency: formattedCurrency,
                formattedDate: formattedDate,
                togglePill: togglePill,
                jobCard: jobCard,
                passiveIncomeCard: passiveIncomeCard,
                addJobCard: { addJobCard },
                addPassiveIncomeCard: { addPassiveIncomeCard },
                addNonRecurringIncomeCard: { addNonRecurringIncomeCard },
                summaryCard: { summaryCard },
                headerWithModeSwitch: { headerWithModeSwitch },
                sectionDivider: { sectionDivider }
            )
        }
        .background(Color.clear)
    }
}

// MARK: - FloatingToastBubble (reusable)

struct FloatingToastBubble: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.black.opacity(0.85))
                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 6)
            )
            .accessibilityLabel(text)
    }
}
