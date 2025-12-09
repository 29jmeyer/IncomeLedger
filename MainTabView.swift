import SwiftUI

struct MainTabView: View {

    enum Tab {
        case plans
        case savings
        case home
        case income
        case debt
    }

    @State private var selectedTab: Tab = .home

    var body: some View {
        ZStack {
            // Active page content
            currentPage
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)      // app background
                .ignoresSafeArea()            // let white go behind status bar
        }
        // Attach a custom bar at the bottom safe area
        // and extend its BACKGROUND into the unsafe zone.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            tabBar
        }
    }

    // MARK: - Current page

    @ViewBuilder
    private var currentPage: some View {
        switch selectedTab {
        case .plans:
            PlansView()          // or PlansView() if you renamed it
        case .savings:
            SaveView()
        case .home:
            HomeView()
        case .income:
            IncomeView()
        case .debt:
            DebtView()
        }
    }

    // MARK: - Tab bar

    private var tabBar: some View {
        ZStack {
            // BACKGROUND that fills side-to-side and down behind home indicator
            Color(.systemGray6)                 // slightly different from pure white
                .ignoresSafeArea(edges: .bottom)

            // Row of small tabs (space left in the middle for the big Home button)
            HStack {
                tabButton(tab: .plans,
                          title: "Plans",
                          systemName: "doc.text")

                Spacer()

                tabButton(tab: .savings,
                          title: "Save",
                          systemName: "chart.bar.fill")

                Spacer()
                Spacer(minLength: 64)           // gap under the floating Home button

                tabButton(tab: .income,
                          title: "Income",
                          systemName: "dollarsign.circle")

                Spacer()

                tabButton(tab: .debt,
                          title: "Debt",
                          systemName: "creditcard")
            }
            .padding(.horizontal, 28)
            .padding(.top, 8)
            .padding(.bottom, 10)

            // Big center Home button that pops upward
            homeButton
        }
        .frame(height: 30)
    }

    // Small side tabs
    private func tabButton(tab: Tab,
                           title: String,
                           systemName: String) -> some View {

        let isSelected = (tab == selectedTab)

        return Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: systemName)
                    .font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(
                isSelected ? Color(.systemGreen) : Color(.systemGray)
            )
        }
        .buttonStyle(.plain)
    }

    // Big floating Home button in the centre
    private var homeButton: some View {
        let isSelected = (selectedTab == .home)

        return Button {
            selectedTab = .home
        } label: {
            Image(systemName: "house.fill")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 72, height: 72)
                .background(
                    Circle()
                        .fill(Color(.systemGreen))
                )
                .shadow(color: Color.black.opacity(0.25),
                        radius: 10, x: 0, y: 6)
                .scaleEffect(isSelected ? 1.0 : 0.9)  // tiny pop when selected
                .animation(.spring(response: 0.35,
                                   dampingFraction: 0.8),
                           value: isSelected)
        }
        .buttonStyle(.plain)
        .offset(y: -28)   // lift it above the bar, like before
    }
}

