import Foundation
import Testing
@testable import EDEngine

@Suite("Price board")
struct EDPriceBoardTests {
    @Test("Starts at the opening prices with no monthly history")
    func startsAtOpeningPrices() {
        let board = EDPriceBoard()

        #expect(board.rawMaterialPrices == [
            .xfine: 40,
            .fine: 30,
            .standard: 20
        ])
        #expect(board.finishedGoodPrices == [
            .a: 140,
            .b: 115,
            .c: 90
        ])
        #expect(board.history.isEmpty)
    }

    @Test("Applies movement to previous prices and appends a monthly snapshot")
    func appliesMovementAndRecordsMonthlyHistory() throws {
        let openingBoard = EDPriceBoard()
        let firstMonth = try openingBoard.applying(
            movement: EDPriceMovement(
                rawMaterials: [.xfine: 2, .fine: -4],
                finishedGoods: [.a: 5, .c: -10]
            )
        )

        #expect(openingBoard.price(for: .xfine) == 40)
        #expect(firstMonth.price(for: .xfine) == 42)
        #expect(firstMonth.price(for: .fine) == 26)
        #expect(firstMonth.price(for: .standard) == 20)
        #expect(firstMonth.price(for: .a) == 145)
        #expect(firstMonth.price(for: .b) == 115)
        #expect(firstMonth.price(for: .c) == 80)
        #expect(firstMonth.history.count == 1)
        #expect(firstMonth.history[0].rawMaterialPrices == firstMonth.rawMaterialPrices)
        #expect(firstMonth.history[0].finishedGoodPrices == firstMonth.finishedGoodPrices)

        let secondMonth = try firstMonth.applying(
            movement: EDPriceMovement(rawMaterials: [.xfine: 3])
        )
        #expect(secondMonth.price(for: .xfine) == 45)
        #expect(secondMonth.history.count == 2)
        #expect(secondMonth.history[0].rawMaterialPrices[.xfine] == 42)
        #expect(secondMonth.history[1].rawMaterialPrices[.xfine] == 45)
    }

    @Test("Applies the $1 default floor for raw materials and finished goods")
    func appliesDefaultPriceFloor() throws {
        let board = try EDPriceBoard(
            rawMaterialPrices: [.xfine: 1, .fine: 3, .standard: 10],
            finishedGoodPrices: [.a: 1, .b: 5, .c: 10]
        )
        let updated = try board.applying(
            movement: EDPriceMovement(
                rawMaterials: [.xfine: -10, .fine: -1],
                finishedGoods: [.a: -20, .b: -5]
            )
        )

        #expect(updated.price(for: .xfine) == 1)
        #expect(updated.price(for: .fine) == 2)
        #expect(updated.price(for: .a) == 1)
        #expect(updated.price(for: .b) == 1)
    }

    @Test("Supports a configured price floor")
    func appliesConfiguredFloor() throws {
        let board = try EDPriceBoard(
            rawMaterialPrices: [.xfine: 5, .fine: 5, .standard: 5],
            finishedGoodPrices: [.a: 5, .b: 5, .c: 5]
        )
        let floor = try EDPriceFloorPolicy(
            rawMaterialMinimum: 2,
            finishedGoodMinimum: 3
        )
        let updated = try board.applying(
            movement: EDPriceMovement(
                rawMaterials: [.xfine: -10],
                finishedGoods: [.a: -10]
            ),
            floorPolicy: floor
        )

        #expect(updated.price(for: .xfine) == 2)
        #expect(updated.price(for: .a) == 3)
    }

    @Test("Rejects invalid price floors and incomplete or nonpositive price tables")
    func validatesFloorsAndPrices() {
        for invalidFloor in [0, -1] {
            #expect(throws: EDPriceBoardError.invalidPrice(invalidFloor)) {
                try EDPriceFloorPolicy(rawMaterialMinimum: invalidFloor)
            }
            #expect(throws: EDPriceBoardError.invalidPrice(invalidFloor)) {
                try EDPriceFloorPolicy(finishedGoodMinimum: invalidFloor)
            }
        }

        #expect(throws: EDPriceBoardError.invalidPrice(0)) {
            try EDPriceBoard(
                rawMaterialPrices: [.xfine: 40, .fine: 30, .standard: 0],
                finishedGoodPrices: [.a: 140, .b: 115, .c: 90]
            )
        }
        #expect(throws: EDPriceBoardError.invalidPrice(0)) {
            try EDPriceBoard(
                rawMaterialPrices: [.xfine: 40, .fine: 30],
                finishedGoodPrices: [.a: 140, .b: 115, .c: 90]
            )
        }
    }

    @Test("Reports price overflow without changing the source board")
    func rejectsPriceOverflow() throws {
        let board = try EDPriceBoard(
            rawMaterialPrices: [.xfine: Int.max, .fine: 30, .standard: 20],
            finishedGoodPrices: [.a: 140, .b: 115, .c: 90]
        )

        #expect(throws: EDPriceBoardError.priceOverflow) {
            try board.applying(movement: EDPriceMovement(rawMaterials: [.xfine: 1]))
        }
        #expect(board.price(for: .xfine) == Int.max)
        #expect(board.history.isEmpty)
    }

    @Test("Codable round-trips current prices and monthly history")
    func codableRoundTrip() throws {
        let board = try EDPriceBoard().applying(
            movement: EDPriceMovement(
                rawMaterials: [.fine: 2],
                finishedGoods: [.b: -3]
            )
        )
        let data = try JSONEncoder().encode(board)
        let decoded = try JSONDecoder().decode(EDPriceBoard.self, from: data)

        #expect(decoded == board)
    }
}
