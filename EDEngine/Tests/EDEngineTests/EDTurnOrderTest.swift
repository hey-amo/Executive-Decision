import XCTest
@testable import EDEngine

private struct TestPlayer: TurnOrderPlayer, Equatable {
    let id: Int
}

final class EDTurnOrderTests: XCTestCase {
        func testAdvanceMovesPlayersInForwardOrder() {
        let players = [TestPlayer(id: 1), TestPlayer(id: 2), TestPlayer(id: 3)]
        var manager = TurnOrderManager(players: players)

        XCTAssertEqual(manager.currentPlayer, players[0])
        XCTAssertEqual(manager.allPlayers, players)
        XCTAssertEqual(manager.totalPlayers, 3)
        XCTAssertTrue(manager.currentPlayerIsTurn)

        XCTAssertEqual(manager.advance(), players[1])
        XCTAssertEqual(manager.advance(), players[2])
        XCTAssertEqual(manager.advance(), players[0])
    }

    func testAdvanceMovesPlayersInReverseOrder() {
        let players = [TestPlayer(id: 1), TestPlayer(id: 2), TestPlayer(id: 3)]
        var manager = TurnOrderManager(players: players, direction: .reverse)

        XCTAssertEqual(manager.currentPlayer, players[0])

        XCTAssertEqual(manager.advance(), players[2])
        XCTAssertEqual(manager.advance(), players[1])
        XCTAssertEqual(manager.advance(), players[0])
    }

    func testSkipCurrentPlayerAdvancesToNextPlayer() {
        let players = [TestPlayer(id: 1), TestPlayer(id: 2), TestPlayer(id: 3)]
        var manager = TurnOrderManager(players: players)

        XCTAssertEqual(manager.skipCurrentPlayer(), players[1])
        XCTAssertEqual(manager.currentPlayer, players[1])
    }
}