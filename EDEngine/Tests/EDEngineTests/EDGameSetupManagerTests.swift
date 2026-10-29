import XCTest
@testable import EDEngine

final class EDGameSetupManagerTests: XCTestCase {
    func testAcceptsPlayerCountsFromTwoThroughSixWithoutPlayerObjects() throws {
        for playerCount in kConstants.minPlayers...kConstants.maxPlayers {
            let setup = try EDGameSetupManager(playerCount: playerCount)
            XCTAssertEqual(setup.playerCount, playerCount)
        }
    }

    func testRejectsPlayerCountsOutsideSupportedRange() {
        for playerCount in [kConstants.minPlayers - 1, kConstants.maxPlayers + 1] {
            XCTAssertThrowsError(try EDGameSetupManager(playerCount: playerCount)) { error in
                XCTAssertEqual(error as? EDGameSetupError, .invalidPlayerCount(playerCount))
            }
        }
    }

    func testSupportsSixOrTwelveMonthGameDuration() throws {
        let shortGame = try EDGameSetupManager(
            playerCount: kConstants.minPlayers,
            durationMonths: kConstants.durationShortGame
        )
        let longGame = try EDGameSetupManager(
            playerCount: kConstants.maxPlayers,
            durationMonths: kConstants.durationLongGame
        )

        XCTAssertEqual(shortGame.durationMonths, 6)
        XCTAssertEqual(longGame.durationMonths, 12)
    }

    func testRejectsUnsupportedGameDuration() {
        XCTAssertThrowsError(
            try EDGameSetupManager(playerCount: kConstants.minPlayers, durationMonths: 9)
        ) { error in
            XCTAssertEqual(error as? EDGameSetupError, .invalidGameDuration(9))
        }
    }

    func testUsesDefaultDurationAndPreservesProvidedSettings() throws {
        let settings = EDGameSettings(
            allowLoans: true,
            allowPartialRawMaterialPurchases: true,
            soundEnabled: false,
            musicEnabled: true,
            hapticFeedbackEnabled: true
        )
        let setup = try EDGameSetupManager(playerCount: 3, settings: settings)

        XCTAssertEqual(setup.durationMonths, kConstants.durationLongGame)
        XCTAssertTrue(setup.settings.allowLoans)
        XCTAssertTrue(setup.settings.allowPartialRawMaterialPurchases)
        XCTAssertFalse(setup.settings.soundEnabled)
        XCTAssertTrue(setup.settings.musicEnabled)
        XCTAssertTrue(setup.settings.hapticFeedbackEnabled)
    }
}
