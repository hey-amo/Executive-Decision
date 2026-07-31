import XCTest
@testable import EDEngine

private struct DummyPlayerFactory {
    static func player(playerId: Int, cash: Int) -> Player {
        Player(playerId: playerId, cash: cash)
    }
}

final class EDEndGameScoringTests: XCTestCase {
    func testPlayersSortedByCoinsReturnsPlayersInDescendingCashOrder() {
        let players = [
            DummyPlayerFactory.player(playerId: 1, cash: 200),
            DummyPlayerFactory.player(playerId: 2, cash: 500),
            DummyPlayerFactory.player(playerId: 3, cash: 100)
        ]

        let game = ExecutiveDecisionGame.newGame(players: players, monthCount: 12)
        let sorted = game.playersSortedByCoins()

        XCTAssertEqual(sorted.map { $0.playerId }, [2, 1, 3])
        XCTAssertEqual(sorted.map { $0.cash }, [500, 200, 100])
    }

    func testPlayersSortedByCoinsHandlesTiesByPreservingRelativeOrder() {
        let players = [
            DummyPlayerFactory.player(playerId: 1, cash: 300),
            DummyPlayerFactory.player(playerId: 2, cash: 300),
            DummyPlayerFactory.player(playerId: 3, cash: 150)
        ]

        let game = ExecutiveDecisionGame.newGame(players: players, monthCount: 12)
        let sorted = game.playersSortedByCoins()

        XCTAssertEqual(sorted.map { $0.cash }, [300, 300, 150])
        XCTAssertEqual(sorted.map { $0.playerId }, [1, 2, 3])
    }
}
