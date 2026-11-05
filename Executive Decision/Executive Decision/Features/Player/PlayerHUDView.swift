//
//  PlayerHUDView.swift
//  Executive Decision
//
//  Created by Amarjit on 04/11/2026.
//

import SwiftUI

// Shows 1 avatar, coins, cards

struct PlayerHUDView: View {
    var avatarResource = MockPlayer.rex.avatarResource
    var isActive = true
    var coins = MockPlayer.rex.coins
    var cardCount = MockPlayer.rex.cardCount

    var body: some View {
        HStack(spacing: 14) {
            PlayerAvatarView(
                avatarResource: avatarResource,
                isActive: isActive,
                size: 60
            )

            VStack(alignment: .leading, spacing: 6) {
                CoinsView(coins: coins)

                Text("🃏 \(cardCount)")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(PlayerSetupStyle.ink)
                    .accessibilityLabel("\(cardCount) cards")
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
        PlayerHUDView(
            avatarResource: MockPlayer.rex.avatarResource,
            isActive: true,
            coins: MockPlayer.rex.coins,
            cardCount: MockPlayer.rex.cardCount
        )
        PlayerHUDView(
            avatarResource: MockPlayer.gordon.avatarResource,
            isActive: false,
            coins: MockPlayer.gordon.coins,
            cardCount: MockPlayer.gordon.cardCount
        )
    }
    .padding()
    .background(PlayerSetupStyle.paper)
}
