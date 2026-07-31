import Foundation

public struct EDRawMaterialBid: Codable, Equatable, Sendable {
    public let material: RawMaterial
    public let units: Int
    public let bidPrice: Int

    public init(material: RawMaterial, units: Int, bidPrice: Int) {
        self.material = material
        self.units = units
        self.bidPrice = bidPrice
    }
}

public struct EDFinishedGoodsOffer: Codable, Equatable, Sendable {
    public let product: ProductType
    public let units: Int
    public let askPrice: Int

    public init(product: ProductType, units: Int, askPrice: Int) {
        self.product = product
        self.units = units
        self.askPrice = askPrice
    }
}

public struct EDMonthlyTallyRecord: Codable, Equatable {
    public let monthName: String
    public let monthIndex: Int
    public var rawMaterialOrders: [EDRawMaterialBid]
    public var finishedGoodsOffers: [EDFinishedGoodsOffer]

    public init(monthName: String, monthIndex: Int, rawMaterialOrders: [EDRawMaterialBid] = [], finishedGoodsOffers: [EDFinishedGoodsOffer] = []) {
        self.monthName = monthName
        self.monthIndex = monthIndex
        self.rawMaterialOrders = rawMaterialOrders
        self.finishedGoodsOffers = finishedGoodsOffers
    }
}

public struct EDTallySheet: Codable, Equatable {
    public var monthlyRecords: [EDMonthlyTallyRecord]

    public init(monthlyRecords: [EDMonthlyTallyRecord] = []) {
        self.monthlyRecords = monthlyRecords
    }

    public init(months: [EDGameMonth]) {
        self.monthlyRecords = months.map { EDMonthlyTallyRecord(monthName: $0.name, monthIndex: $0.index) }
    }

    public mutating func recordRawMaterialBid(_ bid: EDRawMaterialBid, forMonth index: Int) {
        guard let offset = monthlyRecords.firstIndex(where: { $0.monthIndex == index }) else { return }
        monthlyRecords[offset].rawMaterialOrders.append(bid)
    }

    public mutating func recordFinishedGoodsOffer(_ offer: EDFinishedGoodsOffer, forMonth index: Int) {
        guard let offset = monthlyRecords.firstIndex(where: { $0.monthIndex == index }) else { return }
        monthlyRecords[offset].finishedGoodsOffers.append(offer)
    }
}
