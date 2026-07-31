import XCTest
@testable import EDEngine

final class EDGameTests: XCTestCase {
    func testNewGameInitializesBoardAndMonths() {
        let players = [
            Player(playerId: 1, cash: 0),
            Player(playerId: 2, cash: 0),
            Player(playerId: 3, cash: 0)
        ]

        let game = ExecutiveDecisionGame.newGame(players: players, monthCount: 12)

        XCTAssertEqual(game.phase, .setup)
        XCTAssertEqual(game.state, .setup)
        XCTAssertEqual(game.decisionState, .idle)
        XCTAssertEqual(game.setup.months.count, 12)
        XCTAssertEqual(game.currentMonth.name, "January")
        XCTAssertEqual(game.boardReference.rawMaterialOpeningPrices[.xfine], 40)
        XCTAssertEqual(game.boardReference.rawMaterialOpeningPrices[.fine], 30)
        XCTAssertEqual(game.boardReference.rawMaterialOpeningPrices[.standard], 20)
        XCTAssertEqual(game.boardReference.finishedGoodsOpeningPrices[.a], 140)
        XCTAssertEqual(game.boardReference.finishedGoodsOpeningPrices[.b], 115)
        XCTAssertEqual(game.boardReference.finishedGoodsOpeningPrices[.c], 90)
    }

    func testNewGameAssignsSeedCapitalForPlayerCount() {
        let players = [
            Player(playerId: 1, cash: 0),
            Player(playerId: 2, cash: 0)
        ]

        let game = ExecutiveDecisionGame.newGame(players: players)
        XCTAssertEqual(game.players.count, 2)
        XCTAssertTrue(game.players.allSatisfy { $0.cash == 900 })
    }

    func testNewGamePreservesPlayerSetAndRandomizesStartPlayer() {
        let players = [
            Player(playerId: 1, cash: 0),
            Player(playerId: 2, cash: 0),
            Player(playerId: 3, cash: 0),
            Player(playerId: 4, cash: 0)
        ]

        let game = ExecutiveDecisionGame.newGame(players: players)
        let inputIds = Set(players.map { $0.playerId })
        let gameIds = Set(game.players.map { $0.playerId })

        XCTAssertEqual(inputIds, gameIds)
        XCTAssertEqual(game.turnOrderManager.totalPlayers, players.count)
    }

    func testTallySheetSerializationAndMonthlyBidRecording() throws {
        let setup = EDGameSetup.standardSetup(monthCount: 12)
        var tallySheet = EDTallySheet(months: setup.months)

        let rawMaterialBid = EDRawMaterialBid(material: .xfine, units: 5, bidPrice: 35)
        tallySheet.recordRawMaterialBid(rawMaterialBid, forMonth: 1)

        let finishedGoodsOffer = EDFinishedGoodsOffer(product: .a, units: 3, askPrice: 145)
        tallySheet.recordFinishedGoodsOffer(finishedGoodsOffer, forMonth: 1)

        XCTAssertEqual(tallySheet.monthlyRecords[0].rawMaterialOrders, [rawMaterialBid])
        XCTAssertEqual(tallySheet.monthlyRecords[0].finishedGoodsOffers, [finishedGoodsOffer])

        let encoded = try JSONEncoder().encode(tallySheet)
        let decoded = try JSONDecoder().decode(EDTallySheet.self, from: encoded)

        XCTAssertEqual(decoded, tallySheet)
        XCTAssertEqual(decoded.monthlyRecords[0].rawMaterialOrders.first?.material, .xfine)
        XCTAssertEqual(decoded.monthlyRecords[0].rawMaterialOrders.first?.units, 5)
        XCTAssertEqual(decoded.monthlyRecords[0].rawMaterialOrders.first?.bidPrice, 35)
        XCTAssertEqual(decoded.monthlyRecords[0].finishedGoodsOffers.first?.product, .a)
        XCTAssertEqual(decoded.monthlyRecords[0].finishedGoodsOffers.first?.units, 3)
        XCTAssertEqual(decoded.monthlyRecords[0].finishedGoodsOffers.first?.askPrice, 145)
    }
}
