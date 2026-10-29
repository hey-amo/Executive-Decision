// EDPlayer.swift

import Foundation
import GameKit

public typealias Player = EDPlayer

public class EDPlayer: GKPlayer, Identifiable {
    public var name: String
    private var coins: Int = 0
    public var isBankrupt: Bool = false // not implemented

    public init(name: String, coins: Int = 0, isBankrupt: Bool = false) {
        self.name = name
        self.coins = coins
        self.isBankrupt = isBankrupt
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
