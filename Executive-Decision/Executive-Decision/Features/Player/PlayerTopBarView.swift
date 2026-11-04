//
//  PlayerTopBarView.swift
//  Executive-Decision

import SwiftUI
import EDEngine

// List players in a horizontal bar at the top of the screen, showing their avatars and current money amounts
// Scrollable if there are too many players to fit on the screen

// Expect: 
// - Lazy Scroll view horizontal that is memory-efficient and no show indicators
// - List each player in a horizontal stack
// - Each player shows their avatar and current money amount
// - Each player is clickable

struct PlayerTopBarView: View {
    private static let samplePlayers = [
        EDPlayer(name: "Player 1", avatar: .avt1, coins: 100),
        EDPlayer(name: "Player 2", avatar: .avt2, coins: 200),
        EDPlayer(name: "Player 3", avatar: .avt3, coins: 300),
        EDPlayer(name: "Player 4", avatar: .avt4, coins: 400),
        EDPlayer(name: "Player 5", avatar: .avt5, coins: 500),
        EDPlayer(name: "Player 6", avatar: .avt6, coins: 600)
    ]

    private let players: [EDPlayer]
    private let currentPlayerID: UUID?
    private let onPlayerSelected: (EDPlayer) -> Void

    init(
        players: [EDPlayer]? = nil,
        currentPlayerID: UUID? = nil,
        onPlayerSelected: @escaping (EDPlayer) -> Void = { _ in }
    ) {
        let players = players ?? Self.samplePlayers
        self.players = players
        self.currentPlayerID = currentPlayerID ?? players.first?.id
        self.onPlayerSelected = onPlayerSelected
    }

    var body: some View {        
        ScrollView(.horizontal) {
            LazyHStack(spacing: 16) {
                ForEach(players) { player in
                    Button {
                        onPlayerSelected(player)
                    } label: {
                        VStack(spacing: 4) {
                            PlayerAvatarView(
                                avatarResource: player.avatarResource?.rawValue ?? "avt-1",
                                isHighlighted: player.id == currentPlayerID,
                                size: 48
                            )
                            CoinView(coins: player.coins)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(player.name), \(player.coins.formatted(.currency(code: "USD")))")
                }
            }
            .padding(.horizontal)
        }
        .scrollIndicators(.hidden)
    }
}

#Preview {
    PlayerTopBarView()
}
