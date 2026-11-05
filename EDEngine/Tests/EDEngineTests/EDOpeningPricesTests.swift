import Testing
@testable import EDEngine

@Suite("Opening prices")
struct EDOpeningPricesTests {
    @Test("Raw material prices match the opening-price table")
    func rawMaterialPricesMatchRules() {
        let expectedPrices: [EDRawMaterialGrade: Int] = [
            .xfine: 40,
            .fine: 30,
            .standard: 20
        ]

        #expect(EDRawMaterialGrade.allCases.count == expectedPrices.count)
        for grade in EDRawMaterialGrade.allCases {
            #expect(EDOpeningPrices.rawMaterialPrice(for: grade) == expectedPrices[grade])
        }
    }

    @Test("Finished-good prices match the opening-price table")
    func finishedGoodPricesMatchRules() {
        let expectedPrices: [EDRecipe: Int] = [
            .a: 140,
            .b: 115,
            .c: 90
        ]

        #expect(EDRecipe.allCases.count == expectedPrices.count)
        for good in EDRecipe.allCases {
            #expect(EDOpeningPrices.finishedGoodPrice(for: good) == expectedPrices[good])
        }
    }
}
