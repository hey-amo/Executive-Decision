import Foundation

public enum GamePhase: Int, Codable, Sendable, Equatable {
    case setup, main, gameOver
}


// Game class to manage the overall game state
public class ExecutiveDecisionGame {
    public var phase: GamePhase
    public var turnOrderManager: any TurnOrderManager<TurnOrderPlayer>
    public var players: [Player]

    init(players: [Player]) {
        self.phase = .setup
        self.players = players
        self.turnOrderManager = TurnOrderManager(players: players)
    }
}