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

    @Test("Movement boundaries and extreme unit counts are safe")
    func movementBoundariesAndExtremeUnitsAreSafe() {
        #expect(EDMarketCalculator.rawMaterialMovement(forUnits: Int.min) == -10)
        #expect(EDMarketCalculator.rawMaterialMovement(forUnits: 0) == -10)
        #expect(EDMarketCalculator.rawMaterialMovement(forUnits: 24) == 14)
        #expect(EDMarketCalculator.rawMaterialMovement(forUnits: Int.max) == 14)
        #expect(EDMarketCalculator.finishedGoodMovement(forUnits: Int.min) == 11)
        #expect(EDMarketCalculator.finishedGoodMovement(forUnits: 0) == 11)
        #expect(EDMarketCalculator.finishedGoodMovement(forUnits: 16) == -21)
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

    @Test("Minimum raw bid uses only the player's units")
    func minimumRawBidUsesPlayerOrder() throws {
        #expect(try EDMarketCalculator.minimumRawBidPrice(
            previousPrice: 40,
            playerOrderedUnits: 3
        ) == 33)
    }

    @Test("Minimum raw bid is floored at one dollar")
    func minimumRawBidHasDollarFloor() throws {
        #expect(try EDMarketCalculator.minimumRawBidPrice(
            previousPrice: 5,
            playerOrderedUnits: 0
        ) == 1)
        #expect(try EDMarketCalculator.minimumRawBidPrice(
            previousPrice: 1,
            playerOrderedUnits: 0
        ) == 1)
    }

    @Test("Minimum raw bid honors the raw movement range")
    func minimumRawBidCapsUnitsToCalculatorRange() throws {
        #expect(try EDMarketCalculator.minimumRawBidPrice(
            previousPrice: 40,
            playerOrderedUnits: 25
        ) == 54)
    }

    @Test("Minimum raw bid reports price overflow")
    func minimumRawBidReportsOverflow() {
        do {
            _ = try EDMarketCalculator.minimumRawBidPrice(
                previousPrice: Int.min,
                playerOrderedUnits: 0
            )
            Issue.record("Expected price overflow.")
        } catch {
            #expect(error == .priceOverflow)
        }
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

    @Test("Price arithmetic handles representable extreme results")
    func extremePriceArithmeticRemainsRepresentable() throws {
        #expect(try EDMarketCalculator.rawMaterialPrice(
            previousPrice: Int.min,
            orderedUnits: 24
        ) == 1)
        #expect(try EDMarketCalculator.rawMaterialPrice(
            previousPrice: Int.max,
            orderedUnits: 0
        ) == Int.max - 10)
        #expect(try EDMarketCalculator.finishedGoodPrice(
            previousPrice: Int.min,
            offeredUnits: 0
        ) == Int.min + 11)
        #expect(try EDMarketCalculator.finishedGoodPrice(
            previousPrice: Int.max,
            offeredUnits: 16
        ) == Int.max - 21)
    }

    @Test("Price arithmetic reports overflow in both directions")
    func priceArithmeticReportsOverflowInBothDirections() {
        do {
            _ = try EDMarketCalculator.rawMaterialPrice(previousPrice: Int.max, orderedUnits: 24)
            Issue.record("Expected positive price overflow.")
        } catch {
            #expect(error == .priceOverflow)
        }

        do {
            _ = try EDMarketCalculator.finishedGoodPrice(previousPrice: Int.min, offeredUnits: 16)
            Issue.record("Expected negative price overflow.")
        } catch {
            #expect(error == .priceOverflow)
        }
    }
}
