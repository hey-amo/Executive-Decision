import Foundation

public enum EDTallyMonth: Int, CaseIterable, Sendable {
    case january = 1
    case february
    case march
    case april
    case may
    case june
    case july
    case august
    case september
    case october
    case november
    case december
}

public struct EDOrderEntry: Sendable {
    public let unitsOrdered: Int
    public let bidPrice: Int
    public let unitsPurchased: Int

    public var amountPaid: Int {
        unitsPurchased * bidPrice
    }

    public init(unitsOrdered: Int, bidPrice: Int, unitsPurchased: Int) {
        self.unitsOrdered = unitsOrdered
        self.bidPrice = bidPrice
        self.unitsPurchased = unitsPurchased
    }
}

public struct EDSaleEntry: Sendable {
    public let unitsOffered: Int
    public let askingPrice: Int
    public let unitsSold: Int

    public var amountReceived: Int {
        unitsSold * askingPrice
    }

    public init(unitsOffered: Int, askingPrice: Int, unitsSold: Int) {
        self.unitsOffered = unitsOffered
        self.askingPrice = askingPrice
        self.unitsSold = unitsSold
    }
}

public struct EDTallyTotals: Equatable, Sendable {
    public let orders: Int
    public let sales: Int

    public var net: Int {
        sales - orders
    }

    public init(orders: Int, sales: Int) {
        self.orders = orders
        self.sales = sales
    }
}

public struct EDMonthlyTally: Sendable {
    public let month: EDTallyMonth
    public let orders: [RawMaterial: EDOrderEntry]
    public let sales: [FinishedGood: EDSaleEntry]

    public var totals: EDTallyTotals {
        EDTallyTotals(
            orders: orders.values.reduce(0) { $0 + $1.amountPaid },
            sales: sales.values.reduce(0) { $0 + $1.amountReceived }
        )
    }

    public init(
        month: EDTallyMonth,
        orders: [RawMaterial: EDOrderEntry] = [:],
        sales: [FinishedGood: EDSaleEntry] = [:]
    ) {
        self.month = month
        self.orders = orders
        self.sales = sales
    }
}

public enum EDTallySheetError: Error, Equatable {
    case monthAlreadyRecorded(EDTallyMonth)
}

public struct EDTallySheet: Sendable {
    public private(set) var monthlyTallies: [EDTallyMonth: EDMonthlyTally]

    public var yearlyTotals: EDTallyTotals {
        monthlyTallies.values.reduce(into: EDTallyTotals(orders: 0, sales: 0)) { totals, tally in
            totals = EDTallyTotals(
                orders: totals.orders + tally.totals.orders,
                sales: totals.sales + tally.totals.sales
            )
        }
    }

    public init() {
        monthlyTallies = [:]
    }

    public func totals(for month: EDTallyMonth) -> EDTallyTotals {
        monthlyTallies[month]?.totals ?? EDTallyTotals(orders: 0, sales: 0)
    }

    public mutating func record(_ tally: EDMonthlyTally) throws {
        guard monthlyTallies[tally.month] == nil else {
            throw EDTallySheetError.monthAlreadyRecorded(tally.month)
        }
        monthlyTallies[tally.month] = tally
    }
}
