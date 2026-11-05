// EDGameConfig.swift — player count, month count, and enabled rule variations.


/// Optional rules that change how a game is resolved.
///
/// Rules: Variations. The loan and partial-purchase rules may each be used
/// independently or together.
public enum EDGameVariation: String, CaseIterable, Codable, Hashable, Sendable {
    case loans
    case partialRawPurchases
}

/// Validated settings for one game.
///
/// Rules: Setup. Games have 2–6 players, may use a player-selected number of
/// months, and may enable either or both optional variations.
public struct EDGameConfig: Codable, Equatable, Hashable, Sendable {
    public let playerCount: Int
    public let monthCount: Int
    public let enabledVariations: Set<EDGameVariation>

    /// Creates a game configuration.
    ///
    /// Rules: Setup and Variations. The player count must be 2–6, games use at
    /// least one month, and the optional variations can be combined.
    public init(
        playerCount: Int,
        monthCount: Int = 12,
        enabledVariations: Set<EDGameVariation> = []
    ) throws(EDGameConfigError) {
        guard monthCount > 0 else {
            throw .invalidMonthCount(monthCount)
        }

        do {
            _ = try EDGameSetup(playerCount: playerCount)
        } catch {
            throw .invalidPlayerCount(playerCount)
        }

        self.playerCount = playerCount
        self.monthCount = monthCount
        self.enabledVariations = enabledVariations
    }

    private enum CodingKeys: String, CodingKey {
        case playerCount
        case monthCount
        case enabledVariations
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let playerCount = try container.decode(Int.self, forKey: .playerCount)
        let monthCount = try container.decodeIfPresent(Int.self, forKey: .monthCount) ?? 12
        let enabledVariations = try container.decodeIfPresent(
            Set<EDGameVariation>.self,
            forKey: .enabledVariations
        ) ?? []

        do {
            try self.init(
                playerCount: playerCount,
                monthCount: monthCount,
                enabledVariations: enabledVariations
            )
        } catch {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Invalid game configuration: \(error)"
                )
            )
        }
    }
}

/// Errors raised when validating a game configuration.
public enum EDGameConfigError: Error, Equatable, Sendable {
    /// Rules: Setup. The player count must be between 2 and 6.
    case invalidPlayerCount(Int)

    /// Rules: Setup. A game must contain at least one month.
    case invalidMonthCount(Int)
}
