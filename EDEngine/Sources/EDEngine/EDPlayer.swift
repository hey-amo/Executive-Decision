import Foundation
import GameplayKit

public class Player: GKPlayer, Identifiable, Codable, Sendable, TurnOrderPlayer {
    public typealias ID = UUID
    public var cash: Int
    public var isAI: Bool

    public init(playerId: UUID = UUID(), cash: Int = 0, isAI: Bool = false  ) {
        self.playerId = playerId
        self.cash = cash
        self.isAI = isAI
    }

    public static func == (lhs: Player, rhs: Player) -> Bool {
        return lhs.playerId == rhs.playerId
    }
}