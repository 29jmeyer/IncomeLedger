import SwiftUI

struct SavingsJarPage: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var goal: SavingsGoal

    private var hasTarget: Bool {
        goal.targetAmount > 0
    }

    private var progress: Double {
        guard hasTarget else { return 0 }
        return min(goal.currentSaved / goal.targetAmount, 1)
    }

    @State private var showMoneyEdit = false
    @State private var animationTrigger: Int = 0   // drives the jar animation

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
                          },
                          onConfirmedAdd: {
                              // Increment the trigger to start the animation now (only for Add)
                              animationTrigger &+= 1
                          })
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
            startDate: Date()
        )

        var body: some View {
            SavingsJarPage(goal: $sample)
        }
    }
}
