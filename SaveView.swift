//
//  SaveView.swift
//  IncomeLedger
//
//  Created by john meyer on 2025-12-02.
//

import SwiftUI

struct SaveView: View {
    var body: some View {
        ZStack {
            Color.clear   // we use financeBackground from ContentView

            Text("Save")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
        }
    }
}
