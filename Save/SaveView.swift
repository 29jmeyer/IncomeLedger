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

                    // For now: empty body space (no Total Saved / jars yet)
                    Spacer(minLength: 40)
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
    }
}

