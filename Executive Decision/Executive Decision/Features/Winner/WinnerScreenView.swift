//
//  WinnerScreenView.swift
//  Executive Decision
//

import SwiftUI

struct WinnerScreenView: View {
    var players: [MockPlayer] = MockPlayer.roster

    private var winners: [MockPlayer] {
        guard let highestCoins = players.map(\.coins).max() else {
            return []
        }
        return players.filter { $0.coins == highestCoins }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                WinnerHeroView(winners: winners)
                playAgainButton
            }
            .padding(.horizontal, 22)
            .padding(.top, 24)
            .padding(.bottom, 28)
        }
        .background(PlayerSetupStyle.paper.ignoresSafeArea())
    }

    private var playAgainButton: some View {
        Button {
            print("button clicked")
        } label: {
            Text("Play again")
                .font(.custom("Georgia-Bold", size: 23))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(PlayerSetupStyle.tomato)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(PlayerSetupStyle.ink, lineWidth: 3)
                }
        }
        .buttonStyle(.plain)
    }
}

#Preview("Single winner") {
    WinnerScreenView()
}

#Preview("Tie") {
    WinnerScreenView(players: [
        MockPlayer.rex,
        MockPlayer(
            id: "saxon-tie",
            name: MockPlayer.saxon.name,
            avatarResource: MockPlayer.saxon.avatarResource,
            coins: MockPlayer.rex.coins,
            cardCount: MockPlayer.saxon.cardCount
        ),
        MockPlayer.gordon
    ])
}

#Preview("Six-way tie") {
    WinnerScreenView(players: MockPlayer.roster.map { player in
        MockPlayer(
            id: player.id,
            name: player.name,
            avatarResource: player.avatarResource,
            coins: MockPlayer.rex.coins,
            cardCount: player.cardCount
        )
    })
}
