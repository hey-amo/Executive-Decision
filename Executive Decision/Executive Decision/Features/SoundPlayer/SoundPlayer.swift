import AVFoundation
import Foundation
import OSLog
import Synchronization

/// Sound effects bundled with the game.
public enum AudioEffect: String, CaseIterable, Hashable, Sendable {
    case cardDraw = "card-draw"
    case cardPlay = "card-play"
    case cardShuffle = "card-shuffle"
}

struct AudioCommandSnapshot: Sendable {
    let soundEnabled: Bool
    let musicEnabled: Bool
    let isSuspended: Bool
    let stopGeneration: UInt64
    let pendingEffect: AudioEffect?
}

private struct AudioCommandState: Sendable {
    var soundEnabled = false
    var musicEnabled = false
    var isSuspended = false
    var stopGeneration: UInt64 = 0
    var pendingEffect: AudioEffect?

    var snapshot: AudioCommandSnapshot {
        AudioCommandSnapshot(
            soundEnabled: soundEnabled,
            musicEnabled: musicEnabled,
            isSuspended: isSuspended,
            stopGeneration: stopGeneration,
            pendingEffect: pendingEffect
        )
    }
}

final class AudioCommandMailbox: Sendable {
    private let state = Mutex(AudioCommandState())
    private let continuation: AsyncStream<Void>.Continuation

    init(continuation: AsyncStream<Void>.Continuation) {
        self.continuation = continuation
    }

    func setSoundEnabled(_ isEnabled: Bool) {
        state.withLock { state in
            state.soundEnabled = isEnabled
            if !isEnabled {
                state.pendingEffect = nil
                state.stopGeneration &+= 1
            }
        }
        continuation.yield(())
    }

    func setMusicEnabled(_ isEnabled: Bool) {
        state.withLock { $0.musicEnabled = isEnabled }
        continuation.yield(())
    }

    func play(_ effect: AudioEffect) {
        state.withLock { state in
            guard state.soundEnabled, !state.isSuspended else { return }
            state.pendingEffect = effect
        }
        continuation.yield(())
    }

    func stopAll() {
        state.withLock { state in
            state.isSuspended = true
            state.pendingEffect = nil
            state.stopGeneration &+= 1
        }
        continuation.yield(())
    }

    func resume() {
        state.withLock { $0.isSuspended = false }
        continuation.yield(())
    }

    func takeSnapshot() -> AudioCommandSnapshot {
        state.withLock { state in
            let snapshot = state.snapshot
            state.pendingEffect = nil
            return snapshot
        }
    }
}

/// Non-blocking, thread-safe entry point for background music and sound effects.
public final class AudioManager: Sendable {
    /// The app-wide audio manager.
    public static let shared = AudioManager()

    private let mailbox: AudioCommandMailbox
    private let playbackTask: Task<Void, Never>

    private init() {
        let (signals, continuation) = AsyncStream.makeStream(
            of: Void.self,
            bufferingPolicy: .bufferingNewest(1)
        )
        mailbox = AudioCommandMailbox(continuation: continuation)

        let playback = AudioPlayback(mailbox: mailbox)
        playbackTask = Task.detached(priority: .utility) {
            await playback.run(signals: signals)
        }
    }

    /// Enables or disables game sound effects without blocking the caller.
    public func setSoundEnabled(_ isEnabled: Bool) {
        mailbox.setSoundEnabled(isEnabled)
    }

    /// Enables looping background music or pauses it without blocking the caller.
    public func setMusicEnabled(_ isEnabled: Bool) {
        mailbox.setMusicEnabled(isEnabled)
    }

    /// Restarts the requested clip from its beginning when sound effects are enabled.
    public func play(_ effect: AudioEffect) {
        mailbox.play(effect)
    }

    /// Stops all playback and discards any pending sound effect.
    public func stopAll() {
        mailbox.stopAll()
    }

    /// Resumes music if it was enabled before playback was suspended.
    public func resume() {
        mailbox.resume()
    }
}

private actor AudioPlayback {
    private let mailbox: AudioCommandMailbox
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "ExecutiveDecision",
        category: "AudioManager"
    )

    private var musicPlayer: AVAudioPlayer?
    private var effectPlayer: AVAudioPlayer?
    private var effectData: [AudioEffect: Data] = [:]
    private var lastStopGeneration: UInt64 = 0

    init(mailbox: AudioCommandMailbox) {
        self.mailbox = mailbox
    }

    func run(signals: AsyncStream<Void>) async {
        preloadAudio()

        for await _ in signals {
            process(mailbox.takeSnapshot())
        }

        musicPlayer?.stop()
        effectPlayer?.stop()
    }

    private func process(_ command: AudioCommandSnapshot) {
        if command.stopGeneration != lastStopGeneration {
            lastStopGeneration = command.stopGeneration
            effectPlayer?.stop()
            effectPlayer = nil
            musicPlayer?.pause()
        }

        if !command.soundEnabled || command.isSuspended {
            effectPlayer?.stop()
            effectPlayer = nil
        } else if let effect = command.pendingEffect {
            playEffect(effect)
        }

        if command.musicEnabled && !command.isSuspended {
            resumeMusic()
        } else {
            musicPlayer?.pause()
        }
    }

    private func preloadAudio() {
        if let url = audioURL(named: "vibedepot-slow-jazz", extension: "mp3") {
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.numberOfLoops = -1
                _ = player.prepareToPlay()
                musicPlayer = player
            } catch {
                logger.error("Could not preload background music: \(error.localizedDescription, privacy: .public)")
            }
        } else {
            logger.error("Could not find bundled background music.")
        }

        for effect in AudioEffect.allCases {
            guard let url = audioURL(named: effect.rawValue, extension: "m4a") else {
                logger.error("Could not find bundled sound effect: \(effect.rawValue, privacy: .public)")
                continue
            }

            do {
                effectData[effect] = try Data(contentsOf: url)
            } catch {
                logger.error("Could not preload sound effect \(effect.rawValue, privacy: .public): \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private func resumeMusic() {
        guard let musicPlayer else {
            logger.error("Background music is unavailable.")
            return
        }

        if !musicPlayer.isPlaying && !musicPlayer.play() {
            logger.error("Could not resume background music.")
        }
    }

    private func playEffect(_ effect: AudioEffect) {
        guard let data = effectData[effect] else {
            logger.error("Sound effect is unavailable: \(effect.rawValue, privacy: .public)")
            return
        }

        effectPlayer?.stop()

        do {
            let player = try AVAudioPlayer(data: data)
            _ = player.prepareToPlay()
            effectPlayer = player
            if !player.play() {
                logger.error("Could not play sound effect: \(effect.rawValue, privacy: .public)")
            }
        } catch {
            logger.error("Could not create sound effect player \(effect.rawValue, privacy: .public): \(error.localizedDescription, privacy: .public)")
        }
    }

    private func audioURL(named name: String, extension fileExtension: String) -> URL? {
        Bundle.main.url(
            forResource: name,
            withExtension: fileExtension,
            subdirectory: "Sounds"
        ) ?? Bundle.main.url(forResource: name, withExtension: fileExtension)
    }
}
