// EDGoodsOfferValidator.swift — disqualifies over-offers and excludes them from goods pricing.

import Foundation

/// Errors raised while preparing finished-good offers for market pricing.
public enum EDGoodsOfferValidationError: Error, Equatable, Sendable {
    /// Rules: FR-10. An offer must have a matching player's inventory.
    case missingInventory(playerID: UUID)

    /// Rules: FR-10. Valid offered units must be summable for market pricing.
    case validOfferUnitAggregationOverflow(good: EDRecipe)
}

/// Offers eligible for sale and price determination after FR-10 validation.
///
/// Rules: FR-10. Disqualified players' entire offers are excluded from the
/// valid market totals.
public struct EDGoodsOfferValidationResult: Equatable, Sendable {
    /// Offers from players whose complete offer can be produced.
    public let validOffersByPlayer: [UUID: EDGoodsOffer]

    /// Players whose offer exceeded the goods they can produce.
    public let disqualifiedPlayerIDs: Set<UUID>

    /// Per-good totals from valid offers only; use these for price determination.
    public let validOfferedUnitsByGood: [EDRecipe: Int]

    init(
        validOffersByPlayer: [UUID: EDGoodsOffer],
        disqualifiedPlayerIDs: Set<UUID>,
        validOfferedUnitsByGood: [EDRecipe: Int]
    ) {
        self.validOffersByPlayer = validOffersByPlayer
        self.disqualifiedPlayerIDs = disqualifiedPlayerIDs
        self.validOfferedUnitsByGood = validOfferedUnitsByGood
    }
}

/// Validates finished-good offers against each player's raw-material inventory.
///
/// Rules: FR-10. An over-offer disqualifies that player's complete offer, and
/// none of its units count toward goods-market prices.
public enum EDGoodsOfferValidator {
    /// Returns only producible offers and aggregates their units by good.
    ///
    /// Production is checked jointly across all good types for each player,
    /// allowing only the substitutions in the manufacturing rules.
    ///
    /// Rules: FR-10 Goods offers.
    public static func validate(
        offersByPlayer: [UUID: EDGoodsOffer],
        inventoriesByPlayer: [UUID: EDInventory]
    ) throws(EDGoodsOfferValidationError) -> EDGoodsOfferValidationResult {
        var validOffersByPlayer: [UUID: EDGoodsOffer] = [:]
        var disqualifiedPlayerIDs: Set<UUID> = []
        var validOfferedUnitsByGood = Dictionary(
            uniqueKeysWithValues: EDRecipe.allCases.map { ($0, 0) }
        )

        for (playerID, offer) in offersByPlayer.sorted(by: {
            $0.key.uuidString < $1.key.uuidString
        }) {
            guard let inventory = inventoriesByPlayer[playerID] else {
                throw .missingInventory(playerID: playerID)
            }

            guard EDProductionAllocator.allocate(
                inventory: inventory,
                goodsUnits: offer.unitsByGood
            ) != nil else {
                disqualifiedPlayerIDs.insert(playerID)
                continue
            }

            validOffersByPlayer[playerID] = offer
            for good in EDRecipe.allCases {
                let (total, overflow) = validOfferedUnitsByGood[good, default: 0]
                    .addingReportingOverflow(offer.units(for: good))
                guard !overflow else {
                    throw .validOfferUnitAggregationOverflow(good: good)
                }
                validOfferedUnitsByGood[good] = total
            }
        }

        return EDGoodsOfferValidationResult(
            validOffersByPlayer: validOffersByPlayer,
            disqualifiedPlayerIDs: disqualifiedPlayerIDs,
            validOfferedUnitsByGood: validOfferedUnitsByGood
        )
    }
}
