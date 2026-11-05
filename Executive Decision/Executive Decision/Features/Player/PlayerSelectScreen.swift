//
//  PlayerSelectScreenView.swift
//  Executive Decision
//
//  Created by Amarjit on 04/11/2026.
//

import SwiftUI

struct PlayerSelectScreen: View {
    @State private var selectedPlayer: MockPlayer?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Who do you want to play as?")
                        .font(.custom("Georgia-Bold", size: 33))
                        .foregroundStyle(PlayerSetupStyle.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Choose your character")
                        .font(.system(size: 17, weight: .regular, design: .rounded))
                        .foregroundStyle(PlayerSetupStyle.mutedInk)
                }

                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 14
                ) {
                    ForEach(MockPlayer.roster) { player in
                        playerCard(for: player)
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 18)
            .padding(.bottom, 16)
        }
        .background(PlayerSetupStyle.paper.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            playButton
        }
    }

    private var playButton: some View {
        Button {
            guard let selectedPlayer else { return }
            print("You selected \(selectedPlayer.name)")
        } label: {
            Text("Play as \(selectedPlayer?.name ?? "…")")
                .font(.custom("Georgia-Bold", size: 23))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(
                    selectedPlayer == nil
                        ? PlayerSetupStyle.disabledButton
                        : PlayerSetupStyle.tomato
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(PlayerSetupStyle.ink, lineWidth: 3)
                }
        }
        .buttonStyle(.plain)
        .disabled(selectedPlayer == nil)
        .padding(.horizontal, 22)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(PlayerSetupStyle.paper)
    }

    private func playerCard(for player: MockPlayer) -> some View {
        let isSelected = selectedPlayer == player

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedPlayer = player
            }
        } label: {
            VStack(spacing: 5) {
                ZStack(alignment: .topTrailing) {
                    Image(player.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 136)
                        .padding(.horizontal, 7)
                        .padding(.top, 8)
                        .accessibilityHidden(true)

                    if isSelected {
                        Text("YOU")
                            .font(.custom("Georgia-Bold", size: 14))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(PlayerSetupStyle.tomato)
                            .rotationEffect(.degrees(5))
                            .padding(8)
                    }
                }
                .frame(maxWidth: .infinity)

                Text(player.name)
                    .font(.custom("Georgia-Bold", size: 23))
                    .foregroundStyle(PlayerSetupStyle.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.bottom, 9)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 196)
            .background(isSelected ? PlayerSetupStyle.gold : PlayerSetupStyle.card)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? PlayerSetupStyle.tomato : PlayerSetupStyle.ink,
                        lineWidth: isSelected ? 3 : 2
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(player.name)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    PlayerSelectScreen()
}

private struct MockPlayer: Identifiable, Hashable {
    let name: String
    let imageName: String

    var id: String { imageName }

    static let roster = [
        MockPlayer(name: "Rex", imageName: "avt-1"),
        MockPlayer(name: "Saxon", imageName: "avt-2"),
        MockPlayer(name: "Gordon", imageName: "avt-3"),
        MockPlayer(name: "Dean", imageName: "avt-4"),
        MockPlayer(name: "Morgan", imageName: "avt-5"),
        MockPlayer(name: "Alex", imageName: "avt-6")
    ]
}

enum PlayerSetupStyle {
    static let paper = Color(red: 0.96, green: 0.92, blue: 0.82)
    static let card = Color(red: 0.99, green: 0.97, blue: 0.92)
    static let ink = Color(red: 0.18, green: 0.13, blue: 0.10)
    static let mutedInk = Color(red: 0.42, green: 0.37, blue: 0.32)
    static let tomato = Color(red: 0.78, green: 0.22, blue: 0.07)
    static let gold = Color(red: 0.91, green: 0.62, blue: 0.08)
    static let disabledButton = Color(red: 0.68, green: 0.66, blue: 0.62)
}
