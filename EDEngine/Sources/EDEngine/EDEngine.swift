// # Executive Decision Game Engine
// Swift package

public struct kConstants {
    public static let minPlayers: Int = 2
    public static let maxPlayers: Int = 6
    
    public static let durationShortGame: Int = 6
    public static let durationLongGame: Int = 12
    
    public static let maxMaterialUnitsCanHold: Int = 12
}

public enum GameState: Int, CaseIterable, Codable, Sendable {
    case setup
    case purchaseRawMaterials
    case manufactureProducts
    case sellingFinishedGoods
    case bidding
    case endOfYear
    case gameOver
    case takeALoan
}


public class ExecutiveDecisionGame {
    public var currentMonth: Int
    public let maxMonths: Int
    public var players: [Player]?
    public var gameState: GameState

    public init(currentMonth: Int = 1,
                maxMonths: Int = kConstants.durationLongGame,
                players: [Player],
                gameState: GameState = .setup) {
        self.currentMonth = currentMonth
        self.maxMonths = maxMonths
        self.players = players
        self.gameState = gameState
    }
}
