//
//  WalletAPI.swift
//  EDEngine
//
//  Created by Amarjit on 28/10/2026.
//
import Foundation

// Handles in game 'banking' like features:
// credit,
// debit

public enum IntegerError {
    case negativeNumber
    case notEnoughFunds
}

public enum Transaction {
    case credit(_ amount: Int)
    case debit(_ amount: Int)
}

public typealias Bank = WalletAPI

public struct WalletAPI {
    private var _balance: Int = 0
    public var balance: Int {
        get { return self._balance }
    }
    
    public init(_balance: Int) {
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
    
    private mutating func credit(_ amount: Int = 0) throws {
        guard amount > 0 else { return }
        self._balance += amount
    }
    
    public mutating func debit(_ amount: Int = 0) throws {
        guard amount > 0 else { return }
        guard _balance >= amount else { return }
        self._balance -= amount
    }
}
