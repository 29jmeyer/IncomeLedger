//
//  DebtView.swift
//  IncomeLedger
//
//  Created by john meyer on 2025-12-02.
//

import SwiftUI

struct DebtView: View {
    var body: some View {
        ZStack {
            Color.clear   // we use financeBackground from ContentView

            Text("Debt")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
        }
    }
}
