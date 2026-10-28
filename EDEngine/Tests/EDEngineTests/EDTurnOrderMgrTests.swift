// Turn order manager tests

import XCTest
@testable import EDEngine

final class EDTurnOrderManagerTests: XCTestCase {
    func testInitialTurnIsFirstPlayerInTurnOrder() throws {
        let manager = try EDTurnOrderManager(playerCount: 3, shuffle: false)

        XCTAssertEqual(manager.turnOrder, [1, 2, 3])
        XCTAssertEqual(manager.currentPlayerNumber, 1)
        XCTAssertEqual(manager.completedRounds, 0)
    }

    func testAdvancesThroughPlayersThenWrapsToFirstPlayer() throws {
        var manager = try EDTurnOrderManager(playerCount: 3, shuffle: false)

        XCTAssertFalse(manager.advanceTurn())
        XCTAssertEqual(manager.currentPlayerNumber, 2)

        XCTAssertFalse(manager.advanceTurn())
        XCTAssertEqual(manager.currentPlayerNumber, 3)

        XCTAssertTrue(manager.advanceTurn())
        XCTAssertEqual(manager.currentPlayerNumber, 1)
        XCTAssertEqual(manager.completedRounds, 1)
    }

    func testShuffleContainsEveryPlayerExactlyOnce() throws {
        let manager = try EDTurnOrderManager(playerCount: 5)

        XCTAssertEqual(manager.turnOrder.count, 5)
        XCTAssertEqual(manager.turnOrder.sorted(), [1, 2, 3, 4, 5])
        XCTAssertEqual(manager.currentPlayerNumber, manager.turnOrder[0])
    }

    func testInvalidPlayerCountThrows() {
        XCTAssertThrowsError(try EDTurnOrderManager(playerCount: 0)) { error in
            XCTAssertEqual(error as? TurnOrderError, .invalidPlayerCount)
        }
        XCTAssertThrowsError(try EDTurnOrderManager(playerCount: -1)) { error in
            XCTAssertEqual(error as? TurnOrderError, .invalidPlayerCount)
        }
    }

    func testSinglePlayerCompletesRoundOnEachAdvance() throws {
        var manager = try EDTurnOrderManager(playerCount: 1)

        XCTAssertTrue(manager.advanceTurn())
        XCTAssertEqual(manager.currentPlayerNumber, 1)
        XCTAssertEqual(manager.completedRounds, 1)
    }
}