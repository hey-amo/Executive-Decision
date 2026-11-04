import Foundation

public enum EDPlayerError: Error, Equatable {
    case negativeAmount
    case notEnoughCoins
    case balanceOverflow
}

public struct EDPlayerSnapshot: Sendable, Codable, Identifiable, Hashable {
    public let id: UUID
    public let _name: String
    public let _coins: Int

    public init(id: UUID, name: String, coins: Int) {
        self.id = id
        self._name = name
        self._coins = coins
    }
}

public actor EDPlayer: Identifiable, Hashable {
    public nonisolated let id: UUID
    public private(set) var _name: String
    public private(set) var _coins: Int
    private var tallySheet: EDTallySheet

    public nonisolated static func == (lhs: EDPlayer, rhs: EDPlayer) -> Bool {
        lhs.id == rhs.id
    }

    public nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public init(id: UUID = UUID(), name: String, coins: Int = 0) throws {
        guard coins >= 0 else {
            throw EDPlayerError.negativeAmount
        }

        self.id = id
        self._name = name
        self._coins = coins
        self.tallySheet = try EDTallySheet()
    }

    public init(snapshot: EDPlayerSnapshot) throws {
        try self.init(id: snapshot.id, name: snapshot._name, coins: snapshot._coins)
    }

    public func rename(to name: String) {
        _name = name
    }

    public func addCoins(_ amount: Int) throws {
        guard amount >= 0 else {
            throw EDPlayerError.negativeAmount
        }

        let (newBalance, overflow) = _coins.addingReportingOverflow(amount)
        guard !overflow else {
            throw EDPlayerError.balanceOverflow
        }

        _coins = newBalance
    }

    public func spendCoins(_ amount: Int) throws {
        guard amount >= 0 else {
            throw EDPlayerError.negativeAmount
        }
        guard amount <= _coins else {
            throw EDPlayerError.notEnoughCoins
        }

        _coins -= amount
    }

    /// Records a raw-material bid on this player's private tally sheet.
    ///
    /// Rules: Purchasing Raw Materials.
    public func recordRawOrder(
        _ order: EDRawMaterialTally,
        for grade: EDRawMaterialGrade,
        inMonth monthNumber: Int
    ) throws(EDTallySheetError) {
        try tallySheet.recordRawOrder(order, for: grade, inMonth: monthNumber)
    }

    /// Records a finished-good offer on this player's private tally sheet.
    ///
    /// Rules: Selling Finished Goods.
    public func recordFinishedGoodSale(
        _ sale: EDFinishedGoodTally,
        for good: EDRecipe,
        inMonth monthNumber: Int
    ) throws(EDTallySheetError) {
        try tallySheet.recordFinishedGoodSale(sale, for: good, inMonth: monthNumber)
    }

    /// Returns this player's tally sheet for their private game view.
    ///
    /// Rules: Hidden information. Bids and planned offers are private to the
    /// player whose tally sheet is returned.
    public func tallySheetSnapshot() -> EDTallySheet {
        tallySheet
    }

    public func snapshot() -> EDPlayerSnapshot {
        EDPlayerSnapshot(id: id, name: _name, coins: _coins)
    }
}
