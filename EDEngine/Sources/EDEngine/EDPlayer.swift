import Foundation
import GameplayKit

public final class Player: NSObject, GKGameModelPlayer, Identifiable, Codable, @unchecked Sendable, TurnOrderPlayer {
    public typealias ID = UUID

    public let id: UUID
    public let playerId: Int
    private let stateLock = NSLock()
    private var _cash: Int
    private var _isAI: Bool
    private var _tallySheet: EDTallySheet

    public init(id: UUID = UUID(), playerId: Int, cash: Int = 0, isAI: Bool = false, tallySheet: EDTallySheet = EDTallySheet()) {
        self.id = id
        self.playerId = playerId
        self._cash = cash
        self._isAI = isAI
        self._tallySheet = tallySheet
        super.init()
    }

    public enum CodingKeys: String, CodingKey {
        case id
        case playerId
        case cash
        case isAI
        case tallySheet
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.playerId = try container.decode(Int.self, forKey: .playerId)
        self._cash = try container.decode(Int.self, forKey: .cash)
        self._isAI = try container.decode(Bool.self, forKey: .isAI)
        self._tallySheet = try container.decode(EDTallySheet.self, forKey: .tallySheet)
        super.init()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(playerId, forKey: .playerId)
        try container.encode(_cash, forKey: .cash)
        try container.encode(_isAI, forKey: .isAI)
        try container.encode(_tallySheet, forKey: .tallySheet)
    }

    public var cash: Int {
        get {
            stateLock.lock(); defer { stateLock.unlock() }
            return _cash
        }
        set {
            stateLock.lock(); defer { stateLock.unlock() }
            _cash = newValue
        }
    }

    public var isAI: Bool {
        get {
            stateLock.lock(); defer { stateLock.unlock() }
            return _isAI
        }
        set {
            stateLock.lock(); defer { stateLock.unlock() }
            _isAI = newValue
        }
    }

    public var tallySheet: EDTallySheet {
        get {
            stateLock.lock(); defer { stateLock.unlock() }
            return _tallySheet
        }
        set {
            stateLock.lock(); defer { stateLock.unlock() }
            _tallySheet = newValue
        }
    }

    public static func == (lhs: Player, rhs: Player) -> Bool {
        lhs.playerId == rhs.playerId
    }
}