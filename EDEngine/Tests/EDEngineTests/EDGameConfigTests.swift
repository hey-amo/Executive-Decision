import Foundation
import Testing
@testable import EDEngine

@Suite("Game configuration")
struct EDGameConfigTests {
    @Test("Accepts every supported player count")
    func acceptsSupportedPlayerCounts() throws {
        for playerCount in 2...6 {
            let config = try EDGameConfig(playerCount: playerCount)

            #expect(config.playerCount == playerCount)
            #expect(config.monthCount == 12)
            #expect(config.enabledVariations.isEmpty)
        }
    }

    @Test("Rejects player counts outside the setup rules")
    func rejectsUnsupportedPlayerCounts() {
        for playerCount in [Int.min, -1, 0, 1, 7, Int.max] {
            do {
                _ = try EDGameConfig(playerCount: playerCount)
                Issue.record("Expected player count \(playerCount) to be rejected.")
            } catch {
                #expect(error == .invalidPlayerCount(playerCount))
            }
        }
    }

    @Test("Accepts a player-selected positive month count")
    func acceptsPositiveMonthCounts() throws {
        for monthCount in [1, 3, 12, Int.max] {
            let config = try EDGameConfig(playerCount: 2, monthCount: monthCount)

            #expect(config.monthCount == monthCount)
        }
    }

    @Test("Rejects zero and negative month counts")
    func rejectsNonpositiveMonthCounts() {
        for monthCount in [Int.min, -1, 0] {
            do {
                _ = try EDGameConfig(playerCount: 2, monthCount: monthCount)
                Issue.record("Expected month count \(monthCount) to be rejected.")
            } catch {
                #expect(error == .invalidMonthCount(monthCount))
            }
        }
    }

    @Test("Allows either variation independently or both together")
    func recordsEnabledVariations() throws {
        #expect(
            try EDGameConfig(
                playerCount: 2,
                enabledVariations: [.loans]
            ).enabledVariations == [.loans]
        )
        #expect(
            try EDGameConfig(
                playerCount: 2,
                enabledVariations: [.partialRawPurchases]
            ).enabledVariations == [.partialRawPurchases]
        )
        #expect(
            try EDGameConfig(
                playerCount: 2,
                enabledVariations: [.loans, .partialRawPurchases]
            ).enabledVariations == [.loans, .partialRawPurchases]
        )
    }

    @Test("Configuration round-trips through Codable")
    func codableRoundTrip() throws {
        let config = try EDGameConfig(
            playerCount: 4,
            monthCount: 6,
            enabledVariations: [.loans, .partialRawPurchases]
        )

        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(EDGameConfig.self, from: data)

        #expect(decoded == config)
    }

    @Test("Decoding rejects invalid configuration values")
    func decodingRejectsInvalidConfiguration() {
        for json in [
            #"{"playerCount":1,"monthCount":12,"enabledVariations":[]}"#,
            #"{"playerCount":2,"monthCount":0,"enabledVariations":[]}"#
        ] {
            do {
                _ = try JSONDecoder().decode(EDGameConfig.self, from: Data(json.utf8))
                Issue.record("Expected invalid game configuration to fail decoding.")
            } catch is DecodingError {
                continue
            } catch {
                Issue.record("Unexpected decoding error: \(error)")
            }
        }
    }
}
