// EDLoanEntry.swift

public struct EDLoanEntry: Codable, Equatable, Sendable {
    public let amount: Int
}

public class LoanRepaymentManager{
    public func playerRepaysLoans(p: Player) -> Int {
        let wallet: Wallet = Wallet(p.coins)
        return 0
    }
}