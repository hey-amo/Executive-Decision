import Foundation

public enum GamePhase: Int, Codable, Sendable, Equatable {
    case setup, main, gameOver
}

public class ExecutiveDecisionGame {
    public var phase: GamePhase

    init(phase: GamePhase = .setup) {
        self.phase = phase
    }
}