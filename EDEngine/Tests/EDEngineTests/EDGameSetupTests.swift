import Testing
@testable import EDEngine

@Suite("Game setup")
struct EDGameSetupTests {
    @Test("Starting cash follows the setup rules")
    func startingCashMatchesPlayerCount() throws {
        let expectedStartingCash = [
            2: 900,
            3: 600,
            4: 450,
            5: 350,
            6: 300
        ]

        for (playerCount, startingCash) in expectedStartingCash {
            let setup = try EDGameSetup(playerCount: playerCount)

            #expect(setup.playerCount == playerCount)
            #expect(setup.startingCashPerPlayer == startingCash)
        }
    }

    @Test("Rejects player counts outside the setup rules")
    func rejectsUnsupportedPlayerCounts() {
        for playerCount in [Int.min, -1, 0, 1, 7, Int.max] {
            do {
                _ = try EDGameSetup(playerCount: playerCount)
                Issue.record("Expected player count \(playerCount) to be rejected.")
            } catch {
                #expect(error == .invalidPlayerCount(playerCount))
            }
        }
    }
}
