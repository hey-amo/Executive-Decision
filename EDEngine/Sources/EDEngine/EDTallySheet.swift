/// A player's raw-material order for one month.
///
/// Rules: Purchasing Raw Materials. Each monthly row records the bid units,
/// bid price, and amount paid.
public struct EDRawMaterialTally: Codable, Equatable, Hashable, Sendable {
    public let units: Int
    public let bidPrice: Int
    public let amountPaid: Int

    public init(units: Int = 0, bidPrice: Int = 0, amountPaid: Int = 0) {
        self.units = units
        self.bidPrice = bidPrice
        self.amountPaid = amountPaid
    }
}

/// A player's finished-good sale for one month.
///
/// Rules: Selling Finished Goods. Each monthly row records the offer units,
/// asking price, and amount received.
public struct EDFinishedGoodTally: Codable, Equatable, Hashable, Sendable {
    public let units: Int
    public let askingPrice: Int
    public let amountReceived: Int

    public init(units: Int = 0, askingPrice: Int = 0, amountReceived: Int = 0) {
        self.units = units
        self.askingPrice = askingPrice
        self.amountReceived = amountReceived
    }
}

/// Errors raised when accessing a month on a tally sheet.
public enum EDTallySheetError: Error, Equatable, Sendable {
    case invalidMonthCount(Int)
    case monthOutOfRange(Int)
}

/// One month's private orders and sales on a player's tally sheet.
///
/// Rules: Purchasing Raw Materials and Selling Finished Goods. Each player
/// records bids and planned offers separately for every month.
public struct EDTallySheetMonth: Codable, Equatable, Hashable, Sendable {
    public private(set) var rawOrders: [EDRawMaterialGrade: EDRawMaterialTally]
    public private(set) var finishedGoodSales: [EDRecipe: EDFinishedGoodTally]

    public init() {
        rawOrders = Dictionary(
            uniqueKeysWithValues: EDRawMaterialGrade.allCases.map { ($0, EDRawMaterialTally()) }
        )
        finishedGoodSales = Dictionary(
            uniqueKeysWithValues: EDRecipe.allCases.map { ($0, EDFinishedGoodTally()) }
        )
    }

    mutating func setRawOrder(_ order: EDRawMaterialTally, for grade: EDRawMaterialGrade) {
        rawOrders[grade] = order
    }

    mutating func setFinishedGoodSale(_ sale: EDFinishedGoodTally, for good: EDRecipe) {
        finishedGoodSales[good] = sale
    }
}

/// Private monthly orders and sales belonging to one player.
///
/// Rules: Setup and the monthly Purchasing Raw Materials and Selling Finished
/// Goods steps. Standard games have 12 months; shorter games may choose fewer.
public struct EDTallySheet: Codable, Equatable, Hashable, Sendable {
    public private(set) var months: [EDTallySheetMonth]

    /// Creates a player's tally sheet for the selected number of months.
    ///
    /// Rules: Setup. A standard game consists of 12 months.
    public init(monthCount: Int = 12) throws(EDTallySheetError) {
        guard monthCount > 0 else {
            throw .invalidMonthCount(monthCount)
        }
        months = Array(repeating: EDTallySheetMonth(), count: monthCount)
    }

    /// Records one raw-material bid and its resolved payment for a month.
    ///
    /// Rules: Purchasing Raw Materials. The tally sheet has a separate row for
    /// each raw-material grade and month.
    public mutating func recordRawOrder(
        _ order: EDRawMaterialTally,
        for grade: EDRawMaterialGrade,
        inMonth monthNumber: Int
    ) throws(EDTallySheetError) {
        let index = try monthIndex(for: monthNumber)
        months[index].setRawOrder(order, for: grade)
    }

    /// Records one finished-good offer and its resolved proceeds for a month.
    ///
    /// Rules: Selling Finished Goods. The tally sheet has a separate row for
    /// each finished good and month.
    public mutating func recordFinishedGoodSale(
        _ sale: EDFinishedGoodTally,
        for good: EDRecipe,
        inMonth monthNumber: Int
    ) throws(EDTallySheetError) {
        let index = try monthIndex(for: monthNumber)
        months[index].setFinishedGoodSale(sale, for: good)
    }

    private func monthIndex(for monthNumber: Int) throws(EDTallySheetError) -> Int {
        guard monthNumber > 0, monthNumber <= months.count else {
            throw .monthOutOfRange(monthNumber)
        }
        return monthNumber - 1
    }
}
