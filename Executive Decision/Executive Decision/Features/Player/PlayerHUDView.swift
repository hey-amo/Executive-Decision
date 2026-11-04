//
//  PlayerHUDView.swift
//  Executive Decision
//
//  Created by Amarjit on 04/11/2026.
//

import SwiftUI

// Shows 1 avatar, coins, cards

struct PlayerHUDView: View {
    var body: some View {
        VStack {
            Image("avt-1")
            Text("$100")
        }
    }
}

#Preview {
    PlayerHUDView()
}
