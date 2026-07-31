import Foundation

public enum GamePhase: Int, Codable, Sendable, Equatable {
    case setup, main, gameOver
}


// Game class to manage the overall game state
public class ExecutiveDecisionGame {
    public var phase: GamePhase
    public var turnOrderManager: TurnOrderManager<AnyTurnOrderPlayer>
    public var players: [AnyTurnOrderPlayer]
}