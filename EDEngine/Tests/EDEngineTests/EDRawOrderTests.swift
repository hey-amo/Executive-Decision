import Foundation
import Testing
@testable import EDEngine

@Suite("Raw-material orders")
struct EDRawOrderTests {
    @Test("Stores units and bids independently for each grade")
    func storesGradeOrders() throws {
        let order = try EDRawOrder(
            unitsByGrade: [.extraFine: 2, .fine: 3],
            bidsByGrade: [.extraFine: 40, .fine: 31]
        )

        #expect(order.units(for: .extraFine) == 2)
        #expect(order.units(for: .fine) == 3)
        #expect(order.units(for: .standard) == 0)
        #expect(order.bid(for: .extraFine) == 40)
        #expect(order.bid(for: .fine) == 31)
        #expect(order.bid(for: .standard) == 0)
        #expect(order.unitsByGrade == [.extraFine: 2, .fine: 3, .standard: 0])
        #expect(order.bidsByGrade == [.extraFine: 40, .fine: 31, .standard: 0])
    }

    @Test("Defaults to a passing order with zero units")
    func emptyOrderHasZeroTotals() throws {
        let order = try EDRawOrder()

        #expect(try order.totalUnits() == 0)
        #expect(order.unitsByGrade.values.allSatisfy { $0 == 0 })
        #expect(order.bidsByGrade.values.allSatisfy { $0 == 0 })
    }

    @Test("Totals unit counts across grades")
    func totalsUnits() throws {
        let order = try EDRawOrder(
            unitsByGrade: [.extraFine: 12, .fine: 5, .standard: 1]
        )

        #expect(try order.totalUnits() == 18)
    }

    @Test("Rejects negative unit counts and bid prices")
    func rejectsNegativeValues() {
        #expect(throws: EDRawOrderError.negativeUnits(grade: .fine, units: -1)) {
            try EDRawOrder(unitsByGrade: [.fine: -1])
        }
        #expect(throws: EDRawOrderError.negativeBid(grade: .standard, bid: -10)) {
            try EDRawOrder(bidsByGrade: [.standard: -10])
        }
    }

    @Test("Reports overflow when summing large grade orders")
    func reportsTotalOverflow() throws {
        let order = try EDRawOrder(
            unitsByGrade: [.extraFine: Int.max, .standard: 1]
        )

        #expect(throws: EDRawOrderError.totalUnitsOverflow) {
            try order.totalUnits()
        }
    }

    @Test("Codable round-trips orders and rejects negative persisted values")
    func codableValidation() throws {
        let order = try EDRawOrder(
            unitsByGrade: [.extraFine: 2, .standard: 4],
            bidsByGrade: [.extraFine: 55, .standard: 20]
        )
        let data = try JSONEncoder().encode(order)
        #expect(try JSONDecoder().decode(EDRawOrder.self, from: data) == order)

        let invalid = #"{"unitsByGrade":{"fine":-1},"bidsByGrade":{}}"#
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(EDRawOrder.self, from: Data(invalid.utf8))
        }
    }
}
