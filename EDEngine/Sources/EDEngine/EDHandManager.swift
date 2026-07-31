import Foundation


public struct EDRawMaterialCard: Codable, Equatable, Sendable, Hashable {
    public let material: RawMaterial

    public init(material: RawMaterial) {
        self.material = material
    }
}

public struct EDRawMaterialDeck: Codable, Equatable, Sendable {
    public static let cardsPerGrade: Int = 28
    public private(set) var cards: [EDRawMaterialCard]

    public init(cards: [EDRawMaterialCard] = []) {
        self.cards = cards
    }

    public static func standardDeck() -> EDRawMaterialDeck {
        let cards = RawMaterial.allCases.flatMap { material in
            Array(repeating: EDRawMaterialCard(material: material), count: cardsPerGrade)
        }
        return EDRawMaterialDeck(cards: cards)
    }

    public var totalCards: Int {
        cards.count
    }

    public var materialCounts: [RawMaterial: Int] {
        cards.reduce(into: [RawMaterial: Int]()) { counts, card in
            counts[card.material, default: 0] += 1
        }
    }

    public var isEmpty: Bool {
        cards.isEmpty
    }

    public mutating func drawCard() -> EDRawMaterialCard? {
        guard !cards.isEmpty else { return nil }
        return cards.removeFirst()
    }

    public mutating func drawCards(count: Int) -> [EDRawMaterialCard] {
        guard count > 0 else { return [] }
        let drawn = Array(cards.prefix(count))
        cards.removeFirst(min(count, cards.count))
        return drawn
    }

    public mutating func drawCards(of material: RawMaterial, count: Int) -> [EDRawMaterialCard]? {
        guard count > 0 else { return [] }

        var drawn: [EDRawMaterialCard] = []
        var remaining: [EDRawMaterialCard] = []
        var toDraw = count

        for card in cards {
            if card.material == material && toDraw > 0 {
                drawn.append(card)
                toDraw -= 1
            } else {
                remaining.append(card)
            }
        }

        guard toDraw == 0 else { return nil }
        cards = remaining
        return drawn
    }
}

public struct EDRawMaterialHand: Codable, Equatable, Sendable {
    public private(set) var cards: [EDRawMaterialCard]

    public init(cards: [EDRawMaterialCard] = []) {
        self.cards = cards
    }

    public var count: Int {
        cards.count
    }

    public var materialCounts: [RawMaterial: Int] {
        cards.reduce(into: [RawMaterial: Int]()) { counts, card in
            counts[card.material, default: 0] += 1
        }
    }

    public func adding(_ cards: [EDRawMaterialCard]) -> EDRawMaterialHand {
        EDRawMaterialHand(cards: self.cards + cards)
    }

    public func removing(of material: RawMaterial, count: Int) -> (hand: EDRawMaterialHand, removed: [EDRawMaterialCard])? {
        guard count > 0 else { return (self, []) }

        var removed: [EDRawMaterialCard] = []
        var remaining: [EDRawMaterialCard] = []
        var toRemove = count

        for card in cards {
            if card.material == material && toRemove > 0 {
                removed.append(card)
                toRemove -= 1
            } else {
                remaining.append(card)
            }
        }

        guard toRemove == 0 else { return nil }
        return (EDRawMaterialHand(cards: remaining), removed)
    }
}

public protocol EDRawMaterialHandReceiver: AnyObject {
    var rawMaterialHand: EDRawMaterialHand { get }
    func didUpdateRawMaterialHand(_ hand: EDRawMaterialHand)
}

/// Manages the raw material card deck and deals cards to hand receivers.
///
/// Responsibilities:
/// - own the shared raw material deck state
/// - draw cards by grade from the deck
/// - deal cards into a receiver's hand via protocol callback
/// - keep player-hand management separate from the deck logic
public final class EDRawMaterialCardManager: Equatable, @unchecked Sendable {
    private let stateLock = NSLock()
    public private(set) var deck: EDRawMaterialDeck

    public init(deck: EDRawMaterialDeck = .standardDeck()) {
        self.deck = deck
    }

    public func drawCards(of material: RawMaterial, count: Int) -> [EDRawMaterialCard]? {
        stateLock.lock(); defer { stateLock.unlock() }
        return deck.drawCards(of: material, count: count)
    }

    public func dealCards(to receiver: EDRawMaterialHandReceiver, material: RawMaterial, count: Int) -> Bool {
        guard let cards = drawCards(of: material, count: count) else {
            return false
        }

        let updatedHand = receiver.rawMaterialHand.adding(cards)
        receiver.didUpdateRawMaterialHand(updatedHand)
        return true
    }

    public static func == (lhs: EDRawMaterialCardManager, rhs: EDRawMaterialCardManager) -> Bool {
        lhs.deck == rhs.deck
    }
}