// EDEngine.swift
// Main game engine

public enum EDGameState: Sendable, Codable {
    case mainMenu
    case inGame
    case paused
    case gameOver
}

public actor EDEngine {
    public private(set) var _state: EDGameState
    public var player: [EDPlayer]?

    public init(withState initialState: EDGameState = .mainMenu, players: [EDPlayer]? = nil) {
        self._state = initialState
        self.player = players
    }

    public func changeState(to newState: EDGameState) {
        _state = newState
    }
}