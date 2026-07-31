import Foundation

public protocol LocalizedErrorDescription {
    var errorDescription: String { get }
}

public protocol LocalizedFailureReason {
    var failureReason: String { get }
}

public protocol LocalizedRecoverySuggestion {
    var recoverySuggestion: String { get }
}

public extension LocalizedErrorDescription where Self: Error {
    var localizedDescription: String {
        errorDescription
    }
}

public extension LocalizedFailureReason where Self: Error {
    var localizedFailureReason: String {
        failureReason
    }
}

public extension LocalizedRecoverySuggestion where Self: Error {
    var localizedRecoverySuggestion: String {
        recoverySuggestion
    }
}

public protocol EDGameError: Error, LocalizedErrorDescription, LocalizedFailureReason, LocalizedRecoverySuggestion {}

// Default error implementations

public extension EDGameError {
    var errorDescription: String {
        "An unexpected game error occurred."
    }

    var failureReason: String {
        "The operation could not be completed."
    }

    var recoverySuggestion: String {
        "Please try again or contact support if the issue persists."
    }
}

public enum EDValueError: EDGameError, Equatable {
    case numericBelowZero(value: Int)
    case insufficientFunds(required: Int, available: Int)

    public var errorDescription: String {
        switch self {
        case .numericBelowZero:
            return "Numeric value cannot be below zero."
        case .insufficientFunds:
            return "Not enough funds available."
        }
    }

    public var failureReason: String {
        switch self {
        case let .numericBelowZero(value):
            return "Cannot use negative value: \(value)."
        case let .insufficientFunds(required, available):
            return "You don't have enough funds. Required: \(required), available: \(available)."
        }
    }

    public var recoverySuggestion: String {
        switch self {
        case .numericBelowZero:
            return "Use a non-negative value."
        case .insufficientFunds:
            return "Gather more funds or reduce your required amount."
        }
    }
}

