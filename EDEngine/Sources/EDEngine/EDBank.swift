import Foundation

// Handles "financial transactions" in the game
public final class EDBank: Sendable {
    private let stateLock = NSLock()
    private nonisolated(unsafe) var _cash: Int 

    public var cash: Int {
        stateLock.lock()
        defer { stateLock.unlock() }
        return _cash
    }

    public init(cash: Int) {
        self._cash = cash
    }
}

extension EDBank {
    public func credit(amount: Int) throws {
        guard canCredit(amount: amount) else {
            throw EDValueError.numericBelowZero(value: amount)
        }

        stateLock.lock()
        defer { stateLock.unlock() }
        _cash += amount
    }

    @discardableResult
    public func debit(amount: Int) throws -> Int {
        guard canDebit(amount: amount) else {
            if amount < 0 {
                throw EDValueError.numericBelowZero(value: amount)
            }

            stateLock.lock()
            let available = _cash
            stateLock.unlock()
            throw EDValueError.insufficientFunds(required: amount, available: available)
        }

        stateLock.lock()
        defer { stateLock.unlock() }
        _cash -= amount
        return _cash
    }
}

extension EDBank {
    public func canCredit(amount: Int = 0) -> Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        guard amount >= 0 else { return false }
        return true
    }
    public func canDebit(amount: Int = 0) -> Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        // 1. can't debit negative amount
        guard amount >= 0 else { return false }
        // 2. can't debit more than available cash
        guard _cash >= amount else { return false }
        return true
    }
}

extension EDBank: CustomStringConvertible {
    public var description: String {
        "Bank(cash: \(_cash))"
    }
}