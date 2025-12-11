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

    init(
        id: UUID = UUID(),
        name: String,
        targetAmount: Double,
        currentSaved: Double
    ) {
        self.id = id
        self.name = name
        self.targetAmount = targetAmount
        self.currentSaved = currentSaved
    }
}

struct SaveView: View {
    // All goals live here
    @State private var goals: [SavingsGoal] = []

    // Controls the + flow
    @State private var showingAddGoal = false

    // Deletion state for jars
    @State private var goalPendingDelete: SavingsGoal? = nil
    @State private var showDeleteGoalAlert: Bool = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Row: "Add more goals →" pill + green +
                    HStack(spacing: 12) {
                        Spacer()    // <- pushes pill + plus to the RIGHT side

                        // White pill with GREEN text & arrow (shrinks to fit content)
                        HStack(spacing: 6) {
                            Text("Add more goals")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.green)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, bubbleHorizontalPadding) // tweak to shorten/lengthen bubble
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
                        // Simple adaptive grid of jars
                        let columns = [
                            GridItem(.adaptive(minimum: 120), spacing: 20)
                        ]
                        LazyVGrid(columns: columns, spacing: 24) {
                            ForEach(goals) { goal in
                                // How full the jar is (0…1). Protect against /0.
                                let ratio = goal.targetAmount > 0
                                    ? goal.currentSaved / goal.targetAmount
                                    : 0

                                SavingsJarView(
                                    name: goal.name,        // 👈 this is drawn INSIDE the jar
                                    fillAmount: ratio,
                                    onDelete: {
                                        goalPendingDelete = goal
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                            showDeleteGoalAlert = true
                                        }
                                    }
                                )
                                // Smaller overall footprint for the jar
                                .frame(width: 130, height: 170)
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
                // Principal title centered, just like IncomeView
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
        // Delete overlay matching the Income page style
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
    }

    // Reusable delete dialog overlay (copied to match IncomeView style)
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
