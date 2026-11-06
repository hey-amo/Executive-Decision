/// Raw-material order limits derived from a validated game configuration.
///
/// Rules: FR-5. Monthly order caps depend on player count, with an additional
/// per-grade cap in two-player games.
public struct EDRawOrderLimits: Equatable, Hashable, Sendable {
    /// Maximum total raw-material units one player may order in a month.
    ///
    /// Rules: FR-5 Raw order limits.
    public let maximumTotalUnitsPerPlayer: Int

    /// Maximum units of one grade in a two-player game; `nil` otherwise.
    ///
    /// Rules: FR-5 Raw order limits.
    public let maximumUnitsPerGrade: Int?

    init(maximumTotalUnitsPerPlayer: Int, maximumUnitsPerGrade: Int?) {
        self.maximumTotalUnitsPerPlayer = maximumTotalUnitsPerPlayer
        self.maximumUnitsPerGrade = maximumUnitsPerGrade
    }

    /// Returns whether a per-grade order is within the game's limits.
    ///
    /// Missing grades count as zero. Negative units, totals above the per-player
    /// limit, and two-player per-grade excesses are invalid.
    ///
    /// Rules: FR-5 Raw order limits.
    public func allowsOrder(unitsByGrade: [EDRawMaterialGrade: Int]) -> Bool {
        var totalUnits = 0

        for grade in EDRawMaterialGrade.allCases {
            let units = unitsByGrade[grade, default: 0]
            guard units >= 0 else {
                return false
            }
            if let maximumUnitsPerGrade, units > maximumUnitsPerGrade {
                return false
            }

            let (newTotal, overflow) = totalUnits.addingReportingOverflow(units)
            guard !overflow, newTotal <= maximumTotalUnitsPerPlayer else {
                return false
            }
            totalUnits = newTotal
        }

        return true
    }
}
