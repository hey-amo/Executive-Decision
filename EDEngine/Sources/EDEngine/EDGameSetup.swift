// EDGameSetup.swift

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

    /// Raw-material order limits for this game's player count.
    ///
    /// Rules: Raw order limits. Monthly unit limits depend on player count.
    public let rawOrderLimits: EDRawOrderLimits

    /// Creates setup for a supported player count.
    ///
    /// Rules: Setup. Games have 2–6 players, with starting cash determined by
    /// player count.
    public init(playerCount: Int) throws(EDGameSetupError) {
        let setupValues: (startingCash: Int, rawOrderLimits: EDRawOrderLimits)
        switch playerCount {
        case 2:
            setupValues = (
                900,
                EDRawOrderLimits(maximumTotalUnitsPerPlayer: 18, maximumUnitsPerGrade: 12)
            )
        case 3:
            setupValues = (
                600,
                EDRawOrderLimits(maximumTotalUnitsPerPlayer: 12, maximumUnitsPerGrade: nil)
            )
        case 4:
            setupValues = (
                450,
                EDRawOrderLimits(maximumTotalUnitsPerPlayer: 9, maximumUnitsPerGrade: nil)
            )
        case 5:
            setupValues = (
                350,
                EDRawOrderLimits(maximumTotalUnitsPerPlayer: 7, maximumUnitsPerGrade: nil)
            )
        case 6:
            setupValues = (
                300,
                EDRawOrderLimits(maximumTotalUnitsPerPlayer: 6, maximumUnitsPerGrade: nil)
            )
        default: throw .invalidPlayerCount(playerCount)
        }

        self.playerCount = playerCount
        self.startingCashPerPlayer = setupValues.startingCash
        self.rawOrderLimits = setupValues.rawOrderLimits
    }
}
