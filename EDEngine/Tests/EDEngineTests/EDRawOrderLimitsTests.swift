import Testing
@testable import EDEngine

@Suite("Raw order limits")
struct EDRawOrderLimitsTests {
    @Test("Total limits match the player-count rules")
    func totalLimitsMatchRules() throws {
        let expectedLimits = [
            2: 18,
            3: 12,
            4: 9,
            5: 7,
            6: 6
        ]

        for (playerCount, maximumUnits) in expectedLimits {
            let limits = try EDGameConfig(playerCount: playerCount).rawOrderLimits
            #expect(limits.maximumTotalUnitsPerPlayer == maximumUnits)
        }
    }

    @Test("Only two-player games have a per-grade limit")
    func perGradeLimitMatchesRules() throws {
        for playerCount in 2...6 {
            let limits = try EDGameConfig(playerCount: playerCount).rawOrderLimits
            #expect(limits.maximumUnitsPerGrade == (playerCount == 2 ? 12 : nil))
        }
    }

    @Test("Orders at the total limit are allowed and excess is rejected")
    func totalOrderLimitIsEnforced() throws {
        let expectedLimits = [2: 18, 3: 12, 4: 9, 5: 7, 6: 6]

        for (playerCount, maximumUnits) in expectedLimits {
            let limits = try EDGameConfig(playerCount: playerCount).rawOrderLimits
            let allowedOrder: [EDRawMaterialGrade: Int]
            let excessiveOrder: [EDRawMaterialGrade: Int]
            if playerCount == 2 {
                allowedOrder = [.xfine: 12, .fine: maximumUnits - 12]
                excessiveOrder = [.xfine: 12, .fine: maximumUnits - 11]
            } else {
                allowedOrder = [.fine: maximumUnits]
                excessiveOrder = [.fine: maximumUnits + 1]
            }

            #expect(limits.allowsOrder(unitsByGrade: allowedOrder))
            #expect(!limits.allowsOrder(unitsByGrade: excessiveOrder))
        }
    }

    @Test("Two-player orders enforce both total and per-grade limits")
    func twoPlayerLimitsAreEnforced() throws {
        let limits = try EDGameConfig(playerCount: 2).rawOrderLimits

        #expect(limits.allowsOrder(unitsByGrade: [.xfine: 12, .fine: 6]))
        #expect(!limits.allowsOrder(unitsByGrade: [.xfine: 13, .fine: 5]))
        #expect(!limits.allowsOrder(unitsByGrade: [.xfine: 12, .fine: 7]))
    }

    @Test("Passing and zero-unit orders are allowed")
    func zeroUnitOrdersAreAllowed() throws {
        let limits = try EDGameConfig(playerCount: 2).rawOrderLimits

        #expect(limits.allowsOrder(unitsByGrade: [:]))
        #expect(limits.allowsOrder(unitsByGrade: [.standard: 0]))
    }

    @Test("Negative and overflowing orders are rejected")
    func invalidUnitCountsAreRejected() throws {
        let limits = try EDGameConfig(playerCount: 3).rawOrderLimits

        #expect(!limits.allowsOrder(unitsByGrade: [.fine: -1]))
        #expect(!limits.allowsOrder(unitsByGrade: [.xfine: Int.max, .standard: 1]))
    }
}
