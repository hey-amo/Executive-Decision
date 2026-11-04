// # Executive Decision Game Engine
// Swift package

import Foundation

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
    case phaseActionNotSubmitted(EDGameState)
    case phaseActionAlreadySubmitted(EDGameState)
    case invalidOrderQuantity(RawMaterial)
    case invalidBidPrice(RawMaterial)
}

public struct EDRawMaterialOrder: Sendable {
    public let units: Int
    public let bidPrice: Int

    public init(units: Int, bidPrice: Int) {
        self.units = units
        self.bidPrice = bidPrice
    }
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
    public private(set) var submittedRawMaterialOrders:
        [Int: [UUID: [RawMaterial: EDRawMaterialOrder]]] = [:]

    private var turnOrderManager: EDTurnOrderManager
    private var submittedActionPlayerNumbers: Set<Int> = []

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

    /// Marks a player ready only after their current phase action was submitted.
    public func markPlayerReady(_ player: Player) throws {
        guard isActionPhase else {
            throw EDGameReadinessError.notActionablePhase(gameState)
        }
        let playerNumber = try validateActivePlayer(player)
        // Acknowledgement cannot replace the phase's submitted action.
        guard submittedActionPlayerNumbers.contains(playerNumber) else {
            throw EDGameReadinessError.phaseActionNotSubmitted(gameState)
        }

        readyPlayerNumbers.insert(playerNumber)
        turnOrderManager.advanceTurn()
    }

    /// Submits the player's raw-material order for the active purchase phase.
    public func submitRawMaterialOrder(
        _ orders: [RawMaterial: EDRawMaterialOrder],
        for player: Player
    ) throws {
        try validateActionSubmission(for: player, during: .purchaseRawMaterials)
        for (material, order) in orders {
            guard order.units >= 0 else {
                throw EDGameReadinessError.invalidOrderQuantity(material)
            }
            guard order.bidPrice >= 0 else {
                throw EDGameReadinessError.invalidBidPrice(material)
            }
        }

        let playerNumber = try playerNumber(for: player)
        submittedRawMaterialOrders[currentMonth, default: [:]][player.id] = orders
        submittedActionPlayerNumbers.insert(playerNumber)
    }

    /// Records the player's production for the active manufacturing phase.
    public func submitProduction(
        _ quantities: [FinishedGood: Int],
        for player: Player
    ) throws {
        try validateActionSubmission(for: player, during: .manufactureProducts)
        var updatedGoods = player.monthlyGoods
        try updatedGoods.recordProduction(quantities)
        player.monthlyGoods = updatedGoods
        submittedActionPlayerNumbers.insert(try playerNumber(for: player))
    }

    /// Records the player's completed offers and sales for the active sales phase.
    public func submitSales(
        _ sales: [FinishedGood: EDSaleEntry],
        for player: Player
    ) throws {
        try validateActionSubmission(for: player, during: .sellingFinishedGoods)
        let offers = sales.mapValues(\.unitsOffered)
        let sold = sales.mapValues(\.unitsSold)
        var updatedGoods = player.monthlyGoods
        try updatedGoods.recordOffer(offers)
        try updatedGoods.recordSales(sold)
        player.monthlyGoods = updatedGoods
        submittedActionPlayerNumbers.insert(try playerNumber(for: player))
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
        submittedActionPlayerNumbers.removeAll()
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

    private func validateActionSubmission(
        for player: Player,
        during phase: EDGameState
    ) throws {
        guard gameState == phase else {
            throw EDGameReadinessError.notActionablePhase(gameState)
        }
        let number = try validateActivePlayer(player)
        guard !submittedActionPlayerNumbers.contains(number) else {
            throw EDGameReadinessError.phaseActionAlreadySubmitted(phase)
        }
    }

    private func validateActivePlayer(_ player: Player) throws -> Int {
        guard !isPhaseBarrierReached else {
            throw EDGameReadinessError.phaseBarrierReached
        }
        let number = try playerNumber(for: player)
        let expectedPlayerNumber = turnOrderManager.currentPlayerNumber
        guard number == expectedPlayerNumber else {
            throw EDGameReadinessError.notActivePlayer(
                expectedPlayerNumber: expectedPlayerNumber,
                receivedPlayerNumber: number
            )
        }
        return number
    }

    private func playerNumber(for player: Player) throws -> Int {
        guard let number = players.firstIndex(where: { $0.id == player.id }).map({ $0 + 1 }) else {
            throw EDGameReadinessError.playerNotInGame
        }
        return number
    }
}
