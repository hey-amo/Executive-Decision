// EDPlayerState.swift — a player’s name, cash, inventory, and loan balance.

import Foundation

/// Errors raised while updating a player's game state.
public enum EDPlayerStateError: Error, Equatable, Sendable {
    /// Rules: FR-Wallet-Fixes. Cash cannot fall below the supported minimum.
    case money(EDMoneyError)

    /// Rules: FR-13 Loans are recorded in positive $100 increments.
    case invalidLoanAmount(Int)

    /// Rules: FR-13 Loans are recorded in positive $100 increments.
    case invalidLoanBalance(Int)

    /// Rules: FR-13 Loan principal is accumulated without integer overflow.
    case loanBalanceOverflow

    /// Rules: FR-13 Repayment is $125 for each $100 borrowed.
    case repaymentOverflow
}

/// The serializable, value-type state of one player.
///
/// Rules: FR-15 Player information includes cash and public raw-certificate
/// inventory; FR-13 tracks loans as principal repaid at $125 per $100 borrowed.
public struct EDPlayerState: Codable, Equatable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public private(set) var name: String
    public private(set) var cash: EDMoney
    public var inventory: EDInventory
    public private(set) var loanBalance: Int

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case cash
        case inventory
        case loanBalance
    }

    /// Creates a player state with validated cash, inventory, and loan principal.
    ///
    /// Rules: FR-13 Loans are tracked in $100 increments. FR-Wallet-Fixes
    /// allows cash down to the configured minimum balance.
    public init(
        id: UUID = UUID(),
        name: String,
        cashBalance: Int = 0,
        inventory: EDInventory = EDInventory(),
        loanBalance: Int = 0
    ) throws(EDPlayerStateError) {
        do {
            cash = try EDMoney(balance: cashBalance)
        } catch {
            throw .money(error)
        }
        guard loanBalance >= 0, loanBalance.isMultiple(of: 100) else {
            throw .invalidLoanBalance(loanBalance)
        }

        self.id = id
        self.name = name
        self.inventory = inventory
        self.loanBalance = loanBalance
    }

    /// Changes the player's display name.
    ///
    /// Rules: Setup. Player names are part of the player's state.
    public mutating func rename(to name: String) {
        self.name = name
    }

    /// Adds cash, allowing a zero-value no-op.
    ///
    /// Rules: FR-Wallet-Fixes. Positive amounts increase cash; zero has no
    /// effect and negative amounts are invalid.
    public mutating func addCash(_ amount: Int) throws(EDPlayerStateError) {
        guard amount >= 0 else {
            throw .money(.additionMustBePositive(amount))
        }
        guard amount > 0 else {
            return
        }

        do {
            cash = try cash.adding(amount)
        } catch {
            throw .money(error)
        }
    }

    /// Subtracts cash down to the minimum supported balance.
    ///
    /// Rules: FR-Wallet-Fixes. Cash may become negative but cannot fall below
    /// the configured minimum.
    public mutating func subtractCash(_ amount: Int) throws(EDPlayerStateError) {
        do {
            cash = try cash.subtracting(amount)
        } catch {
            throw .money(error)
        }
    }

    /// Borrows a positive multiple of $100, adding the principal to cash.
    ///
    /// Rules: FR-13 Loans are made in $100 increments and only the borrowed
    /// principal is recorded.
    public mutating func borrow(_ amount: Int) throws(EDPlayerStateError) {
        guard amount > 0, amount.isMultiple(of: 100) else {
            throw .invalidLoanAmount(amount)
        }
        let (newLoanBalance, overflow) = loanBalance.addingReportingOverflow(amount)
        guard !overflow else {
            throw .loanBalanceOverflow
        }
        do {
            let newCash = try cash.adding(amount)
            cash = newCash
            loanBalance = newLoanBalance
        } catch {
            throw .money(error)
        }
    }

    /// Computes the amount due at game end for the recorded loan principal.
    ///
    /// Rules: FR-13 Repayment is $125 per $100 borrowed.
    public func loanRepaymentAmount() throws(EDPlayerStateError) -> Int {
        let (amount, overflow) = (loanBalance / 100).multipliedReportingOverflow(by: 125)
        guard !overflow else {
            throw .repaymentOverflow
        }
        return amount
    }

    /// Decodes persisted player state while validating its loan balance.
    ///
    /// Rules: FR-16 Persistence resumes a valid game state; loan principal is
    /// nonnegative and recorded in $100 increments.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let name = try container.decode(String.self, forKey: .name)
        let cash = try container.decode(EDMoney.self, forKey: .cash)
        let inventory = try container.decode(EDInventory.self, forKey: .inventory)
        let loanBalance = try container.decode(Int.self, forKey: .loanBalance)

        do {
            try self.init(
                id: id,
                name: name,
                cashBalance: cash.balance,
                inventory: inventory,
                loanBalance: loanBalance
            )
        } catch {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Invalid player state: \(error)"
                )
            )
        }
    }
}
