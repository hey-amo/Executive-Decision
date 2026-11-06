import Foundation
import Testing
@testable import EDEngine

@Suite("Month resolver")
struct EDMonthResolverTests {
    @Test("Resolves raw purchases before the goods-offer decision stage")
    func resolvesMonthInTwoStages() throws {
        let players = try makePlayers()
        let game = try EDGameState(
            configuration: EDGameConfig(playerCount: 2, monthCount: 1),
            players: players
        )
        let rawOrders = [
            players[0].id: try EDRawOrder(
                unitsByGrade: [.xfine: 1],
                bidsByGrade: [.xfine: 40]
            ),
            players[1].id: try EDRawOrder()
        ]

        let rawStage = try EDMonthResolver.resolveRawStage(
            gameState: game,
            ordersByPlayer: rawOrders
        )

        #expect(rawStage.playerStatesForGoods[players[0].id]?.inventory.count(of: .xfine) == 1)
        #expect(rawStage.playerStatesForGoods[players[0].id]?.cash.balance == 860)
        #expect(game.players[0].inventory == EDInventory())

        let goodsOffers = [
            players[0].id: try EDGoodsOffer(),
            players[1].id: try EDGoodsOffer()
        ]
        let result = try EDMonthResolver.resolveGoodsStage(
            rawResolution: rawStage,
            offersByPlayer: goodsOffers
        )

        #expect(result.monthResult.monthNumber == 1)
        #expect(result.nextGameState.isComplete)
        #expect(result.nextGameState.monthResults == [result.monthResult])
        #expect(result.nextGameState.priceBoard.history.last == result.monthResult.closingPrices)
    }

    @Test("Disqualified offers do not affect goods prices")
    func excludesOverOfferFromMarketTotal() throws {
        let players = try makePlayers()
        let game = try EDGameState(
            configuration: EDGameConfig(playerCount: 2, monthCount: 1),
            players: players
        )
        let rawStage = try EDMonthResolver.resolveRawStage(
            gameState: game,
            ordersByPlayer: Dictionary(uniqueKeysWithValues: players.map {
                ($0.id, try EDRawOrder())
            })
        )
        let offers = [
            players[0].id: try EDGoodsOffer(unitsByGood: [.a: 1]),
            players[1].id: try EDGoodsOffer()
        ]

        let result = try EDMonthResolver.resolveGoodsStage(
            rawResolution: rawStage,
            offersByPlayer: offers
        )

        #expect(result.offerValidation.disqualifiedPlayerIDs == [players[0].id])
        #expect(result.goodsMarket.offeredUnitsByGood == [.a: 0, .b: 0, .c: 0])
        #expect(result.goodsMarket.movementsByGood == [.a: 11, .b: 11, .c: 11])
    }

    @Test("Rejects missing, extra, or invalid submissions without returning partial results")
    func validatesStageInputs() throws {
        let players = try makePlayers()
        let game = try EDGameState(
            configuration: EDGameConfig(playerCount: 2, monthCount: 1),
            players: players
        )

        #expect(throws: EDMonthResolverError.submissionsDoNotMatchPlayers) {
            try EDMonthResolver.resolveRawStage(
                gameState: game,
                ordersByPlayer: [players[0].id: try EDRawOrder()]
            )
        }
        #expect(
            throws: EDMonthResolverError.rawOrderValidation(
                playerID: players[0].id,
                error: .orderExceedsLimits
            )
        ) {
            try EDMonthResolver.resolveRawStage(
                gameState: game,
                ordersByPlayer: [
                    players[0].id: try EDRawOrder(unitsByGrade: [.xfine: 13]),
                    players[1].id: try EDRawOrder()
                ]
            )
        }
    }

    private func makePlayers() throws -> [EDPlayerState] {
        [
            try EDPlayerState(name: "Alex", cashBalance: 900),
            try EDPlayerState(name: "Sam", cashBalance: 900)
        ]
    }
}
