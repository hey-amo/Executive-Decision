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
    private var _bidSession: EDPlayerBidSession
    private var _rawMaterialHand: EDRawMaterialHand

    public init(id: UUID = UUID(), playerId: Int, cash: Int = 0, isAI: Bool = false, tallySheet: EDTallySheet = EDTallySheet(), bidSession: EDPlayerBidSession = EDPlayerBidSession(monthIndex: 1), rawMaterialHand: EDRawMaterialHand = EDRawMaterialHand()) {
        self.id = id
        self.playerId = playerId
        self._cash = cash
        self._isAI = isAI
        self._tallySheet = tallySheet
        self._bidSession = bidSession
        self._rawMaterialHand = rawMaterialHand
        super.init()
    }

    public enum CodingKeys: String, CodingKey {
        case id
        case playerId
        case cash
        case isAI
        case tallySheet
        case bidSession
        case rawMaterialHand
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.playerId = try container.decode(Int.self, forKey: .playerId)
        self._cash = try container.decode(Int.self, forKey: .cash)
        self._isAI = try container.decode(Bool.self, forKey: .isAI)
        self._tallySheet = try container.decode(EDTallySheet.self, forKey: .tallySheet)
        self._bidSession = try container.decode(EDPlayerBidSession.self, forKey: .bidSession)
        self._rawMaterialHand = try container.decode(EDRawMaterialHand.self, forKey: .rawMaterialHand)
        super.init()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(playerId, forKey: .playerId)
        try container.encode(_cash, forKey: .cash)
        try container.encode(_isAI, forKey: .isAI)
        try container.encode(_tallySheet, forKey: .tallySheet)
        try container.encode(_bidSession, forKey: .bidSession)
        try container.encode(_rawMaterialHand, forKey: .rawMaterialHand)
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

    public var bidSession: EDPlayerBidSession {
        get {
            stateLock.lock(); defer { stateLock.unlock() }
            return _bidSession
        }
        set {
            stateLock.lock(); defer { stateLock.unlock() }
            _bidSession = newValue
        }
    }

    public var rawMaterialHand: EDRawMaterialHand {
        get {
            stateLock.lock(); defer { stateLock.unlock() }
            return _rawMaterialHand
        }
        set {
            stateLock.lock(); defer { stateLock.unlock() }
            _rawMaterialHand = newValue
        }
    }

    public func didUpdateRawMaterialHand(_ hand: EDRawMaterialHand) {
        stateLock.lock(); defer { stateLock.unlock() }
        _rawMaterialHand = hand
    }

    public func canSubmitBid(playersCount: Int) -> Bool {
        stateLock.lock(); defer { stateLock.unlock() }
        return _bidSession.canSubmitRawMaterialBid(withCash: _cash, playersCount: playersCount)
    }

    public static func == (lhs: Player, rhs: Player) -> Bool {
        lhs.playerId == rhs.playerId
    }
}