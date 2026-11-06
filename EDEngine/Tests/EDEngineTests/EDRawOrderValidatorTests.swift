import Testing
@testable import EDEngine

@Suite("Raw order validator")
struct EDRawOrderValidatorTests {
    @Test("Accepts orders at total and two-player per-grade caps")
    func acceptsOrdersAtLimits() throws {
        let limits = try EDGameConfig(playerCount: 2).rawOrderLimits
        let order = try EDRawOrder(
            unitsByGrade: [.xfine: 12, .fine: 6],
            bidsByGrade: [.xfine: 42, .fine: 36]
        )

        try EDRawOrderValidator.validate(
            order,
            limits: limits,
            previousPrices: [.xfine: 40, .fine: 30]
        )
    }

    @Test("Rejects an order above the total-unit cap")
    func rejectsTotalLimitExcess() throws {
        let limits = try EDGameConfig(playerCount: 3).rawOrderLimits
        let order = try EDRawOrder(
            unitsByGrade: [.xfine: 8, .fine: 5],
            bidsByGrade: [.xfine: 100, .fine: 100]
        )

        #expect(throws: EDRawOrderValidationError.orderExceedsLimits) {
            try EDRawOrderValidator.validate(order, limits: limits, previousPrices: [:])
        }
    }

    @Test("Rejects a two-player per-grade cap excess")
    func rejectsPerGradeLimitExcess() throws {
        let limits = try EDGameConfig(playerCount: 2).rawOrderLimits
        let order = try EDRawOrder(
            unitsByGrade: [.xfine: 13],
            bidsByGrade: [.xfine: 100]
        )

        #expect(throws: EDRawOrderValidationError.orderExceedsLimits) {
            try EDRawOrderValidator.validate(order, limits: limits, previousPrices: [:])
        }
    }

    @Test("Accepts a bid exactly at the minimum based on the player's units")
    func acceptsMinimumBid() throws {
        let limits = try EDGameConfig(playerCount: 3).rawOrderLimits
        let order = try EDRawOrder(
            unitsByGrade: [.fine: 3],
            bidsByGrade: [.fine: 23]
        )

        try EDRawOrderValidator.validate(
            order,
            limits: limits,
            previousPrices: [.fine: 30]
        )
    }

    @Test("Rejects a bid below the minimum based on the player's units")
    func rejectsBidBelowMinimum() throws {
        let limits = try EDGameConfig(playerCount: 3).rawOrderLimits
        let order = try EDRawOrder(
            unitsByGrade: [.fine: 3],
            bidsByGrade: [.fine: 22]
        )

        #expect(throws: EDRawOrderValidationError.bidBelowMinimum(
            grade: .fine,
            bid: 22,
            minimum: 23
        )) {
            try EDRawOrderValidator.validate(
                order,
                limits: limits,
                previousPrices: [.fine: 30]
            )
        }
    }

    @Test("Zero-unit grades do not require a previous price or minimum bid")
    func skipsMinimumForZeroUnits() throws {
        let limits = try EDGameConfig(playerCount: 3).rawOrderLimits
        let order = try EDRawOrder(bidsByGrade: [.standard: 0])

        try EDRawOrderValidator.validate(order, limits: limits, previousPrices: [:])
    }

    @Test("Positive-unit grades require a previous price")
    func requiresPreviousPriceForOrderedGrade() throws {
        let limits = try EDGameConfig(playerCount: 3).rawOrderLimits
        let order = try EDRawOrder(
            unitsByGrade: [.standard: 1],
            bidsByGrade: [.standard: 100]
        )

        #expect(throws: EDRawOrderValidationError.missingPreviousPrice(grade: .standard)) {
            try EDRawOrderValidator.validate(order, limits: limits, previousPrices: [:])
        }
    }

    @Test("Reports order-total overflow")
    func reportsTotalOverflow() throws {
        let limits = try EDGameConfig(playerCount: 3).rawOrderLimits
        let order = try EDRawOrder(unitsByGrade: [.xfine: Int.max, .standard: 1])

        #expect(throws: EDRawOrderValidationError.totalUnitsOverflow) {
            try EDRawOrderValidator.validate(order, limits: limits, previousPrices: [:])
        }
    }

    @Test("Reports minimum-bid price overflow")
    func reportsMinimumBidPriceOverflow() throws {
        let limits = try EDGameConfig(playerCount: 3).rawOrderLimits
        let order = try EDRawOrder(
            unitsByGrade: [.fine: 1],
            bidsByGrade: [.fine: 0]
        )

        #expect(throws: EDRawOrderValidationError.minimumBidPriceOverflow(grade: .fine)) {
            try EDRawOrderValidator.validate(
                order,
                limits: limits,
                previousPrices: [.fine: Int.min]
            )
        }
    }
}
