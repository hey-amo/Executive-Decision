// EDLoanEntry.swift

public struct EDLoanEntry: Codable, Equatable, Sendable {
    public let amount: Int

    public init(amount: Int) {
        self.amount = amount
    }
}

public class LoanRepaymentManager {
    public init() {}

    public func playerRepaysLoans(p: Player) throws {
        guard !p.loans.isEmpty else {
            return
        }

        let loansToRepay = p.loans
        var unpaidLoans: [EDLoanEntry] = []
        var wallet = try Wallet(p.coins)

        for (index, loan) in loansToRepay.enumerated() {
            do {
                try wallet.apply(t: .debit(loan.amount), notifying: p)
            } catch IntegerError.notEnoughFunds {
                unpaidLoans.append(loan)
            } catch {
                unpaidLoans.append(contentsOf: loansToRepay.dropFirst(index))
                p.loans = unpaidLoans
                throw error
            }
        }

        p.loans = unpaidLoans
    }
}