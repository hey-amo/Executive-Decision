// EDPlayer.swift

import Foundation
import GameKit

public typealias Player = EDPlayer

public class EDPlayer: Equatable, Hashable, Identifiable {
    public let id: UUID = UUID()
    public var name: String
    private var coins: Int = 0

    public init(name: String, coins: Int = 0) {
        self.name = name
        self.coins = coins
    }

    public static func == (lhs: EDPlayer, rhs: EDPlayer) -> Bool {
        return lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension EDPlayer: UpdateWalletDelegate {
    public func walletDidUpdate(balance: Int) {
        self.coins = balance
    }

}
