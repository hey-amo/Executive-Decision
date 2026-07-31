import Foundation

public enum EDBidStatus: String, Codable, Sendable, Equatable {
    case thinking
    case ready
}

public struct EDPlayerBidSession: Codable, Equatable, Sendable {
    public let monthIndex: Int
    public private(set) var rawMaterialBids: [EDRawMaterialBid]
    public private(set) var finishedGoodsOffers: [EDFinishedGoodsOffer]
    public private(set) var status: EDBidStatus

    public init(monthIndex: Int, rawMaterialBids: [EDRawMaterialBid] = [], finishedGoodsOffers: [EDFinishedGoodsOffer] = [], status: EDBidStatus = .thinking) {
        self.monthIndex = monthIndex
        self.rawMaterialBids = rawMaterialBids
        self.finishedGoodsOffers = finishedGoodsOffers
        self.status = status
    }

    public var totalRawMaterialUnits: Int {
        rawMaterialBids.reduce(0) { $0 + $1.units }
    }

    public var totalRawMaterialCost: Int {
        rawMaterialBids.reduce(0) { $0 + $1.units * $1.bidPrice }
    }

    public mutating func addRawMaterialBid(_ bid: EDRawMaterialBid) {
        rawMaterialBids.append(bid)
    }

    public mutating func addFinishedGoodsOffer(_ offer: EDFinishedGoodsOffer) {
        finishedGoodsOffers.append(offer)
    }

    public mutating func setReady() {
        status = .ready
    }

    public mutating func setThinking() {
        status = .thinking
    }

    public mutating func reset() {
        rawMaterialBids.removeAll()
        finishedGoodsOffers.removeAll()
        status = .thinking
    }

    public static func maxRawMaterialUnitsPerPlayer(for playersCount: Int) -> Int {
        switch playersCount {
        case 2: return 18
        case 3: return 12
        case 4: return 9
        case 5: return 7
        case 6: return 6
        default: return 0
        }
    }

    public func isWithinRawMaterialUnitLimit(for playersCount: Int) -> Bool {
        totalRawMaterialUnits <= Self.maxRawMaterialUnitsPerPlayer(for: playersCount)
    }

    public func isWithinPerGradeLimit(for playersCount: Int) -> Bool {
        guard playersCount == 2 else { return true }

        let unitsByGrade = rawMaterialBids.reduce(into: [RawMaterial: Int]()) { result, bid in
            result[bid.material, default: 0] += bid.units
        }

        return unitsByGrade.values.allSatisfy { $0 <= 12 }
    }

    public static func minimumBidPrice(for material: RawMaterial, units: Int) -> Int? {
        guard let movement = EDMarketCalculator.rawMaterialMovement(for: units) else {
            return nil
        }

        return max(1, material.openingPrice + movement)
    }

    public func isRawMaterialBidPriceValid() -> Bool {
        rawMaterialBids.allSatisfy { bid in
            guard let minimum = Self.minimumBidPrice(for: bid.material, units: bid.units) else {
                return false
            }
            return bid.bidPrice >= minimum
        }
    }

    public func canSubmitRawMaterialBid(withCash cash: Int, playersCount: Int) -> Bool {
        guard isWithinRawMaterialUnitLimit(for: playersCount) else { return false }
        guard isWithinPerGradeLimit(for: playersCount) else { return false }
        guard isRawMaterialBidPriceValid() else { return false }
        return totalRawMaterialCost <= cash
    }
}
