import Foundation
import Testing
@testable import EDEngine

@Suite("Goods-market resolver")
struct EDGoodsMarketResolverTests {
    private let openingPrices: [EDRecipe: Int] = [
        .a: EDOpeningPrices.finishedGoodPrice(for: .a),
        .b: EDOpeningPrices.finishedGoodPrice(for: .b),
        .c: EDOpeningPrices.finishedGoodPrice(for: .c)
    ]

    @Test("Resolves rulebook finished-good movements from valid offer totals")
    func resolvesRulebookFinishedGoodMovements() throws {
        let result = try EDGoodsMarketResolver.resolve(
            validOfferedUnitsByGood: [.a: 12, .b: 3],
            previousPrices: openingPrices
        )

        #expect(result.offeredUnitsByGood == [.a: 12, .b: 3, .c: 0])
        #expect(result.movementsByGood == [.a: -13, .b: 5, .c: 11])
        #expect(result.finishedGoodPrices == [.a: 127, .b: 120, .c: 101])
    }

    @Test("Zero offers use the zero-unit movement for every good")
    func resolvesZeroOffers() throws {
        let result = try EDGoodsMarketResolver.resolve(
            validOfferedUnitsByGood: [:],
            previousPrices: openingPrices
        )

        #expect(result.offeredUnitsByGood == [.a: 0, .b: 0, .c: 0])
        #expect(result.movementsByGood == [.a: 11, .b: 11, .c: 11])
        #expect(result.finishedGoodPrices == [.a: 151, .b: 126, .c: 101])
    }

    @Test("Caps each valid offer total to the calculator range")
    func capsOfferedUnitsAtCalculatorMaximum() throws {
        let result = try EDGoodsMarketResolver.resolve(
            validOfferedUnitsByGood: [.a: 17],
            previousPrices: openingPrices
        )

        #expect(result.movementsByGood[.a] == -21)
        #expect(result.finishedGoodPrices[.a] == 119)
    }

    @Test("Rejects a missing prior finished-good price")
    func rejectsMissingPreviousPrice() {
        var prices = openingPrices
        prices.removeValue(forKey: .b)

        #expect(throws: EDGoodsMarketResolverError.missingPreviousPrice(good: .b)) {
            try EDGoodsMarketResolver.resolve(
                validOfferedUnitsByGood: [:],
                previousPrices: prices
            )
        }
    }

    @Test("Rejects a nonpositive prior finished-good price")
    func rejectsNonpositivePreviousPrice() {
        var prices = openingPrices
        prices[.c] = 0

        #expect(throws: EDGoodsMarketResolverError.nonPositivePreviousPrice(
            good: .c,
            price: 0
        )) {
            try EDGoodsMarketResolver.resolve(
                validOfferedUnitsByGood: [:],
                previousPrices: prices
            )
        }
    }

    @Test("Reports overflow while updating a finished-good price")
    func reportsPriceOverflow() {
        var prices = openingPrices
        prices[.a] = Int.max

        #expect(throws: EDGoodsMarketResolverError.priceOverflow(good: .a)) {
            try EDGoodsMarketResolver.resolve(
                validOfferedUnitsByGood: [:],
                previousPrices: prices
            )
        }
    }

    @Test("Resolution round-trips through Codable")
    func resolutionCodableRoundTrip() throws {
        let result = try EDGoodsMarketResolver.resolve(
            validOfferedUnitsByGood: [.a: 1],
            previousPrices: openingPrices
        )

        let data = try JSONEncoder().encode(result)
        #expect(try JSONDecoder().decode(EDGoodsMarketResolution.self, from: data) == result)
    }
}
