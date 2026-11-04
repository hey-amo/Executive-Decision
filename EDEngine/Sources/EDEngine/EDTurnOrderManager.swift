import Foundation

public enum TurnOrderError: Error, Equatable {
    case invalidPlayerCount
    case invalidTurnOrder([Int])
}

public struct EDTurnOrderManager {
    public private(set) var turnOrder: [Int]
    public private(set) var currentPlayerNumber: Int
    public private(set) var completedRounds = 0

    private var currentTurnIndex = 0

    public init(playerCount: Int, shuffle: Bool = true) throws {
        guard playerCount > 0 else {
            throw TurnOrderError.invalidPlayerCount
        }

        var players = Array(1...playerCount)
        if shuffle {
            players.shuffle()
        }
        self.turnOrder = players
        self.currentPlayerNumber = players[0]
    }

    public init(turnOrder: [Int]) throws {
        guard !turnOrder.isEmpty,
              Set(turnOrder).count == turnOrder.count,
              turnOrder.sorted() == Array(1...turnOrder.count) else {
            throw TurnOrderError.invalidTurnOrder(turnOrder)
        }

        self.turnOrder = turnOrder
        self.currentPlayerNumber = turnOrder[0]
    }

    /// Advances to the next player and returns true when the turn order wraps to a new round.
    @discardableResult
    public mutating func advanceTurn() -> Bool {
        currentTurnIndex += 1
        let roundCompleted = currentTurnIndex == turnOrder.count

        if roundCompleted {
            currentTurnIndex = 0
            completedRounds += 1
        }

        currentPlayerNumber = turnOrder[currentTurnIndex]
        return roundCompleted
    }
}