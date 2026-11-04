/// Errors raised while applying a market movement to a previous price.
public enum EDMarketCalculatorError: Error, Equatable, Sendable {
    case priceOverflow
}

/// Calculates market movements and prices from the units ordered or offered.
public enum EDMarketCalculator {
    private static let maximumRawMaterialUnits = 24
    private static let maximumFinishedGoodUnits = 16

    /// Returns the raw-material market movement for an order.
    ///
    /// Rules: Market Calculator, Raw Materials. Orders above 24 units count as
    /// 24 units; movement is added to the previous market price.
    public static func rawMaterialMovement(forUnits units: Int) -> Int {
        min(max(units, 0), maximumRawMaterialUnits) - 10
    }

    /// Returns the finished-good market movement for an offer.
    ///
    /// Rules: Market Calculator, Finished Goods. Offers above 16 units count as
    /// 16 units; movement is added to the previous market price.
    public static func finishedGoodMovement(forUnits units: Int) -> Int {
        11 - 2 * min(max(units, 0), maximumFinishedGoodUnits)
    }

    /// Returns the updated raw-material price, with the rules' $1 minimum.
    ///
    /// Rules: Raw Material Prices. The movement is added to the previous price,
    /// and a raw-material price cannot fall below $1.
    public static func rawMaterialPrice(
        previousPrice: Int,
        orderedUnits: Int
    ) throws(EDMarketCalculatorError) -> Int {
        let updatedPrice = try adding(
            rawMaterialMovement(forUnits: orderedUnits),
            to: previousPrice
        )
        return max(1, updatedPrice)
    }

    /// Returns the minimum bid for a player's raw-material order.
    ///
    /// Rules: FR-6 Minimum raw bid. The minimum bid is the price the grade
    /// reaches using only that player's units, with a $1 floor.
    public static func minimumRawBidPrice(
        previousPrice: Int,
        playerOrderedUnits: Int
    ) throws(EDMarketCalculatorError) -> Int {
        try rawMaterialPrice(previousPrice: previousPrice, orderedUnits: playerOrderedUnits)
    }

    /// Returns the updated finished-good price.
    ///
    /// Rules: Finished Goods. The movement is added to the previous market price.
    public static func finishedGoodPrice(
        previousPrice: Int,
        offeredUnits: Int
    ) throws(EDMarketCalculatorError) -> Int {
        try adding(finishedGoodMovement(forUnits: offeredUnits), to: previousPrice)
    }

    private static func adding(
        _ movement: Int,
        to previousPrice: Int
    ) throws(EDMarketCalculatorError) -> Int {
        let (price, overflow) = previousPrice.addingReportingOverflow(movement)
        guard !overflow else {
            throw .priceOverflow
        }
        return price
    }
}
