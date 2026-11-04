import XCTest
@testable import EDEngine

final class EDGameSettingsTests: XCTestCase {
    func testSettingsAreDisabledByDefault() async {
        let settings = EDGameSettings()

        for setting in EDGameSetting.allCases {
            let isEnabled = await settings.isEnabled(setting)
            XCTAssertFalse(isEnabled)
        }
    }

    func testToggleAndSetEnabledUpdateOnlySelectedSetting() async {
        let settings = EDGameSettings()

        let soundIsEnabled = await settings.toggle(.sound)
        XCTAssertTrue(soundIsEnabled)
        var currentSoundSetting = await settings.isEnabled(.sound)
        var currentMusicSetting = await settings.isEnabled(.music)
        XCTAssertTrue(currentSoundSetting)
        XCTAssertFalse(currentMusicSetting)

        await settings.setEnabled(true, for: .music)
        await settings.setEnabled(true, for: .music)
        currentMusicSetting = await settings.isEnabled(.music)
        XCTAssertTrue(currentMusicSetting)

        let soundIsStillEnabled = await settings.toggle(.sound)
        XCTAssertFalse(soundIsStillEnabled)
        currentSoundSetting = await settings.isEnabled(.sound)
        XCTAssertFalse(currentSoundSetting)
    }

    func testPreferencesReflectCurrentInMemoryState() async {
        let settings = EDGameSettings(enabledSettings: [.sound, .darkMode])

        let preferences = await settings.preferences

        XCTAssertEqual(
            preferences,
            [
                .sound(enabled: true),
                .music(enabled: false),
                .haptic(enabled: false),
                .darkMode(enabled: true)
            ]
        )
    }

    func testConcurrentTogglesAreSerialized() async throws {
        let settings = EDGameSettings()

        try await withThrowingTaskGroup(of: Void.self) { group in
            for _ in 0..<500 {
                group.addTask {
                    await settings.toggle(.sound)
                }
            }
            try await group.waitForAll()
        }

        let isEnabled = await settings.isEnabled(.sound)
        XCTAssertFalse(isEnabled)
    }
}
