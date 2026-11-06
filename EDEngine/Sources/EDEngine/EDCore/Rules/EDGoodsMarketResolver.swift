// EDGoodsMarketResolver.swift
// Resolves valid finished-good offer totals into updated market prices.

/// Errors raised while resolving the finished-good market.
public enum EDGoodsMarketResolverError: Error, Codable, Equatable, Hashable, Sendable {
    /// Rules: FR-11. Every finished good needs a prior market price.
    case missingPreviousPrice(good: EDRecipe)

    /// Rules: FR-11. A prior finished-good price must be positive.
    case nonPositivePreviousPrice(good: EDRecipe, price: Int)

    /// Rules: FR-11. The updated finished-good price must fit in an integer.
    case priceOverflow(good: EDRecipe)
}

/// The aggregate valid offers and resulting finished-good market prices.
///
/// Rules: FR-11. Each good's valid offered units independently determine its
/// market movement and updated price.
public struct EDGoodsMarketResolution: Codable, Equatable, Hashable, Sendable {
    public let offeredUnitsByGood: [EDRecipe: Int]
    public let movementsByGood: [EDRecipe: Int]
    public let finishedGoodPrices: [EDRecipe: Int]

    /// Creates a resolution containing aggregate units and updated prices.
    ///
    /// Rules: FR-11. A resolution records the per-good market result without
    /// mutating monthly price history.
    public init(
        offeredUnitsByGood: [EDRecipe: Int],
        movementsByGood: [EDRecipe: Int],
        finishedGoodPrices: [EDRecipe: Int]
    ) {
        self.offeredUnitsByGood = offeredUnitsByGood
        self.movementsByGood = movementsByGood
        self.finishedGoodPrices = finishedGoodPrices
    }
}

/// Resolves valid finished-good offer totals without mutating a price board.
///
/// Rules: FR-11. Only the valid per-good totals produced by goods-offer
/// validation determine monthly finished-good movements and prices.
public enum EDGoodsMarketResolver {
    /// Calculates movements and updated prices from valid offered-unit totals.
    ///
    /// Unspecified goods have zero valid offers. Every good must have a
    /// positive prior price.
    ///
    /// Rules: FR-11 Goods pricing. The finished-good movement is applied to the
    /// previous price using the finished-goods market calculator.
    public static func resolve(
        validOfferedUnitsByGood: [EDRecipe: Int],
        previousPrices: [EDRecipe: Int]
    ) throws(EDGoodsMarketResolverError) -> EDGoodsMarketResolution {
        for good in EDRecipe.allCases {
            guard let price = previousPrices[good] else {
                throw .missingPreviousPrice(good: good)
            }
            guard price > 0 else {
                throw .nonPositivePreviousPrice(good: good, price: price)
            }
        }

        var movementsByGood: [EDRecipe: Int] = [:]
        var finishedGoodPrices: [EDRecipe: Int] = [:]
        for good in EDRecipe.allCases {
            let offeredUnits = validOfferedUnitsByGood[good, default: 0]
            movementsByGood[good] = EDMarketCalculator.finishedGoodMovement(
                forUnits: offeredUnits
            )
            guard let previousPrice = previousPrices[good] else {
                throw .missingPreviousPrice(good: good)
            }
            do {
                finishedGoodPrices[good] = try EDMarketCalculator.finishedGoodPrice(
                    previousPrice: previousPrice,
                    offeredUnits: offeredUnits
                )
            } catch {
                throw .priceOverflow(good: good)
            }
        }

        return EDGoodsMarketResolution(
            offeredUnitsByGood: Dictionary(
                uniqueKeysWithValues: EDRecipe.allCases.map {
                    ($0, validOfferedUnitsByGood[$0, default: 0])
                }
            ),
            movementsByGood: movementsByGood,
            finishedGoodPrices: finishedGoodPrices
        )
    }
}
