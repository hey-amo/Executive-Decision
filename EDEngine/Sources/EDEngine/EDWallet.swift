// EDWallet.swift

import Foundation

public enum IntegerError: Error, Equatable {
    case negativeValue
    case notEnoughFunds
}

extension IntegerError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .negativeValue:
            return NSLocalizedString("Negative value is not allowed.", comment: "Negative value is not allowed.")
        case .notEnoughFunds:
            return NSLocalizedString("Not enough funds available.", comment: "Not enough funds available.")
        }
    }
}


public enum TransactionType: Sendable, Codable {
    case add(_ amount: Int)
    case subtract( _ amount: Int)
}

public actor Wallet {
    private var _balance: Int

    public var balance: Int {
        _balance
    }

    public init(with balance: Int = 0) throws {
        guard balance >= 0 else {
            throw IntegerError.negativeValue
        }
        self._balance = balance
    }

    public func performTransaction(_ transaction: TransactionType) throws {
        switch transaction {
        case .add(let amount):
            try add(amount)
        case .subtract(let amount):
            try subtract(amount)
        }
    }

    private func add(_ amount: Int) throws {
        guard amount >= 0 else {
            throw IntegerError.negativeValue
        }

        let (result, overflow) = _balance.addingReportingOverflow(amount)
        _balance = overflow ? Int.max : result
    }

    private func subtract(_ amount: Int) throws {
        guard amount >= 0 else {
            throw IntegerError.negativeValue
        }

        guard amount <= _balance else {
            throw IntegerError.notEnoughFunds
        }

        _balance -= amount
    }
}