import Foundation
import Testing
@testable import EDEngine

@Suite("End-game scorer")
struct EDEndGameScorerTests {
    @Test("Sells remaining certificates at final prices and includes loan repayment in profit")
    func settlesCertificatesAndLoansThenRanksPlayers() throws {
        let indebtedPlayer = try EDPlayerState(
            name: "Alex",
            cashBalance: 800,
            inventory: EDInventory(certificatesByGrade: [.xfine: 1, .fine: 2, .standard: 1]),
            loanBalance: 100
        )
        let leadingPlayer = try EDPlayerState(name: "Sam", cashBalance: 1_000)
        let game = try completedGame(players: [indebtedPlayer, leadingPlayer])

        let result = try EDEndGameScorer.score(gameState: game)

        #expect(result.rankedPlayers.map(\.playerID) == [leadingPlayer.id, indebtedPlayer.id])
        #expect(result.rankedPlayers.map(\.rank) == [1, 2])
        #expect(result.winnerIDs == [leadingPlayer.id])

        let indebtedScore = try #require(
            result.rankedPlayers.first { $0.playerID == indebtedPlayer.id }
        )
        #expect(indebtedScore.rawMaterialSaleRevenue == 120)
        #expect(indebtedScore.loanRepaymentAmount == 125)
        #expect(indebtedScore.finalPlayerState.cash.balance == 795)
        #expect(indebtedScore.finalPlayerState.inventory == EDInventory())
        #expect(indebtedScore.profit == -105)

        let leadingScore = try #require(result.rankedPlayers.first)
        #expect(leadingScore.profit == 100)
        #expect(indebtedPlayer.cash.balance == 800)
        #expect(indebtedPlayer.inventory.certificatesByGrade == [
            .xfine: 1,
            .fine: 2,
            .standard: 1
        ])
    }

    @Test("Reports every player tied for highest profit as a winner")
    func reportsTiedWinners() throws {
        let first = try EDPlayerState(name: "Alex", cashBalance: 900)
        let second = try EDPlayerState(name: "Sam", cashBalance: 900)
        let third = try EDPlayerState(name: "Jordan", cashBalance: 800)
        let game = try completedGame(players: [first, second, third])

        let result = try EDEndGameScorer.score(gameState: game)

        #expect(result.winnerIDs == [first.id, second.id])
        #expect(result.rankedPlayers.map(\.rank) == [1, 1, 3])
        #expect(result.rankedPlayers.map(\.profit) == [300, 300, 200])
    }

    @Test("Scores a player with no remaining certificates or loans")
    func scoresNoSettlementAdjustments() throws {
        let player = try EDPlayerState(name: "Alex", cashBalance: 1_000)
        let game = try completedGame(players: [
            player,
            EDPlayerState(name: "Sam", cashBalance: 900)
        ])

        let result = try EDEndGameScorer.score(gameState: game)

        let score = try #require(result.rankedPlayers.first { $0.playerID == player.id })
        #expect(score.rawMaterialSaleRevenue == 0)
        #expect(score.loanRepaymentAmount == 0)
        #expect(score.profit == 100)
    }

    @Test("Requires every configured month to be resolved before scoring")
    func rejectsIncompleteGame() throws {
        let config = try EDGameConfig(playerCount: 2, monthCount: 2)
        let players = [
            try EDPlayerState(name: "Alex", cashBalance: 900),
            try EDPlayerState(name: "Sam", cashBalance: 900)
        ]
        let game = try EDGameState(configuration: config, players: players)

        #expect(throws: EDEndGameScorerError.gameNotComplete) {
            try EDEndGameScorer.score(gameState: game)
        }
    }

    @Test("Reports overflow when selling remaining certificates")
    func reportsCertificateSaleOverflow() throws {
        let player = try EDPlayerState(
            name: "Alex",
            cashBalance: 900,
            inventory: EDInventory(certificatesByGrade: [.xfine: Int.max])
        )
        let game = try completedGame(players: [
            player,
            EDPlayerState(name: "Sam", cashBalance: 900)
        ])

        #expect(
            throws: EDEndGameScorerError.rawMaterialSaleOverflow(
                playerID: player.id,
                grade: .xfine
            )
        ) {
            try EDEndGameScorer.score(gameState: game)
        }
    }

    @Test("Reports cash overflow during final certificate settlement")
    func reportsCashOverflowDuringSettlement() throws {
        let player = try EDPlayerState(
            name: "Alex",
            cashBalance: Int.max,
            inventory: EDInventory(certificatesByGrade: [.xfine: 1])
        )
        let game = try completedGame(players: [
            player,
            EDPlayerState(name: "Sam", cashBalance: 900)
        ])

        #expect(
            throws: EDEndGameScorerError.playerState(
                playerID: player.id,
                error: .money(.balanceOverflow)
            )
        ) {
            try EDEndGameScorer.score(gameState: game)
        }
    }

    @Test("Reports when loan repayment would exceed the supported negative cash balance")
    func reportsLoanRepaymentBelowCashMinimum() throws {
        let player = try EDPlayerState(
            name: "Alex",
            cashBalance: EDMoney.minimumBalance,
            loanBalance: 100
        )
        let game = try completedGame(players: [
            player,
            EDPlayerState(name: "Sam", cashBalance: 900)
        ])

        #expect(
            throws: EDEndGameScorerError.playerState(
                playerID: player.id,
                error: .money(.balanceBelowMinimum(EDMoney.minimumBalance - 125))
            )
        ) {
            try EDEndGameScorer.score(gameState: game)
        }
    }

    private func completedGame(players: [EDPlayerState]) throws -> EDGameState {
        let configuration = try EDGameConfig(playerCount: players.count, monthCount: 1)
        let priceBoard = try EDPriceBoard().applying(movement: EDPriceMovement())
        let playerResults = try players.map {
            try EDPlayerMonthResult(playerID: $0.id)
        }
        let monthResult = try EDMonthResult(
            monthNumber: 1,
            closingPrices: priceBoard.history[0],
            playerResults: playerResults
        )

        return try EDGameState(
            configuration: configuration,
            players: players,
            priceBoard: priceBoard,
            monthResults: [monthResult]
        )
    }
}
