// EDMoney.swift — money values and arithmetic

import Foundation

public enum EDMoneyError: Error, Equatable, Sendable {
    case additionMustBePositive(Int)
    case subtractionMustBeNonnegative(Int)
    case balanceBelowMinimum(Int)
    case balanceOverflow
}

extension EDMoneyError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .additionMustBePositive:
            return NSLocalizedString("Addition amount must be positive.", comment: "Addition amount must be positive.")
        case .subtractionMustBeNonnegative:
            return NSLocalizedString("Subtraction amount must be non-negative.", comment: "Subtraction amount must be non-negative.")
        case .balanceBelowMinimum:
            return NSLocalizedString("Balance is below the minimum allowed.", comment: "Balance is below the minimum allowed.")
        case .balanceOverflow:
            return NSLocalizedString("Balance has overflowed.", comment: "Balance has overflowed.")
        }
    }
}

public struct EDMoney: Codable, Equatable, Hashable, Sendable {
    public static let minimumBalance = -5_000

    public let balance: Int

    public init(balance: Int = 0) throws(EDMoneyError) {
        guard balance >= Self.minimumBalance else {
            throw .balanceBelowMinimum(balance)
        }
        self.balance = balance
    }

    public func adding(_ amount: Int) throws(EDMoneyError) -> Self {
        guard amount > 0 else {
            throw .additionMustBePositive(amount)
        }

        let (newBalance, overflow) = balance.addingReportingOverflow(amount)
        guard !overflow else {
            throw .balanceOverflow
        }
        return try Self(balance: newBalance)
    }

    public func subtracting(_ amount: Int) throws(EDMoneyError) -> Self {
        guard amount >= 0 else {
            throw .subtractionMustBeNonnegative(amount)
        }

        let (newBalance, overflow) = balance.subtractingReportingOverflow(amount)
        guard !overflow else {
            throw .balanceOverflow
        }
        return try Self(balance: newBalance)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let balance = try container.decode(Int.self)

        do {
            try self.init(balance: balance)
        } catch {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Money balance is below the minimum."
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(balance)
    }
}
