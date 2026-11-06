// EDRawPurchaseResolver.swift
// Resolves raw purchases, affordability, loans, and partial fills.

/// Errors raised while resolving a player's raw-material purchase.
public enum EDRawPurchaseResolverError: Error, Equatable, Sendable {
    /// Rules: FR-7. A current market price must exist for every raw grade.
    case missingMarketPrice(grade: EDRawMaterialGrade)

    /// Rules: FR-7. A current market price must be positive.
    case invalidMarketPrice(grade: EDRawMaterialGrade, price: Int)

    /// Rules: FR-8. Purchase costs must be representable as whole-dollar amounts.
    case purchaseCostOverflow(grade: EDRawMaterialGrade)

    /// Rules: FR-8. Total purchase cost must be representable as a whole-dollar amount.
    case totalCostOverflow

    /// Rules: FR-13. Required loan amount must fit a whole-dollar integer.
    case loanAmountOverflow

    /// Rules: FR-8 and FR-13. Player cash or loan state could not be updated.
    case playerState(EDPlayerStateError)

    /// Rules: FR-8. Purchased certificate counts must fit in the player's inventory.
    case inventory(EDInventoryError)
}

/// Resolved purchases and the resulting player state.
///
/// Rules: FR-8 records purchased units at each player's bid price. Loan and
/// partial-purchase variations adjust affordability and purchased quantities.
public struct EDRawPurchaseResolution: Codable, Equatable, Hashable, Sendable {
    public let playerState: EDPlayerState
    public let unitsPurchasedByGrade: [EDRawMaterialGrade: Int]
    public let totalCost: Int
    public let loanAmount: Int

    /// Creates a raw-purchase result.
    ///
    /// Rules: FR-8, FR-13, and FR-14. The result records actual purchases,
    /// payment, any loan principal borrowed, and the updated player state.
    public init(
        playerState: EDPlayerState,
        unitsPurchasedByGrade: [EDRawMaterialGrade: Int],
        totalCost: Int,
        loanAmount: Int
    ) {
        self.playerState = playerState
        self.unitsPurchasedByGrade = unitsPurchasedByGrade
        self.totalCost = totalCost
        self.loanAmount = loanAmount
    }

    /// Returns the number of purchased units for a grade.
    ///
    /// Rules: Raw purchases are resolved separately by certificate grade.
    public func unitsPurchased(of grade: EDRawMaterialGrade) -> Int {
        unitsPurchasedByGrade[grade, default: 0]
    }
}

/// Resolves a player's raw-material order against current market prices.
///
/// Rules: FR-8 base purchasing, FR-13 loan variation, and FR-14 partial-purchase
/// variation. The resolver is pure: it returns a new player state.
public enum EDRawPurchaseResolver {
    /// Resolves eligible units, affordability, payment, loans, and inventory.
    ///
    /// Bids at or above market purchase all ordered units. With the partial
    /// purchase variation, a below-market bid loses one unit for each dollar
    /// of shortfall. In base rules, insufficient cash cancels all purchases;
    /// loan variation borrows in $100 increments as needed.
    ///
    /// Rules: FR-8, FR-13, and FR-14.
    public static func resolve(
        order: EDRawOrder,
        marketPrices: [EDRawMaterialGrade: Int],
        playerState: EDPlayerState,
        enabledVariations: Set<EDGameVariation> = []
    ) throws(EDRawPurchaseResolverError) -> EDRawPurchaseResolution {
        for grade in EDRawMaterialGrade.allCases {
            guard let price = marketPrices[grade] else {
                throw .missingMarketPrice(grade: grade)
            }
            guard price > 0 else {
                throw .invalidMarketPrice(grade: grade, price: price)
            }
        }

        var unitsPurchased = Dictionary(
            uniqueKeysWithValues: EDRawMaterialGrade.allCases.map { ($0, 0) }
        )
        var totalCost = 0

        for grade in EDRawMaterialGrade.allCases {
            let orderedUnits = order.units(for: grade)
            let bid = order.bid(for: grade)
            let marketPrice = marketPrices[grade, default: 0]
            let purchasedUnits: Int

            if orderedUnits == 0 {
                purchasedUnits = 0
            } else if bid >= marketPrice {
                purchasedUnits = orderedUnits
            } else if enabledVariations.contains(.partialRawPurchases) {
                let shortfallPerUnit = marketPrice - bid
                purchasedUnits = shortfallPerUnit >= orderedUnits
                    ? 0
                    : orderedUnits - shortfallPerUnit
            } else {
                purchasedUnits = 0
            }

            let (gradeCost, costOverflow) = purchasedUnits.multipliedReportingOverflow(by: bid)
            guard !costOverflow else {
                throw .purchaseCostOverflow(grade: grade)
            }
            let (newTotalCost, totalOverflow) = totalCost.addingReportingOverflow(gradeCost)
            guard !totalOverflow else {
                throw .totalCostOverflow
            }

            unitsPurchased[grade] = purchasedUnits
            totalCost = newTotalCost
        }

        guard totalCost > 0 else {
            return try completePurchase(
                unitsPurchased: unitsPurchased,
                totalCost: totalCost,
                loanAmount: 0,
                playerState: playerState
            )
        }

        if totalCost > playerState.cash.balance {
            guard enabledVariations.contains(.loans) else {
                return noPurchase(playerState)
            }
            return try completePurchaseWithLoan(
                unitsPurchased: unitsPurchased,
                totalCost: totalCost,
                playerState: playerState
            )
        }

        return try completePurchase(
            unitsPurchased: unitsPurchased,
            totalCost: totalCost,
            loanAmount: 0,
            playerState: playerState
        )
    }

    private static func noPurchase(
        _ playerState: EDPlayerState
    ) -> EDRawPurchaseResolution {
        EDRawPurchaseResolution(
            playerState: playerState,
            unitsPurchasedByGrade: Dictionary(
                uniqueKeysWithValues: EDRawMaterialGrade.allCases.map { ($0, 0) }
            ),
            totalCost: 0,
            loanAmount: 0
        )
    }

    private static func completePurchaseWithLoan(
        unitsPurchased: [EDRawMaterialGrade: Int],
        totalCost: Int,
        playerState: EDPlayerState
    ) throws(EDRawPurchaseResolverError) -> EDRawPurchaseResolution {
        let (shortfall, shortfallOverflow) = totalCost.subtractingReportingOverflow(
            playerState.cash.balance
        )
        guard !shortfallOverflow, shortfall > 0 else {
            throw .loanAmountOverflow
        }

        let loanHundreds = shortfall / 100 + (shortfall.isMultiple(of: 100) ? 0 : 1)
        let (loanAmount, loanOverflow) = loanHundreds.multipliedReportingOverflow(by: 100)
        guard !loanOverflow else {
            throw .loanAmountOverflow
        }

        var fundedState = playerState
        do {
            try fundedState.borrow(loanAmount)
        } catch {
            throw .playerState(error)
        }

        return try completePurchase(
            unitsPurchased: unitsPurchased,
            totalCost: totalCost,
            loanAmount: loanAmount,
            playerState: fundedState
        )
    }

    private static func completePurchase(
        unitsPurchased: [EDRawMaterialGrade: Int],
        totalCost: Int,
        loanAmount: Int,
        playerState: EDPlayerState
    ) throws(EDRawPurchaseResolverError) -> EDRawPurchaseResolution {
        var updatedState = playerState
        do {
            try updatedState.subtractCash(totalCost)
        } catch {
            throw .playerState(error)
        }

        for grade in EDRawMaterialGrade.allCases {
            do {
                try updatedState.inventory.add(
                    unitsPurchased[grade, default: 0],
                    of: grade
                )
            } catch {
                throw .inventory(error)
            }
        }

        return EDRawPurchaseResolution(
            playerState: updatedState,
            unitsPurchasedByGrade: unitsPurchased,
            totalCost: totalCost,
            loanAmount: loanAmount
        )
    }
}
