import AVFoundation
import XCTest
@testable import Executive_Decision

final class SoundPlayerTests: XCTestCase {
    func testBundledAudioFilesCanBeLoaded() throws {
        let resources = [
            ("vibedepot-slow-jazz", "mp3"),
            ("card-draw", "m4a"),
            ("card-play", "m4a"),
            ("card-shuffle", "m4a")
        ]

        for (name, fileExtension) in resources {
            let url = Bundle.main.url(
                forResource: name,
                withExtension: fileExtension,
                subdirectory: "Sounds"
            ) ?? Bundle.main.url(forResource: name, withExtension: fileExtension)

            let audioURL = try XCTUnwrap(url, "Missing bundled audio file: \(name).\(fileExtension)")
            let player = try AVAudioPlayer(contentsOf: audioURL)

            XCTAssertGreaterThan(player.duration, 0, "Audio file is empty: \(name).\(fileExtension)")
        }
    }

    func testDisablingSoundClearsPendingEffects() {
        let (_, continuation) = AsyncStream.makeStream(
            of: Void.self,
            bufferingPolicy: .bufferingNewest(1)
        )
        let mailbox = AudioCommandMailbox(continuation: continuation)
        mailbox.setSoundEnabled(true)
        mailbox.play(.cardDraw)

        mailbox.setSoundEnabled(false)

        let command = mailbox.takeSnapshot()
        XCTAssertFalse(command.soundEnabled)
        XCTAssertNil(command.pendingEffect)
        XCTAssertGreaterThan(command.stopGeneration, 0)
    }

    func testStopAllClearsPendingEffectsAndSuspendsPlayback() {
        let (_, continuation) = AsyncStream.makeStream(
            of: Void.self,
            bufferingPolicy: .bufferingNewest(1)
        )
        let mailbox = AudioCommandMailbox(continuation: continuation)
        mailbox.setSoundEnabled(true)
        mailbox.setMusicEnabled(true)
        mailbox.play(.cardDraw)

        mailbox.stopAll()

        let command = mailbox.takeSnapshot()
        XCTAssertTrue(command.isSuspended)
        XCTAssertTrue(command.musicEnabled)
        XCTAssertNil(command.pendingEffect)
    }

    func testOnlyLatestPendingEffectIsRetained() {
        let (_, continuation) = AsyncStream.makeStream(
            of: Void.self,
            bufferingPolicy: .bufferingNewest(1)
        )
        let mailbox = AudioCommandMailbox(continuation: continuation)
        mailbox.setSoundEnabled(true)
        mailbox.play(.cardDraw)
        mailbox.play(.cardPlay)

        XCTAssertEqual(mailbox.takeSnapshot().pendingEffect, .cardPlay)
    }
}
