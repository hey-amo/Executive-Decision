import Foundation

/// The submission phase currently controlled by a game session.
public enum EDGamePhase: Codable, Equatable, Hashable, Sendable {
    case rawOrderSubmission(monthNumber: Int)
    case goodsOfferSubmission(monthNumber: Int)
    case finished
}

/// Actions that advance the game lifecycle.
public enum EDGamePhaseAction: Equatable, Sendable {
    case rawStageResolved
    case monthResolved(monthCount: Int)
}

/// Errors raised when a requested lifecycle transition is invalid.
public enum EDGamePhaseReducerError: Error, Equatable, Sendable {
    case invalidTransition(phase: EDGamePhase, action: EDGamePhaseAction)
    case invalidMonthCount(Int)
    case invalidMonthNumber(Int)
}

/// Applies the deterministic month lifecycle transitions.
public enum EDGamePhaseReducer {
    /// Advances to goods offers after raw resolution, or advances/finishes after a month.
    ///
    /// Rules: FR-7 through FR-12. Submission and resolution ownership stays in
    /// GameSession; this reducer only determines the next phase.
    public static func reduce(
        _ phase: EDGamePhase,
        action: EDGamePhaseAction
    ) throws(EDGamePhaseReducerError) -> EDGamePhase {
        switch (phase, action) {
        case let (.rawOrderSubmission(monthNumber), .rawStageResolved):
            guard monthNumber > 0 else {
                throw .invalidMonthNumber(monthNumber)
            }
            return .goodsOfferSubmission(monthNumber: monthNumber)
        case let (.goodsOfferSubmission(monthNumber), .monthResolved(monthCount)):
            guard monthCount > 0 else {
                throw .invalidMonthCount(monthCount)
            }
            guard (1...monthCount).contains(monthNumber) else {
                throw .invalidMonthNumber(monthNumber)
            }
            return monthNumber < monthCount
                ? .rawOrderSubmission(monthNumber: monthNumber + 1)
                : .finished
        default:
            throw .invalidTransition(phase: phase, action: action)
        }
    }
}

/// A player's read-only projection of public state and their own unrevealed input.
///
/// Rules: FR-15. The view omits all other players' pending submissions.
public struct EDPlayerView: Equatable, Sendable {
    public let playerID: UUID
    public let phase: EDGamePhase
    public let players: [EDPlayerState]
    public let rawMaterialPrices: [EDRawMaterialGrade: Int]
    public let finishedGoodPrices: [EDRecipe: Int]
    public let ownRawOrder: EDRawOrder?
    public let ownGoodsOffer: EDGoodsOffer?

    init(
        playerID: UUID,
        phase: EDGamePhase,
        players: [EDPlayerState],
        rawMaterialPrices: [EDRawMaterialGrade: Int],
        finishedGoodPrices: [EDRecipe: Int],
        ownRawOrder: EDRawOrder?,
        ownGoodsOffer: EDGoodsOffer?
    ) {
        self.playerID = playerID
        self.phase = phase
        self.players = players
        self.rawMaterialPrices = rawMaterialPrices
        self.finishedGoodPrices = finishedGoodPrices
        self.ownRawOrder = ownRawOrder
        self.ownGoodsOffer = ownGoodsOffer
    }
}

/// The result of accepting a submission.
public enum EDSubmissionStatus: Equatable, Sendable {
    case waiting(submittedCount: Int, totalCount: Int)
    case advanced(to: EDGamePhase)
}

/// Immutable, ordered notifications from committed game-session transitions.
public enum EDGameEvent: Sendable {
    case phaseChanged(EDGamePhase)
    case submissionProgress(phase: EDGamePhase, submittedCount: Int, totalCount: Int)
    case rawOrdersRevealed([UUID: EDRawOrder])
    case rawMarketResolved(EDRawMarketResolution)
    case goodsOffersRevealed([UUID: EDGoodsOffer])
    case monthResolved(EDMonthResult)
    case gameFinished(EDEndGameScore)
}
