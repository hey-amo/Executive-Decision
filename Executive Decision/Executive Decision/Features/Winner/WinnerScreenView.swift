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

    private var rankedOtherPlayers: [RankedPlayer] {
        let winnerIDs = Set(winners.map(\.id))
        let orderedPlayers = players.sorted { $0.coins > $1.coins }
        var previousCoins: Int?
        var previousRank = 0
        var rankedPlayers: [RankedPlayer] = []

        for (index, player) in orderedPlayers.enumerated() {
            if previousCoins != player.coins {
                previousCoins = player.coins
                previousRank = index + 1
            }

            if !winnerIDs.contains(player.id) {
                rankedPlayers.append(RankedPlayer(rank: previousRank, player: player))
            }
        }

        return rankedPlayers
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                WinnerHeroView(winners: winners)

                if !rankedOtherPlayers.isEmpty {
                    otherPlayersSection
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 24)
            .padding(.bottom, 24)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            playAgainButton
                .padding(.horizontal, 22)
                .padding(.top, 12)
                .padding(.bottom, 12)
                .background(PlayerSetupStyle.paper)
        }
        .background(PlayerSetupStyle.paper.ignoresSafeArea())
    }

    private var otherPlayersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("OTHER PLAYERS")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(PlayerSetupStyle.mutedInk)

            LazyVStack(spacing: 10) {
                ForEach(rankedOtherPlayers) { rankedPlayer in
                    OtherPlayerCard(rankedPlayer: rankedPlayer)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

private struct RankedPlayer: Identifiable {
    let rank: Int
    let player: MockPlayer

    var id: String { player.id }
}

private struct OtherPlayerCard: View {
    let rankedPlayer: RankedPlayer

    var body: some View {
        HStack(spacing: 12) {
            Text("#\(rankedPlayer.rank)")
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundStyle(PlayerSetupStyle.ink)
                .frame(width: 42, height: 42)
                .background(PlayerSetupStyle.gold.opacity(0.45))
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(PlayerSetupStyle.ink, lineWidth: 2)
                }
                .accessibilityHidden(true)

            Image(rankedPlayer.player.avatarResource)
                .resizable()
                .scaledToFill()
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .accessibilityHidden(true)

            Text(rankedPlayer.player.name)
                .font(.custom("Georgia-Bold", size: 18))
                .foregroundStyle(PlayerSetupStyle.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 3) {
                Text(rankedPlayer.player.coins.formatted())
                    .font(.custom("Georgia-Bold", size: 17))
                    .foregroundStyle(rankedPlayer.player.coins < 0 ? .red : PlayerSetupStyle.ink)
                Text("COINS")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(PlayerSetupStyle.mutedInk)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PlayerSetupStyle.card)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .overlay {
            RoundedRectangle(cornerRadius: 15)
                .stroke(PlayerSetupStyle.ink, lineWidth: 2)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "Place \(rankedPlayer.rank), \(rankedPlayer.player.name), \(rankedPlayer.player.coins) coins"
        )
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
