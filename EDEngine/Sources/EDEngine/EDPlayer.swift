import Foundation

public enum EDPlayerError: Error, Equatable, Sendable {
    case negativeAmount
    case notEnoughCoins
    case balanceOverflow
}

public actor EDPlayer: Identifiable, Hashable {
    public nonisolated let id: UUID
    private var state: EDPlayerState
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
        self.state = try EDPlayerState(id: id, name: name, cashBalance: coins)
        self.tallySheet = try EDTallySheet()
    }

    /// Creates an actor around an existing value-type player state.
    ///
    /// Rules: FR-16 Persistence restores the player's saved state.
    public init(state: EDPlayerState) throws {
        self.id = state.id
        self.state = state
        self.tallySheet = try EDTallySheet()
    }

    public func rename(to name: String) {
        state.rename(to: name)
    }

    public func addCoins(_ amount: Int) throws {
        guard amount >= 0 else {
            throw EDPlayerError.negativeAmount
        }

        do {
            try state.addCash(amount)
        } catch EDPlayerStateError.money(.balanceOverflow) {
            throw EDPlayerError.balanceOverflow
        } catch {
            throw error
        }
    }

    public func spendCoins(_ amount: Int) throws {
        guard amount >= 0 else {
            throw EDPlayerError.negativeAmount
        }
        guard amount <= state.cash.balance else {
            throw EDPlayerError.notEnoughCoins
        }

        try state.subtractCash(amount)
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

    /// Returns this player's current value-type state.
    ///
    /// Rules: FR-16 Persistence snapshots the complete player state.
    public func snapshot() -> EDPlayerState {
        state
    }
}
