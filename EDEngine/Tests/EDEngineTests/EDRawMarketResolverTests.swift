import Foundation
import Testing
@testable import EDEngine

@Suite("Raw-market resolver")
struct EDRawMarketResolverTests {
    private let openingPrices: [EDRawMaterialGrade: Int] = [
        .xfine: EDOpeningPrices.rawMaterialPrice(for: .xfine),
        .fine: EDOpeningPrices.rawMaterialPrice(for: .fine),
        .standard: EDOpeningPrices.rawMaterialPrice(for: .standard)
    ]

    @Test("Resolves rulebook raw movements from aggregate orders")
    func resolvesRulebookRawMovements() throws {
        let order = try EDRawOrder(unitsByGrade: [.xfine: 12, .fine: 3])

        let result = try EDRawMarketResolver.resolve(
            orders: [order],
            previousPrices: openingPrices
        )

        #expect(result.orderedUnitsByGrade == [.xfine: 12, .fine: 3, .standard: 0])
        #expect(result.movementsByGrade == [.xfine: 2, .fine: -7, .standard: -10])
        #expect(result.rawMaterialPrices == [.xfine: 42, .fine: 23, .standard: 10])
    }

    @Test("Zero orders use the zero-unit movement for every grade")
    func resolvesZeroOrders() throws {
        let result = try EDRawMarketResolver.resolve(
            orders: [],
            previousPrices: openingPrices
        )

        #expect(result.orderedUnitsByGrade == [.xfine: 0, .fine: 0, .standard: 0])
        #expect(result.movementsByGrade == [.xfine: -10, .fine: -10, .standard: -10])
        #expect(result.rawMaterialPrices == [.xfine: 30, .fine: 20, .standard: 10])
    }

    @Test("Aggregates units across multiple player orders before pricing")
    func aggregatesMultipleOrders() throws {
        let first = try EDRawOrder(unitsByGrade: [.xfine: 12, .fine: 2])
        let second = try EDRawOrder(unitsByGrade: [.fine: 3, .standard: 4])

        let result = try EDRawMarketResolver.resolve(
            orders: [first, second],
            previousPrices: openingPrices
        )

        #expect(result.orderedUnitsByGrade == [.xfine: 12, .fine: 5, .standard: 4])
        #expect(result.movementsByGrade == [.xfine: 2, .fine: -5, .standard: -6])
        #expect(result.rawMaterialPrices == [.xfine: 42, .fine: 25, .standard: 14])
    }

    @Test("Applies the one-dollar floor")
    func appliesDollarFloor() throws {
        let prices: [EDRawMaterialGrade: Int] = [
            .xfine: 1,
            .fine: 2,
            .standard: 9
        ]

        let result = try EDRawMarketResolver.resolve(orders: [], previousPrices: prices)

        #expect(result.rawMaterialPrices == [.xfine: 1, .fine: 1, .standard: 1])
    }

    @Test("Rejects a nonpositive prior price")
    func rejectsNonpositivePriorPrice() throws {
        var prices = openingPrices
        prices[.fine] = 0

        #expect(throws: EDRawMarketResolverError.nonPositivePreviousPrice(
            grade: .fine,
            price: 0
        )) {
            try EDRawMarketResolver.resolve(orders: [], previousPrices: prices)
        }
    }

    @Test("Rejects a missing prior grade price")
    func rejectsMissingPriorPrice() {
        var prices = openingPrices
        prices.removeValue(forKey: .standard)

        #expect(throws: EDRawMarketResolverError.missingPreviousPrice(grade: .standard)) {
            try EDRawMarketResolver.resolve(orders: [], previousPrices: prices)
        }
    }

    @Test("Reports overflow while aggregating units by grade")
    func reportsUnitAggregationOverflow() throws {
        let first = try EDRawOrder(unitsByGrade: [.fine: Int.max])
        let second = try EDRawOrder(unitsByGrade: [.fine: 1])

        #expect(throws: EDRawMarketResolverError.unitAggregationOverflow(grade: .fine)) {
            try EDRawMarketResolver.resolve(
                orders: [first, second],
                previousPrices: openingPrices
            )
        }
    }

    @Test("Reports overflow while updating a raw price")
    func reportsPriceOverflow() throws {
        var prices = openingPrices
        prices[.xfine] = Int.max
        let order = try EDRawOrder(unitsByGrade: [.xfine: 24])

        #expect(throws: EDRawMarketResolverError.priceOverflow(grade: .xfine)) {
            try EDRawMarketResolver.resolve(orders: [order], previousPrices: prices)
        }
    }

    @Test("Resolution round-trips through Codable")
    func resolutionCodableRoundTrip() throws {
        let result = try EDRawMarketResolver.resolve(
            orders: [],
            previousPrices: openingPrices
        )

        let data = try JSONEncoder().encode(result)
        #expect(try JSONDecoder().decode(EDRawMarketResolution.self, from: data) == result)
    }
}
