//
//  WinnerHeroView.swift
//  Executive Decision
//

import SwiftUI

struct WinnerHeroView: View {
    let winners: [MockPlayer]

    private var isTie: Bool {
        winners.count > 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 8) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 15, weight: .bold))
                Text("GAME COMPLETE")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .tracking(1.5)
            }
            .foregroundStyle(PlayerSetupStyle.tomato)

            Text(title)
                .font(.custom("Georgia-Bold", size: 34))
                .foregroundStyle(PlayerSetupStyle.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text(subtitle)
                .font(.system(size: 17, weight: .regular, design: .rounded))
                .foregroundStyle(PlayerSetupStyle.mutedInk)
                .fixedSize(horizontal: false, vertical: true)

            if winners.isEmpty {
                Text("No players to score.")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(PlayerSetupStyle.mutedInk)
            } else {
                VStack(spacing: 12) {
                    ForEach(winners) { player in
                        WinnerPlayerCard(player: player)
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PlayerSetupStyle.gold.opacity(0.28))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(PlayerSetupStyle.ink.opacity(0.5), lineWidth: 2)
        }
        .accessibilityElement(children: .contain)
    }

    private var title: String {
        if winners.isEmpty {
            return "Game over"
        }
        return isTie ? "It's a tie!" : "\(winners[0].name) wins!"
    }

    private var subtitle: String {
        if winners.isEmpty {
            return "There are no players to rank."
        }
        return isTie
            ? "The most coins are shared by \(winners.count) players."
            : "The most coins at the end of the game."
    }
}

private struct WinnerPlayerCard: View {
    let player: MockPlayer

    var body: some View {
        HStack(spacing: 14) {
            Image(player.avatarResource)
                .resizable()
                .scaledToFill()
                .frame(width: 68, height: 68)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(PlayerSetupStyle.ink, lineWidth: 2)
                }
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                Text(player.name)
                    .font(.custom("Georgia-Bold", size: 22))
                    .foregroundStyle(PlayerSetupStyle.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text("WINNER")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(PlayerSetupStyle.mutedInk)
            }

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 3) {
                Text(player.coins.formatted())
                    .font(.custom("Georgia-Bold", size: 19))
                    .foregroundStyle(PlayerSetupStyle.ink)
                    .contentTransition(.numericText())
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(player.name), winner, \(player.coins) coins")
    }
}
