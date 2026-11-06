import Foundation
import Testing
@testable import EDEngine

@Suite("Goods sales resolver")
struct EDGoodsSalesResolverTests {
    private let marketPrices: [EDRecipe: Int] = [
        .a: 140,
        .b: 115,
        .c: 90
    ]

    @Test("Sells all qualifying units at asking price and consumes their certificates")
    func resolvesRulebookSalePricesAndCertificateConsumption() throws {
        let playerID = UUID()
        let offer = try EDGoodsOffer(
            unitsByGood: [.a: 1, .b: 1, .c: 1],
            askingPricesByGood: [.a: 140, .b: 100, .c: 91]
        )
        let inventory = try EDInventory(
            certificatesByGrade: [.xfine: 2, .fine: 3, .standard: 1]
        )

        let result = try EDGoodsSalesResolver.resolve(
            eligibleOffersByPlayer: [playerID: offer],
            marketPrices: marketPrices,
            inventoriesByPlayer: [playerID: inventory]
        )

        let sale = try #require(result.salesByPlayer[playerID])
        #expect(sale.finishedGoodsSold == [.a: 1, .b: 1, .c: 0])
        #expect(sale.goodsSalesRevenue == 240)
        #expect(sale.certificatesUsedByGrade == [.xfine: 2, .fine: 3, .standard: 1])
        #expect(result.updatedInventoriesByPlayer[playerID] == EDInventory())
        #expect(result.certificateDeliveryFailures.isEmpty)
        #expect(inventory.certificatesByGrade == [.xfine: 2, .fine: 3, .standard: 1])
    }

    @Test("Prohibits the player's entire sale when certificates cannot cover all qualifying goods")
    func prohibitsWholeOfferWhenCertificateDeliveryFails() throws {
        let failingPlayerID = UUID()
        let independentPlayerID = UUID()
        let failingOffer = try EDGoodsOffer(
            unitsByGood: [.a: 1, .b: 1],
            askingPricesByGood: [.a: 100, .b: 100]
        )
        let independentOffer = try EDGoodsOffer(
            unitsByGood: [.c: 1],
            askingPricesByGood: [.c: 90]
        )
        let failingInventory = try EDInventory(
            certificatesByGrade: [.xfine: 2, .fine: 1]
        )
        let independentInventory = try EDInventory(
            certificatesByGrade: [.fine: 1, .standard: 2]
        )

        let result = try EDGoodsSalesResolver.resolve(
            eligibleOffersByPlayer: [
                failingPlayerID: failingOffer,
                independentPlayerID: independentOffer
            ],
            marketPrices: marketPrices,
            inventoriesByPlayer: [
                failingPlayerID: failingInventory,
                independentPlayerID: independentInventory
            ]
        )

        let failedSale = try #require(result.salesByPlayer[failingPlayerID])
        #expect(failedSale.finishedGoodsSold == [.a: 0, .b: 0, .c: 0])
        #expect(failedSale.goodsSalesRevenue == 0)
        #expect(failedSale.certificatesUsedByGrade == [.xfine: 0, .fine: 0, .standard: 0])
        #expect(result.updatedInventoriesByPlayer[failingPlayerID] == failingInventory)
        #expect(result.certificateDeliveryFailures == [failingPlayerID])

        let independentSale = try #require(result.salesByPlayer[independentPlayerID])
        #expect(independentSale.finishedGoodsSold == [.a: 0, .b: 0, .c: 1])
        #expect(independentSale.goodsSalesRevenue == 90)
        #expect(result.updatedInventoriesByPlayer[independentPlayerID] == EDInventory())
    }

    @Test("Uses legal certificate substitutions for sold goods")
    func consumesSubstitutedCertificates() throws {
        let playerID = UUID()
        let offer = try EDGoodsOffer(
            unitsByGood: [.b: 1],
            askingPricesByGood: [.b: 115]
        )
        let inventory = try EDInventory(
            certificatesByGrade: [.xfine: 1, .fine: 1, .standard: 1]
        )

        let result = try EDGoodsSalesResolver.resolve(
            eligibleOffersByPlayer: [playerID: offer],
            marketPrices: marketPrices,
            inventoriesByPlayer: [playerID: inventory]
        )

        let sale = try #require(result.salesByPlayer[playerID])
        #expect(sale.finishedGoodsSold == [.a: 0, .b: 1, .c: 0])
        #expect(sale.certificatesUsedByGrade == [.xfine: 1, .fine: 1, .standard: 1])
        #expect(result.updatedInventoriesByPlayer[playerID] == EDInventory())
    }

    @Test("Requires positive market prices and an inventory for every eligible offer")
    func validatesMarketPricesAndInventories() throws {
        let playerID = UUID()
        let offer = try EDGoodsOffer()
        let inventory = EDInventory()

        #expect(throws: EDGoodsSalesResolverError.missingMarketPrice(good: .c)) {
            try EDGoodsSalesResolver.resolve(
                eligibleOffersByPlayer: [playerID: offer],
                marketPrices: [.a: 140, .b: 115],
                inventoriesByPlayer: [playerID: inventory]
            )
        }
        #expect(throws: EDGoodsSalesResolverError.invalidMarketPrice(good: .b, price: 0)) {
            try EDGoodsSalesResolver.resolve(
                eligibleOffersByPlayer: [playerID: offer],
                marketPrices: [.a: 140, .b: 0, .c: 90],
                inventoriesByPlayer: [playerID: inventory]
            )
        }
        #expect(throws: EDGoodsSalesResolverError.missingInventory(playerID: playerID)) {
            try EDGoodsSalesResolver.resolve(
                eligibleOffersByPlayer: [playerID: offer],
                marketPrices: marketPrices,
                inventoriesByPlayer: [:]
            )
        }
    }

    @Test("Reports revenue overflow without returning a partial resolution")
    func rejectsRevenueOverflow() throws {
        let playerID = UUID()
        let offer = try EDGoodsOffer(
            unitsByGood: [.a: 2],
            askingPricesByGood: [.a: Int.max]
        )
        let inventory = try EDInventory(
            certificatesByGrade: [.xfine: 4, .fine: 2]
        )

        #expect(
            throws: EDGoodsSalesResolverError.salesRevenueOverflow(
                playerID: playerID,
                good: .a
            )
        ) {
            try EDGoodsSalesResolver.resolve(
                eligibleOffersByPlayer: [playerID: offer],
                marketPrices: [.a: Int.max, .b: 115, .c: 90],
                inventoriesByPlayer: [playerID: inventory]
            )
        }
    }

    @Test("Reports overflow when otherwise valid good revenues exceed the total")
    func rejectsTotalRevenueOverflow() throws {
        let playerID = UUID()
        let offer = try EDGoodsOffer(
            unitsByGood: [.a: 1, .b: 1],
            askingPricesByGood: [.a: Int.max, .b: 1]
        )
        let inventory = try EDInventory(
            certificatesByGrade: [.xfine: 2, .fine: 3, .standard: 1]
        )

        #expect(
            throws: EDGoodsSalesResolverError.totalSalesRevenueOverflow(playerID: playerID)
        ) {
            try EDGoodsSalesResolver.resolve(
                eligibleOffersByPlayer: [playerID: offer],
                marketPrices: [.a: Int.max, .b: 115, .c: 90],
                inventoriesByPlayer: [playerID: inventory]
            )
        }
    }
}
