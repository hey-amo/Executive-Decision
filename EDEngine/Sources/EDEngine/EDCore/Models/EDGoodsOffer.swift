// EDGoodsOffer.swift — goods units and asking prices

/// Errors raised when constructing or inspecting finished-good offers.
public enum EDGoodsOfferError: Error, Equatable, Sendable {
    /// Rules: FR-10 Goods offers. Offered unit counts cannot be negative.
    case negativeUnits(good: EDRecipe, units: Int)

    /// Rules: Selling Finished Goods. An asking price cannot be negative.
    case negativeAskingPrice(good: EDRecipe, price: Int)

    /// Rules: Goods offers count all offered units without integer overflow.
    case totalUnitsOverflow
}

/// One player's finished-good offers for a month.
///
/// Rules: FR-10 Goods offers. A player submits the units offered and minimum
/// asking price for each good. Inventory eligibility and over-offer handling
/// are checked separately by goods-offer rules.
public struct EDGoodsOffer: Codable, Equatable, Hashable, Sendable {
    public private(set) var unitsByGood: [EDRecipe: Int]
    public private(set) var askingPricesByGood: [EDRecipe: Int]

    private enum CodingKeys: String, CodingKey {
        case unitsByGood
        case askingPricesByGood
    }

    /// Creates an offer with per-good units and asking prices.
    ///
    /// Rules: FR-10 Goods offers record units and asking price per type;
    /// omitted goods default to zero units and a zero asking price.
    public init(
        unitsByGood: [EDRecipe: Int] = [:],
        askingPricesByGood: [EDRecipe: Int] = [:]
    ) throws(EDGoodsOfferError) {
        for good in EDRecipe.allCases {
            let units = unitsByGood[good, default: 0]
            guard units >= 0 else {
                throw .negativeUnits(good: good, units: units)
            }

            let askingPrice = askingPricesByGood[good, default: 0]
            guard askingPrice >= 0 else {
                throw .negativeAskingPrice(good: good, price: askingPrice)
            }
        }

        self.unitsByGood = Dictionary(
            uniqueKeysWithValues: EDRecipe.allCases.map {
                ($0, unitsByGood[$0, default: 0])
            }
        )
        self.askingPricesByGood = Dictionary(
            uniqueKeysWithValues: EDRecipe.allCases.map {
                ($0, askingPricesByGood[$0, default: 0])
            }
        )
    }

    /// Returns units offered for one good.
    ///
    /// Rules: FR-10 Goods offers track offered units by good type.
    public func units(for good: EDRecipe) -> Int {
        unitsByGood[good, default: 0]
    }

    /// Returns the per-unit asking price for one good.
    ///
    /// Rules: FR-10 Goods offers track asking prices by good type.
    public func askingPrice(for good: EDRecipe) -> Int {
        askingPricesByGood[good, default: 0]
    }

    /// Returns the total number of units offered across all good types.
    ///
    /// Rules: Goods market resolution sums valid offers by good type.
    public func totalUnits() throws(EDGoodsOfferError) -> Int {
        var total = 0
        for good in EDRecipe.allCases {
            let (newTotal, overflow) = total.addingReportingOverflow(units(for: good))
            guard !overflow else {
                throw .totalUnitsOverflow
            }
            total = newTotal
        }
        return total
    }

    /// Decodes an offer and validates nonnegative units and asking prices.
    ///
    /// Rules: FR-10 Goods offers cannot contain negative units or asking prices.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let unitsByGood = try container.decodeIfPresent(
            [EDRecipe: Int].self,
            forKey: .unitsByGood
        ) ?? [:]
        let askingPricesByGood = try container.decodeIfPresent(
            [EDRecipe: Int].self,
            forKey: .askingPricesByGood
        ) ?? [:]

        do {
            try self.init(
                unitsByGood: unitsByGood,
                askingPricesByGood: askingPricesByGood
            )
        } catch {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Goods offer units and asking prices cannot be negative."
                )
            )
        }
    }
}
