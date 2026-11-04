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
}

public class ExecutiveDecisionGame {
    public private(set) var currentMonth: Int
    public let duration: Int
    public var players: [Player]
    public private(set) var gameState: EDGameState
    public var settings: EDGameSettings
    public private(set) var marketBoard: EDMarketBoard

    init(currentMonth: Int = 1,
         maxMonths: Int = kConstants.durationLongGame,
         players: [Player],
         gameState: EDGameState = .setup,
         settings: EDGameSettings = EDGameSettings()) {
        self.currentMonth = currentMonth
        self.duration = maxMonths
        self.players = players
        self.gameState = gameState
        self.settings = settings
        self.marketBoard = EDMarketBoard()
    }

    @discardableResult
    public func advancePhase() throws -> EDGameState {
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
}
