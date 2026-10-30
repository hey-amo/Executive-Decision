// EDPlayer (swift)

import Foundation
import GameKit

public typealias Player = EDPlayer

public typealias Avatar = EDPlayerAvatar

public enum EDPlayerCharacter: String, CaseIterable, Sendable, CustomStringConvertible {
    case tom, alex, sarah, saxton, chow, manos
    
    public static func getAvatar(for name: EDPlayerCharacter) -> String {
        switch name {
        case .tom: return EDPlayerAvatar.avt1.rawValue
        case .alex: return EDPlayerAvatar.avt2.rawValue
        case .sarah: return EDPlayerAvatar.avt3.rawValue
        case .saxton: return EDPlayerAvatar.avt4.rawValue
        case .chow: return EDPlayerAvatar.avt5.rawValue
        case .manos: return EDPlayerAvatar.avt6.rawValue
        }
    }
    
    public var description: String {
        switch self {
        case .tom: return "Tom"
        case .alex: return "Alex"
        case .sarah: return "Sarah"
        case .saxton: return "Saxton"
        case .chow: return "Chow"
        case .manos: return "Manos"
        }
    }
}

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
    private var _coins: Int
    public var coins: Int { get { return self._coins} }
    public var isBankrupt: Bool
    public var loans: [EDLoanEntry] = []
    public var isAI: Bool

    public init(name: String,
                avatar: Avatar? = nil,
                coins: Int = 0,
                isBankrupt: Bool = false,
                loans: [EDLoanEntry]  = [],
                isAI: Bool = false) {
        self.name = name
        self.avatar = avatar
        self._coins = coins
        self.isBankrupt = isBankrupt
        self.loans = loans
        self.isAI = isAI
    }

    public static func == (lhs: EDPlayer, rhs: EDPlayer) -> Bool {
        return lhs.id == rhs.id
    }
}

extension EDPlayer: UpdateWalletDelegate {
    public func walletDidUpdate(balance: Int) {
        self._coins = balance
    }

}
