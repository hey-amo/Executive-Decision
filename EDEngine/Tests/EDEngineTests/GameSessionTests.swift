import Foundation
import Testing
@testable import EDEngine

@Suite("Game session")
struct GameSessionTests {
    @Test("Keeps pending decisions private and reveals them only after the gate")
    @available(macOS 10.15, *)
    func keepsPendingInputsPrivate() async throws {
        let (state, players) = try makeGame(monthCount: 1)
        let session = try GameSession(state: state)
        var iterator = await session.events().makeAsyncIterator()
        let order = try EDRawOrder()

        guard case .some(.phaseChanged(.rawOrderSubmission(monthNumber: 1))) =
            await iterator.next() else {
            Issue.record("Expected initial raw-order phase event")
            return
        }

        let waiting = try await session.submitRawOrder(order, for: players[0].id)
        #expect(waiting == .waiting(submittedCount: 1, totalCount: 2))
        let ownView = try await session.view(for: players[0].id)
        let otherView = try await session.view(for: players[1].id)
        #expect(ownView.ownRawOrder == order)
        #expect(otherView.ownRawOrder == nil)

        guard case .some(.submissionProgress(
            phase: .rawOrderSubmission(monthNumber: 1),
            submittedCount: 1,
            totalCount: 2
        )) = await iterator.next() else {
            Issue.record("Expected private submission progress only")
            return
        }

        let advanced = try await session.submitRawOrder(order, for: players[1].id)
        #expect(advanced == .advanced(to: .goodsOfferSubmission(monthNumber: 1)))
        guard case .some(.rawOrdersRevealed(let revealedOrders)) = await iterator.next() else {
            Issue.record("Expected raw-order reveal after all submissions")
            return
        }
        #expect(revealedOrders == [players[0].id: order, players[1].id: order])
        guard case .some(.rawMarketResolved) = await iterator.next() else {
            Issue.record("Expected raw-market resolution event")
            return
        }
        guard case .some(.phaseChanged(.goodsOfferSubmission(monthNumber: 1))) =
            await iterator.next() else {
            Issue.record("Expected goods-offer phase event")
            return
        }

        let offer = try EDGoodsOffer()
        _ = try await session.submitGoodsOffer(offer, for: players[0].id)
        let ownGoodsView = try await session.view(for: players[0].id)
        let otherGoodsView = try await session.view(for: players[1].id)
        #expect(ownGoodsView.ownGoodsOffer == offer)
        #expect(otherGoodsView.ownGoodsOffer == nil)

        _ = try await session.submitGoodsOffer(offer, for: players[1].id)
        guard case .some(.submissionProgress(
            phase: .goodsOfferSubmission(monthNumber: 1),
            submittedCount: 1,
            totalCount: 2
        )) = await iterator.next() else {
            Issue.record("Expected private goods-offer progress")
            return
        }
        guard case .some(.goodsOffersRevealed(let revealedOffers)) = await iterator.next() else {
            Issue.record("Expected goods-offer reveal after all submissions")
            return
        }
        #expect(revealedOffers == [players[0].id: offer, players[1].id: offer])
        guard case .some(.monthResolved) = await iterator.next() else {
            Issue.record("Expected month summary event")
            return
        }
        guard case .some(.gameFinished) = await iterator.next() else {
            Issue.record("Expected end-game event")
            return
        }
        guard case .some(.phaseChanged(.finished)) = await iterator.next() else {
            Issue.record("Expected terminal phase event")
            return
        }
    }

    @Test("Serializes concurrent submissions and advances each stage once")
    @available(macOS 10.15, *)
    func serializesConcurrentSubmissions() async throws {
        let (state, players) = try makeGame(monthCount: 1)
        let session = try GameSession(state: state)
        let order = try EDRawOrder()

        async let first = session.submitRawOrder(order, for: players[0].id)
        async let second = session.submitRawOrder(order, for: players[1].id)
        let statuses = try await [first, second]

        #expect(statuses.contains(.waiting(submittedCount: 1, totalCount: 2)))
        #expect(statuses.contains(.advanced(to: .goodsOfferSubmission(monthNumber: 1))))
        #expect(await session.currentPhase() == .goodsOfferSubmission(monthNumber: 1))

        let offer = try EDGoodsOffer()
        _ = try await session.submitGoodsOffer(offer, for: players[0].id)
        let finalStatus = try await session.submitGoodsOffer(offer, for: players[1].id)
        #expect(finalStatus == .advanced(to: .finished))
        #expect(await session.currentPhase() == .finished)
        #expect(await session.snapshot().monthResults.count == 1)
        #expect(await session.finalScore() != nil)
        await #expect(throws: EDGameSessionError.wrongPhase(
            expected: .rawOrderSubmission(monthNumber: 2),
            actual: .finished
        )) {
            try await session.submitRawOrder(order, for: players[0].id)
        }
    }

    @Test("Rejects invalid, duplicate, unknown-seat, and out-of-phase submissions without mutation")
    @available(macOS 10.15, *)
    func rejectsInvalidSubmissionsWithoutMutation() async throws {
        let (state, players) = try makeGame(monthCount: 2)
        let session = try GameSession(state: state)
        let initialSnapshot = await session.snapshot()
        let unknownID = UUID(uuidString: "00000000-0000-0000-0000-000000000099")!

        await #expect(throws: EDGameSessionError.unknownPlayer(unknownID)) {
            try await session.submitRawOrder(try EDRawOrder(), for: unknownID)
        }
        await #expect(throws: EDGameSessionError.rawOrderValidation(.orderExceedsLimits)) {
            try await session.submitRawOrder(
                EDRawOrder(unitsByGrade: [.xfine: 13]),
                for: players[0].id
            )
        }
        _ = try await session.submitRawOrder(try EDRawOrder(), for: players[0].id)
        await #expect(throws: EDGameSessionError.duplicateSubmission(players[0].id)) {
            try await session.submitRawOrder(try EDRawOrder(), for: players[0].id)
        }
        #expect(await session.snapshot() == initialSnapshot)
        #expect(await session.currentPhase() == .rawOrderSubmission(monthNumber: 1))

        _ = try await session.submitRawOrder(try EDRawOrder(), for: players[1].id)
        await #expect(throws: EDGameSessionError.wrongPhase(
            expected: .rawOrderSubmission(monthNumber: 1),
            actual: .goodsOfferSubmission(monthNumber: 1)
        )) {
            try await session.submitRawOrder(try EDRawOrder(), for: players[0].id)
        }
        #expect(await session.snapshot() == initialSnapshot)
    }

    @Test("Runs every month before computing terminal standings")
    @available(macOS 10.15, *)
    func advancesAcrossMonthsAndScoresOnce() async throws {
        let (state, players) = try makeGame(monthCount: 2)
        let session = try GameSession(state: state)
        let order = try EDRawOrder()
        let offer = try EDGoodsOffer()

        for month in 1...2 {
            _ = try await session.submitRawOrder(order, for: players[0].id)
            let rawStatus = try await session.submitRawOrder(order, for: players[1].id)
            let expectedGoodsPhase = EDGamePhase.goodsOfferSubmission(monthNumber: month)
            #expect(rawStatus == .advanced(to: expectedGoodsPhase))
            _ = try await session.submitGoodsOffer(offer, for: players[0].id)
            let expectedNextPhase: EDGamePhase = month == 1
                ? .rawOrderSubmission(monthNumber: 2)
                : .finished
            let goodsStatus = try await session.submitGoodsOffer(offer, for: players[1].id)
            #expect(goodsStatus == .advanced(to: expectedNextPhase))
        }

        #expect(await session.snapshot().monthResults.count == 2)
        #expect(await session.finalScore()?.rankedPlayers.count == 2)
        #expect(await session.currentPhase() == .finished)
    }

    @Test("Rejects invalid lifecycle transitions and month numbers")
    func phaseReducerRejectsInvalidTransitions() throws {
        #expect(throws: EDGamePhaseReducerError.invalidTransition(
            phase: .rawOrderSubmission(monthNumber: 1),
            action: .monthResolved(monthCount: 1)
        )) {
            try EDGamePhaseReducer.reduce(
                .rawOrderSubmission(monthNumber: 1),
                action: .monthResolved(monthCount: 1)
            )
        }
        #expect(throws: EDGamePhaseReducerError.invalidMonthNumber(0)) {
            try EDGamePhaseReducer.reduce(
                .goodsOfferSubmission(monthNumber: 0),
                action: .monthResolved(monthCount: 1)
            )
        }
    }

    @Test("Does not commit a failed goods stage and permits a corrected final offer")
    @available(macOS 10.15, *)
    func retriesFailedGoodsResolutionAtomically() async throws {
        let configuration = try EDGameConfig(playerCount: 2, monthCount: 1)
        let players = try [
            EDPlayerState(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000011")!,
                name: "Alex",
                cashBalance: configuration.startingCashPerPlayer
            ),
            EDPlayerState(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000012")!,
                name: "Sam",
                cashBalance: configuration.startingCashPerPlayer,
                inventory: try EDInventory(certificatesByGrade: [.xfine: 12, .fine: 6])
            )
        ]
        let openingBoard = EDPriceBoard()
        var goodPrices = openingBoard.finishedGoodPrices
        goodPrices[.a] = Int.max
        let priceBoard = try EDPriceBoard(
            rawMaterialPrices: openingBoard.rawMaterialPrices,
            finishedGoodPrices: goodPrices
        )
        let state = try EDGameState(
            configuration: configuration,
            players: players,
            priceBoard: priceBoard
        )
        let session = try GameSession(state: state)
        let emptyOrder = try EDRawOrder()
        _ = try await session.submitRawOrder(emptyOrder, for: players[0].id)
        _ = try await session.submitRawOrder(emptyOrder, for: players[1].id)
        let emptyOffer = try EDGoodsOffer()
        _ = try await session.submitGoodsOffer(emptyOffer, for: players[0].id)

        await #expect(throws: EDGameSessionError.monthResolution(
            .goodsMarket(.priceOverflow(good: .a))
        )) {
            try await session.submitGoodsOffer(emptyOffer, for: players[1].id)
        }
        #expect(await session.snapshot() == state)
        #expect(await session.currentPhase() == .goodsOfferSubmission(monthNumber: 1))
        #expect(try await session.view(for: players[0].id).ownGoodsOffer == emptyOffer)
        #expect(try await session.view(for: players[1].id).ownGoodsOffer == nil)

        let correctedOffer = try EDGoodsOffer(
            unitsByGood: [.a: 6],
            askingPricesByGood: [.a: 1]
        )
        let status = try await session.submitGoodsOffer(
            correctedOffer,
            for: players[1].id
        )
        #expect(status == .advanced(to: .finished))
        #expect(await session.snapshot().monthResults.count == 1)
    }

    private func makeGame(
        monthCount: Int
    ) throws -> (EDGameState, [EDPlayerState]) {
        let configuration = try EDGameConfig(playerCount: 2, monthCount: monthCount)
        let players = try [
            EDPlayerState(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                name: "Alex",
                cashBalance: configuration.startingCashPerPlayer
            ),
            EDPlayerState(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
                name: "Sam",
                cashBalance: configuration.startingCashPerPlayer
            )
        ]
        return (try EDGameState(configuration: configuration, players: players), players)
    }
}
