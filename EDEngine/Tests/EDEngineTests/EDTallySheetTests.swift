import XCTest
@testable import EDEngine

final class EDTallySheetTests: XCTestCase {
    func testMonthlyTotalsUsePurchasedAndSoldUnitsAtBidPrices() {
        let tally = EDMonthlyTally(
            month: .january,
            orders: [
                .extraFine: EDOrderEntry(unitsOrdered: 3, bidPrice: 40, unitsPurchased: 2),
                .fine: EDOrderEntry(unitsOrdered: 2, bidPrice: 30, unitsPurchased: 2),
                .standard: EDOrderEntry(unitsOrdered: 1, bidPrice: 20, unitsPurchased: 0)
            ],
            sales: [
                .a: EDSaleEntry(unitsOffered: 2, askingPrice: 140, unitsSold: 1),
                .c: EDSaleEntry(unitsOffered: 3, askingPrice: 90, unitsSold: 2)
            ]
        )

        XCTAssertEqual(tally.totals, EDTallyTotals(orders: 140, sales: 320))
        XCTAssertEqual(tally.totals.net, 180)
    }

    func testYearlyTotalsCombineRecordedMonthlyTotals() throws {
        var sheet = EDTallySheet()
        try sheet.record(
            EDMonthlyTally(
                month: .january,
                orders: [.fine: EDOrderEntry(unitsOrdered: 2, bidPrice: 30, unitsPurchased: 2)],
                sales: [.a: EDSaleEntry(unitsOffered: 1, askingPrice: 140, unitsSold: 1)]
            )
        )
        try sheet.record(
            EDMonthlyTally(
                month: .february,
                orders: [.standard: EDOrderEntry(unitsOrdered: 3, bidPrice: 20, unitsPurchased: 1)],
                sales: [.b: EDSaleEntry(unitsOffered: 2, askingPrice: 115, unitsSold: 2)]
            )
        )

        XCTAssertEqual(sheet.totals(for: .january), EDTallyTotals(orders: 60, sales: 140))
        XCTAssertEqual(sheet.totals(for: .february), EDTallyTotals(orders: 20, sales: 230))
        XCTAssertEqual(sheet.totals(for: .march), EDTallyTotals(orders: 0, sales: 0))
        XCTAssertEqual(sheet.yearlyTotals, EDTallyTotals(orders: 80, sales: 370))
        XCTAssertEqual(sheet.yearlyTotals.net, 290)
    }

    func testCannotRecordMonthMoreThanOnce() throws {
        var sheet = EDTallySheet()
        let january = EDMonthlyTally(
            month: .january,
            orders: [.fine: EDOrderEntry(unitsOrdered: 1, bidPrice: 30, unitsPurchased: 1)]
        )
        try sheet.record(january)

        XCTAssertThrowsError(try sheet.record(january)) { error in
            XCTAssertEqual(error as? EDTallySheetError, .monthAlreadyRecorded(.january))
        }
        XCTAssertEqual(sheet.totals(for: .january), EDTallyTotals(orders: 30, sales: 0))
    }

    func testEachPlayerHasTheirOwnTallySheet() throws {
        let firstPlayer = EDPlayer(name: "First")
        let secondPlayer = EDPlayer(name: "Second")
        try firstPlayer.tallySheet.record(
            EDMonthlyTally(
                month: .january,
                sales: [.a: EDSaleEntry(unitsOffered: 1, askingPrice: 140, unitsSold: 1)]
            )
        )

        XCTAssertEqual(firstPlayer.tallySheet.yearlyTotals.sales, 140)
        XCTAssertEqual(secondPlayer.tallySheet.yearlyTotals.sales, 0)
    }
}
