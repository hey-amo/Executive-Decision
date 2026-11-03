//
//  PlayerHUDView.swift
//  Executive-Decision

// Displays a single player avatar and their current money amount
import SwiftUI
import EDEngine

struct PlayerHUDView: View {
    let player: EDPlayer
    var body: some View {
        VStack {
            PlayerAvatarView(avatarResource: player.avatar.rawValue, isHighlighted: true)
            CoinView(coins: player.coins)
        }
    }
}

#Preview {
    // Use EDPlayer model for a single player
    PlayerHUDView(
        player: EDPlayer(
            name: "Player 1",
            avatar: .avt1,
            coins: 100
        )
    )
}
