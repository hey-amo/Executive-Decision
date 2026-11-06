import Foundation
import Testing
@testable import EDEngine

@Suite("Player state")
struct EDPlayerStateTests {
    @Test("Creates a value state with defaults and updates its name")
    func createsAndRenamesPlayerState() throws {
        var state = try EDPlayerState(name: "Alex")

        #expect(state.name == "Alex")
        #expect(state.cash.balance == 0)
        #expect(state.inventory == EDInventory())
        #expect(state.loanBalance == 0)
        #expect(try state.loanRepaymentAmount() == 0)

        state.rename(to: "Sam")
        #expect(state.name == "Sam")
    }

    @Test("Validates starting cash and loan principal")
    func validatesInitialBalances() {
        do {
            _ = try EDPlayerState(name: "Alex", cashBalance: -5_001)
            Issue.record("Expected cash below the supported minimum to fail.")
        } catch {
            #expect(error == .money(.balanceBelowMinimum(-5_001)))
        }

        for loanBalance in [-100, 1, 150] {
            do {
                _ = try EDPlayerState(name: "Alex", loanBalance: loanBalance)
                Issue.record("Expected invalid loan principal \(loanBalance) to fail.")
            } catch {
                #expect(error == .invalidLoanBalance(loanBalance))
            }
        }

        #expect(throws: Never.self) {
            try EDPlayerState(name: "Alex", cashBalance: -5_000, loanBalance: 200)
        }
    }

    @Test("Adds and subtracts cash using wallet balance rules")
    func updatesCash() throws {
        var state = try EDPlayerState(name: "Alex", cashBalance: 10)

        try state.addCash(0)
        try state.addCash(15)
        try state.subtractCash(30)

        #expect(state.cash.balance == -5)
    }

    @Test("Rejects invalid cash changes without changing the balance")
    func invalidCashUpdatesAreAtomic() throws {
        var state = try EDPlayerState(name: "Alex", cashBalance: 10)

        do {
            try state.addCash(-1)
            Issue.record("Expected negative cash addition to fail.")
        } catch {
            #expect(error == .money(.additionMustBePositive(-1)))
        }

        do {
            try state.subtractCash(-1)
            Issue.record("Expected negative cash subtraction to fail.")
        } catch {
            #expect(error == .money(.subtractionMustBeNonnegative(-1)))
        }

        do {
            try state.subtractCash(5_011)
            Issue.record("Expected cash below the supported minimum to fail.")
        } catch {
            #expect(error == .money(.balanceBelowMinimum(-5_001)))
        }

        #expect(state.cash.balance == 10)
    }

    @Test("Rejects cash overflow without changing cash")
    func cashOverflowIsAtomic() throws {
        var state = try EDPlayerState(name: "Alex", cashBalance: Int.max)

        do {
            try state.addCash(1)
            Issue.record("Expected cash overflow to fail.")
        } catch {
            #expect(error == .money(.balanceOverflow))
        }

        #expect(state.cash.balance == Int.max)
    }

    @Test("Borrowing adds $100 increments to cash and records repayment")
    func borrowsInHundredDollarIncrements() throws {
        var state = try EDPlayerState(name: "Alex", cashBalance: 50)

        try state.borrow(100)
        try state.borrow(200)

        #expect(state.cash.balance == 350)
        #expect(state.loanBalance == 300)
        #expect(try state.loanRepaymentAmount() == 375)
    }

    @Test("Rejects invalid or overflowing loans atomically")
    func invalidLoansDoNotChangePlayerState() throws {
        var state = try EDPlayerState(name: "Alex", cashBalance: 50)

        for amount in [0, -100, 1, 150] {
            do {
                try state.borrow(amount)
                Issue.record("Expected loan amount \(amount) to be rejected.")
            } catch {
                #expect(error == .invalidLoanAmount(amount))
            }
        }

        #expect(state.cash.balance == 50)
        #expect(state.loanBalance == 0)

        var overflowingLoan = try EDPlayerState(
            name: "Alex",
            loanBalance: (Int.max / 100) * 100
        )
        do {
            try overflowingLoan.borrow(100)
            Issue.record("Expected loan principal overflow to fail.")
        } catch {
            #expect(error == .loanBalanceOverflow)
        }

        #expect(overflowingLoan.loanBalance == (Int.max / 100) * 100)
        #expect(overflowingLoan.cash.balance == 0)
    }

    @Test("A failed loan cash deposit does not record borrowed principal")
    func loanCashOverflowIsAtomic() throws {
        var state = try EDPlayerState(name: "Alex", cashBalance: Int.max - 50)

        do {
            try state.borrow(100)
            Issue.record("Expected loan cash overflow to fail.")
        } catch {
            #expect(error == .money(.balanceOverflow))
        }

        #expect(state.cash.balance == Int.max - 50)
        #expect(state.loanBalance == 0)
    }

    @Test("Detects overflow when computing end-game loan repayment")
    func loanRepaymentOverflowIsReported() throws {
        let state = try EDPlayerState(name: "Alex", loanBalance: (Int.max / 100) * 100)

        #expect(throws: EDPlayerStateError.repaymentOverflow) {
            try state.loanRepaymentAmount()
        }
    }

    @Test("Codable round-trips complete player state and validates persisted loans")
    func codableRoundTripAndValidation() throws {
        let id = UUID()
        let state = try EDPlayerState(
            id: id,
            name: "Alex",
            cashBalance: -25,
            inventory: EDInventory(certificatesByGrade: [.xfine: 2, .standard: 3]),
            loanBalance: 100
        )
        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(EDPlayerState.self, from: data)

        #expect(decoded == state)

        let invalidLoan = """
        {"id":"\(id.uuidString)","name":"Alex","cash":0,"inventory":{},"loanBalance":150}
        """
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(EDPlayerState.self, from: Data(invalidLoan.utf8))
        }
    }
}
