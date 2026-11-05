// EDRawOrderValidator.swift
// Validates raw orders against FR-5 and FR-6.

/// Errors raised when a raw-material order violates purchasing rules.
///
/// Rules: FR-5 Raw order limits; FR-6 Minimum raw bid.
public enum EDRawOrderValidationError: Error, Equatable, Sendable {
    /// Rules: FR-5. The player's total order cannot be summed without overflow.
    case totalUnitsOverflow

    /// Rules: FR-5. The order exceeds a player-count-dependent unit limit.
    case orderExceedsLimits

    /// Rules: FR-6. A positive-unit grade requires its previous market price.
    case missingPreviousPrice(grade: EDRawMaterialGrade)

    /// Rules: FR-6. The bid is below the price reached using the player's own units.
    case bidBelowMinimum(grade: EDRawMaterialGrade, bid: Int, minimum: Int)

    /// Rules: FR-6. The minimum bid price could not be calculated without overflow.
    case minimumBidPriceOverflow(grade: EDRawMaterialGrade)
}

/// Validates a player's raw order against order limits and minimum bids.
///
/// Rules: FR-5 Raw order limits; FR-6 Minimum raw bid.
public enum EDRawOrderValidator {
    /// Validates total and per-grade limits, then the FR-6 minimum bid per grade.
    ///
    /// Minimum bids are checked only for grades with positive units and use
    /// that player's units with the supplied previous market prices.
    ///
    /// Rules: FR-5 Raw order limits; FR-6 Minimum raw bid.
    public static func validate(
        _ order: EDRawOrder,
        limits: EDRawOrderLimits,
        previousPrices: [EDRawMaterialGrade: Int]
    ) throws(EDRawOrderValidationError) {
        do {
            _ = try order.totalUnits()
        } catch {
            throw .totalUnitsOverflow
        }

        guard limits.allowsOrder(unitsByGrade: order.unitsByGrade) else {
            throw .orderExceedsLimits
        }

        for grade in EDRawMaterialGrade.allCases where order.units(for: grade) > 0 {
            guard let previousPrice = previousPrices[grade] else {
                throw .missingPreviousPrice(grade: grade)
            }

            let minimumBid: Int
            do {
                minimumBid = try EDMarketCalculator.minimumRawBidPrice(
                    previousPrice: previousPrice,
                    playerOrderedUnits: order.units(for: grade)
                )
            } catch {
                throw .minimumBidPriceOverflow(grade: grade)
            }

            let bid = order.bid(for: grade)
            guard bid >= minimumBid else {
                throw .bidBelowMinimum(grade: grade, bid: bid, minimum: minimumBid)
            }
        }
    }
}
