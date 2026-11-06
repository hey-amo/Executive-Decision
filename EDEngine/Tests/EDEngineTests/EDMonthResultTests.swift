import Foundation
import Testing
@testable import EDEngine

@Suite("Month results")
struct EDMonthResultTests {
    @Test("Records a month's closing prices and player outcomes")
    func recordsMonthlyOutcomes() throws {
        let playerID = UUID()
        let prices = try EDPriceBoard().applying(
            movement: EDPriceMovement(
                rawMaterials: [.xfine: 2],
                finishedGoods: [.a: -1]
            )
        ).history[0]
        let playerResult = try EDPlayerMonthResult(
            playerID: playerID,
            rawUnitsPurchased: [.xfine: 2, .fine: 1],
            rawPurchaseCost: 110,
            finishedGoodsSold: [.a: 1],
            goodsSalesRevenue: 139
        )
        let monthResult = try EDMonthResult(
            monthNumber: 1,
            closingPrices: prices,
            playerResults: [playerResult]
        )

        #expect(monthResult.monthNumber == 1)
        #expect(monthResult.closingPrices.rawMaterialPrices[.xfine] == 42)
        #expect(monthResult.closingPrices.finishedGoodPrices[.a] == 139)
        #expect(monthResult.playerResults == [playerResult])
        #expect(monthResult.playerResults[0].cashChange == 29)
    }

    @Test("Player result defaults unspecified grades and goods to zero")
    func playerResultDefaultsUnspecifiedOutcomes() throws {
        let result = try EDPlayerMonthResult(playerID: UUID())

        #expect(result.rawUnitsPurchased == [
            .xfine: 0,
            .fine: 0,
            .standard: 0
        ])
        #expect(result.finishedGoodsSold == [.a: 0, .b: 0, .c: 0])
        #expect(result.cashChange == 0)
    }

    @Test("Rejects negative purchase units, costs, sales, and proceeds")
    func rejectsNegativePlayerOutcomes() {
        let playerID = UUID()
        #expect(throws: EDPlayerMonthResultError.negativePurchasedUnits(
            grade: .fine,
            units: -1
        )) {
            try EDPlayerMonthResult(playerID: playerID, rawUnitsPurchased: [.fine: -1])
        }
        #expect(throws: EDPlayerMonthResultError.negativeRawPurchaseCost(-1)) {
            try EDPlayerMonthResult(playerID: playerID, rawPurchaseCost: -1)
        }
        #expect(throws: EDPlayerMonthResultError.negativeSoldUnits(good: .b, units: -1)) {
            try EDPlayerMonthResult(playerID: playerID, finishedGoodsSold: [.b: -1])
        }
        #expect(throws: EDPlayerMonthResultError.negativeGoodsSalesRevenue(-1)) {
            try EDPlayerMonthResult(playerID: playerID, goodsSalesRevenue: -1)
        }
    }

    @Test("Requires a positive month number and at most one result per player")
    func validatesMonthAndUniquePlayers() throws {
        let prices = try EDPriceBoard().applying(movement: EDPriceMovement()).history[0]
        let result = try EDPlayerMonthResult(playerID: UUID())

        for invalidMonth in [0, -1] {
            #expect(throws: EDMonthResultError.invalidMonthNumber(invalidMonth)) {
                try EDMonthResult(
                    monthNumber: invalidMonth,
                    closingPrices: prices,
                    playerResults: []
                )
            }
        }

        #expect(throws: EDMonthResultError.duplicatePlayerResult(result.playerID)) {
            try EDMonthResult(
                monthNumber: 1,
                closingPrices: prices,
                playerResults: [result, result]
            )
        }
    }

    @Test("Codable round-trips complete monthly results")
    func codableRoundTrip() throws {
        let prices = try EDPriceBoard().applying(
            movement: EDPriceMovement(rawMaterials: [.fine: -2])
        ).history[0]
        let result = try EDMonthResult(
            monthNumber: 2,
            closingPrices: prices,
            playerResults: [
                try EDPlayerMonthResult(
                    playerID: UUID(),
                    rawUnitsPurchased: [.fine: 3],
                    rawPurchaseCost: 90,
                    finishedGoodsSold: [.c: 1],
                    goodsSalesRevenue: 80
                )
            ]
        )
        let data = try JSONEncoder().encode(result)

        #expect(try JSONDecoder().decode(EDMonthResult.self, from: data) == result)
    }
}
