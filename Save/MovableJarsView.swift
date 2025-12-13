import SwiftUI

// This view demonstrates movable jars with a toggle button placed just
// under the "Add more goals" header row, using your existing SavingsJarView
// and DraggableJarWrapper. It keeps its own local list of demo goals so you
// can try dragging freely without touching SaveView’s persistence yet.
struct MovableJarsView: View {

    // Local demo goals; you can pass in a Binding<[SavingsGoal]> if you prefer.
    @State private var goals: [SavingsGoal] = [
        .init(name: "Holiday", targetAmount: 1000, currentSaved: 250),
        .init(name: "New Phone", targetAmount: 1200, currentSaved: 400),
        .init(name: "Trip", targetAmount: 2000, currentSaved: 1500)
    ]

    // Drag toggle
    @State private var dragEnabled: Bool = false

    // Positions for each jar (center points in container coordinates)
    @State private var positions: [UUID: CGPoint] = [:]

    // Layout
    @State private var containerSize: CGSize = .zero

    // Tuning
    private let tapMovementThreshold: CGFloat = 6      // how far finger has to move to count as drag
    private let minSpacing: CGFloat = 16               // reserved if you later want to avoid overlap
    private let jarSize = CGSize(width: 160, height: 210)

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    headerRow

                    dragToggleRow

                    // Movable canvas
                    GeometryReader { geo in
                        let size = geo.size

                        ZStack {
                            // Optional: a faint background
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)

                            // Place jars using DraggableJarWrapper
                            ForEach(goals) { goal in
                                let id = goal.id
                                DraggableJarWrapper(
                                    id: id,
                                    positions: $positions,
                                    containerSize: size,
                                    itemSize: jarSize,
                                    barrierRects: [],                // no barriers for now
                                    minSpacing: minSpacing,
                                    otherItemFrames: [],             // could be used to avoid overlap
                                    tapMovementThreshold: tapMovementThreshold,
                                    dragEnabled: dragEnabled
                                ) {
                                    let ratio = goal.targetAmount == 0
                                        ? 0
                                        : min(max(goal.currentSaved / goal.targetAmount, 0), 1)

                                    SavingsJarView(
                                        name: goal.name,
                                        fillAmount: ratio,
                                        onDelete: {
                                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                                removeGoal(goal)
                                            }
                                        }
                                    )
                                }
                            }
                        }
                        .onAppear {
                            containerSize = size
                            seedInitialPositions(in: size)
                        }
                        .onChange(of: size) { newSize in
                            containerSize = newSize
                        }
                    }
                    .frame(height: 540) // adjustable canvas height
                    .padding(.horizontal, 24)

                    Spacer(minLength: 24)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 12)
            }
            .background(Color.clear)
        }
        .navigationTitle("Movable Jars")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header row ("Add more goals" + green plus)
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
            .padding(.horizontal, bubbleHorizontalPadding)  // uses the global from SaveView.swift
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
            .fixedSize(horizontal: true, vertical: false)

            Button(action: addGoal) {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 42, height: 42)
                    .background(Color.green)
                    .clipShape(Circle())
                    .shadow(color: Color.green.opacity(0.4), radius: 10, x: 0, y: 6)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }

    // MARK: - Drag toggle row (under header)
    private var dragToggleRow: some View {
        HStack {
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

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Helpers

    private func addGoal() {
        let new = SavingsGoal(
            name: nextName(),
            targetAmount: 1000,
            currentSaved: 0
        )
        goals.append(new)

        // If we know the container size, drop the new jar near the center with an offset
        if containerSize != .zero {
            let base = CGPoint(x: containerSize.width / 2, y: containerSize.height / 2)
            let offset = CGFloat(goals.count % 5) * 18
            positions[new.id] = CGPoint(x: base.x + offset, y: base.y + offset)
        }
    }

    private func removeGoal(_ goal: SavingsGoal) {
        goals.removeAll { $0.id == goal.id }
        positions.removeValue(forKey: goal.id)
    }

    private func nextName() -> String {
        let names = ["Holiday", "Phone", "Trip", "Bike", "Laptop", "Games", "Gifts"]
        let idx = (goals.count) % names.count
        return names[idx]
    }

    // Seed initial positions if a jar has no position yet
    private func seedInitialPositions(in size: CGSize) {
        guard size != .zero else { return }

        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let gridStep: CGFloat = 190

        var i = 0
        for g in goals {
            if positions[g.id] == nil {
                // Drop them in a loose grid around center
                let dx = CGFloat(i % 3 - 1) * gridStep
                let dy = CGFloat(i / 3) * gridStep - gridStep
                positions[g.id] = CGPoint(x: center.x + dx, y: center.y + dy)
                i += 1
            }
        }
    }
}

#Preview {
    NavigationView {
        MovableJarsView()
    }
}
