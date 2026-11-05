//
//  PlayerRosterView.swift
//  Executive Decision
//

import SwiftUI

struct PlayerRosterView: View {
    private let currentPlayer = MockPlayer.rex

    @State private var rivalPlayers: [RivalPlayer] = []
    @State private var editorContext: PlayerEditorContext?

    private var playerCount: Int {
        rivalPlayers.count + 1
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                currentPlayerCard

                ForEach(rivalPlayers) { rival in
                    rivalPlayerRow(rival)
                }

                addPlayerButton
            }
            .padding(.horizontal, 22)
            .padding(.top, 18)
            .padding(.bottom, 24)
        }
        .background(PlayerSetupStyle.paper.ignoresSafeArea())
        .sheet(item: $editorContext) { context in
            editor(for: context)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text("OFFLINE PLAY")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(PlayerSetupStyle.mutedInk)

                Spacer()

                Text("\(playerCount) of 6")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(PlayerSetupStyle.ink)
                    .accessibilityLabel("\(playerCount) of 6 players")
            }

            Text("Who's playing?")
                .font(.custom("Georgia-Bold", size: 35))
                .foregroundStyle(PlayerSetupStyle.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text("2 to 6 players. You're in.")
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(PlayerSetupStyle.mutedInk)
        }
        .padding(.bottom, 3)
    }

    private var currentPlayerCard: some View {
        HStack(spacing: 14) {
            characterPortrait(currentPlayer, size: 72)

            VStack(alignment: .leading, spacing: 4) {
                Text(currentPlayer.name)
                    .font(.custom("Georgia-Bold", size: 24))
                    .foregroundStyle(PlayerSetupStyle.ink)

                Text("You · Human")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(PlayerSetupStyle.mutedInk)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PlayerSetupStyle.gold.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(PlayerSetupStyle.ink.opacity(0.55), lineWidth: 2)
        }
        .accessibilityElement(children: .combine)
    }

    private var addPlayerButton: some View {
        Button {
            editorContext = .add
        } label: {
            HStack(spacing: 14) {
                Text("Add player")
                    .font(.custom("Georgia-Bold", size: 21))
                    .foregroundStyle(PlayerSetupStyle.ink)

                Spacer()

                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(PlayerSetupStyle.ink)
                    .frame(width: 38, height: 38)
                    .background(PlayerSetupStyle.gold.opacity(0.55))
                    .clipShape(Circle())
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 76)
            .background(PlayerSetupStyle.card)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(PlayerSetupStyle.ink, style: StrokeStyle(lineWidth: 2, dash: [7, 5]))
            }
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(playerCount >= 6)
        .opacity(playerCount >= 6 ? 0.55 : 1)
        .accessibilityHint(
            playerCount >= 6
                ? "The maximum of six players has been reached."
                : "Opens character and player type options."
        )
    }

    private func rivalPlayerRow(_ rival: RivalPlayer) -> some View {
        HStack(spacing: 0) {
            Button {
                editorContext = .edit(rival.id)
            } label: {
                HStack(spacing: 14) {
                    characterPortrait(rival.character, size: 72)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(rival.character.name)
                            .font(.custom("Georgia-Bold", size: 24))
                            .foregroundStyle(PlayerSetupStyle.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        Text(rival.type.rawValue)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(PlayerSetupStyle.mutedInk)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.leading, 12)
                .padding(.vertical, 11)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens this player's settings.")

            if playerCount > 2 {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        rivalPlayers.removeAll { $0.id == rival.id }
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 25))
                        .foregroundStyle(PlayerSetupStyle.mutedInk)
                        .frame(width: 52, height: 72)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove \(rival.character.name)")
                .accessibilityHint("Removes this rival player.")
            }
        }
        .frame(maxWidth: .infinity, minHeight: 94)
        .background(PlayerSetupStyle.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(PlayerSetupStyle.ink, lineWidth: 2)
        }
    }

    private func characterPortrait(_ character: MockPlayer, size: CGFloat) -> some View {
        Image(character.avatarResource)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .background(PlayerSetupStyle.card)
            .overlay {
                Rectangle()
                    .stroke(PlayerSetupStyle.ink, lineWidth: 2)
            }
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private func editor(for context: PlayerEditorContext) -> some View {
        switch context {
        case .add:
            PlayerEditorSheet(
                title: "Add player",
                availableCharacters: availableCharacters(),
                initialCharacter: nil,
                initialType: .human
            ) { character, type in
                guard playerCount < 6,
                      !rivalPlayers.contains(where: { $0.character == character })
                else {
                    return
                }

                withAnimation(.easeInOut(duration: 0.15)) {
                    rivalPlayers.append(RivalPlayer(character: character, type: type))
                }
            }
        case .edit(let id):
            if let rival = rivalPlayers.first(where: { $0.id == id }) {
                PlayerEditorSheet(
                    title: "Edit player",
                    availableCharacters: availableCharacters(editing: id),
                    initialCharacter: rival.character,
                    initialType: rival.type
                ) { character, type in
                    guard let index = rivalPlayers.firstIndex(where: { $0.id == id }),
                          !rivalPlayers.contains(where: { $0.id != id && $0.character == character })
                    else {
                        return
                    }

                    withAnimation(.easeInOut(duration: 0.15)) {
                        rivalPlayers[index].character = character
                        rivalPlayers[index].type = type
                    }
                }
            }
        }
    }

    private func availableCharacters(editing id: UUID? = nil) -> [MockPlayer] {
        let assignedCharacters = Set(
            rivalPlayers
                .filter { $0.id != id }
                .map(\.character)
        )

        return MockPlayer.roster.filter {
            $0 != currentPlayer && !assignedCharacters.contains($0)
        }
    }
}

private struct PlayerEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let availableCharacters: [MockPlayer]
    let onSave: (MockPlayer, RivalType) -> Void

    @State private var selectedCharacter: MockPlayer?
    @State private var selectedType: RivalType

    init(
        title: String,
        availableCharacters: [MockPlayer],
        initialCharacter: MockPlayer?,
        initialType: RivalType,
        onSave: @escaping (MockPlayer, RivalType) -> Void
    ) {
        self.title = title
        self.availableCharacters = availableCharacters
        self.onSave = onSave
        _selectedCharacter = State(initialValue: initialCharacter)
        _selectedType = State(initialValue: initialType)
    }

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(title)
                            .font(.custom("Georgia-Bold", size: 29))
                            .foregroundStyle(PlayerSetupStyle.ink)

                        Text("Choose an available character.")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(PlayerSetupStyle.mutedInk)
                    }

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(PlayerSetupStyle.ink)
                            .frame(width: 34, height: 34)
                            .background(PlayerSetupStyle.gold.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Dismiss")
                }

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(availableCharacters) { character in
                        characterOption(character)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("PLAYER TYPE")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(PlayerSetupStyle.mutedInk)

                    Picker("Player type", selection: $selectedType) {
                        ForEach(RivalType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(PlayerSetupStyle.tomato)
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 24)
            .padding(.bottom, 20)
        }
        .background(PlayerSetupStyle.paper.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            confirmButton
        }
        .modifier(PlayerEditorPresentationStyle())
    }

    private func characterOption(_ character: MockPlayer) -> some View {
        let isSelected = selectedCharacter == character

        return Button {
            selectedCharacter = character
        } label: {
            VStack(spacing: 5) {
                Image(character.avatarResource)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 76)
                    .padding(.top, 7)
                    .accessibilityHidden(true)

                Text(character.name)
                    .font(.custom("Georgia-Bold", size: 17))
                    .foregroundStyle(PlayerSetupStyle.ink)
                    .lineLimit(1)
                    .padding(.bottom, 8)
            }
            .frame(maxWidth: .infinity)
            .background(isSelected ? PlayerSetupStyle.gold : PlayerSetupStyle.card)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isSelected ? PlayerSetupStyle.tomato : PlayerSetupStyle.ink,
                        lineWidth: isSelected ? 3 : 2
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(character.name)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var confirmButton: some View {
        Button {
            guard let selectedCharacter else { return }
            onSave(selectedCharacter, selectedType)
            dismiss()
        } label: {
            Text(title == "Add player" ? "Add player" : "Save player")
                .font(.custom("Georgia-Bold", size: 21))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(
                    selectedCharacter == nil
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
        .disabled(selectedCharacter == nil)
        .padding(.horizontal, 22)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(PlayerSetupStyle.paper)
    }
}

private struct PlayerEditorPresentationStyle: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            content
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(22)
        } else if #available(iOS 16.0, *) {
            content
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        } else {
            content
        }
    }
}

private struct RivalPlayer: Identifiable {
    let id = UUID()
    var character: MockPlayer
    var type: RivalType
}

private enum RivalType: String, CaseIterable, Identifiable {
    case human = "Human"
    case bot = "Bot"

    var id: Self { self }
}

private enum PlayerEditorContext: Identifiable {
    case add
    case edit(UUID)

    var id: String {
        switch self {
        case .add:
            "add"
        case .edit(let id):
            id.uuidString
        }
    }
}

#Preview {
    PlayerRosterView()
}
