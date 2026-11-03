import EDEngine
import SwiftUI

struct PlayerCharacter: Identifiable {
    let name: String
    let avatar: Avatar

    var id: String { avatar.rawValue }

    static let all: [PlayerCharacter] = [
        PlayerCharacter(name: "Rex", avatar: .avt1),
        PlayerCharacter(name: "Saxon", avatar: .avt2),
        PlayerCharacter(name: "Gordon", avatar: .avt3),
        PlayerCharacter(name: "Dean", avatar: .avt4),
        PlayerCharacter(name: "Vivian", avatar: .avt5),
        PlayerCharacter(name: "Nanish", avatar: .avt6)
    ]
}

enum PlayerRosterStyle {
    static let parchment = Color(red: 0.96, green: 0.92, blue: 0.82)
    static let ink = Color(red: 0.19, green: 0.14, blue: 0.11)
    static let selected = Color(red: 0.91, green: 0.65, blue: 0.13)
    static let button = Color(red: 0.78, green: 0.25, blue: 0.08)
    static let muted = Color(red: 0.55, green: 0.50, blue: 0.41)
}

enum PlayerKind: String, CaseIterable, Identifiable {
    case human = "Human"
    case bot = "Bot"

    var id: String { rawValue }
    var isAI: Bool { self == .bot }
}

struct PlayerRosterHeaderView: View {
    let playerCount: Int
    let maximumPlayers: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("OFFLINE PLAY")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(PlayerRosterStyle.muted)
                Spacer()
                Text("\(playerCount) of \(maximumPlayers)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(PlayerRosterStyle.ink)
                    .accessibilityLabel("\(playerCount) of \(maximumPlayers) players")
            }

            Text("Who's playing?")
                .font(.system(size: 36, weight: .black, design: .serif))
                .foregroundStyle(PlayerRosterStyle.ink)
                .minimumScaleFactor(0.75)
                .lineLimit(1)

            Text("2 to 6 players. You're in.")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(PlayerRosterStyle.muted)
        }
    }
}

struct PlayerRosterRowView: View {
    let player: EDPlayer
    let isFirstPlayer: Bool
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            avatar
                .frame(width: 64, height: 64)
                .overlay {
                    Rectangle()
                        .stroke(PlayerRosterStyle.ink, lineWidth: 2)
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(player.name)
                    .font(.system(size: 23, weight: .black, design: .serif))
                    .foregroundStyle(PlayerRosterStyle.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(isFirstPlayer ? "You · Human" : (player.isAI ? "Bot" : "Human"))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(PlayerRosterStyle.ink)
            }

            Spacer(minLength: 4)

            if !isFirstPlayer {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 25, weight: .semibold))
                        .foregroundStyle(PlayerRosterStyle.ink.opacity(0.72))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove \(player.name)")
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
        .background(isFirstPlayer ? PlayerRosterStyle.selected : Color.white.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(PlayerRosterStyle.ink, lineWidth: isFirstPlayer ? 3 : 2)
        }
        .shadow(color: PlayerRosterStyle.ink, radius: 0, x: 4, y: 4)
    }

    @ViewBuilder
    private var avatar: some View {
        if let avatar = player.avatarResource {
            Image(avatar.rawValue)
                .resizable()
                .scaledToFill()
                .clipped()
        } else {
            Image(systemName: "person.fill")
                .font(.system(size: 28))
                .foregroundStyle(PlayerRosterStyle.ink)
                .background(PlayerRosterStyle.parchment)
        }
    }
}

struct AddPlayerButtonView: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text("Add player")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(PlayerRosterStyle.muted)
                Spacer()
                Image(systemName: "plus")
                    .font(.system(size: 19, weight: .black))
                    .foregroundStyle(PlayerRosterStyle.muted)
                    .frame(width: 44, height: 44)
                    .overlay {
                        Circle()
                            .stroke(PlayerRosterStyle.muted, style: StrokeStyle(lineWidth: 2, dash: [5, 3]))
                    }
            }
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity, minHeight: 76)
            .contentShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(PlayerRosterStyle.muted, style: StrokeStyle(lineWidth: 2, dash: [8, 5]))
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Choose an available player and whether they are human or a bot")
    }
}

struct ContinuePlayersButton: View {
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Continue")
                .font(.system(size: 24, weight: .black, design: .serif))
                .frame(maxWidth: .infinity, minHeight: 68)
                .foregroundStyle(.white)
                .background(
                    isEnabled ? PlayerRosterStyle.button : PlayerRosterStyle.muted.opacity(0.55),
                    in: RoundedRectangle(cornerRadius: 8)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(PlayerRosterStyle.ink, lineWidth: 3)
                }
                .shadow(color: PlayerRosterStyle.ink, radius: 0, x: 5, y: 5)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityHint(isEnabled ? "" : "Add at least one more player to continue")
    }
}

struct AvailablePlayersDrawer: View {
    @Environment(\.dismiss) private var dismiss
    let availablePlayers: [PlayerCharacter]
    let onSelect: (PlayerCharacter, PlayerKind) -> Void
    @State private var playerKind: PlayerKind = .human

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Add a player")
                        .font(.system(size: 28, weight: .black, design: .serif))
                        .foregroundStyle(PlayerRosterStyle.ink)
                    Text("Choose a character and player type.")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(PlayerRosterStyle.muted)
                }
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(PlayerRosterStyle.ink)
                        .frame(width: 40, height: 40)
                        .background(PlayerRosterStyle.ink.opacity(0.08), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close player picker")
            }

            Picker("Player type", selection: $playerKind) {
                ForEach(PlayerKind.allCases) { kind in
                    Text(kind.rawValue).tag(kind)
                }
            }
            .pickerStyle(.segmented)

            if availablePlayers.isEmpty {
                ContentUnavailableView(
                    "All players added",
                    systemImage: "person.3",
                    description: Text("You have reached the six-player limit.")
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(availablePlayers) { player in
                            Button {
                                onSelect(player, playerKind)
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    Image(player.avatar.rawValue)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 54, height: 54)
                                        .clipped()
                                        .overlay {
                                            Rectangle()
                                                .stroke(PlayerRosterStyle.ink, lineWidth: 2)
                                        }
                                    Text(player.name)
                                        .font(.system(size: 20, weight: .black, design: .serif))
                                        .foregroundStyle(PlayerRosterStyle.ink)
                                    Spacer()
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 27))
                                        .foregroundStyle(PlayerRosterStyle.button)
                                }
                                .padding(10)
                                .background(Color.white.opacity(0.65), in: RoundedRectangle(cornerRadius: 8))
                                .contentShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Add \(player.name) as \(playerKind.rawValue)")
                        }
                    }
                }
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(PlayerRosterStyle.parchment.ignoresSafeArea())
    }
}
