import Foundation
import Testing
@testable import EDEngine

@Suite("Goods offer validator")
struct EDGoodsOfferValidatorTests {
    @Test("Accepts offers producible with the player's inventory")
    func acceptsProducibleOffersAndAggregatesTheirUnits() throws {
        let firstPlayerID = UUID()
        let secondPlayerID = UUID()
        let result = try EDGoodsOfferValidator.validate(
            offersByPlayer: [
                firstPlayerID: try EDGoodsOffer(unitsByGood: [.a: 1]),
                secondPlayerID: try EDGoodsOffer(unitsByGood: [.b: 1])
            ],
            inventoriesByPlayer: [
                firstPlayerID: try EDInventory(certificatesByGrade: [.xfine: 2, .fine: 1]),
                secondPlayerID: try EDInventory(certificatesByGrade: [.fine: 2, .standard: 1])
            ]
        )

        #expect(result.validOffersByPlayer.count == 2)
        #expect(result.disqualifiedPlayerIDs.isEmpty)
        #expect(result.validOfferedUnitsByGood == [.a: 1, .b: 1, .c: 0])
    }

    @Test("Disqualifies all offers from a player who over-offers")
    func excludesAnOverOfferFromAllMarketTotals() throws {
        let overOfferingPlayerID = UUID()
        let eligiblePlayerID = UUID()
        let result = try EDGoodsOfferValidator.validate(
            offersByPlayer: [
                overOfferingPlayerID: try EDGoodsOffer(unitsByGood: [.a: 1, .b: 1]),
                eligiblePlayerID: try EDGoodsOffer(unitsByGood: [.a: 1])
            ],
            inventoriesByPlayer: [
                overOfferingPlayerID: try EDInventory(certificatesByGrade: [.xfine: 2, .fine: 1]),
                eligiblePlayerID: try EDInventory(certificatesByGrade: [.xfine: 2, .fine: 1])
            ]
        )
        let expectedEligibleOffer = try EDGoodsOffer(unitsByGood: [.a: 1])

        #expect(result.validOffersByPlayer == [eligiblePlayerID: expectedEligibleOffer])
        #expect(result.disqualifiedPlayerIDs == [overOfferingPlayerID])
        #expect(result.validOfferedUnitsByGood == [.a: 1, .b: 0, .c: 0])
    }

    @Test("Accepts legal substitutions when validating an offer")
    func acceptsOffersUsingLegalSubstitutions() throws {
        let playerID = UUID()
        let result = try EDGoodsOfferValidator.validate(
            offersByPlayer: [playerID: try EDGoodsOffer(unitsByGood: [.b: 1])],
            inventoriesByPlayer: [playerID: try EDInventory(certificatesByGrade: [.xfine: 1, .fine: 2])]
        )

        #expect(result.validOffersByPlayer[playerID] != nil)
        #expect(result.disqualifiedPlayerIDs.isEmpty)
    }

    @Test("Reports when an offer has no matching inventory")
    func requiresInventoryForEveryOffer() throws {
        let playerID = UUID()
        let offer = try EDGoodsOffer(unitsByGood: [.a: 1])

        #expect(throws: EDGoodsOfferValidationError.missingInventory(playerID: playerID)) {
            try EDGoodsOfferValidator.validate(
                offersByPlayer: [playerID: offer],
                inventoriesByPlayer: [:]
            )
        }
    }

    @Test("Reports overflow when valid offers are aggregated")
    func reportsValidOfferAggregationOverflow() throws {
        let playerIDs = [UUID(), UUID(), UUID()]
        var offers: [UUID: EDGoodsOffer] = [:]
        var inventories: [UUID: EDInventory] = [:]
        for playerID in playerIDs {
            offers[playerID] = try EDGoodsOffer(unitsByGood: [.a: Int.max / 2])
            inventories[playerID] = try EDInventory(
                certificatesByGrade: [.xfine: Int.max, .fine: Int.max]
            )
        }

        #expect(
            throws: EDGoodsOfferValidationError.validOfferUnitAggregationOverflow(good: .a)
        ) {
            try EDGoodsOfferValidator.validate(
                offersByPlayer: offers,
                inventoriesByPlayer: inventories
            )
        }
    }
}
