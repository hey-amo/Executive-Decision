//
//  PlayerListTopBarView.swift
//  Executive Decision
//
//  Created by Amarjit on 04/11/2026.
//

import SwiftUI

// Shows players in turn order. Only the player whose turn is active can be selected.
struct PlayerListTopBarView: View {
    var players: [MockPlayer] = MockPlayer.roster
    var activePlayerID = MockPlayer.rex.id
    var isInteractionLocked = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: 12) {
                    ForEach(players) { player in
                        playerCard(player)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 3)
            }
            .modifier(PlayerListScrollStyle(isLocked: isInteractionLocked))
            .allowsHitTesting(!isInteractionLocked)

            if players.count > 2 {
                HStack(spacing: 5) {
                    Image(systemName: "arrow.left.and.right")
                        .font(.system(size: 10, weight: .bold))
                    Text("SWIPE TO SEE ALL PLAYERS")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .tracking(1)
                }
                .foregroundStyle(PlayerSetupStyle.mutedInk)
                .frame(maxWidth: .infinity)
                .accessibilityHidden(true)
            }
        }
    }

    private func playerCard(_ player: MockPlayer) -> some View {
        let isActive = player.id == activePlayerID

        return Button {
            guard isActive, !isInteractionLocked else { return }
            print("Clicked on player: \(player.name)")
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(isActive ? PlayerSetupStyle.tomato : PlayerSetupStyle.mutedInk.opacity(0.35))
                        .frame(width: 8, height: 8)

                    Text(player.name)
                        .font(.custom("Georgia-Bold", size: 16))
                        .foregroundStyle(PlayerSetupStyle.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .padding(.horizontal, 2)

                PlayerHUDView(
                    avatarResource: player.avatarResource,
                    isActive: isActive,
                    coins: player.coins,
                    cardCount: player.cardCount
                )
            }
            .padding(8)
            .frame(width: 184, alignment: .leading)
            .background(isActive ? PlayerSetupStyle.gold.opacity(0.35) : PlayerSetupStyle.paper)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isActive ? PlayerSetupStyle.tomato : PlayerSetupStyle.ink.opacity(0.3),
                        lineWidth: isActive ? 3 : 1
                    )
            }
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .disabled(!isActive || isInteractionLocked)
        .accessibilityLabel("\(player.name), \(player.coins) coins, \(player.cardCount) cards")
        .accessibilityHint(isActive ? "Current player." : "Not currently active.")
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}

private struct PlayerListScrollStyle: ViewModifier {
    let isLocked: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content
                .scrollIndicators(.visible)
                .scrollDisabled(isLocked)
        } else {
            content
        }
    }
}

#Preview("Six players") {
    PlayerListTopBarView()
        .padding()
        .background(PlayerSetupStyle.paper)
}

#Preview("Two players, locked") {
    PlayerListTopBarView(
        players: Array(MockPlayer.roster.prefix(2)),
        isInteractionLocked: true
    )
    .padding()
    .background(PlayerSetupStyle.paper)
}
