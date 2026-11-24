//
//  PlayerHUDView.swift
//  Executive Decision
//
//  Created by Amarjit on 04/11/2026.
//

import SwiftUI

// Shows 1 avatar, coins, cards

struct PlayerHUDView: View {
    let player: MockPlayer
    
    var body: some View {
        HStack(spacing: 14) {
            PlayerAvatarView(
                avatarResource: player.avatarResource,
                isActive: player.isActive,
                size: 60
            )

            VStack(alignment: .leading, spacing: 6) {
                CoinsView(coins: player.coins)

                Text("🃏 \(player.cardCount)")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(PlayerSetupStyle.ink)
                    .accessibilityLabel("\(player.cardCount) cards")
            }
        }
        .padding(12)
        .background(PlayerSetupStyle.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(PlayerSetupStyle.ink, lineWidth: 2)
        }
    }
}


#Preview {
    VStack(spacing: 12) {
        PlayerHUDView(player: MockPlayer.rex)
        PlayerHUDView(player: MockPlayer.alex)        
    }
    .padding()
    .background(PlayerSetupStyle.paper)
}
