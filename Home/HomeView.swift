//
//  HomeView.swift
//  IncomeLedger
//
//  Created by john meyer on 2025-12-02.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        ZStack {
            Color.clear   // we use the gradient/white background from MainTabView

            Text("Home")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    HomeView()
}
