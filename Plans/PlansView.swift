//
//  PlansView.swift
//  IncomeLedger
//
//  Created by john meyer on 2025-12-02.
//

import SwiftUI

struct PlansView: View {
    var body: some View {
        ZStack {
            Color.clear   // we use financeBackground from ContentView

            Text("Plans")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
        }
    }
}
