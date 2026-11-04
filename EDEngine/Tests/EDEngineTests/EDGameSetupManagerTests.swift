import XCTest
@testable import EDEngine

final class EDGameSetupManagerTests: XCTestCase {
    func testAcceptsPlayerCountsFromTwoThroughSixWithoutPlayerObjects() throws {
        for playerCount in kConstants.minPlayers...kConstants.maxPlayers {
            try EDGameSetupManager.validate(
                playerCount: playerCount,
                durationMonths: kConstants.durationLongGame
            )
        }
    }

    func testStartingCashMatchesRulesForEveryValidPlayerCount() throws {
        let expectedStartingCoins = [
            2: 900,
            3: 600,
            4: 450,
            5: 350,
            6: 300
        ]
        let manager = EDGameSetupManager()

        for playerCount in kConstants.minPlayers...kConstants.maxPlayers {
            let game = try manager.startGame(playerCount: playerCount)
            let startingCoins = try XCTUnwrap(expectedStartingCoins[playerCount])

            XCTAssertEqual(game.players.count, playerCount)
            XCTAssertEqual(
                game.players.map(\.coins),
                Array(repeating: startingCoins, count: playerCount),
                "Unexpected starting cash for \(playerCount) players"
            )
            try advanceToGameOver(game)
        }
    }

    func testRejectsPlayerCountsOutsideSupportedRange() {
        for playerCount in [kConstants.minPlayers - 1, kConstants.maxPlayers + 1] {
            XCTAssertThrowsError(
                try EDGameSetupManager.validate(
                    playerCount: playerCount,
                    durationMonths: kConstants.durationLongGame
                )
            ) { error in
                XCTAssertEqual(error as? EDGameSetupError, .invalidPlayerCount(playerCount))
            }
        }
    }

    func testSupportsSixOrTwelveMonthGameDuration() throws {
        try EDGameSetupManager.validate(
            playerCount: kConstants.minPlayers,
            durationMonths: kConstants.durationShortGame
        )
        try EDGameSetupManager.validate(
            playerCount: kConstants.maxPlayers,
            durationMonths: kConstants.durationLongGame
        )
    }

    func testRejectsUnsupportedGameDuration() {
        XCTAssertThrowsError(
            try EDGameSetupManager.validate(
                playerCount: kConstants.minPlayers,
                durationMonths: 9
            )
        ) { error in
            XCTAssertEqual(error as? EDGameSetupError, .invalidGameDuration(9))
        }
    }

    func testRejectNewGameAnotherUntilGameOver() throws {
        let settings = EDGameSettings(
            allowLoans: true,
            allowPartialRawMaterialPurchases: true,
            soundEnabled: false,
            musicEnabled: true,
            hapticFeedbackEnabled: true
        )
        let manager = EDGameSetupManager()
        let game = try manager.startGame(playerCount: 3, settings: settings)

        XCTAssertTrue(manager.activeGame === game)
        XCTAssertEqual(game.currentMonth, 1)
        XCTAssertEqual(game.duration, kConstants.durationLongGame)
        XCTAssertEqual(game.gameState, .setup)
        XCTAssertEqual(game.players.count, 3)
        XCTAssertEqual(game.players.map(\.name), ["Player 1", "Player 2", "Player 3"])
        XCTAssertTrue(game.settings.allowLoans)
        XCTAssertTrue(game.settings.allowPartialRawMaterialPurchases)
        XCTAssertFalse(game.settings.soundEnabled)
        XCTAssertTrue(game.settings.musicEnabled)
        XCTAssertTrue(game.settings.hapticFeedbackEnabled)

        XCTAssertThrowsError(try manager.startGame(playerCount: 2)) { error in
            XCTAssertEqual(error as? EDGameSetupError, .gameAlreadyInProgress)
        }
        XCTAssertTrue(manager.activeGame === game)
        try advanceToGameOver(game)
    }

    func testCanStartNewGameAfterCurrentGameIsOver() throws {
        let manager = EDGameSetupManager()

        let firstGame = try manager.startGame(playerCount: 2)
        try advanceToGameOver(firstGame)

        let secondGame = try manager.startGame(
            playerCount: 4,
            durationMonths: kConstants.durationShortGame
        )

        XCTAssertFalse(firstGame === secondGame)
        XCTAssertTrue(manager.activeGame === secondGame)
        XCTAssertEqual(secondGame.players.count, 4)
        XCTAssertEqual(secondGame.duration, kConstants.durationShortGame)
        try advanceToGameOver(secondGame)
    }

    func testSeparateSetupManagersManageSeparateGames() throws {
        let firstManager = EDGameSetupManager()
        let secondManager = EDGameSetupManager()

        let firstGame = try firstManager.startGame(playerCount: 2)
        let secondGame = try secondManager.startGame(playerCount: 3)

        XCTAssertFalse(firstGame === secondGame)
        XCTAssertTrue(firstManager.activeGame === firstGame)
        XCTAssertTrue(secondManager.activeGame === secondGame)

        try advanceToGameOver(firstGame)
        try advanceToGameOver(secondGame)
    }

    func testDebugStateDescriptionIncludesGameAndPlayerState() throws {
        let manager = EDGameSetupManager()
        let game = try manager.startGame(playerCount: 2, durationMonths: kConstants.durationShortGame)

        for _ in 0..<7 {
            try advancePhase(game)
        }

        let description = game.debugStateDescription

        XCTAssertTrue(description.contains("Month: 3/6"))
        XCTAssertTrue(description.contains("Players: 2"))
        XCTAssertTrue(description.contains("Turn order:"))
        XCTAssertTrue(description.contains("Current player: Player"))
        XCTAssertTrue(description.contains("Phase barrier reached: No"))
        XCTAssertTrue(description.contains("Deck: Not tracked"))
        XCTAssertTrue(description.contains("Game state: purchaseRawMaterials"))
        XCTAssertTrue(description.contains("Game phase: Purchase raw materials"))
        XCTAssertTrue(description.contains("Raw-material market:"))
        XCTAssertTrue(description.contains("Raw materials: Standard: 0, Fine: 0, Extra Fine: 0"))
        XCTAssertTrue(description.contains("Player 1"))
        XCTAssertTrue(description.contains("Coins: $900"))
        XCTAssertTrue(description.contains("This month's production: A: 0, B: 0, C: 0"))
        try advanceToGameOver(game)
    }

    private func advanceToGameOver(_ game: ExecutiveDecisionGame) throws {
        while game.gameState != .gameOver {
            try advancePhase(game)
        }
    }

    private func advancePhase(_ game: ExecutiveDecisionGame) throws {
        while let activePlayer = game.activePlayer {
            switch game.gameState {
            case .purchaseRawMaterials:
                try game.submitRawMaterialOrder([:], for: activePlayer)
            case .manufactureProducts:
                try game.submitProduction([:], for: activePlayer)
            case .sellingFinishedGoods:
                try game.submitSales([:], for: activePlayer)
            case .setup, .bidding, .endOfYear, .gameOver, .takeALoan:
                XCTFail("No player action can be submitted during \(game.gameState)")
            }
            try game.markPlayerReady(activePlayer)
        }
        try game.advancePhase()
    }
}
