// EDGameState.swift — the game’s domain state, if represented as a value type.

/// Errors raised when validating a complete game state.
public enum EDGameStateError: Error, Equatable, Sendable {
    /// Rules: FR-1 The game must contain exactly the configured number of players.
    case invalidPlayerCount(expected: Int, actual: Int)

    /// Rules: Each player identity is unique within one game.
    case duplicatePlayerID

    /// Rules: A game cannot have more resolved months than configured.
    case tooManyMonthResults(maximum: Int, actual: Int)

    /// Rules: Resolved months are numbered consecutively starting at 1.
    case invalidMonthNumber(expected: Int, actual: Int)

    /// Rules: Every resolved month includes exactly one result per player.
    case invalidPlayerResults(monthNumber: Int)

    /// Rules: Price-board history contains one closing snapshot per resolved month.
    case invalidPriceHistoryCount(expected: Int, actual: Int)

    /// Rules: Recorded closing prices match the corresponding month result.
    case closingPricesDoNotMatch(monthNumber: Int)
}

/// Serializable value state for a game, independent of engine orchestration.
///
/// Rules: FR-1 setup, FR-16 persistence, and FR-17 game state. Holds the game
/// configuration, each player's current state, the current market, and all
/// resolved monthly outcomes.
public struct EDGameState: Codable, Equatable, Hashable, Sendable {
    public let configuration: EDGameConfig
    public private(set) var players: [EDPlayerState]
    public private(set) var priceBoard: EDPriceBoard
    public private(set) var monthResults: [EDMonthResult]

    private enum CodingKeys: String, CodingKey {
        case configuration
        case players
        case priceBoard
        case monthResults
    }

    /// Creates a validated game state.
    ///
    /// Rules: FR-1 player count must match setup; FR-16 retains the current
    /// market and resolved month history.
    public init(
        configuration: EDGameConfig,
        players: [EDPlayerState],
        priceBoard: EDPriceBoard = EDPriceBoard(),
        monthResults: [EDMonthResult] = []
    ) throws(EDGameStateError) {
        guard players.count == configuration.playerCount else {
            throw .invalidPlayerCount(
                expected: configuration.playerCount,
                actual: players.count
            )
        }

        var playerIDs = Set<EDPlayerState.ID>()
        for player in players {
            guard playerIDs.insert(player.id).inserted else {
                throw .duplicatePlayerID
            }
        }

        guard monthResults.count <= configuration.monthCount else {
            throw .tooManyMonthResults(
                maximum: configuration.monthCount,
                actual: monthResults.count
            )
        }
        guard priceBoard.history.count == monthResults.count else {
            throw .invalidPriceHistoryCount(
                expected: monthResults.count,
                actual: priceBoard.history.count
            )
        }

        for (index, result) in monthResults.enumerated() {
            let expectedMonthNumber = index + 1
            guard result.monthNumber == expectedMonthNumber else {
                throw .invalidMonthNumber(
                    expected: expectedMonthNumber,
                    actual: result.monthNumber
                )
            }

            let resultPlayerIDs = Set(result.playerResults.map(\.playerID))
            guard resultPlayerIDs == playerIDs,
                  result.playerResults.count == players.count else {
                throw .invalidPlayerResults(monthNumber: result.monthNumber)
            }

            guard result.closingPrices == priceBoard.history[index] else {
                throw .closingPricesDoNotMatch(monthNumber: result.monthNumber)
            }
        }

        self.configuration = configuration
        self.players = players
        self.priceBoard = priceBoard
        self.monthResults = monthResults
    }

    /// The next month to resolve, or `monthCount + 1` when the game is complete.
    ///
    /// Rules: Setup month numbering starts at 1 and advances after each
    /// resolved month.
    public var currentMonthNumber: Int {
        monthResults.count + 1
    }

    /// Whether all configured months have been resolved.
    ///
    /// Rules: FR-12 The game ends after the configured number of months.
    public var isComplete: Bool {
        monthResults.count == configuration.monthCount
    }

    /// Decodes persisted state and validates relationships between its members.
    ///
    /// Rules: FR-16 Persistence resumes a valid game state.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let configuration = try container.decode(EDGameConfig.self, forKey: .configuration)
        let players = try container.decode([EDPlayerState].self, forKey: .players)
        let priceBoard = try container.decode(EDPriceBoard.self, forKey: .priceBoard)
        let monthResults = try container.decode([EDMonthResult].self, forKey: .monthResults)

        do {
            try self.init(
                configuration: configuration,
                players: players,
                priceBoard: priceBoard,
                monthResults: monthResults
            )
        } catch {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Game state contains inconsistent game data: \(error)"
                )
            )
        }
    }
}
