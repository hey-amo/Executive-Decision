import XCTest
@testable import EDEngine

private struct TestPlayer: TurnOrderPlayer, Equatable {
    let id: Int
}

final class EDEngineTests: XCTestCase {
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

    func testValueErrorProvidesLocalizedDescriptions() {
        let numericError = EDValueError.numericBelowZero(value: -3)
        XCTAssertEqual(numericError.localizedDescription, "Numeric value cannot be below zero.")
        XCTAssertEqual(numericError.localizedFailureReason, "Cannot use negative value: -3.")
        XCTAssertEqual(numericError.localizedRecoverySuggestion, "Use a non-negative value.")

        let fundsError = EDValueError.insufficientFunds(required: 50, available: 20)
        XCTAssertEqual(fundsError.localizedDescription, "Not enough funds available.")
        XCTAssertEqual(fundsError.localizedFailureReason, "You don't have enough funds. Required: 50, available: 20.")
        XCTAssertEqual(fundsError.localizedRecoverySuggestion, "Gather more funds or reduce your required amount.")
    }

    func testGameErrorDefaultsProvideFallbackDescriptions() {
        struct TestGameError: EDGameError {}

        let error = TestGameError()
        XCTAssertEqual(error.localizedDescription, "An unexpected game error occurred.")
        XCTAssertEqual(error.localizedFailureReason, "The operation could not be completed.")
        XCTAssertEqual(error.localizedRecoverySuggestion, "Please try again or contact support if the issue persists.")
    }
}
