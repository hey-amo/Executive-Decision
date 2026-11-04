//
//  PlayerSelectScreen.swift
//  Executive-Decision

import SwiftUI
import EDEngine

struct PlayerSelectScreen: View {
    private let onContinue: (EDPlayer) -> Void
    @State private var selectedCharacter = PlayerCharacter.all[0]

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    private let parchment = Color(red: 0.96, green: 0.92, blue: 0.82)
    private let ink = Color(red: 0.19, green: 0.14, blue: 0.11)
    private let selectedColor = Color(red: 0.91, green: 0.65, blue: 0.13)
    private let buttonColor = Color(red: 0.78, green: 0.25, blue: 0.08)

    init(onContinue: @escaping (EDPlayer) -> Void = { _ in }) {
        self.onContinue = onContinue
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Who do you want to play as?")
                        .font(.system(size: 30, weight: .black, design: .serif))
                        .foregroundStyle(ink)

                    Text("Choose your character")
                        .font(.subheadline)
                        .foregroundStyle(ink.opacity(0.75))
                }

                LazyVGrid(columns: columns, spacing: 18) {
                    ForEach(PlayerCharacter.all) { character in
                        characterCard(character)
                    }
                }
            }
            .padding(20)
        }
        .background(parchment.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button {
                onContinue(
                    EDPlayer(name: selectedCharacter.name, avatar: selectedCharacter.avatar)
                )
            } label: {
                Text("Play as \(selectedCharacter.name)")
                    .font(.system(size: 24, weight: .black, design: .serif))
                    .frame(maxWidth: .infinity, minHeight: 68)
                    .foregroundStyle(.white)
                    .background(buttonColor, in: RoundedRectangle(cornerRadius: 8))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(ink, lineWidth: 3)
                    }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 22)
            .padding(.top, 14)
            .padding(.bottom, 10)
            .background(parchment)
        }
    }

    private func characterCard(_ character: PlayerCharacter) -> some View {
        let isSelected = selectedCharacter.id == character.id

        return Button {
            selectedCharacter = character
        } label: {
            VStack(spacing: 8) {
                Image(character.avatar.rawValue)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 142)
                    .clipped()
                    .overlay(alignment: .topTrailing) {
                        if isSelected {
                            Text("YOU")
                                .font(.system(size: 14, weight: .black, design: .serif))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(buttonColor)
                                .rotationEffect(.degrees(7))
                                .offset(x: 8, y: -8)
                        }
                    }

                Text(character.name)
                    .font(.system(size: 21, weight: .black, design: .serif))
                    .foregroundStyle(ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.bottom, 4)
            }
            .padding(8)
            .background(isSelected ? selectedColor : Color.white.opacity(0.65))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? buttonColor : ink, lineWidth: isSelected ? 4 : 3)
            }
            .contentShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(character.name)\(isSelected ? ", selected" : "")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    PlayerSelectScreen()
}
