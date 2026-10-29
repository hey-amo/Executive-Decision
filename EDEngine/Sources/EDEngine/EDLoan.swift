// EDLoanEntry.swift

public struct EDLoanEntry: Codable, Equatable, Sendable {
    public let amount: Int
}

public class LoanRepaymentManager {
    public func playerRepaysLoans(p: Player) -> Int {
        return 0
        
        // var wallet: EDWallet = EDWallet(p.coins)


        // let totalRepayment = loans.reduce(0) { $0 + $1.amount }
        // p.loans.removeAll()
        // return totalRepayment
    }
}