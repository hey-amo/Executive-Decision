//
//  EDWalletAPITests.swift
//  EDEngine
//
//  Created by Amarjit on 28/10/2026.
//

import XCTest
@testable import EDEngine

private final class DummyPlayer: UpdateWalletDelegate {
    var coins = 0

    func walletDidUpdate(balance: Int) {
        coins = balance
    }
}

final class EDWalletAPITests: XCTestCase {

    func testCreditAddsAmountToBalance() throws {
        var wallet = try WalletAPI(_balance: 0)

        try wallet.apply(t: .credit(100))

        XCTAssertEqual(wallet.balance, 100)
    }

    func testDebitSubtractsAmountFromBalance() throws {
        var wallet = try WalletAPI(_balance: 150)

        try wallet.debit(100)

        XCTAssertEqual(wallet.balance, 50)
    }

    func testNegativeInitialBalanceThrows() {
        XCTAssertThrowsError(try WalletAPI(_balance: -1)) { error in
            XCTAssertEqual(error as? IntegerError, .negativeNumber)
        }
    }

    func testNegativeCreditThrowsWithoutChangingBalance() throws {
        var wallet = try WalletAPI(_balance: 100)

        XCTAssertThrowsError(try wallet.apply(t: .credit(-1))) { error in
            XCTAssertEqual(error as? IntegerError, .negativeNumber)
        }
        XCTAssertEqual(wallet.balance, 100)
    }

    func testNegativeDebitThrowsWithoutChangingBalance() throws {
        var wallet = try WalletAPI(_balance: 100)

        XCTAssertThrowsError(try wallet.debit(-1)) { error in
            XCTAssertEqual(error as? IntegerError, .negativeNumber)
        }
        XCTAssertEqual(wallet.balance, 100)
    }

    func testDebitAboveBalanceThrowsWithoutMakingBalanceNegative() throws {
        var wallet = try WalletAPI(_balance: 50)

        XCTAssertThrowsError(try wallet.apply(t: .debit(51))) { error in
            XCTAssertEqual(error as? IntegerError, .notEnoughFunds)
        }
        XCTAssertEqual(wallet.balance, 50)
    }

    func testDebitEqualToBalanceLeavesZero() throws {
        var wallet = try WalletAPI(_balance: 50)

        try wallet.debit(50)

        XCTAssertEqual(wallet.balance, 0)
    }

    func testInitialBalanceAboveMaximumThrows() {
        XCTAssertThrowsError(try WalletAPI(_balance: WalletAPI.maximumBalance + 1)) { error in
            XCTAssertEqual(error as? IntegerError, .maxBalancedReached)
        }
    }

    func testCreditAboveMaximumThrowsWithoutChangingBalance() throws {
        var wallet = try WalletAPI(_balance: WalletAPI.maximumBalance - 1)

        XCTAssertThrowsError(try wallet.apply(t: .credit(2))) { error in
            XCTAssertEqual(error as? IntegerError, .maxBalancedReached)
        }
        XCTAssertEqual(wallet.balance, WalletAPI.maximumBalance - 1)
    }

    func testCreditCanReachMaximumBalance() throws {
        var wallet = try WalletAPI(_balance: WalletAPI.maximumBalance - 100)

        try wallet.apply(t: .credit(100))

        XCTAssertEqual(wallet.balance, WalletAPI.maximumBalance)
    }

    func testZeroCreditThrowsWithoutChangingBalance() throws {
        var wallet = try WalletAPI(_balance: 100)

        XCTAssertThrowsError(try wallet.apply(t: .credit(0))) { error in
            XCTAssertEqual(error as? IntegerError, .zeroAmount)
        }
        XCTAssertEqual(wallet.balance, 100)
    }

    func testZeroDebitThrowsWithoutChangingBalance() throws {
        var wallet = try WalletAPI(_balance: 100)

        XCTAssertThrowsError(try wallet.debit(0)) { error in
            XCTAssertEqual(error as? IntegerError, .zeroAmount)
        }

        XCTAssertEqual(wallet.balance, 100)
    }

    func testApplyingDebitAtZeroBalanceThrows() throws {
        var wallet = try WalletAPI(_balance: 0)

        XCTAssertThrowsError(try wallet.apply(t: .debit(1))) { error in
            XCTAssertEqual(error as? IntegerError, .notEnoughFunds)
        }
        XCTAssertEqual(wallet.balance, 0)
    }

    func testDelegateTracksPlayerCoinsAfterCreditAndDebit() throws {
        var wallet = try WalletAPI(_balance: 0)
        let player = DummyPlayer()

        try wallet.apply(t: .credit(100), notifying: player)
        XCTAssertEqual(player.coins, 100)

        try wallet.apply(t: .debit(50), notifying: player)
        XCTAssertEqual(player.coins, 50)
        XCTAssertEqual(wallet.balance, 50)
    }
}
