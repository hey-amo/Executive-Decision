import Foundation

public enum EDTallyMonth: Int, CaseIterable, Sendable {
    case january = 1, february, march, april, may, june, july, august, september, october, november, december
}

extension EDTallyMonth: CustomStringConvertible {
    public var description: String {
        localizedDescription
    }

    public var localizedDescription: String {
        switch self {
        case .january: return NSLocalizedString("January", comment: "Month: January")
        case .february: return NSLocalizedString("February", comment: "Month: February")
        case .march: return NSLocalizedString("March", comment: "Month: March")
        case .april: return NSLocalizedString("April", comment: "Month: April")
        case .may: return NSLocalizedString("May", comment: "Month: May")
        case .june: return NSLocalizedString("June", comment: "Month: June")
        case .july: return NSLocalizedString("July", comment: "Month: July")
        case .august: return NSLocalizedString("August", comment: "Month: August")
        case .september: return NSLocalizedString("September", comment: "Month: September")
        case .october: return NSLocalizedString("October", comment: "Month: October")
        case .november: return NSLocalizedString("November", comment: "Month: November")
        case .december: return NSLocalizedString("December", comment: "Month: December")
        }
    }

    public var shortDescription: String {
        String(localizedDescription.prefix(3))
    }
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

public enum EDMonthlyGoodsError: Error, Equatable {
    case negativeQuantity(FinishedGood)
    case offerExceedsProduction(FinishedGood)
    case saleExceedsOffer(FinishedGood)
}

public struct EDMonthlyGoodsState: Sendable {
    public private(set) var produced: [FinishedGood: Int] = [:]
    public private(set) var offered: [FinishedGood: Int] = [:]
    public private(set) var sold: [FinishedGood: Int] = [:]

    public init() {}

    public mutating func recordProduction(_ quantities: [FinishedGood: Int]) throws {
        try Self.validateNonnegative(quantities)
        for good in FinishedGood.allCases where offered[good, default: 0] > quantities[good, default: 0] {
            throw EDMonthlyGoodsError.offerExceedsProduction(good)
        }
        produced = quantities
    }

    public mutating func recordOffer(_ quantities: [FinishedGood: Int]) throws {
        try Self.validateNonnegative(quantities)
        for good in FinishedGood.allCases where quantities[good, default: 0] > produced[good, default: 0] {
            throw EDMonthlyGoodsError.offerExceedsProduction(good)
        }
        offered = quantities
    }

    public mutating func recordSales(_ quantities: [FinishedGood: Int]) throws {
        try Self.validateNonnegative(quantities)
        for good in FinishedGood.allCases where quantities[good, default: 0] > offered[good, default: 0] {
            throw EDMonthlyGoodsError.saleExceedsOffer(good)
        }
        sold = quantities
    }

    private static func validateNonnegative(_ quantities: [FinishedGood: Int]) throws {
        for good in FinishedGood.allCases where quantities[good, default: 0] < 0 {
            throw EDMonthlyGoodsError.negativeQuantity(good)
        }
    }
}
