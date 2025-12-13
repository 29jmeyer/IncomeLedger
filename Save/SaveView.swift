import SwiftUI

// Simple model for a savings goal.
// Kept in this file so Save feature lives in just 2 files.
struct SavingsGoal: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var targetAmount: Double
    var currentSaved: Double

    // Optional schedule (persisted from AddSavingsGoalFlow when user enables it)
    var useSchedule: Bool?
    var intervalDays: Int?
    var scheduleAmount: Double?
    var startDate: Date?

    // Persisted, editable plan of remaining scheduled entries
    var plannedEntries: [SavingsPlannedEntry]?

    init(
        id: UUID = UUID(),
        name: String,
        targetAmount: Double,
        currentSaved: Double,
        useSchedule: Bool? = nil,
        intervalDays: Int? = nil,
        scheduleAmount: Double? = nil,
        startDate: Date? = nil,
        plannedEntries: [SavingsPlannedEntry]? = nil
    ) {
        self.id = id
        self.name = name
        self.targetAmount = targetAmount
        self.currentSaved = currentSaved
        self.useSchedule = useSchedule
        self.intervalDays = intervalDays
        self.scheduleAmount = scheduleAmount
        self.startDate = startDate
        self.plannedEntries = plannedEntries
    }
}

struct SaveView: View {
    // All goals live here
    @State private var goals: [SavingsGoal] = []

    // Track which goal is open
    @State private var selectedGoalId: UUID? = nil
    @State private var isShowingGoalPage = false

    // Controls the + flow
    @State private var showingAddGoal = false

    // Deletion state for jars
    @State private var goalPendingDelete: SavingsGoal? = nil
    @State private var showDeleteGoalAlert: Bool = false

    // Drag toggle state
    @State private var dragEnabled: Bool = false

    // Positions for draggable mode (normalized in bubble: 0...1)
    @State private var normalizedPositions: [UUID: CGPoint] = [:]

    // Max jars
    private let maxJars = 3
    @State private var showMaxJarsAlert = false

    // Completion celebration
    @State private var showCompletionConfetti: Bool = false

    // Tuning for draggable mode
    private let jarSize = CGSize(width: 160, height: 210)
    private let tapMovementThreshold: CGFloat = 6

    // MARK: - Persistence
    private let goalsStorageKey = "SaveView.goals"
    private let positionsStorageKey = "SaveView.normalizedPositions"

    private func loadGoals() {
        guard let data = UserDefaults.standard.data(forKey: goalsStorageKey) else { return }
        do {
            let decoded = try JSONDecoder().decode([SavingsGoal].self, from: data)
            goals = decoded
        } catch {
            print("Failed to decode goals from UserDefaults: \(error)")
        }
    }

    private func saveGoals() {
        do {
            let data = try JSONEncoder().encode(goals)
            UserDefaults.standard.set(data, forKey: goalsStorageKey)
        } catch {
            print("Failed to encode goals to UserDefaults: \(error)")
        }
    }

    private func loadPositions() {
        guard let data = UserDefaults.standard.data(forKey: positionsStorageKey) else { return }
        do {
            let decoded = try JSONDecoder().decode([UUID: CGPoint].self, from: data)
            // Keep only positions for existing goals
            let validIds = Set(goals.map { $0.id })
            normalizedPositions = decoded.filter { validIds.contains($0.key) }
        } catch {
            print("Failed to decode positions from UserDefaults: \(error)")
        }
    }

    private func savePositions() {
        do {
            let data = try JSONEncoder().encode(normalizedPositions)
            UserDefaults.standard.set(data, forKey: positionsStorageKey)
        } catch {
            print("Failed to encode positions to UserDefaults: \(error)")
        }
    }

    // Helper: index of selected goal
    private var selectedIndex: Int? {
        guard let id = selectedGoalId else { return nil }
        return goals.firstIndex(where: { $0.id == id })
    }

    // Helper: binding to selected goal if available
    private var selectedGoalBinding: Binding<SavingsGoal>? {
        guard let idx = selectedIndex else { return nil }
        return Binding<SavingsGoal>(
            get: { goals[idx] },
            set: { goals[idx] = $0 }
        )
    }

    var body: some View {
        NavigationView {
            // Static layout in both modes (no page scrolling)
            VStack(alignment: .leading, spacing: 12) {
                // Header row
                headerRow

                // Drag toggle directly under header, right-aligned
                HStack {
                    Spacer()
                    dragTogglePill
                }
                .padding(.horizontal, 24)

                // Draggable canvas uses normalized positions; it converts to absolute internally.
                DraggableCanvas(
                    ids: goals.map { $0.id },
                    positions: $normalizedPositions,
                    itemSize: jarSize,
                    bubbleInsets: saveViewBubbleInsets,
                    dragEnabled: dragEnabled,
                    tapMovementThreshold: tapMovementThreshold,
                    bubbleCornerRadius: 18
                ) { id in
                    if let goal = goals.first(where: { $0.id == id }) {
                        let ratio = goal.targetAmount == 0 ? 0 :
                            min(max(goal.currentSaved / goal.targetAmount, 0), 1)

                        Group {
                            if dragEnabled {
                                SavingsJarView(
                                    name: goal.name,
                                    fillAmount: ratio,
                                    onDelete: {
                                        goalPendingDelete = goal
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                            showDeleteGoalAlert = true
                                        }
                                    }
                                )
                            } else {
                                Button {
                                    // Set the selection then present
                                    selectedGoalId = goal.id
                                    DispatchQueue.main.async {
                                        if selectedGoalBinding != nil {
                                            isShowingGoalPage = true
                                        } else {
                                            DispatchQueue.main.async {
                                                if selectedGoalBinding != nil {
                                                    isShowingGoalPage = true
                                                }
                                            }
                                        }
                                    }
                                } label: {
                                    SavingsJarView(
                                        name: goal.name,
                                        fillAmount: ratio,
                                        onDelete: {
                                            goalPendingDelete = goal
                                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                                showDeleteGoalAlert = true
                                            }
                                        }
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } else {
                        EmptyView()
                    }
                }
                .frame(height: 560)

                Spacer(minLength: 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color.white)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Save")
                        .font(.headline)
                        .bold()
                }
            }
        }
        .background(Color.white.ignoresSafeArea())

        // Open the goal flow as a full-screen page
        .fullScreenCover(isPresented: $showingAddGoal) {
            AddSavingsGoalFlow(goals: $goals)
        }

        // Delete overlay
        .overlay {
            if showDeleteGoalAlert, let goal = goalPendingDelete {
                deleteDialogOverlay(
                    title: "Delete savings goal?",
                    message: "This will remove \"\(goal.name)\" from your goals.",
                    deleteLabel: "Delete goal",
                    onDelete: {
                        if let index = goals.firstIndex(where: { $0.id == goal.id }) {
                            goals.remove(at: index)
                            normalizedPositions.removeValue(forKey: goal.id)
                        }
                    },
                    onDismiss: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            showDeleteGoalAlert = false
                            goalPendingDelete = nil
                        }
                    }
                )
            }
        }

        // Present the jar page FULL-SCREEN with a binding to the selected goal
        .fullScreenCover(isPresented: Binding(
            get: { isShowingGoalPage && selectedGoalBinding != nil },
            set: { newValue in isShowingGoalPage = newValue }
        )) {
            if let binding = selectedGoalBinding {
                SavingsJarPage(goal: binding, onGoalCompleted: { id in
                    // Remove the goal and close page, then show confetti on Save screen
                    if let idx = goals.firstIndex(where: { $0.id == id }) {
                        goals.remove(at: idx)
                        normalizedPositions.removeValue(forKey: id)
                    }
                    isShowingGoalPage = false
                    // Defer to next runloop to ensure we're back on Save screen before showing confetti
                    DispatchQueue.main.async {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showCompletionConfetti = true
                        }
                        // Auto-hide after a short duration
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showCompletionConfetti = false
                            }
                        }
                    }
                })
            } else {
                Text("Goal not found")
                    .font(.headline)
                    .onAppear { isShowingGoalPage = false }
            }
        }

        // Completion confetti overlay on Save screen
        .overlay {
            if showCompletionConfetti {
                GoalCompletionOverlay(
                    message: "Congratulations on hitting your goal!",
                    duration: 1.8
                ) {
                    // Nothing extra; overlay hides itself via showCompletionConfetti flag timer
                }
                .transition(.opacity)
            }
        }

        // Max jars alert
        .alert("Limit reached", isPresented: $showMaxJarsAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("You can only have up to 3 jars.")
        }

        // Persistence hooks
        .onAppear {
            loadGoals()
            loadPositions()
            pruneOrphanPositions()
            savePositions()
        }
        .onChange(of: goals) { _ in
            saveGoals()
            pruneOrphanPositions()
            savePositions()
        }
        .onChange(of: normalizedPositions) { _ in
            savePositions()
        }
    }

    // MARK: - Header rows

    private var headerRow: some View {
        HStack(spacing: 12) {
            Spacer()

            HStack(spacing: 6) {
                Text("Add more goals")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.green)
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.green)
            }
            .padding(.horizontal, bubbleHorizontalPadding)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.06),
                    radius: 8, x: 0, y: 4)
            .fixedSize(horizontal: true, vertical: false)

            Button(action: {
                if goals.count >= maxJars {
                    showMaxJarsAlert = true
                } else {
                    showingAddGoal = true
                }
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 42, height: 42)
                    .background(Color.green)
                    .clipShape(Circle())
                    .shadow(color: Color.green.opacity(0.4),
                            radius: 10, x: 0, y: 6)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }

    private var dragTogglePill: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                dragEnabled.toggle()
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: dragEnabled ? "hand.point.up.left.fill" : "hand.tap.fill")
                    .font(.system(size: 14, weight: .semibold))
                Text(dragEnabled ? "Drag on" : "Tap on")
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(dragEnabled ? Color.green.opacity(0.9) : Color.gray.opacity(0.2))
            .foregroundColor(dragEnabled ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(dragEnabled ? "Drag mode on" : "Drag mode off")
    }

    // MARK: - Delete dialog overlay

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
    }

    // MARK: - Helpers

    private func pruneOrphanPositions() {
        let valid = Set(goals.map { $0.id })
        normalizedPositions = normalizedPositions.filter { valid.contains($0.key) }
    }
}
