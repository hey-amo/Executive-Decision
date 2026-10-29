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

    func testStartGameSpawnsConfiguredGameAndRejectsAnotherUntilGameOver() throws {
        let settings = EDGameSettings(
            allowLoans: true,
            allowPartialRawMaterialPurchases: true,
            soundEnabled: false,
            musicEnabled: true,
            hapticFeedbackEnabled: true
        )
        let manager = EDGameSetupManager()
        let game = try manager.startGame(playerCount: 3, settings: settings)
        defer { game.gameState = .gameOver }

        XCTAssertTrue(manager.activeGame === game)
        XCTAssertEqual(game.currentMonth, 1)
        XCTAssertEqual(game.maxMonths, kConstants.durationLongGame)
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
    }

    func testCanStartNewGameAfterCurrentGameIsOver() throws {
        let manager = EDGameSetupManager()

        let firstGame = try manager.startGame(playerCount: 2)
        firstGame.gameState = .gameOver

        let secondGame = try manager.startGame(
            playerCount: 4,
            durationMonths: kConstants.durationShortGame
        )
        defer { secondGame.gameState = .gameOver }

        XCTAssertFalse(firstGame === secondGame)
        XCTAssertTrue(manager.activeGame === secondGame)
        XCTAssertEqual(secondGame.players.count, 4)
        XCTAssertEqual(secondGame.maxMonths, kConstants.durationShortGame)
    }

    func testSeparateSetupManagersManageSeparateGames() throws {
        let firstManager = EDGameSetupManager()
        let secondManager = EDGameSetupManager()

        let firstGame = try firstManager.startGame(playerCount: 2)
        let secondGame = try secondManager.startGame(playerCount: 3)

        XCTAssertFalse(firstGame === secondGame)
        XCTAssertTrue(firstManager.activeGame === firstGame)
        XCTAssertTrue(secondManager.activeGame === secondGame)

        firstGame.gameState = .gameOver
        secondGame.gameState = .gameOver
    }
}
