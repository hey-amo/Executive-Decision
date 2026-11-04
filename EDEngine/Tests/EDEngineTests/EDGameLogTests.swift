import XCTest
@testable import EDEngine

final class EDGameLogTests: XCTestCase {
    func testCanAddEntry() {
        var log = EDGameLog()

        log.addEntry(type: .success, message: "Purchase completed")

        XCTAssertEqual(log.entries.count, 1)
        XCTAssertEqual(log.entries.first?.type, .success)
        XCTAssertEqual(log.entries.first?.message, "Purchase completed")
    }

    func testMaximumEntriesRetainsNewestEntries() {
        var log = EDGameLog()

        for index in 0...100 {
            log.addEntry(type: .info, message: "Entry \(index)")
        }

        XCTAssertEqual(log.entries.count, 100)
        XCTAssertEqual(log.entries.first?.message, "Entry 1")
        XCTAssertEqual(log.entries.last?.message, "Entry 100")
    }

    func testClearRemovesAllEntries() {
        var log = EDGameLog()
        log.addEntry(type: .info, message: "First entry")
        log.addEntry(type: .warning, message: "Second entry")

        log.clear()

        XCTAssertTrue(log.entries.isEmpty)
    }
}
