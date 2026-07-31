import XCTest
@testable import EDEngine

final class EDErrorTests: XCTestCase {

    func testValueErrorProvidesLocalizedDescriptions() {
        let numericError = EDValueError.numericBelowZero(value: -3)
        XCTAssertEqual(numericError.localizedDescription, "Numeric value cannot be below zero.")
        XCTAssertEqual(numericError.localizedFailureReason, "Cannot use negative value: -3.")
        XCTAssertEqual(numericError.localizedRecoverySuggestion, "Use a non-negative value.")

        let fundsError = EDValueError.insufficientFunds(required: 50, available: 20)
        XCTAssertEqual(fundsError.localizedDescription, "Not enough funds available.")
        XCTAssertEqual(fundsError.localizedFailureReason, "You don't have enough funds. Required: 50, available: 20.")
        XCTAssertEqual(fundsError.localizedRecoverySuggestion, "Gather more funds or reduce your required amount.")
    }

    func testGameErrorDefaultsProvideFallbackDescriptions() {
        struct TestGameError: EDGameError {}

        let error = TestGameError()
        XCTAssertEqual(error.localizedDescription, "An unexpected game error occurred.")
        XCTAssertEqual(error.localizedFailureReason, "The operation could not be completed.")
        XCTAssertEqual(error.localizedRecoverySuggestion, "Please try again or contact support if the issue persists.")
    }

}