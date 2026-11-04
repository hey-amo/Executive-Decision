import XCTest
@testable import EDEngine

final class EDPlayerTests: XCTestCase {
    func testEqualityAndHashingUsePlayerIdentity() async throws {
        let id = UUID()
        let first = try EDPlayer(id: id, name: "Alex", coins: 100)
        let sameIdentity = try EDPlayer(id: id, name: "Different name", coins: 0)
        let differentIdentity = try EDPlayer(name: "Alex", coins: 100)

        XCTAssertEqual(first, sameIdentity)
        XCTAssertNotEqual(first, differentIdentity)
        XCTAssertEqual(Set([first, sameIdentity, differentIdentity]).count, 2)
    }

    func testPlayerStateCanChangeAndBeRestoredFromSnapshot() async throws {
        let player = try EDPlayer(name: "Alex", coins: 100)

        await player.rename(to: "Sam")
        try await player.addCoins(25)
        try await player.spendCoins(40)

        let snapshot = await player.snapshot()
        XCTAssertEqual(snapshot._name, "Sam")
        XCTAssertEqual(snapshot._coins, 85)

        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(EDPlayerSnapshot.self, from: data)
        let restoredPlayer = try EDPlayer(snapshot: decoded)
        let restoredSnapshot = await restoredPlayer.snapshot()

        XCTAssertEqual(restoredSnapshot.id, snapshot.id)
        XCTAssertEqual(restoredSnapshot._name, "Sam")
        XCTAssertEqual(restoredSnapshot._coins, 85)
        XCTAssertEqual(restoredPlayer, player)
    }

    func testNegativeInitialCoinsAreRejected() {
        XCTAssertThrowsError(try EDPlayer(name: "Alex", coins: -1)) { error in
            XCTAssertEqual(error as? EDPlayerError, .negativeAmount)
        }
    }

    func testInvalidCoinTransactionsDoNotChangeBalance() async throws {
        let player = try EDPlayer(name: "Alex", coins: 10)

        do {
            try await player.addCoins(-1)
            XCTFail("Expected negative amount error")
        } catch {
            XCTAssertEqual(error as? EDPlayerError, .negativeAmount)
        }

        do {
            try await player.spendCoins(-1)
            XCTFail("Expected negative amount error")
        } catch {
            XCTAssertEqual(error as? EDPlayerError, .negativeAmount)
        }

        do {
            try await player.spendCoins(11)
            XCTFail("Expected insufficient coins error")
        } catch {
            XCTAssertEqual(error as? EDPlayerError, .notEnoughCoins)
        }

        let snapshot = await player.snapshot()
        XCTAssertEqual(snapshot._coins, 10)
    }

    func testAddingCoinsAtMaximumBalanceThrowsWithoutOverflow() async throws {
        let player = try EDPlayer(name: "Alex", coins: Int.max)

        do {
            try await player.addCoins(1)
            XCTFail("Expected balance overflow error")
        } catch {
            XCTAssertEqual(error as? EDPlayerError, .balanceOverflow)
        }

        let snapshot = await player.snapshot()
        XCTAssertEqual(snapshot._coins, Int.max)
    }

    func testConcurrentCoinTransactionsAreSerialized() async throws {
        let player = try EDPlayer(name: "Alex")

        try await withThrowingTaskGroup(of: Void.self) { group in
            for _ in 0..<500 {
                group.addTask {
                    try await player.addCoins(1)
                }
            }
            try await group.waitForAll()
        }

        let snapshot = await player.snapshot()
        XCTAssertEqual(snapshot._coins, 500)
    }
}
