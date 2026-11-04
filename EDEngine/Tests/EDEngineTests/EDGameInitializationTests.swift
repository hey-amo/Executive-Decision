import XCTest
@testable import EDEngine

final class EDGameInitializationTests: XCTestCase {
    func testMarketBoardStartsAtRulesPricesAndCertificateCounts() {
        let board = EDMarketBoard()

        XCTAssertEqual(
            RawMaterial.allCases.map { board.price(for: $0) },
            [20, 30, 40]
        )
        XCTAssertEqual(
            FinishedGood.allCases.map { board.price(for: $0) },
            [140, 115, 90]
        )
        XCTAssertEqual(
            RawMaterial.allCases.map {
                board.availableRawMaterialCertificates[$0, default: 0]
            },
            Array(repeating: EDMarketBoard.rawMaterialCertificatesPerGrade, count: 3)
        )
    }

    func testMarketBoardAppliesMovementFromPreviousPrices() throws {
        var board = EDMarketBoard()

        try board.updateRawMaterialPrices(orderTotals: [
            .standard: 12,
            .fine: 0,
            .extraFine: 24
        ])
        try board.updateFinishedGoodPrices(offeringTotals: [
            .a: 1,
            .b: 16,
            .c: 0
        ])

        XCTAssertEqual(board.price(for: .standard), 22)
        XCTAssertEqual(board.price(for: .fine), 20)
        XCTAssertEqual(board.price(for: .extraFine), 54)
        XCTAssertEqual(board.price(for: .a), 149)
        XCTAssertEqual(board.price(for: .b), 94)
        XCTAssertEqual(board.price(for: .c), 101)
    }

    func testMarketBoardPriceUpdateIsAtomicOnInvalidTotals() {
        var board = EDMarketBoard()
        let initialPrices = board.rawMaterialPrices

        XCTAssertThrowsError(
            try board.updateRawMaterialPrices(orderTotals: [.fine: 25])
        ) { error in
            XCTAssertEqual(error as? MarketCalculatorError, .unitCountOutOfRange)
        }
        XCTAssertEqual(board.rawMaterialPrices, initialPrices)
    }

    func testGameExposesMarketUpdatesWithoutAllowingBoardReplacement() throws {
        let game = try EDGameSetupManager().startGame(playerCount: 2)

        try game.updateRawMaterialMarket(orderTotals: [.fine: 12])
        try game.updateFinishedGoodMarket(offeringTotals: [.a: 1])
        try game.takeRawMaterialCertificates(of: .standard, units: 2)

        XCTAssertEqual(game.marketBoard.price(for: .fine), 32)
        XCTAssertEqual(game.marketBoard.price(for: .a), 149)
        XCTAssertEqual(game.marketBoard.availableRawMaterialCertificates[.standard], 26)
    }

    func testCertificateStockCanBeTakenAndReturnedWithinSupply() throws {
        var board = EDMarketBoard()

        try board.takeCertificates(of: .fine, units: 7)
        XCTAssertEqual(board.availableRawMaterialCertificates[.fine], 21)
        try board.returnCertificates(of: .fine, units: 7)
        XCTAssertEqual(
            board.availableRawMaterialCertificates[.fine],
            EDMarketBoard.rawMaterialCertificatesPerGrade
        )

        XCTAssertThrowsError(try board.takeCertificates(of: .fine, units: 29)) { error in
            XCTAssertEqual(error as? EDMarketBoardError, .insufficientCertificates(.fine))
        }
        XCTAssertThrowsError(try board.returnCertificates(of: .fine, units: 29)) { error in
            XCTAssertEqual(error as? EDMarketBoardError, .certificateSupplyExceeded(.fine))
        }
        XCTAssertThrowsError(try board.takeCertificates(of: .fine, units: -1)) { error in
            XCTAssertEqual(error as? EDMarketBoardError, .invalidCertificateQuantity(-1))
        }
    }

    func testPlayerRawMaterialInventoryAddsAndConsumesAtomically() throws {
        let player = EDPlayer(name: "Player")
        try player.addRawMaterials([.fine: 2, .standard: 3])
        XCTAssertEqual(player.rawMaterialInventory, [.fine: 2, .standard: 3])

        XCTAssertThrowsError(
            try player.consumeRawMaterials([.fine: 3, .standard: 1])
        ) { error in
            XCTAssertEqual(error as? EDPlayerInventoryError, .insufficientMaterials(.fine))
        }
        XCTAssertEqual(player.rawMaterialInventory, [.fine: 2, .standard: 3])

        try player.consumeRawMaterials([.fine: 1, .standard: 2])
        XCTAssertEqual(player.rawMaterialInventory, [.fine: 1, .standard: 1])
    }

    func testMonthlyGoodsTrackProductionOfferAndSaleWithoutInventory() throws {
        var state = EDMonthlyGoodsState()
        try state.recordProduction([.a: 2, .c: 1])
        try state.recordOffer([.a: 1, .c: 1])
        try state.recordSales([.a: 1])

        XCTAssertEqual(state.produced, [.a: 2, .c: 1])
        XCTAssertEqual(state.offered, [.a: 1, .c: 1])
        XCTAssertEqual(state.sold, [.a: 1])
        XCTAssertThrowsError(try state.recordOffer([.a: 3])) { error in
            XCTAssertEqual(error as? EDMonthlyGoodsError, .offerExceedsProduction(.a))
        }
        XCTAssertThrowsError(try state.recordSales([.b: 1])) { error in
            XCTAssertEqual(error as? EDMonthlyGoodsError, .saleExceedsOffer(.b))
        }
    }

    func testGameAdvancesMonthsInOrderAndResetsMonthlyGoods() throws {
        let game = try EDGameSetupManager().startGame(
            playerCount: 2,
            durationMonths: kConstants.durationShortGame,
            shuffleTurnOrder: false
        )
        let player = try XCTUnwrap(game.players.first)
        try player.monthlyGoods.recordProduction([.a: 1])
        try player.monthlyGoods.recordOffer([.a: 1])

        XCTAssertEqual(try advancePhase(game), .purchaseRawMaterials)
        XCTAssertEqual(try advancePhase(game), .manufactureProducts)
        XCTAssertEqual(try advancePhase(game), .sellingFinishedGoods)
        XCTAssertEqual(try advancePhase(game), .purchaseRawMaterials)
        XCTAssertEqual(game.currentMonth, 2)
        XCTAssertTrue(player.monthlyGoods.produced.isEmpty)
        XCTAssertTrue(player.monthlyGoods.offered.isEmpty)

        var transitions: [EDGameState] = []
        while game.gameState != .gameOver {
            transitions.append(try advancePhase(game))
        }

        XCTAssertEqual(game.currentMonth, kConstants.durationShortGame)
        XCTAssertEqual(transitions.suffix(2), [.endOfYear, .gameOver])
        XCTAssertThrowsError(try game.advancePhase()) { error in
            XCTAssertEqual(
                error as? EDGameTransitionError,
                .invalidTransition(from: .gameOver)
            )
        }
    }

    func testGameRejectsPhaseTransitionsOutsideTheGameLoop() throws {
        let game = try EDGameSetupManager().startGame(playerCount: 2)
        try advanceToGameOver(game)

        XCTAssertThrowsError(try game.advancePhase()) { error in
            XCTAssertEqual(
                error as? EDGameTransitionError,
                .invalidTransition(from: .gameOver)
            )
        }
    }

    func testGameRequiresPlayersInTurnOrderToCompletePhaseBeforeAdvancing() throws {
        let game = try EDGameSetupManager().startGame(
            playerCount: 3,
            shuffleTurnOrder: false
        )
        let players = game.players

        XCTAssertEqual(game.turnOrder, [1, 2, 3])
        XCTAssertNil(game.activePlayer)
        XCTAssertThrowsError(try game.markPlayerReady(players[0])) { error in
            XCTAssertEqual(
                error as? EDGameReadinessError,
                .notActionablePhase(.setup)
            )
        }
        XCTAssertEqual(try game.advancePhase(), .purchaseRawMaterials)
        XCTAssertTrue(game.activePlayer === players[0])

        XCTAssertThrowsError(try game.advancePhase()) { error in
            XCTAssertEqual(
                error as? EDGameTransitionError,
                .phaseNotReady(remainingPlayerNumbers: [1, 2, 3])
            )
        }
        XCTAssertThrowsError(try game.markPlayerReady(players[1])) { error in
            XCTAssertEqual(
                error as? EDGameReadinessError,
                .notActivePlayer(expectedPlayerNumber: 1, receivedPlayerNumber: 2)
            )
        }

        try game.markPlayerReady(players[0])
        XCTAssertEqual(game.readyPlayerNumbers, [1])
        XCTAssertTrue(game.activePlayer === players[1])
        XCTAssertThrowsError(try game.advancePhase()) { error in
            XCTAssertEqual(
                error as? EDGameTransitionError,
                .phaseNotReady(remainingPlayerNumbers: [2, 3])
            )
        }

        try game.markPlayerReady(players[1])
        try game.markPlayerReady(players[2])
        XCTAssertTrue(game.isPhaseBarrierReached)
        XCTAssertNil(game.activePlayer)
        XCTAssertThrowsError(try game.markPlayerReady(players[0])) { error in
            XCTAssertEqual(error as? EDGameReadinessError, .phaseBarrierReached)
        }

        XCTAssertEqual(try game.advancePhase(), .manufactureProducts)
        XCTAssertTrue(game.readyPlayerNumbers.isEmpty)
        XCTAssertTrue(game.activePlayer === players[0])
    }

    func testPlayerOutsideGameCannotMarkReadiness() throws {
        let game = try EDGameSetupManager().startGame(
            playerCount: 2,
            shuffleTurnOrder: false
        )
        try game.advancePhase()

        XCTAssertThrowsError(try game.markPlayerReady(EDPlayer(name: "Outsider"))) { error in
            XCTAssertEqual(error as? EDGameReadinessError, .playerNotInGame)
        }
    }

    func testEveryPlayerActionPhaseUsesReadinessBarrier() throws {
        let game = try EDGameSetupManager().startGame(
            playerCount: 2,
            durationMonths: kConstants.durationShortGame,
            shuffleTurnOrder: false
        )
        try game.advancePhase()

        for expectedNextPhase in [
            EDGameState.manufactureProducts,
            .sellingFinishedGoods,
            .purchaseRawMaterials
        ] {
            XCTAssertThrowsError(try game.advancePhase()) { error in
                XCTAssertEqual(
                    error as? EDGameTransitionError,
                    .phaseNotReady(remainingPlayerNumbers: [1, 2])
                )
            }
            while let activePlayer = game.activePlayer {
                try game.markPlayerReady(activePlayer)
            }
            XCTAssertTrue(game.isPhaseBarrierReached)
            XCTAssertEqual(try game.advancePhase(), expectedNextPhase)
            XCTAssertFalse(game.isPhaseBarrierReached)
        }
    }

    private func advanceToGameOver(_ game: ExecutiveDecisionGame) throws {
        while game.gameState != .gameOver {
            try advancePhase(game)
        }
    }

    @discardableResult
    private func advancePhase(_ game: ExecutiveDecisionGame) throws -> EDGameState {
        while let activePlayer = game.activePlayer {
            try game.markPlayerReady(activePlayer)
        }
        return try game.advancePhase()
    }
}
