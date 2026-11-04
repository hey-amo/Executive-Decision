// # Executive Decision Game Engine
// Swift package

public struct kConstants {
    public static let minPlayers: Int = 2
    public static let maxPlayers: Int = 6
    
    public static let durationShortGame: Int = 6
    public static let durationLongGame: Int = 12
    
    public static let maxMaterialUnitsCanHold: Int = 12
    public static let repaymentAmountPerLoan: Int = 125 // how much a player must pay per loan they have 
}

public enum EDGameState: Int, CaseIterable, Codable, Sendable {
    case setup
    case purchaseRawMaterials
    case manufactureProducts
    case sellingFinishedGoods
    case bidding
    case endOfYear
    case gameOver
    case takeALoan
}

public enum EDThinkingState: Int, CaseIterable, Codable, Sendable {
    case idle, thinking, waiting, playing, done
}

public enum EDGameTransitionError: Error, Equatable {
    case invalidTransition(from: EDGameState)
    case phaseNotReady(remainingPlayerNumbers: [Int])
}

public enum EDGameReadinessError: Error, Equatable {
    case playerNotInGame
    case notActivePlayer(expectedPlayerNumber: Int, receivedPlayerNumber: Int)
    case phaseBarrierReached
    case notActionablePhase(EDGameState)
}

public class ExecutiveDecisionGame {
    public private(set) var currentMonth: Int
    public let duration: Int
    public private(set) var players: [Player]
    public private(set) var gameState: EDGameState
    public var settings: EDGameSettings
    public private(set) var marketBoard: EDMarketBoard
    public private(set) var turnOrder: [Int]
    public private(set) var readyPlayerNumbers: Set<Int> = []

    private var turnOrderManager: EDTurnOrderManager

    /// The player whose turn it is in an action phase, or nil outside a turn or at its barrier.
    public var activePlayer: Player? {
        guard isActionPhase, !isPhaseBarrierReached else {
            return nil
        }
        let playerIndex = turnOrderManager.currentPlayerNumber - 1
        guard players.indices.contains(playerIndex) else {
            return nil
        }
        return players[playerIndex]
    }

    public var isPhaseBarrierReached: Bool {
        isActionPhase && readyPlayerNumbers.count == players.count
    }

    init(currentMonth: Int = 1,
         maxMonths: Int = kConstants.durationLongGame,
         players: [Player],
         turnOrderManager: EDTurnOrderManager,
         gameState: EDGameState = .setup,
         settings: EDGameSettings = EDGameSettings()) {
        self.currentMonth = currentMonth
        self.duration = maxMonths
        self.players = players
        self.gameState = gameState
        self.settings = settings
        self.marketBoard = EDMarketBoard()
        self.turnOrderManager = turnOrderManager
        self.turnOrder = turnOrderManager.turnOrder
    }

    /// Completes the active player's action for this phase and advances the turn order.
    public func markPlayerReady(_ player: Player) throws {
        guard isActionPhase else {
            throw EDGameReadinessError.notActionablePhase(gameState)
        }
        guard !isPhaseBarrierReached else {
            throw EDGameReadinessError.phaseBarrierReached
        }
        guard let playerNumber = players.firstIndex(where: { $0.id == player.id }).map({ $0 + 1 }) else {
            throw EDGameReadinessError.playerNotInGame
        }
        let expectedPlayerNumber = turnOrderManager.currentPlayerNumber
        guard playerNumber == expectedPlayerNumber else {
            throw EDGameReadinessError.notActivePlayer(
                expectedPlayerNumber: expectedPlayerNumber,
                receivedPlayerNumber: playerNumber
            )
        }

        readyPlayerNumbers.insert(playerNumber)
        turnOrderManager.advanceTurn()
    }

    /// Advances only when every player has completed the current action phase.
    @discardableResult
    public func advancePhase() throws -> EDGameState {
        if isActionPhase, !isPhaseBarrierReached {
            let remainingPlayers = turnOrder
                .filter { !readyPlayerNumbers.contains($0) }
            throw EDGameTransitionError.phaseNotReady(
                remainingPlayerNumbers: remainingPlayers
            )
        }

        switch gameState {
        case .setup:
            gameState = .purchaseRawMaterials
        case .purchaseRawMaterials:
            gameState = .manufactureProducts
        case .manufactureProducts:
            gameState = .sellingFinishedGoods
        case .sellingFinishedGoods:
            if currentMonth == duration {
                gameState = .endOfYear
            } else {
                currentMonth += 1
                players.forEach { $0.monthlyGoods = EDMonthlyGoodsState() }
                gameState = .purchaseRawMaterials
            }
        case .endOfYear:
            gameState = .gameOver
        case .bidding, .gameOver, .takeALoan:
            throw EDGameTransitionError.invalidTransition(from: gameState)
        }

        readyPlayerNumbers.removeAll()
        return gameState
    }

    public func updateRawMaterialMarket(orderTotals: [RawMaterial: Int]) throws {
        try marketBoard.updateRawMaterialPrices(orderTotals: orderTotals)
    }

    public func updateFinishedGoodMarket(
        offeringTotals: [FinishedGood: Int]
    ) throws {
        try marketBoard.updateFinishedGoodPrices(offeringTotals: offeringTotals)
    }

    public func takeRawMaterialCertificates(
        of material: RawMaterial,
        units: Int
    ) throws {
        try marketBoard.takeCertificates(of: material, units: units)
    }

    public func returnRawMaterialCertificates(
        of material: RawMaterial,
        units: Int
    ) throws {
        try marketBoard.returnCertificates(of: material, units: units)
    }

    private var isActionPhase: Bool {
        switch gameState {
        case .purchaseRawMaterials, .manufactureProducts, .sellingFinishedGoods:
            true
        case .setup, .bidding, .endOfYear, .gameOver, .takeALoan:
            false
        }
    }
}
