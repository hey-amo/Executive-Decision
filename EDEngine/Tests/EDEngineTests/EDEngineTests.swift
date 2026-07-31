import XCTest
@testable import EDEngine

final class EDEngineTests: XCTestCase {


    func testMarketCalculatorRawMaterialBounds() {
        XCTAssertEqual(EDMarketCalculator.rawMaterialMovement(for: 0), -10)
        XCTAssertEqual(EDMarketCalculator.rawMaterialMovement(for: 10), 0)
        XCTAssertEqual(EDMarketCalculator.rawMaterialMovement(for: 24), 14)
        XCTAssertNil(EDMarketCalculator.rawMaterialMovement(for: -1))
        XCTAssertNil(EDMarketCalculator.rawMaterialMovement(for: 25))
    }

    func testMarketCalculatorFinishedGoodsBounds() {
        XCTAssertEqual(EDMarketCalculator.finishedGoodsMovement(for: 0), 11)
        XCTAssertEqual(EDMarketCalculator.finishedGoodsMovement(for: 8), -5)
        XCTAssertEqual(EDMarketCalculator.finishedGoodsMovement(for: 16), -21)
        XCTAssertNil(EDMarketCalculator.finishedGoodsMovement(for: -1))
        XCTAssertNil(EDMarketCalculator.finishedGoodsMovement(for: 17))
    }

    func testRecipeRequirementsMatchRules() {
        XCTAssertEqual(EDGameRecipe.productA.requiredMaterials, [.xfine, .xfine, .fine])
        XCTAssertEqual(EDGameRecipe.productB.requiredMaterials, [.fine, .fine, .standard])
        XCTAssertEqual(EDGameRecipe.productC.requiredMaterials, [.fine, .standard, .standard])
    }

    func testStandard12MonthSetupReference() {
        let setup = EDGameSetup.standardSetup(monthCount: 12)

        XCTAssertEqual(setup.months.count, 12)
        XCTAssertEqual(setup.months.first?.name, "January")
        XCTAssertEqual(setup.months.last?.name, "December")
        XCTAssertEqual(setup.boardReference.rawMaterialOpeningPrices[.xfine], 40)
        XCTAssertEqual(setup.boardReference.rawMaterialOpeningPrices[.fine], 30)
        XCTAssertEqual(setup.boardReference.rawMaterialOpeningPrices[.standard], 20)
        XCTAssertEqual(setup.boardReference.finishedGoodsOpeningPrices[.a], 140)
        XCTAssertEqual(setup.boardReference.finishedGoodsOpeningPrices[.b], 115)
        XCTAssertEqual(setup.boardReference.finishedGoodsOpeningPrices[.c], 90)
    }
}
