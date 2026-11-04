import Foundation

public struct EDRawMaterialCard: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let material: RawMaterial

    public init(material: RawMaterial, id: UUID = UUID()) {
        self.id = id
        self.material = material
    }
}

public protocol EDHandManagerDelegate: AnyObject {
    @MainActor
    func handManager(_ manager: EDHandManager, didUpdate cards: [EDRawMaterialCard])
}

public enum EDHandManagerError: Error, Equatable {
    case duplicateCard(UUID)
    case invalidCardIndex(Int)
}

@MainActor
public final class EDHandManager {
    private var hand: [EDRawMaterialCard] = []
    private weak var delegate: (any EDHandManagerDelegate)?

    public init(delegate: (any EDHandManagerDelegate)? = nil) {
        self.delegate = delegate
    }

    public var cards: [EDRawMaterialCard] {
        hand
    }

    public func addCard(_ card: EDRawMaterialCard) throws {
        guard !hand.contains(where: { $0.id == card.id }) else {
            throw EDHandManagerError.duplicateCard(card.id)
        }
        hand.append(card)
        notifyDelegate()
    }

    public func findCard(withID id: UUID) -> EDRawMaterialCard? {
        hand.first { $0.id == id }
    }

    public func cards(of material: RawMaterial) -> [EDRawMaterialCard] {
        hand.filter { $0.material == material }
    }

    @discardableResult
    public func removeCard(at index: Int) throws -> EDRawMaterialCard {
        guard hand.indices.contains(index) else {
            throw EDHandManagerError.invalidCardIndex(index)
        }
        let removedCard = hand.remove(at: index)
        notifyDelegate()
        return removedCard
    }

    public func removeAllCards() {
        guard !hand.isEmpty else { return }
        hand.removeAll()
        notifyDelegate()
    }

    private func notifyDelegate() {
        delegate?.handManager(self, didUpdate: hand)
    }
}
