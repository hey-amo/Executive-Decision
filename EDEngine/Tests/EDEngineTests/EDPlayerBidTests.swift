import XCTest
@testable import EDEngine

final class EDPlayerBidTests: XCTestCase {
    func testBidSessionCanSubmitWhenWithinLimitsAndCashAvailable() {
        var bidSession = EDPlayerBidSession(monthIndex: 1)
        bidSession.addRawMaterialBid(EDRawMaterialBid(material: .fine, units: 4, bidPrice: 35))
        bidSession.addRawMaterialBid(EDRawMaterialBid(material: .standard, units: 3, bidPrice: 22))

        XCTAssertTrue(bidSession.isWithinRawMaterialUnitLimit(for: 3))
        XCTAssertTrue(bidSession.isRawMaterialBidPriceValid())
        XCTAssertEqual(bidSession.totalRawMaterialCost, 4 * 35 + 3 * 22)
        XCTAssertTrue(bidSession.canSubmitRawMaterialBid(withCash: 300, playersCount: 3))
    }

    func testBidSessionFailsWhenCashIsInsufficient() {
        var bidSession = EDPlayerBidSession(monthIndex: 1)
        bidSession.addRawMaterialBid(EDRawMaterialBid(material: .xfine, units: 10, bidPrice: 40))

        XCTAssertFalse(bidSession.canSubmitRawMaterialBid(withCash: 100, playersCount: 2))
    }

    func testBidSessionFailsWhenPlayerExceedsUnitLimit() {
        var bidSession = EDPlayerBidSession(monthIndex: 1)
        bidSession.addRawMaterialBid(EDRawMaterialBid(material: .fine, units: 13, bidPrice: 35))

        XCTAssertFalse(bidSession.isWithinRawMaterialUnitLimit(for: 2))
        XCTAssertFalse(bidSession.canSubmitRawMaterialBid(withCash: 1000, playersCount: 2))
    }

    func testBidSessionEnforcesTwoPlayerGradeLimit() {
        var bidSession = EDPlayerBidSession(monthIndex: 1)
        bidSession.addRawMaterialBid(EDRawMaterialBid(material: .fine, units: 13, bidPrice: 35))

        XCTAssertFalse(bidSession.isWithinPerGradeLimit(for: 2))
    }

    func testBidStatusTransitionsAndSerialization() throws {
        var bidSession = EDPlayerBidSession(monthIndex: 1)
        XCTAssertEqual(bidSession.status, .thinking)

        bidSession.setReady()
        XCTAssertEqual(bidSession.status, .ready)

        bidSession.reset()
        XCTAssertEqual(bidSession.status, .thinking)
        XCTAssertTrue(bidSession.rawMaterialBids.isEmpty)

        let encoded = try JSONEncoder().encode(bidSession)
        let decoded = try JSONDecoder().decode(EDPlayerBidSession.self, from: encoded)

        XCTAssertEqual(decoded, bidSession)
    }
}
