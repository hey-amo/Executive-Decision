// EDPlayer (swift)

import Foundation
import GameKit

public typealias Player = EDPlayer

public typealias Avatar = EDPlayerAvatar

public enum EDPlayerAvatar: String, CaseIterable, Sendable {
    case avt1 = "avt-1"
    case avt2 = "avt-2"
    case avt3 = "avt-3"
    case avt4 = "avt-4"
    case avt5 = "avt-5"
    case avt6 = "avt-6"
}

public class EDPlayer: GKPlayer, Identifiable {
    public var name: String
    public var avatar: Avatar?
    public var tallySheet: EDTallySheet = EDTallySheet()
    private var coins: Int
    public var isBankrupt: Bool
    public var loans: [EDLoanEntry] = []

    public init(name: String, 
        avatar: Avatar? = nil, 
        coins: Int = 0, 
        isBankrupt: Bool = false,
        loans: [EDLoanEntry] = []) {
        self.name = name
        self.avatar = avatar
        self.coins = coins
        self.isBankrupt = isBankrupt
        self.loans = loans
    }

    public static func == (lhs: EDPlayer, rhs: EDPlayer) -> Bool {
        return lhs.id == rhs.id
    }
}

extension EDPlayer: UpdateWalletDelegate {
    public func walletDidUpdate(balance: Int) {
        self.coins = balance
    }

}
