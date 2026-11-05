// EDWallet.swift

public enum TransactionType: Sendable, Codable {
    case add(_ amount: Int)
    case subtract( _ amount: Int)
}

public actor Wallet {
    private var money: EDMoney

    public var balance: Int {
        money.balance
    }

    public init(with balance: Int = 0) throws(EDMoneyError) {
        money = try EDMoney(balance: balance)
    }

    public func performTransaction(_ transaction: TransactionType) throws(EDMoneyError) {
        switch transaction {
        case let .add(amount):
            money = try money.adding(amount)
        case let .subtract(amount):
            money = try money.subtracting(amount)
        }
    }
}