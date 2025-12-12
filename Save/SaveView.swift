import SwiftUI

// Adjustable horizontal padding for the "Add more goals →" bubble
private let bubbleHorizontalPadding: CGFloat = 18

// Simple model for a savings goal.
// Kept in this file so Save feature lives in just 2 files.
struct SavingsGoal: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var targetAmount: Double
    var currentSaved: Double

    // Optional schedule (persisted from AddSavingsGoalFlow when user enables it)
    var useSchedule: Bool?            // true if user enabled a schedule
    var intervalDays: Int?            // e.g., 7, 14, 30
    var scheduleAmount: Double?       // amount per interval
    var startDate: Date?              // first contribution date

    init(
        id: UUID = UUID(),
        name: String,
        targetAmount: Double,
        currentSaved: Double,
        useSchedule: Bool? = nil,
        intervalDays: Int? = nil,
        scheduleAmount: Double? = nil,
        startDate: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.targetAmount = targetAmount
        self.currentSaved = currentSaved
        self.useSchedule = useSchedule
        self.intervalDays = intervalDays
        self.scheduleAmount = scheduleAmount
        self.startDate = startDate
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

    // MARK: - Persistence
    private let goalsStorageKey = "SaveView.goals"

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
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Row: "Add more goals →" pill + green +
                    HStack(spacing: 12) {
                        Spacer()

                        // White pill with GREEN text & arrow (shrinks to fit content)
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

                        // Green + bubble (button)
                        Button(action: {
                            showingAddGoal = true
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

                    // Jars grid/list
                    if goals.isEmpty {
                        Spacer(minLength: 40)
                    } else {
                        let columns = [
                            GridItem(.adaptive(minimum: 120), spacing: 20)
                        ]
                        LazyVGrid(columns: columns, spacing: 24) {
                            ForEach(goals) { goal in
                                let ratio = goal.targetAmount == 0 ? 0 :
                                    goal.currentSaved / goal.targetAmount

                                Button {
                                    // Set the selection
                                    selectedGoalId = goal.id
                                    // Defer presentation to next runloop to avoid race with state updates
                                    DispatchQueue.main.async {
                                        // Only present if the binding is actually available
                                        if selectedGoalBinding != nil {
                                            isShowingGoalPage = true
                                        } else {
                                            // As a fallback, try again shortly if needed
                                            DispatchQueue.main.async {
                                                if selectedGoalBinding != nil {
                                                    isShowingGoalPage = true
                                                }
                                            }
                                        }
                                    }
                                } label: {
                                    VStack(spacing: 8) {
                                        SavingsJarView(
                                            name: goal.name,
                                            fillAmount: ratio,
                                            onDelete: {
                                                goalPendingDelete = goal
                                                withAnimation(.spring(response: 0.35,
                                                                      dampingFraction: 0.85)) {
                                                    showDeleteGoalAlert = true
                                                }
                                            }
                                        )
                                        .frame(width: 160, height: 210)
                                    }
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        goalPendingDelete = goal
                                        withAnimation(.spring(response: 0.35,
                                                              dampingFraction: 0.85)) {
                                            showDeleteGoalAlert = true
                                        }
                                    } label: {
                                        Label("Delete goal", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.clear)
            }
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
        // Guard: only present when we have a valid binding to avoid "Goal not found".
        .fullScreenCover(isPresented: Binding(
            get: { isShowingGoalPage && selectedGoalBinding != nil },
            set: { newValue in isShowingGoalPage = newValue }
        )) {
            if let binding = selectedGoalBinding {
                SavingsJarPage(goal: binding)
            } else {
                // If it somehow becomes nil during presentation, dismiss safely
                Text("Goal not found")
                    .font(.headline)
                    .onAppear { isShowingGoalPage = false }
            }
        }

        // Persistence hooks
        .onAppear { loadGoals() }
        .onChange(of: goals) { _ in saveGoals() }
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
    }
}
