import XCTest
@testable import EDEngine

@MainActor
private final class DummyHandHolder: EDHandManagerDelegate {
    private(set) var hand: [EDRawMaterialCard] = []

    func handManager(_ manager: EDHandManager, didUpdate cards: [EDRawMaterialCard]) {
        hand = cards
    }

    func makeRawMaterialCards() -> [EDRawMaterialCard] {
        RawMaterial.allCases.flatMap { material in
            (0..<EDMarketBoard.rawMaterialCertificatesPerGrade).map { _ in
                EDRawMaterialCard(material: material)
            }
        }
    }
}

final class EDHandManagerTests: XCTestCase {
    @MainActor
    func testManagesOpeningSupplyAndNotifiesHolder() throws {
        let holder = DummyHandHolder()
        let manager = EDHandManager(delegate: holder)

        for card in holder.makeRawMaterialCards() {
            try manager.addCard(card)
        }

        XCTAssertEqual(manager.cards.count, 3 * EDMarketBoard.rawMaterialCertificatesPerGrade)
        XCTAssertEqual(holder.hand, manager.cards)
        XCTAssertEqual(manager.cards(of: .extraFine).count, 28)
        XCTAssertEqual(manager.cards(of: .fine).count, 28)
        XCTAssertEqual(manager.cards(of: .standard).count, 28)
    }

    @MainActor
    func testFindsAndRemovesCardsAndRejectsInvalidOperations() throws {
        let manager = EDHandManager()
        let card = EDRawMaterialCard(material: .fine)

        try manager.addCard(card)

        XCTAssertEqual(manager.findCard(withID: card.id), card)
        XCTAssertThrowsError(try manager.addCard(card)) { error in
            XCTAssertEqual(error as? EDHandManagerError, .duplicateCard(card.id))
        }
        XCTAssertThrowsError(try manager.removeCard(at: -1)) { error in
            XCTAssertEqual(error as? EDHandManagerError, .invalidCardIndex(-1))
        }
        XCTAssertEqual(try manager.removeCard(at: 0), card)
        XCTAssertNil(manager.findCard(withID: card.id))
    }

    @MainActor
    func testPlayerHandChangesOnlyThroughItsManager() throws {
        let player = EDPlayer(name: "Test")
        let card = EDRawMaterialCard(material: .extraFine)

        try player.handManager.addCard(card)

        XCTAssertEqual(player.rawMaterialHand, [card])
    }

    @MainActor
    func testManagerDoesNotRetainDelegate() {
        weak var weakHolder: DummyHandHolder?
        var manager: EDHandManager?

        do {
            let holder = DummyHandHolder()
            weakHolder = holder
            manager = EDHandManager(delegate: holder)
        }

        XCTAssertNil(weakHolder)
        XCTAssertNotNil(manager)
    }

    @MainActor
    func testRemovingAllCardsNotifiesHolderAndIsSafeWhenEmpty() throws {
        let holder = DummyHandHolder()
        let manager = EDHandManager(delegate: holder)
        try manager.addCard(EDRawMaterialCard(material: .standard))

        manager.removeAllCards()

        XCTAssertTrue(manager.cards.isEmpty)
        XCTAssertTrue(holder.hand.isEmpty)
        manager.removeAllCards()
        XCTAssertTrue(holder.hand.isEmpty)
    }
}
