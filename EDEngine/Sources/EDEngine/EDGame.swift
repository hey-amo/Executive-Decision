import Foundation

// Executive Decision Game
/**
Game is over 12 rounds (months). 2-6 players.
Most money wins.
Each month of play consists of: 
1. Purchase: Purchasing Raw Materials which are used in 
2. Manufacturing: Manufacturing the products of your choice and 
3. Selling: Selling of Finished Goods in an attempt to make the greatest profits for your corporation. 
*/

public enum GamePhase: Int, CaseIterable, Codable, Sendable, Equatable {
    case setup, main, gameOver
}

public enum GameState: CaseIterable, Sendable, Equatable {
    case setup, running, paused, finished
}

public enum DecisionState: CaseIterable, Sendable, Equatable {
    case idle, thinking, playing, completed
}

public enum EDPlayPhase: CaseIterable, Equatable {
    case purchase
    case manufacture
    case selling

    public static var allPhases: [EDPlayPhase] {
        Self.allCases
    }
}

public final class ExecutiveDecisionGame {
    public private(set) var phase: GamePhase
    public private(set) var state: GameState
    public private(set) var decisionState: DecisionState
    public private(set) var players: [Player]
    public private(set) var gameHistory: EDGameHistory
    public private(set) var turnOrderManager: TurnOrderManager<Player>
    public private(set) var currentMonthIndex: Int
    public let setup: EDGameSetup
    public let boardReference: EDMainBoardReference

    public var currentMonth: EDGameMonth {
        setup.months[currentMonthIndex]
    }

    public init(players: [Player], setup: EDGameSetup, turnOrderManager: TurnOrderManager<Player>, phase: GamePhase = .setup, state: GameState = .setup, decisionState: DecisionState = .idle, currentMonthIndex: Int = 0, gameHistory: EDGameHistory = EDGameHistory()) {
        self.players = players
        self.setup = setup
        self.boardReference = setup.boardReference
        self.turnOrderManager = turnOrderManager
        self.phase = phase
        self.state = state
        self.decisionState = decisionState
        self.currentMonthIndex = currentMonthIndex
        self.gameHistory = gameHistory
    }

    public func isGameOver() -> Bool {
        return (phase == .gameOver)
    }

    public func recordGameHistory(message: String, type: EDGameMessageType = .info) {
        gameHistory.append(type: type, message: message)
    }

    public func clearGameHistory() {
        gameHistory.clear()
    }

    public static func newGame(players: [Player], monthCount: Int = 12) -> ExecutiveDecisionGame {
        precondition(players.count >= 2 && players.count <= 6, "Game requires 2 to 6 players")

        let setup = EDGameSetup.standardSetup(monthCount: monthCount)
        let seededPlayers = players.map { player -> Player in
            player.cash = seedCapitalForPlayerCount(players.count)
            return player
        }

        let shuffledPlayers = seededPlayers.shuffled()
        let turnOrderManager = TurnOrderManager(players: shuffledPlayers)

        return ExecutiveDecisionGame(
            players: shuffledPlayers,
            setup: setup,
            turnOrderManager: turnOrderManager,
            phase: .setup,
            state: .setup,
            decisionState: .idle,
            currentMonthIndex: 0
        )
    }

    public static func seedCapitalForPlayerCount(_ count: Int) -> Int {
        switch count {
        case 2: return 900
        case 3: return 600
        case 4: return 450
        case 5: return 350
        case 6: return 300
        default: return 300
        }
    }

    public func advanceToNextMonth() {
        guard currentMonthIndex + 1 < setup.months.count else {
            phase = .gameOver
            state = .finished
            return
        }

        currentMonthIndex += 1
    }

    public func setDecisionState(_ newState: DecisionState) {
        decisionState = newState
    }
}
