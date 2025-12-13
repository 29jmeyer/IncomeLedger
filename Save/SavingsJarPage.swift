import SwiftUI

struct SavingsJarPage: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var goal: SavingsGoal

    // Parent-provided callback to remove a finished goal and pop back
    var onGoalCompleted: (UUID) -> Void = { _ in }

    private var hasTarget: Bool {
        goal.targetAmount > 0
    }

    private var progress: Double {
        guard hasTarget else { return 0 }
        return min(goal.currentSaved / goal.targetAmount, 1)
    }

    @State private var showMoneyEdit = false
    @State private var animationTrigger: Int = 0   // drives the jar animation

    // Prevent scheduling completion multiple times
    @State private var completionScheduled: Bool = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            // Main vertical layout with fixed header (back button)
            VStack(spacing: 0) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.green)
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Spacer().frame(height: 420)

                Button {
                    showMoneyEdit = true
                } label: {
                    Text("Add/Remove Money")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.green)
                        )
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            // Jar animation view with trigger
            VStack(spacing: 0) {
                Spacer().frame(height: 16 + 44 + 2)

                JarAddMoneyAnimationView(goalName: goal.name, animationTrigger: $animationTrigger)
                    .frame(width: 340, height: 408, alignment: .center)
                    .accessibilityLabel(goal.name)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            GoalPlanSheet(goal: goal)
                .ignoresSafeArea(edges: .bottom)
        }
        .sheet(isPresented: $showMoneyEdit) {
            MoneyEditView(goal: goal,
                          onConfirm: { updated in
                              goal = updated
                              handleCompletionIfNeeded()
                          },
                          onConfirmedAdd: {
                              // Increment the trigger to start the animation now (only for Add)
                              animationTrigger &+= 1
                          })
        }
        .onAppear {
            handleCompletionIfNeeded()
        }
    }

    private func handleCompletionIfNeeded() {
        // Consider goal completed only when currentSaved reaches the target (with a small epsilon).
        let reachedByAmount = goal.currentSaved >= goal.targetAmount - 0.005

        guard reachedByAmount else { return }

        // Avoid scheduling multiple times if this function is called repeatedly
        guard !completionScheduled else { return }
        completionScheduled = true

        // Delay 2.5 seconds so the coin animation can play before exit
        let delaySeconds: Double = 2
        DispatchQueue.main.asyncAfter(deadline: .now() + delaySeconds) {
            onGoalCompleted(goal.id)
            dismiss()
        }
    }
}

struct SavingsJarPage_Previews: PreviewProvider {
    static var previews: some View {
        StatefulPagePreview()
            .previewLayout(.sizeThatFits)
    }

    private struct StatefulPagePreview: View {
        @State private var sample = SavingsGoal(
            name: "Holiday",
            targetAmount: 1000,
            currentSaved: 250,
            useSchedule: true,
            intervalDays: 7,
            scheduleAmount: 75,
            startDate: Date(),
            plannedEntries: [
                SavingsPlannedEntry(date: Calendar.current.startOfDay(for: Date()), amount: 75),
                SavingsPlannedEntry(date: Calendar.current.date(byAdding: .day, value: 7, to: Calendar.current.startOfDay(for: Date()))!, amount: 75),
            ]
        )

        var body: some View {
            SavingsJarPage(goal: $sample)
        }
    }
}
