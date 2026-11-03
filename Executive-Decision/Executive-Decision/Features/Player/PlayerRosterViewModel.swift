import Foundation
import EDEngine
import Observation

@Observable
final class PlayerRosterViewModel {
    private(set) var players: [EDPlayer]

    var availableCharacters: [PlayerCharacter] {
        PlayerCharacter.all.filter { character in
            !players.contains {
                $0.avatarResource == character.avatar || $0.name == character.name
            }
        }
    }

    var canContinue: Bool {
        players.count >= kConstants.minPlayers && players.contains { !$0.isAI }
    }

    init(firstPlayer: EDPlayer) {
        firstPlayer.isAI = false
        players = [firstPlayer]
    }

    func addPlayer(_ character: PlayerCharacter, isAI: Bool) {
        guard players.count < kConstants.maxPlayers,
              availableCharacters.contains(where: { $0.id == character.id }) else {
            return
        }

        players.append(EDPlayer(name: character.name, avatar: character.avatar, isAI: isAI))
    }

    func removePlayer(id: UUID) {
        guard players.first?.id != id,
              let index = players.firstIndex(where: { $0.id == id }) else {
            return
        }

        let remainingPlayers = players.enumerated()
            .filter { $0.offset != index }
            .map(\.element)
        guard remainingPlayers.contains(where: { !$0.isAI }) else {
            return
        }
        players = remainingPlayers
    }
}
