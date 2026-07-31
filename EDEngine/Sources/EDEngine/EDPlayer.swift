import Foundation
import GameplayKit

public class Player: NSObject, Identifiable {
    public var playerId: UUID
    public var cash: Int

    public init(playerId: UUID = UUID(), cash: Int = 0) {
        self.playerId = playerId
        self.cash = cash
    }
}