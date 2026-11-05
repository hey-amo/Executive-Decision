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

        try await wallet.performTransaction(.subtract(125))
        balance = await wallet.balance
        XCTAssertEqual(balance, -5)

        try await wallet.performTransaction(.subtract(0))
        balance = await wallet.balance
        XCTAssertEqual(balance, -5)
    }

    func testNegativeInitialBalanceIsAllowedDownToMinimum() async throws {
        let wallet = try Wallet(with: -5_000)
        let balance = await wallet.balance
        XCTAssertEqual(balance, -5_000)

        XCTAssertThrowsError(try Wallet(with: -5_001)) { error in
            XCTAssertEqual(error as? EDMoneyError, .balanceBelowMinimum(-5_001))
        }
    }

    func testNegativeTransactionAmountsAreRejectedWithoutChangingBalance() async throws {
        let wallet = try Wallet(with: 10)

        await assertWalletError(.additionMustBePositive(0)) {
            try await wallet.performTransaction(.add(0))
        }
        await assertWalletError(.additionMustBePositive(-1)) {
            try await wallet.performTransaction(.add(-1))
        }
        await assertWalletError(.subtractionMustBeNonnegative(-1)) {
            try await wallet.performTransaction(.subtract(-1))
        }
        await assertWalletError(.additionMustBePositive(Int.min)) {
            try await wallet.performTransaction(.add(Int.min))
        }
        await assertWalletError(.subtractionMustBeNonnegative(Int.min)) {
            try await wallet.performTransaction(.subtract(Int.min))
        }

        let balance = await wallet.balance
        XCTAssertEqual(balance, 10)
    }

    func testSubtractingBelowMinimumFailsWithoutChangingBalance() async throws {
        let wallet = try Wallet(with: -4_999)

        await assertWalletError(.balanceBelowMinimum(-5_001)) {
            try await wallet.performTransaction(.subtract(2))
        }

        let balance = await wallet.balance
        XCTAssertEqual(balance, -4_999)
    }

    func testAdditionOverflowFailsAndMaximumBalanceCanBeSpent() async throws {
        let wallet = try Wallet(with: Int.max - 1)

        await assertWalletError(.balanceOverflow) {
            try await wallet.performTransaction(.add(2))
        }
        var balance = await wallet.balance
        XCTAssertEqual(balance, Int.max - 1)

        try await wallet.performTransaction(.subtract(Int.max - 1))
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

    func testMoneyErrorsHaveLocalizedDescriptions() {
        XCTAssertNotNil(EDMoneyError.additionMustBePositive(0).errorDescription)
        XCTAssertNotNil(EDMoneyError.subtractionMustBeNonnegative(-1).errorDescription)
    }

    private func assertWalletError(
        _ expected: EDMoneyError,
        file: StaticString = #filePath,
        line: UInt = #line,
        operation: () async throws -> Void
    ) async {
        do {
            try await operation()
            XCTFail("Expected \(expected), but the operation succeeded.", file: file, line: line)
        } catch let error as EDMoneyError {
            XCTAssertEqual(error, expected, file: file, line: line)
        } catch {
            XCTFail("Unexpected error: \(error)", file: file, line: line)
        }
    }
}
