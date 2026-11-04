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

    public func snapshot() -> EDPlayerSnapshot {
        EDPlayerSnapshot(id: id, name: _name, coins: _coins)
    }
}
