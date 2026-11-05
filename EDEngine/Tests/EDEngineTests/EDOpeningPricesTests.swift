import Testing
@testable import EDEngine

@Suite("Opening prices")
struct EDOpeningPricesTests {
    @Test("Raw material prices match the opening-price table")
    func rawMaterialPricesMatchRules() {
        #expect(EDOpeningPrices.rawMaterialPrice(for: .xfine) == 40)
        #expect(EDOpeningPrices.rawMaterialPrice(for: .fine) == 30)
        #expect(EDOpeningPrices.rawMaterialPrice(for: .standard) == 20)
    }

    @Test("Finished-good prices match the opening-price table")
    func finishedGoodPricesMatchRules() {
        #expect(EDOpeningPrices.finishedGoodPrice(for: .a) == 140)
        #expect(EDOpeningPrices.finishedGoodPrice(for: .b) == 115)
        #expect(EDOpeningPrices.finishedGoodPrice(for: .c) == 90)
    }
}
