import Foundation
import Testing
@testable import EDEngine

@Suite("Game state")
struct EDGameStateTests {
    @Test("Creates a new game with opening prices and no month results")
    func createsNewGameState() throws {
        let configuration = try EDGameConfig(playerCount: 2, monthCount: 3)
        let players = try makePlayers(count: 2, for: configuration)
        let state = try EDGameState(configuration: configuration, players: players)

        #expect(state.configuration == configuration)
        #expect(state.players == players)
        #expect(state.priceBoard == EDPriceBoard())
        #expect(state.monthResults.isEmpty)
        #expect(state.currentMonthNumber == 1)
        #expect(!state.isComplete)
    }

    @Test("Advances the current month and identifies completion")
    func reportsGameProgress() throws {
        let state = try makeGameState(monthCount: 2, resolvedMonths: 1)

        #expect(state.monthResults.count == 1)
        #expect(state.currentMonthNumber == 2)
        #expect(!state.isComplete)

        let completed = try makeGameState(monthCount: 2, resolvedMonths: 2)
        #expect(completed.currentMonthNumber == 3)
        #expect(completed.isComplete)
    }

    @Test("Requires exactly the configured number of unique players")
    func validatesPlayerRoster() throws {
        let configuration = try EDGameConfig(playerCount: 2)
        let onePlayer = try makePlayers(count: 1, for: configuration)
        #expect(throws: EDGameStateError.invalidPlayerCount(expected: 2, actual: 1)) {
            try EDGameState(configuration: configuration, players: onePlayer)
        }

        let id = UUID()
        let duplicatePlayers = [
            try EDPlayerState(id: id, name: "One"),
            try EDPlayerState(id: id, name: "Two")
        ]
        #expect(throws: EDGameStateError.duplicatePlayerID) {
            try EDGameState(configuration: configuration, players: duplicatePlayers)
        }
    }

    @Test("Requires contiguous month results and matching price history")
    func validatesMonthAndPriceHistory() throws {
        let configuration = try EDGameConfig(playerCount: 2, monthCount: 2)
        let players = try makePlayers(count: 2, for: configuration)
        let playerResults = try players.map {
            try EDPlayerMonthResult(playerID: $0.id)
        }
        let board = try EDPriceBoard().applying(movement: EDPriceMovement())
        let wrongNumber = try EDMonthResult(
            monthNumber: 2,
            closingPrices: board.history[0],
            playerResults: playerResults
        )

        #expect(throws: EDGameStateError.invalidMonthNumber(expected: 1, actual: 2)) {
            try EDGameState(
                configuration: configuration,
                players: players,
                priceBoard: board,
                monthResults: [wrongNumber]
            )
        }

        #expect(throws: EDGameStateError.invalidPriceHistoryCount(expected: 0, actual: 1)) {
            try EDGameState(configuration: configuration, players: players, priceBoard: board)
        }

        let tooManyMonths = try makeGameState(monthCount: 1, resolvedMonths: 1)
        #expect(throws: EDGameStateError.tooManyMonthResults(maximum: 1, actual: 2)) {
            try EDGameState(
                configuration: try EDGameConfig(playerCount: 2, monthCount: 1),
                players: tooManyMonths.players,
                priceBoard: tooManyMonths.priceBoard,
                monthResults: tooManyMonths.monthResults + tooManyMonths.monthResults
            )
        }
    }

    @Test("Requires each resolved month to contain the game's player roster")
    func validatesMonthlyPlayerResults() throws {
        let configuration = try EDGameConfig(playerCount: 2, monthCount: 1)
        let players = try makePlayers(count: 2, for: configuration)
        let board = try EDPriceBoard().applying(movement: EDPriceMovement())
        let result = try EDMonthResult(
            monthNumber: 1,
            closingPrices: board.history[0],
            playerResults: [try EDPlayerMonthResult(playerID: players[0].id)]
        )

        #expect(throws: EDGameStateError.invalidPlayerResults(monthNumber: 1)) {
            try EDGameState(
                configuration: configuration,
                players: players,
                priceBoard: board,
                monthResults: [result]
            )
        }
    }

    @Test("Requires each month result to match the corresponding closing prices")
    func validatesClosingPrices() throws {
        let configuration = try EDGameConfig(playerCount: 2, monthCount: 1)
        let players = try makePlayers(count: 2, for: configuration)
        let board = try EDPriceBoard().applying(movement: EDPriceMovement())
        let differentBoard = try EDPriceBoard().applying(
            movement: EDPriceMovement(rawMaterials: [.xfine: 1])
        )
        let result = try EDMonthResult(
            monthNumber: 1,
            closingPrices: differentBoard.history[0],
            playerResults: try players.map { try EDPlayerMonthResult(playerID: $0.id) }
        )

        #expect(throws: EDGameStateError.closingPricesDoNotMatch(monthNumber: 1)) {
            try EDGameState(
                configuration: configuration,
                players: players,
                priceBoard: board,
                monthResults: [result]
            )
        }
    }

    @Test("Codable round-trips complete game state")
    func codableRoundTrip() throws {
        let state = try makeGameState(monthCount: 2, resolvedMonths: 1)
        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(EDGameState.self, from: data)

        #expect(decoded == state)
    }

    @Test("Game session exposes a resolved state snapshot")
    @available(macOS 10.15, *)
    func sessionReturnsGameStateSnapshot() async throws {
        let state = try makeGameState(monthCount: 1, resolvedMonths: 0)
        let session = try GameSession(state: state)

        #expect(await session.snapshot() == state)
        #expect(await session.currentPhase() == .rawOrderSubmission(monthNumber: 1))
    }

    private func makePlayers(
        count: Int,
        for configuration: EDGameConfig
    ) throws -> [EDPlayerState] {
        let startingCash = configuration.startingCashPerPlayer
        return try (0..<count).map { index in
            try EDPlayerState(name: "Player \(index + 1)", cashBalance: startingCash)
        }
    }

    private func makeGameState(
        monthCount: Int,
        resolvedMonths: Int
    ) throws -> EDGameState {
        let configuration = try EDGameConfig(playerCount: 2, monthCount: monthCount)
        let players = try makePlayers(count: 2, for: configuration)
        var priceBoard = EDPriceBoard()
        var monthResults: [EDMonthResult] = []

        for monthIndex in 0..<resolvedMonths {
            let monthNumber = monthIndex + 1
            priceBoard = try priceBoard.applying(
                movement: EDPriceMovement(
                    rawMaterials: [.xfine: monthNumber],
                    finishedGoods: [.a: -monthNumber]
                )
            )
            let playerResults = try players.map {
                try EDPlayerMonthResult(playerID: $0.id)
            }
            monthResults.append(
                try EDMonthResult(
                    monthNumber: monthNumber,
                    closingPrices: priceBoard.history[monthIndex],
                    playerResults: playerResults
                )
            )
        }

        return try EDGameState(
            configuration: configuration,
            players: players,
            priceBoard: priceBoard,
            monthResults: monthResults
        )
    }
}
