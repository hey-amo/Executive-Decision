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
    public let avatarResource: String

    public init(withState initialState: EDGameState = .mainMenu, 
        players: [EDPlayer]? = nil, avatarResource: String = "avt-1.png") {
        self._state = initialState
        self.player = players
        self.avatarResource = avatarResource
    }

    public func changeState(to newState: EDGameState) {
        _state = newState
    }
}