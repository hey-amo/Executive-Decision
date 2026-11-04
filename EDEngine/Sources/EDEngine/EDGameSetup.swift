/// Errors raised while validating game setup.
public enum EDGameSetupError: Error, Equatable, Sendable {
    /// Rules: Setup. The player count must be between 2 and 6.
    case invalidPlayerCount(Int)
}

/// Validated player count and starting cash for a new game.
///
/// Rules: Setup. Starting cash depends on the number of players.
public struct EDGameSetup: Equatable, Sendable {
    public let playerCount: Int
    public let startingCashPerPlayer: Int

    /// Creates setup for a supported player count.
    ///
    /// Rules: Setup. Games have 2–6 players, with starting cash determined by
    /// player count.
    public init(playerCount: Int) throws(EDGameSetupError) {
        let startingCash: Int
        switch playerCount {
        case 2: startingCash = 900
        case 3: startingCash = 600
        case 4: startingCash = 450
        case 5: startingCash = 350
        case 6: startingCash = 300
        default: throw .invalidPlayerCount(playerCount)
        }

        self.playerCount = playerCount
        self.startingCashPerPlayer = startingCash
    }
}
