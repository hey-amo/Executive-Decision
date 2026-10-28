//
//  WalletAPI.swift
//  EDEngine
//
//  Created by Amarjit on 28/10/2026.
//
import Foundation

public enum IntegerError: Error, Equatable {
    case negativeNumber
    case zeroAmount
    case notEnoughFunds
    case maximumBalanceExceeded
}

public protocol UpdateWalletDelegate: AnyObject {
    func walletDidUpdate(balance: Int)
}

public enum Transaction {
    case credit(_ amount: Int)
    case debit(_ amount: Int)
}

public typealias Bank = WalletAPI

public struct WalletAPI {
    public static let maximumBalance = 100_000

    private var _balance: Int = 0
    public var balance: Int {
        get { return self._balance }
    }
    
    public init(_balance: Int) throws {
        guard _balance >= 0 else {
            throw IntegerError.negativeNumber
        }
        guard _balance <= Self.maximumBalance else {
            throw IntegerError.maximumBalanceExceeded
        }
        self._balance = _balance
    }
        
    public mutating func apply(t: Transaction) throws {
        switch t {
        case .credit(let amount):
            try self.credit(amount)
        case .debit(let amount):
            try self.debit(amount)
        }
    }

    public mutating func apply(t: Transaction, notifying delegate: UpdateWalletDelegate) throws {
        try self.apply(t: t)
        delegate.walletDidUpdate(balance: self.balance)
    }
    
    private mutating func credit(_ amount: Int = 0) throws {
        guard amount >= 0 else {
            throw IntegerError.negativeNumber
        }
        guard amount > 0 else {
            throw IntegerError.zeroAmount
        }

        guard amount <= Self.maximumBalance - self._balance else {
            throw IntegerError.maximumBalanceExceeded
        }
        self._balance += amount
    }
    
    public mutating func debit(_ amount: Int = 0) throws {
        guard amount >= 0 else {
            throw IntegerError.negativeNumber
        }
        guard amount > 0 else {
            throw IntegerError.zeroAmount
        }
        guard _balance >= amount else {
            throw IntegerError.notEnoughFunds
        }
        self._balance -= amount
    }
}
