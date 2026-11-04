import XCTest
@testable import EDEngine

final class EDLoanTests: XCTestCase {
    func testRepayingLoansUpdatesPlayerBalanceAndRemovesPaidLoans() throws {
        let player = EDPlayer(
            name: "Player",
            coins: 100,
            loans: [EDLoanEntry(amount: 30), EDLoanEntry(amount: 20)]
        )

        try LoanRepaymentManager().playerRepaysLoans(p: player)

        XCTAssertEqual(player.coins, 50)
        XCTAssertTrue(player.loans.isEmpty)
    }

    func testUnaffordableLoanRemainsWhileAffordableLoansAreRepaid() throws {
        let player = EDPlayer(
            name: "Player",
            coins: 50,
            loans: [EDLoanEntry(amount: 80), EDLoanEntry(amount: 30)]
        )

        try LoanRepaymentManager().playerRepaysLoans(p: player)

        XCTAssertEqual(player.coins, 20)
        XCTAssertEqual(player.loans, [EDLoanEntry(amount: 80)])
    }

    func testOnlyOneOfTwoEqualLoansIsRemovedWhenOnlyOneCanBeRepaid() throws {
        let player = EDPlayer(
            name: "Player",
            coins: 5,
            loans: [EDLoanEntry(amount: 5), EDLoanEntry(amount: 5)]
        )

        try LoanRepaymentManager().playerRepaysLoans(p: player)

        XCTAssertEqual(player.coins, 0)
        XCTAssertEqual(player.loans, [EDLoanEntry(amount: 5)])
    }

    func testInvalidLoanThrowsAndPreservesUnprocessedLoans() {
        let player = EDPlayer(
            name: "Player",
            coins: 30,
            loans: [
                EDLoanEntry(amount: 10),
                EDLoanEntry(amount: 0),
                EDLoanEntry(amount: 20)
            ]
        )

        XCTAssertThrowsError(try LoanRepaymentManager().playerRepaysLoans(p: player)) { error in
            XCTAssertEqual(error as? IntegerError, .zeroAmount)
        }
        XCTAssertEqual(player.coins, 20)
        XCTAssertEqual(
            player.loans,
            [EDLoanEntry(amount: 0), EDLoanEntry(amount: 20)]
        )
    }
}
