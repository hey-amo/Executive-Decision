import Foundation
import GameplayKit

public class Player: NSObject, Identifiable {
    public var playerId: UUID
    public var cash: Int
    public var isAI: Bool

    public init(playerId: UUID = UUID(), cash: Int = 0, isAI: Bool = false  ) {
        self.playerId = playerId
        self.cash = cash
        self.isAI = isAI
    }
}