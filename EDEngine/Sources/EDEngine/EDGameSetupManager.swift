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
            return "Invalid player count: \(count). Must be between \(kConstants.minPlayers) and \(kConstants.maxPlayers)."
        case .invalidGameDuration(let duration):
            return "Invalid game duration: \(duration). Must be either \(kConstants.durationShortGame) or \(kConstants.durationLongGame) months."
        case .gameAlreadyInProgress:
            return "A game is already in progress."
        }
    }
}

public final class EDGameSetupManager: @unchecked Sendable {
    public static let shared = EDGameSetupManager()

    private let lock = NSLock()
    private var storedActiveGame: ExecutiveDecisionGame?

    private init() {}

    public var activeGame: ExecutiveDecisionGame? {
        lock.lock()
        defer { lock.unlock() }
        return storedActiveGame
    }

    public func startGame(
        playerCount: Int,
        durationMonths: Int = kConstants.durationLongGame,
        settings: EDGameSettings = EDGameSettings()
    ) throws -> ExecutiveDecisionGame {
        try Self.validate(playerCount: playerCount, durationMonths: durationMonths)

        lock.lock()
        defer { lock.unlock() }

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
