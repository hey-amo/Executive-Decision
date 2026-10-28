// # Executive Decision Game Engine
// Swift package


public enum GameConstants {
    public static let minPlayers: Int = 2
    public static let maxPlayers: Int = 6

    public enum GameLength: Int {
        case shortGame = 6
        case longGame = 12
    }
}

public class ExecutiveDecisionGame {
    public var currentMonth: Int
    public let maxMonths: Int

    public init(currentMonth: Int = 1, maxMonths: Int = GameConstants.GameLength.longGame.rawValue) {
        self.currentMonth = 1
        self.maxMonths = GameConstants.GameLength.longGame.rawValue
    }
}