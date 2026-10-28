import XCTest
@testable import EDEngine

final class EDMarketRulesTests: XCTestCase {
    func testOpeningPricesMatchRules() {
        XCTAssertEqual(RawMaterial.standard.openingPrice, 20)
        XCTAssertEqual(RawMaterial.fine.openingPrice, 30)
        XCTAssertEqual(RawMaterial.extraFine.openingPrice, 40)

        XCTAssertEqual(FinishedGood.a.openingPrice, 140)
        XCTAssertEqual(FinishedGood.b.openingPrice, 115)
        XCTAssertEqual(FinishedGood.c.openingPrice, 90)
    }

    func testOnlySpecifiedGoodsAndRecipesAreAvailable() {
        XCTAssertEqual(FinishedGood.allCases, [.a, .b, .c])
        XCTAssertEqual(RawMaterial.allCases, [.standard, .fine, .extraFine])

        XCTAssertEqual(FinishedGood.a.recipe.ingredients, [.extraFine: 2, .fine: 1])
        XCTAssertEqual(FinishedGood.b.recipe.ingredients, [.fine: 2, .standard: 1])
        XCTAssertEqual(FinishedGood.c.recipe.ingredients, [.fine: 1, .standard: 2])
    }

    func testEachRecipeCanBeMadeFromItsExactIngredients() throws {
        for good in FinishedGood.allCases {
            let consumed = try good.recipe.materialsToConsume(from: good.recipe.ingredients)
            XCTAssertEqual(consumed, good.recipe.ingredients)
        }
    }

    func testExtraFineCanSubstituteForFine() throws {
        let inventory: [RawMaterial: Int] = [.extraFine: 3]

        XCTAssertEqual(
            try FinishedGood.a.recipe.materialsToConsume(from: inventory),
            [.extraFine: 3]
        )
    }

    func testFineCanSubstituteForStandard() throws {
        let inventory: [RawMaterial: Int] = [.fine: 3]

        XCTAssertEqual(
            try FinishedGood.b.recipe.materialsToConsume(from: inventory),
            [.fine: 3]
        )
    }

    func testCannotSubstituteLowerGradeForHigherGrade() throws {
        let inventory: [RawMaterial: Int] = [.fine: 3]

        XCTAssertNil(try FinishedGood.a.recipe.materialsToConsume(from: inventory))
    }

    func testRecipeCannotBeMadeWhenSubstitutionInventoryIsInsufficient() throws {
        let inventory: [RawMaterial: Int] = [.extraFine: 2]

        XCTAssertNil(try FinishedGood.a.recipe.materialsToConsume(from: inventory))
    }

    func testNegativeInventoryThrows() {
        XCTAssertThrowsError(
            try FinishedGood.a.recipe.materialsToConsume(from: [.extraFine: -1])
        ) { error in
            XCTAssertEqual(error as? RecipeError, .negativeInventory)
        }
    }

    func testRawMaterialCalculatorMovementTable() throws {
        let calculator = MarketCalculator()
        let expectedMovements = Array(-10...14)

        for units in 0...24 {
            XCTAssertEqual(
                try calculator.movement(for: RawMaterial.standard, units: units),
                expectedMovements[units]
            )
        }
    }

    func testFinishedGoodCalculatorMovementTable() throws {
        let calculator = MarketCalculator()
        let expectedMovements = stride(from: 11, through: -21, by: -2)

        for (units, expectedMovement) in zip(0...16, expectedMovements) {
            XCTAssertEqual(
                try calculator.movement(for: FinishedGood.a, units: units),
                expectedMovement
            )
        }
    }

    func testMarketCalculatorRejectsUnitsOutsideEachTable() {
        let calculator = MarketCalculator()

        XCTAssertThrowsError(try calculator.movement(for: RawMaterial.fine, units: -1)) { error in
            XCTAssertEqual(error as? MarketCalculatorError, .unitCountOutOfRange)
        }
        XCTAssertThrowsError(try calculator.movement(for: RawMaterial.fine, units: 25)) { error in
            XCTAssertEqual(error as? MarketCalculatorError, .unitCountOutOfRange)
        }
        XCTAssertThrowsError(try calculator.movement(for: FinishedGood.a, units: 17)) { error in
            XCTAssertEqual(error as? MarketCalculatorError, .unitCountOutOfRange)
        }
    }

    func testMarketPriceUsesOpeningOrPreviousPriceAndRawFloor() throws {
        let calculator = MarketCalculator()

        XCTAssertEqual(try calculator.price(for: RawMaterial.extraFine, units: 12), 42)
        XCTAssertEqual(
            try calculator.price(for: FinishedGood.b, units: 1, previousPrice: 100),
            109
        )
        XCTAssertEqual(try calculator.price(for: RawMaterial.standard, units: 0), 10)
        XCTAssertEqual(
            try calculator.price(for: RawMaterial.standard, units: 0, previousPrice: 5),
            1
        )
    }

    func testMarketCalculatorRejectsPriceOverflow() {
        let calculator = MarketCalculator()

        XCTAssertThrowsError(
            try calculator.price(for: FinishedGood.a, units: 0, previousPrice: Int.max)
        ) { error in
            XCTAssertEqual(error as? MarketCalculatorError, .priceOverflow)
        }
    }
}
