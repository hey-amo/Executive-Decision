import Testing
@testable import EDEngine

@Suite("Market calculator")
struct EDMarketCalculatorTests {
    @Test("Raw-material movements match the rules table")
    func rawMaterialMovementsMatchRules() {
        let expectedMovements = Array(-10...14)

        for (units, movement) in expectedMovements.enumerated() {
            #expect(EDMarketCalculator.rawMaterialMovement(forUnits: units) == movement)
        }
    }

    @Test("Finished-good movements match the rules table")
    func finishedGoodMovementsMatchRules() {
        let expectedMovements = [11, 9, 7, 5, 3, 1, -1, -3, -5, -7, -9, -11, -13, -15, -17, -19, -21]

        for (units, movement) in expectedMovements.enumerated() {
            #expect(EDMarketCalculator.finishedGoodMovement(forUnits: units) == movement)
        }
    }

    @Test("Units above each rules range are ignored")
    func excessUnitsAreIgnored() {
        #expect(EDMarketCalculator.rawMaterialMovement(forUnits: 25) == 14)
        #expect(EDMarketCalculator.rawMaterialMovement(forUnits: Int.max) == 14)
        #expect(EDMarketCalculator.finishedGoodMovement(forUnits: 17) == -21)
        #expect(EDMarketCalculator.finishedGoodMovement(forUnits: Int.max) == -21)
    }

    @Test("Negative units use the zero-unit movement")
    func negativeUnitsUseZeroUnitMovement() {
        #expect(EDMarketCalculator.rawMaterialMovement(forUnits: -1) == -10)
        #expect(EDMarketCalculator.finishedGoodMovement(forUnits: -1) == 11)
    }

    @Test("Movements are applied to the previous market price")
    func movementsUpdatePreviousPrices() throws {
        #expect(try EDMarketCalculator.rawMaterialPrice(previousPrice: 40, orderedUnits: 12) == 42)
        #expect(try EDMarketCalculator.finishedGoodPrice(previousPrice: 90, offeredUnits: 5) == 91)
    }

    @Test("Raw-material prices never fall below one dollar")
    func rawMaterialPriceHasMinimum() throws {
        #expect(try EDMarketCalculator.rawMaterialPrice(previousPrice: 10, orderedUnits: 0) == 1)
        #expect(try EDMarketCalculator.rawMaterialPrice(previousPrice: 1, orderedUnits: 0) == 1)
    }

    @Test("Price overflow is reported")
    func priceOverflowIsReported() {
        do {
            _ = try EDMarketCalculator.finishedGoodPrice(previousPrice: Int.max, offeredUnits: 0)
            Issue.record("Expected price overflow.")
        } catch {
            #expect(error == .priceOverflow)
        }
    }
}
