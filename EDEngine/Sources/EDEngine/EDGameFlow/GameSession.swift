import Foundation

/// The single actor responsible for collecting decisions and committing game rules.
///
/// Rules: FR-15 through FR-17. Pending decisions and intermediate month
/// progress remain actor-isolated and are never included in public snapshots.
@available(macOS 10.15, *)
public actor GameSession {
    private var gameState: EDGameState
    private var phase: EDGamePhase
    private var pendingRawOrders: [UUID: EDRawOrder] = [:]
    private var pendingGoodsOffers: [UUID: EDGoodsOffer] = [:]
    private var rawResolution: EDMonthRawResolution?
    private var endGameScore: EDEndGameScore?
    private let eventStream: AsyncStream<EDGameEvent>
    private let eventContinuation: AsyncStream<EDGameEvent>.Continuation

    /// Creates a session from a validated game state, scoring it if already complete.
    ///
    /// Rules: FR-16 resumes a complete game; FR-12 stores final standings once.
    public init(state: EDGameState) throws(EDGameSessionError) {
        gameState = state
        let initialPhase: EDGamePhase = state.isComplete
            ? .finished
            : .rawOrderSubmission(monthNumber: state.currentMonthNumber)
        phase = initialPhase
        let (stream, continuation) = AsyncStream.makeStream(of: EDGameEvent.self)
        eventStream = stream
        eventContinuation = continuation
        continuation.yield(.phaseChanged(initialPhase))

        if state.isComplete {
            do {
                endGameScore = try EDEndGameScorer.score(gameState: state)
                if let endGameScore {
                    continuation.yield(.gameFinished(endGameScore))
                }
                continuation.finish()
            } catch {
                throw .endGameScoring(error)
            }
        }
    }

    /// Returns the session's single-consumer ordered stream; pending inputs are not payloads.
    ///
    /// Rules: FR-15. Reveal events are emitted only after all seats submit.
    public func events() -> AsyncStream<EDGameEvent> {
        eventStream
    }

    /// Returns the current phase.
    ///
    /// Rules: FR-12. The phase gates which decisions can be submitted.
    public func currentPhase() -> EDGamePhase {
        phase
    }

    /// Returns a value snapshot of resolved public game state.
    ///
    /// Rules: FR-16. Pending decisions and intermediate progress are excluded.
    public func snapshot() -> EDGameState {
        gameState
    }

    /// Returns the final settlement and standings, if the game has ended.
    ///
    /// Rules: Ending the Game. Scoring is performed exactly once at completion.
    public func finalScore() -> EDEndGameScore? {
        endGameScore
    }

    /// Builds a player's view without exposing another player's pending input.
    ///
    /// Rules: FR-15. Each player receives their own unrevealed submission only.
    public func view(for playerID: UUID) throws(EDGameSessionError) -> EDPlayerView {
        guard gameState.players.contains(where: { $0.id == playerID }) else {
            throw .unknownPlayer(playerID)
        }

        let visiblePlayers: [EDPlayerState]
        let rawPrices: [EDRawMaterialGrade: Int]
        if let rawResolution {
            visiblePlayers = gameState.players.map {
                rawResolution.playerStatesForGoods[$0.id] ?? $0
            }
            rawPrices = rawResolution.rawMarket.rawMaterialPrices
        } else {
            visiblePlayers = gameState.players
            rawPrices = gameState.priceBoard.rawMaterialPrices
        }

        return EDPlayerView(
            playerID: playerID,
            phase: phase,
            players: visiblePlayers,
            rawMaterialPrices: rawPrices,
            finishedGoodPrices: gameState.priceBoard.finishedGoodPrices,
            ownRawOrder: pendingRawOrders[playerID],
            ownGoodsOffer: pendingGoodsOffers[playerID]
        )
    }

    /// Accepts one raw order, resolving the raw stage once every seat has submitted.
    ///
    /// Rules: FR-5 through FR-8. Invalid or duplicate submissions do not mutate
    /// accepted submissions or advance the phase.
    public func submitRawOrder(
        _ order: EDRawOrder,
        for playerID: UUID
    ) throws(EDGameSessionError) -> EDSubmissionStatus {
        let expectedPhase = EDGamePhase.rawOrderSubmission(
            monthNumber: gameState.currentMonthNumber
        )
        guard phase == expectedPhase else {
            throw .wrongPhase(expected: expectedPhase, actual: phase)
        }
        guard gameState.players.contains(where: { $0.id == playerID }) else {
            throw .unknownPlayer(playerID)
        }
        guard pendingRawOrders[playerID] == nil else {
            throw .duplicateSubmission(playerID)
        }

        do {
            try EDRawOrderValidator.validate(
                order,
                limits: gameState.configuration.rawOrderLimits,
                previousPrices: gameState.priceBoard.rawMaterialPrices
            )
        } catch {
            throw .rawOrderValidation(error)
        }

        var candidateOrders = pendingRawOrders
        candidateOrders[playerID] = order
        guard candidateOrders.count == gameState.players.count else {
            pendingRawOrders = candidateOrders
            eventContinuation.yield(
                .submissionProgress(
                    phase: phase,
                    submittedCount: candidateOrders.count,
                    totalCount: gameState.players.count
                )
            )
            return .waiting(
                submittedCount: candidateOrders.count,
                totalCount: gameState.players.count
            )
        }

        let resolved: EDMonthRawResolution
        do {
            resolved = try EDMonthResolver.resolveRawStage(
                gameState: gameState,
                ordersByPlayer: candidateOrders
            )
        } catch {
            throw .monthResolution(error)
        }
        let nextPhase: EDGamePhase
        do {
            nextPhase = try EDGamePhaseReducer.reduce(
                phase,
                action: .rawStageResolved
            )
        } catch {
            throw .phaseTransition(error)
        }

        pendingRawOrders.removeAll()
        rawResolution = resolved
        phase = nextPhase
        eventContinuation.yield(.rawOrdersRevealed(candidateOrders))
        eventContinuation.yield(.rawMarketResolved(resolved.rawMarket))
        eventContinuation.yield(.phaseChanged(nextPhase))
        return .advanced(to: nextPhase)
    }

    /// Accepts one goods offer, resolving and committing the month when all seats submit.
    ///
    /// Rules: FR-9 through FR-12. Only a complete, successful resolution
    /// commits state, emits reveal events, and advances the session.
    public func submitGoodsOffer(
        _ offer: EDGoodsOffer,
        for playerID: UUID
    ) throws(EDGameSessionError) -> EDSubmissionStatus {
        guard case let .goodsOfferSubmission(monthNumber) = phase else {
            throw .wrongPhase(
                expected: .goodsOfferSubmission(monthNumber: gameState.currentMonthNumber),
                actual: phase
            )
        }
        guard gameState.players.contains(where: { $0.id == playerID }) else {
            throw .unknownPlayer(playerID)
        }
        guard pendingGoodsOffers[playerID] == nil else {
            throw .duplicateSubmission(playerID)
        }
        guard let progress = rawResolution, monthNumber == gameState.currentMonthNumber else {
            throw .monthResolution(.mismatchedProgress)
        }

        var candidateOffers = pendingGoodsOffers
        candidateOffers[playerID] = offer
        guard candidateOffers.count == gameState.players.count else {
            pendingGoodsOffers = candidateOffers
            eventContinuation.yield(
                .submissionProgress(
                    phase: phase,
                    submittedCount: candidateOffers.count,
                    totalCount: gameState.players.count
                )
            )
            return .waiting(
                submittedCount: candidateOffers.count,
                totalCount: gameState.players.count
            )
        }

        let resolution: EDMonthResolution
        do {
            resolution = try EDMonthResolver.resolveGoodsStage(
                rawResolution: progress,
                offersByPlayer: candidateOffers
            )
        } catch {
            throw .monthResolution(error)
        }
        let nextPhase: EDGamePhase
        do {
            nextPhase = try EDGamePhaseReducer.reduce(
                phase,
                action: .monthResolved(monthCount: gameState.configuration.monthCount)
            )
        } catch {
            throw .phaseTransition(error)
        }

        let finalScore: EDEndGameScore?
        if nextPhase == .finished {
            do {
                finalScore = try EDEndGameScorer.score(gameState: resolution.nextGameState)
            } catch {
                throw .endGameScoring(error)
            }
        } else {
            finalScore = nil
        }

        gameState = resolution.nextGameState
        pendingGoodsOffers.removeAll()
        rawResolution = nil
        endGameScore = finalScore
        phase = nextPhase
        eventContinuation.yield(.goodsOffersRevealed(candidateOffers))
        eventContinuation.yield(.monthResolved(resolution.monthResult))
        if let finalScore {
            eventContinuation.yield(.gameFinished(finalScore))
        }
        eventContinuation.yield(.phaseChanged(nextPhase))
        if nextPhase == .finished {
            eventContinuation.finish()
        }
        return .advanced(to: nextPhase)
    }
}

/// Errors raised while submitting decisions or coordinating a game session.
public enum EDGameSessionError: Error, Equatable, Sendable {
    case wrongPhase(expected: EDGamePhase, actual: EDGamePhase)
    case unknownPlayer(UUID)
    case duplicateSubmission(UUID)
    case rawOrderValidation(EDRawOrderValidationError)
    case monthResolution(EDMonthResolverError)
    case phaseTransition(EDGamePhaseReducerError)
    case endGameScoring(EDEndGameScorerError)
}
