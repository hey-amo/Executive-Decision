// EDRawMarketResolver.swift
// Resolves monthly raw orders into grade totals and updated prices.

/// Errors raised while resolving the monthly raw-material market.
public enum EDRawMarketResolverError: Error, Codable, Equatable, Hashable, Sendable {
    /// Rules: Raw Material Prices. Every raw-material grade needs a prior price.
    case missingPreviousPrice(grade: EDRawMaterialGrade)

    /// Rules: Raw Material Prices. A prior raw-material price must be positive.
    case nonPositivePreviousPrice(grade: EDRawMaterialGrade, price: Int)

    /// Rules: Purchasing Raw Materials. Aggregate grade units must fit in an integer.
    case unitAggregationOverflow(grade: EDRawMaterialGrade)

    /// Rules: Raw Material Prices. The updated raw-material price must fit in an integer.
    case priceOverflow(grade: EDRawMaterialGrade)
}

/// The aggregate monthly raw orders and resulting raw-material market prices.
///
/// Rules: Market Calculator, Raw Materials. Units and prices are tracked
/// independently for each grade before monthly price history is recorded.
public struct EDRawMarketResolution: Codable, Equatable, Hashable, Sendable {
    public let orderedUnitsByGrade: [EDRawMaterialGrade: Int]
    public let movementsByGrade: [EDRawMaterialGrade: Int]
    public let rawMaterialPrices: [EDRawMaterialGrade: Int]

    /// Creates a resolution containing the aggregate units and updated prices.
    ///
    /// Rules: Market Calculator, Raw Materials. A resolution records the
    /// per-grade market result without mutating monthly price history.
    public init(
        orderedUnitsByGrade: [EDRawMaterialGrade: Int],
        movementsByGrade: [EDRawMaterialGrade: Int],
        rawMaterialPrices: [EDRawMaterialGrade: Int]
    ) {
        self.orderedUnitsByGrade = orderedUnitsByGrade
        self.movementsByGrade = movementsByGrade
        self.rawMaterialPrices = rawMaterialPrices
    }
}

/// Resolves player raw-material orders without mutating a price board.
///
/// Rules: Market Calculator, Raw Materials. Monthly raw orders determine
/// independent grade movements and prices.
public enum EDRawMarketResolver {
    /// Aggregates ordered units by grade and calculates the resulting prices.
    ///
    /// Rules: Market Calculator, Raw Materials. Each grade's aggregate units
    /// determine its movement, which is applied to its prior price with a $1
    /// floor. Every grade must have a positive prior price.
    public static func resolve(
        orders: [EDRawOrder],
        previousPrices: [EDRawMaterialGrade: Int]
    ) throws(EDRawMarketResolverError) -> EDRawMarketResolution {
        for grade in EDRawMaterialGrade.allCases {
            guard let price = previousPrices[grade] else {
                throw .missingPreviousPrice(grade: grade)
            }
            guard price > 0 else {
                throw .nonPositivePreviousPrice(grade: grade, price: price)
            }
        }

        var orderedUnitsByGrade = Dictionary(
            uniqueKeysWithValues: EDRawMaterialGrade.allCases.map { ($0, 0) }
        )
        for order in orders {
            for grade in EDRawMaterialGrade.allCases {
                let (total, overflow) = orderedUnitsByGrade[grade, default: 0]
                    .addingReportingOverflow(order.units(for: grade))
                guard !overflow else {
                    throw .unitAggregationOverflow(grade: grade)
                }
                orderedUnitsByGrade[grade] = total
            }
        }

        var movementsByGrade: [EDRawMaterialGrade: Int] = [:]
        var rawMaterialPrices: [EDRawMaterialGrade: Int] = [:]
        for grade in EDRawMaterialGrade.allCases {
            let orderedUnits = orderedUnitsByGrade[grade, default: 0]
            guard let previousPrice = previousPrices[grade] else {
                throw .missingPreviousPrice(grade: grade)
            }
            movementsByGrade[grade] = EDMarketCalculator.rawMaterialMovement(
                forUnits: orderedUnits
            )
            do {
                rawMaterialPrices[grade] = try EDMarketCalculator.rawMaterialPrice(
                    previousPrice: previousPrice,
                    orderedUnits: orderedUnits
                )
            } catch {
                throw .priceOverflow(grade: grade)
            }
        }

        return EDRawMarketResolution(
            orderedUnitsByGrade: orderedUnitsByGrade,
            movementsByGrade: movementsByGrade,
            rawMaterialPrices: rawMaterialPrices
        )
    }
}
