import Foundation
import Testing
@testable import EDEngine

@Suite("Finished-good offers")
struct EDGoodsOfferTests {
    @Test("Stores units and asking prices independently by good")
    func storesGoodOffers() throws {
        let offer = try EDGoodsOffer(
            unitsByGood: [.a: 2, .c: 4],
            askingPricesByGood: [.a: 140, .b: 120]
        )

        #expect(offer.units(for: .a) == 2)
        #expect(offer.units(for: .b) == 0)
        #expect(offer.units(for: .c) == 4)
        #expect(offer.askingPrice(for: .a) == 140)
        #expect(offer.askingPrice(for: .b) == 120)
        #expect(offer.askingPrice(for: .c) == 0)
        #expect(offer.unitsByGood == [.a: 2, .b: 0, .c: 4])
        #expect(offer.askingPricesByGood == [.a: 140, .b: 120, .c: 0])
    }

    @Test("Defaults to a zero-unit offer")
    func emptyOfferHasZeroTotals() throws {
        let offer = try EDGoodsOffer()

        #expect(try offer.totalUnits() == 0)
        #expect(offer.unitsByGood.values.allSatisfy { $0 == 0 })
        #expect(offer.askingPricesByGood.values.allSatisfy { $0 == 0 })
    }

    @Test("Totals offers across good types")
    func totalsUnits() throws {
        let offer = try EDGoodsOffer(unitsByGood: [.a: 2, .b: 3, .c: 1])

        #expect(try offer.totalUnits() == 6)
    }

    @Test("Rejects negative offered units and asking prices")
    func rejectsNegativeValues() {
        #expect(throws: EDGoodsOfferError.negativeUnits(good: .b, units: -1)) {
            try EDGoodsOffer(unitsByGood: [.b: -1])
        }
        #expect(throws: EDGoodsOfferError.negativeAskingPrice(good: .c, price: -10)) {
            try EDGoodsOffer(askingPricesByGood: [.c: -10])
        }
    }

    @Test("Reports overflow when summing offered units")
    func reportsTotalOverflow() throws {
        let offer = try EDGoodsOffer(unitsByGood: [.a: Int.max, .c: 1])

        #expect(throws: EDGoodsOfferError.totalUnitsOverflow) {
            try offer.totalUnits()
        }
    }

    @Test("Codable round-trips offers and rejects negative persisted values")
    func codableValidation() throws {
        let offer = try EDGoodsOffer(
            unitsByGood: [.a: 2, .c: 4],
            askingPricesByGood: [.a: 140, .c: 90]
        )
        let data = try JSONEncoder().encode(offer)
        #expect(try JSONDecoder().decode(EDGoodsOffer.self, from: data) == offer)

        let invalid = #"{"unitsByGood":{"b":-1},"askingPricesByGood":{}}"#
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(EDGoodsOffer.self, from: Data(invalid.utf8))
        }
    }
}
