// TurnOrderManager.swift

import Foundation

public protocol TurnOrderPlayer: Sendable, Equatable {
    associatedtype ID: Hashable
    var id: ID { get }
}

public enum TurnOrderDirection: Sendable, Equatable {
    case forward
    case reverse
}

public struct TurnOrderManager<Player: TurnOrderPlayer> {
    private let players: [Player]
    private var index: Int
    private let direction: TurnOrderDirection

    public init(players: [Player], direction: TurnOrderDirection = .forward) {
        precondition(players.count >= 2, "Turn order requires at least 2 players")
        self.players = players
        self.index = 0
        self.direction = direction
    }

    public var currentPlayer: Player {
        players[index]
    }

    public var allPlayers: [Player] {
        players
    }

    public var totalPlayers: Int {
        players.count
    }

    public var currentPlayerIsTurn: Bool {
        true
    }

    @discardableResult
    public mutating func advance() -> Player {
        let nextIndex: Int
        switch direction {
        case .forward:
            nextIndex = (index + 1) % players.count
        case .reverse:
            nextIndex = (index + players.count - 1) % players.count
        }

        index = nextIndex
        return currentPlayer
    }

    @discardableResult
    public mutating func skipCurrentPlayer() -> Player {
        advance()
    }
}