public enum EDGameSetupError: Error, Equatable {
    case invalidPlayerCount(Int)
    case invalidGameDuration(Int)
}

public struct EDGameSetupManager: Sendable {
    public let playerCount: Int
    public let durationMonths: Int
    public var settings: EDGameSettings

    public init(
        playerCount: Int,
        durationMonths: Int = kConstants.durationLongGame,
        settings: EDGameSettings = EDGameSettings()
    ) throws {
        guard (kConstants.minPlayers...kConstants.maxPlayers).contains(playerCount) else {
            throw EDGameSetupError.invalidPlayerCount(playerCount)
        }

        guard durationMonths == kConstants.durationShortGame
                || durationMonths == kConstants.durationLongGame else {
            throw EDGameSetupError.invalidGameDuration(durationMonths)
        }

        self.playerCount = playerCount
        self.durationMonths = durationMonths
        self.settings = settings
    }
}
