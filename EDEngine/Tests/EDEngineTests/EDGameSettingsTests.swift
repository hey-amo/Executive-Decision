import XCTest
@testable import EDEngine

final class EDGameSettingsTests: XCTestCase {
    func testGameSettingsDefaultBothOptionalRulesToOff() {
        let settings = EDGameSettings()

        XCTAssertFalse(settings.allowLoans)
        XCTAssertFalse(settings.allowPartialRawMaterialPurchases)
    }

    func testEachOptionalRuleCanBeToggledIndependently() {
        var settings = EDGameSettings()

        settings.allowLoans = true
        XCTAssertTrue(settings.allowLoans)
        XCTAssertFalse(settings.allowPartialRawMaterialPurchases)

        settings.allowPartialRawMaterialPurchases = true
        XCTAssertTrue(settings.allowLoans)
        XCTAssertTrue(settings.allowPartialRawMaterialPurchases)

        settings.allowLoans = false
        XCTAssertFalse(settings.allowLoans)
        XCTAssertTrue(settings.allowPartialRawMaterialPurchases)

        settings.soundEnabled = false
        XCTAssertFalse(settings.soundEnabled)

        settings.musicEnabled = false
        XCTAssertFalse(settings.musicEnabled)

        settings.darkModeEnabled = false
        XCTAssertFalse(settings.darkModeEnabled)

        settings.hapticFeedbackEnabled = false
        XCTAssertFalse(settings.hapticFeedbackEnabled) 
    }

    func testGameUsesProvidedSettingsAndAllowsToggling() {
        let settings = EDGameSettings(allowLoans: true)
        let game = ExecutiveDecisionGame(players: [], settings: settings)

        XCTAssertTrue(game.settings.allowLoans)
        XCTAssertFalse(game.settings.allowPartialRawMaterialPurchases)

        game.settings.allowPartialRawMaterialPurchases = true
        XCTAssertTrue(game.settings.allowLoans)
        XCTAssertTrue(game.settings.allowPartialRawMaterialPurchases)
    }
}
