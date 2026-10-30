// EDGameSetupManager.swift
// manages the game setup and initial state

import Foundation

public enum EDGameSetupError: Error, Equatable {
    case invalidPlayerCount(Int)
    case invalidGameDuration(Int)
    case gameAlreadyInProgress
}

extension EDGameSetupError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidPlayerCount(let count):
            let msg: String = "Invalid player count: \(count). Must be between \(kConstants.minPlayers) and \(kConstants.maxPlayers)."
            return NSLocalizedString("invalidPlayerCount", value: msg, comment: "invalidPlayerCount")
        case .invalidGameDuration(let duration):
            let msg = "Invalid game duration: \(duration). Must be either \(kConstants.durationShortGame) or \(kConstants.durationLongGame) months."
            return NSLocalizedString("invalidGameDuration", value: msg, comment: "invalidGameDuration")
        case .gameAlreadyInProgress:
            let msg = "A game is already in progress."
            return NSLocalizedString("gameAlreadyInProgress", value: msg, comment: "gameAlreadyInProgress")
        }
    }
}

public final class EDGameSetupManager {
    private var storedActiveGame: ExecutiveDecisionGame?

    public init() {}

    public var activeGame: ExecutiveDecisionGame? {
        return storedActiveGame
    }

    public func startGame(
        playerCount: Int,
        durationMonths: Int = kConstants.durationLongGame,
        settings: EDGameSettings = EDGameSettings()
    ) throws -> ExecutiveDecisionGame {
        try Self.validate(playerCount: playerCount, durationMonths: durationMonths)

        if let storedActiveGame, storedActiveGame.gameState != .gameOver {
            throw EDGameSetupError.gameAlreadyInProgress
        }

        let players = (1...playerCount).map { EDPlayer(name: "Player \($0)") }
        let game = ExecutiveDecisionGame(
            maxMonths: durationMonths,
            players: players,
            settings: settings
        )
        storedActiveGame = game        
        game.printDebugState()
        return game
    }

    public static func validate(playerCount: Int, durationMonths: Int) throws {
        guard (kConstants.minPlayers...kConstants.maxPlayers).contains(playerCount) else {
            throw EDGameSetupError.invalidPlayerCount(playerCount)
        }

        guard durationMonths == kConstants.durationShortGame
            || durationMonths == kConstants.durationLongGame else {
            throw EDGameSetupError.invalidGameDuration(durationMonths)
        }
    }
}
