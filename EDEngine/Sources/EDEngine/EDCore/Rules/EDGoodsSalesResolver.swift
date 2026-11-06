import Foundation

/// Errors raised while resolving finished-good sales.
public enum EDGoodsSalesResolverError: Error, Equatable, Sendable {
    /// Rules: FR-11. A market price must exist for every finished good.
    case missingMarketPrice(good: EDRecipe)

    /// Rules: FR-11. Finished-good market prices must be positive.
    case invalidMarketPrice(good: EDRecipe, price: Int)

    /// Rules: FR-11. Every eligible offer must have a matching inventory.
    case missingInventory(playerID: UUID)

    /// Rules: FR-11. Revenue for one good must fit a whole-dollar integer.
    case salesRevenueOverflow(playerID: UUID, good: EDRecipe)

    /// Rules: FR-11. Total sales revenue must fit a whole-dollar integer.
    case totalSalesRevenueOverflow(playerID: UUID)

    /// Rules: FR-11. Sold goods consume the certificates used to manufacture them.
    case inventory(EDInventoryError)
}

/// One player's completed finished-good sales.
///
/// Rules: FR-11 records all qualifying offered units at their asking prices.
public struct EDGoodsSaleOutcome: Equatable, Hashable, Sendable {
    /// Rules: FR-11. Units sold by good; unsold and unoffered goods have a count of zero.
    public let finishedGoodsSold: [EDRecipe: Int]

    /// Rules: FR-11. Total proceeds from goods sold at their asking prices.
    public let goodsSalesRevenue: Int

    /// Rules: FR-11. Certificates consumed by grade to manufacture the goods sold.
    public let certificatesUsedByGrade: [EDRawMaterialGrade: Int]

    init(
        finishedGoodsSold: [EDRecipe: Int],
        goodsSalesRevenue: Int,
        certificatesUsedByGrade: [EDRawMaterialGrade: Int]
    ) {
        self.finishedGoodsSold = finishedGoodsSold
        self.goodsSalesRevenue = goodsSalesRevenue
        self.certificatesUsedByGrade = certificatesUsedByGrade
    }
}

/// Completed sales and the resulting raw-certificate inventories.
///
/// Rules: FR-11 sales consume certificates used for sold goods; a player who
/// cannot deliver every certificate required for their sold goods has no sales.
public struct EDGoodsSalesResolution: Equatable, Hashable, Sendable {
    /// Rules: FR-11. Sale outcomes for eligible offers, including offers with no units sold.
    public let salesByPlayer: [UUID: EDGoodsSaleOutcome]

    /// Rules: FR-11. Inventories after all sales; players without offers are unchanged.
    public let updatedInventoriesByPlayer: [UUID: EDInventory]

    /// Rules: FR-11. Players whose otherwise qualifying sales were prohibited
    /// because they could not deliver certificates for all goods sold.
    public let certificateDeliveryFailures: Set<UUID>

    init(
        salesByPlayer: [UUID: EDGoodsSaleOutcome],
        updatedInventoriesByPlayer: [UUID: EDInventory],
        certificateDeliveryFailures: Set<UUID>
    ) {
        self.salesByPlayer = salesByPlayer
        self.updatedInventoriesByPlayer = updatedInventoriesByPlayer
        self.certificateDeliveryFailures = certificateDeliveryFailures
    }
}

/// Resolves eligible finished-good offers against their market prices.
///
/// Rules: FR-11. An offer at or below market sells all offered units at the
/// asking price; an offer above market sells none. Certificates for all goods
/// sold are allocated jointly. If a player cannot deliver all those
/// certificates, that player's entire offer is prohibited from sale.
public enum EDGoodsSalesResolver {
    /// Resolves sales and returns updated inventories without mutating inputs.
    ///
    /// Offers must already be eligible under FR-10; disqualified players are
    /// excluded by the caller. The resolver does not calculate market prices
    /// or validate offers against the amount a player could originally produce.
    ///
    /// Rules: FR-11. Qualifying units sell at the asking price, higher-than-
    /// market offers do not sell, and sold goods consume their raw certificates.
    public static func resolve(
        eligibleOffersByPlayer: [UUID: EDGoodsOffer],
        marketPrices: [EDRecipe: Int],
        inventoriesByPlayer: [UUID: EDInventory]
    ) throws(EDGoodsSalesResolverError) -> EDGoodsSalesResolution {
        for good in EDRecipe.allCases {
            guard let price = marketPrices[good] else {
                throw .missingMarketPrice(good: good)
            }
            guard price > 0 else {
                throw .invalidMarketPrice(good: good, price: price)
            }
        }

        var updatedInventories = inventoriesByPlayer
        var salesByPlayer: [UUID: EDGoodsSaleOutcome] = [:]
        var certificateDeliveryFailures: Set<UUID> = []

        for (playerID, offer) in eligibleOffersByPlayer.sorted(by: {
            $0.key.uuidString < $1.key.uuidString
        }) {
            guard let inventory = inventoriesByPlayer[playerID] else {
                throw .missingInventory(playerID: playerID)
            }

            var qualifyingUnits = Dictionary(
                uniqueKeysWithValues: EDRecipe.allCases.map { ($0, 0) }
            )
            for good in EDRecipe.allCases
            where offer.askingPrice(for: good) <= marketPrices[good, default: 0] {
                qualifyingUnits[good] = offer.units(for: good)
            }

            guard let allocation = EDProductionAllocator.allocate(
                inventory: inventory,
                goodsUnits: qualifyingUnits
            ) else {
                certificateDeliveryFailures.insert(playerID)
                salesByPlayer[playerID] = noSaleOutcome()
                continue
            }

            var revenue = 0
            for good in EDRecipe.allCases {
                let (goodRevenue, revenueOverflow) = qualifyingUnits[good, default: 0]
                    .multipliedReportingOverflow(by: offer.askingPrice(for: good))
                guard !revenueOverflow else {
                    throw .salesRevenueOverflow(playerID: playerID, good: good)
                }
                let (newRevenue, totalOverflow) = revenue.addingReportingOverflow(goodRevenue)
                guard !totalOverflow else {
                    throw .totalSalesRevenueOverflow(playerID: playerID)
                }
                revenue = newRevenue
            }

            var updatedInventory = inventory
            let certificatesUsed = allocation.certificatesUsedByGrade
            for grade in EDRawMaterialGrade.allCases {
                do {
                    try updatedInventory.remove(
                        certificatesUsed[grade, default: 0],
                        of: grade
                    )
                } catch {
                    throw .inventory(error)
                }
            }

            updatedInventories[playerID] = updatedInventory
            salesByPlayer[playerID] = EDGoodsSaleOutcome(
                finishedGoodsSold: qualifyingUnits,
                goodsSalesRevenue: revenue,
                certificatesUsedByGrade: certificatesUsed
            )
        }

        return EDGoodsSalesResolution(
            salesByPlayer: salesByPlayer,
            updatedInventoriesByPlayer: updatedInventories,
            certificateDeliveryFailures: certificateDeliveryFailures
        )
    }

    private static func noSaleOutcome() -> EDGoodsSaleOutcome {
        EDGoodsSaleOutcome(
            finishedGoodsSold: Dictionary(
                uniqueKeysWithValues: EDRecipe.allCases.map { ($0, 0) }
            ),
            goodsSalesRevenue: 0,
            certificatesUsedByGrade: Dictionary(
                uniqueKeysWithValues: EDRawMaterialGrade.allCases.map { ($0, 0) }
            )
        )
    }
}
