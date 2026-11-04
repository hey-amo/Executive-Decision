import XCTest
@testable import EDEngine

final class WalletTests: XCTestCase {
    func testInitialBalanceAndSuccessfulTransactions() async throws {
        let wallet = try Wallet(with: 100)

        var balance = await wallet.balance
        XCTAssertEqual(balance, 100)

        try await wallet.performTransaction(.add(50))
        try await wallet.performTransaction(.subtract(30))
        balance = await wallet.balance
        XCTAssertEqual(balance, 120)

        try await wallet.performTransaction(.subtract(120))
        balance = await wallet.balance
        XCTAssertEqual(balance, 0)

        try await wallet.performTransaction(.add(0))
        try await wallet.performTransaction(.subtract(0))
        balance = await wallet.balance
        XCTAssertEqual(balance, 0)
    }

    func testNegativeInitialBalanceIsRejected() throws {
        XCTAssertThrowsError(try Wallet(with: -1)) { error in
            XCTAssertEqual(error as? IntegerError, .negativeValue)
        }
    }

    func testNegativeTransactionAmountsAreRejectedWithoutChangingBalance() async throws {
        let wallet = try Wallet(with: 10)

        await assertWalletError(.negativeValue) {
            try await wallet.performTransaction(.add(-1))
        }
        await assertWalletError(.negativeValue) {
            try await wallet.performTransaction(.subtract(-1))
        }
        await assertWalletError(.negativeValue) {
            try await wallet.performTransaction(.add(Int.min))
        }
        await assertWalletError(.negativeValue) {
            try await wallet.performTransaction(.subtract(Int.min))
        }

        let balance = await wallet.balance
        XCTAssertEqual(balance, 10)
    }

    func testInsufficientFundsThrowsWithoutChangingBalance() async throws {
        let wallet = try Wallet(with: 10)

        await assertWalletError(.notEnoughFunds) {
            try await wallet.performTransaction(.subtract(11))
        }

        let balance = await wallet.balance
        XCTAssertEqual(balance, 10)

        let emptyWallet = try Wallet()
        await assertWalletError(.notEnoughFunds) {
            try await emptyWallet.performTransaction(.subtract(1))
        }
        let emptyBalance = await emptyWallet.balance
        XCTAssertEqual(emptyBalance, 0)
    }

    func testAdditionOverflowSaturatesAndMaximumBalanceCanBeSpent() async throws {
        let wallet = try Wallet(with: Int.max - 1)

        try await wallet.performTransaction(.add(2))
        var balance = await wallet.balance
        XCTAssertEqual(balance, Int.max)

        try await wallet.performTransaction(.subtract(Int.max))
        balance = await wallet.balance
        XCTAssertEqual(balance, 0)
    }

    func testConcurrentTransactionsAreSerializedByTheWalletActor() async throws {
        let wallet = try Wallet()

        try await withThrowingTaskGroup(of: Void.self) { group in
            for _ in 0..<500 {
                group.addTask {
                    try await wallet.performTransaction(.add(1))
                }
            }
            try await group.waitForAll()
        }

        let balance = await wallet.balance
        XCTAssertEqual(balance, 500)
    }

    func testIntegerErrorsHaveLocalizedDescriptions() {
        XCTAssertNotNil(IntegerError.negativeValue.errorDescription)
        XCTAssertNotNil(IntegerError.notEnoughFunds.errorDescription)
    }

    private func assertWalletError(
        _ expected: IntegerError,
        file: StaticString = #filePath,
        line: UInt = #line,
        operation: () async throws -> Void
    ) async {
        do {
            try await operation()
            XCTFail("Expected \(expected), but the operation succeeded.", file: file, line: line)
        } catch let error as IntegerError {
            XCTAssertEqual(error, expected, file: file, line: line)
        } catch {
            XCTFail("Unexpected error: \(error)", file: file, line: line)
        }
    }
}
