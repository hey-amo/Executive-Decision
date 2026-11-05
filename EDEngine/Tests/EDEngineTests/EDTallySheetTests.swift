import Foundation
import Testing
@testable import EDEngine

@Suite("Tally sheet")
struct EDTallySheetTests {
    @Test("Creates a 12-month sheet with empty rows for each grade and good")
    func createsDefaultSheet() throws {
        let sheet = try EDTallySheet()

        #expect(sheet.months.count == 12)
        #expect(sheet.months[0].rawOrders.count == EDRawMaterialGrade.allCases.count)
        #expect(sheet.months[0].finishedGoodSales.count == EDRecipe.allCases.count)
        #expect(sheet.months[0].rawOrders[.xfine] == EDRawMaterialTally())
        #expect(sheet.months[0].finishedGoodSales[.a] == EDFinishedGoodTally())
    }

    @Test("Records raw orders and finished-good sales in the selected month")
    func recordsMonthlyEntries() throws {
        var sheet = try EDTallySheet(monthCount: 6)
        let rawOrder = EDRawMaterialTally(units: 3, bidPrice: 40, amountPaid: 120)
        let sale = EDFinishedGoodTally(units: 2, askingPrice: 140, amountReceived: 280)

        try sheet.recordRawOrder(rawOrder, for: .xfine, inMonth: 1)
        try sheet.recordFinishedGoodSale(sale, for: .a, inMonth: 6)

        #expect(sheet.months[0].rawOrders[.xfine] == rawOrder)
        #expect(sheet.months[5].finishedGoodSales[.a] == sale)
        #expect(sheet.months[0].finishedGoodSales[.a] == EDFinishedGoodTally())
        #expect(sheet.months[5].rawOrders[.xfine] == EDRawMaterialTally())
    }

    @Test("Rejects empty sheet and out-of-range months")
    func rejectsInvalidMonthCountsAndIndices() throws {
        #expect(throws: EDTallySheetError.invalidMonthCount(0)) {
            try EDTallySheet(monthCount: 0)
        }
        #expect(throws: EDTallySheetError.invalidMonthCount(-1)) {
            try EDTallySheet(monthCount: -1)
        }

        var sheet = try EDTallySheet(monthCount: 2)
        #expect(throws: EDTallySheetError.monthOutOfRange(0)) {
            try sheet.recordRawOrder(EDRawMaterialTally(), for: .fine, inMonth: 0)
        }
        #expect(throws: EDTallySheetError.monthOutOfRange(3)) {
            try sheet.recordFinishedGoodSale(EDFinishedGoodTally(), for: .b, inMonth: 3)
        }
        #expect(sheet.months.count == 2)
    }

    @Test("Round-trips tally sheet data through Codable")
    func tallySheetCanBeEncodedAndDecoded() throws {
        var sheet = try EDTallySheet(monthCount: 1)
        try sheet.recordRawOrder(
            EDRawMaterialTally(units: 2, bidPrice: 38, amountPaid: 76),
            for: .fine,
            inMonth: 1
        )
        try sheet.recordFinishedGoodSale(
            EDFinishedGoodTally(units: 1, askingPrice: 135, amountReceived: 135),
            for: .c,
            inMonth: 1
        )

        let data = try JSONEncoder().encode(sheet)
        let decoded = try JSONDecoder().decode(EDTallySheet.self, from: data)

        #expect(decoded == sheet)
    }

    @Test("Each player maintains a separate private tally sheet")
    func playersKeepSeparateTallySheets() async throws {
        let first = try EDPlayer(name: "Alex")
        let second = try EDPlayer(name: "Sam")

        try await first.recordRawOrder(
            EDRawMaterialTally(units: 2, bidPrice: 40, amountPaid: 80),
            for: .xfine,
            inMonth: 1
        )

        let firstSheet = await first.tallySheetSnapshot()
        let secondSheet = await second.tallySheetSnapshot()
        #expect(firstSheet.months[0].rawOrders[.xfine]?.units == 2)
        #expect(secondSheet.months[0].rawOrders[.xfine] == EDRawMaterialTally())
    }
}
