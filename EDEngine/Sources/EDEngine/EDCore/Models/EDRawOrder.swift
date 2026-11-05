/// Errors raised when constructing or inspecting a raw-material order.
public enum EDRawOrderError: Error, Equatable, Sendable {
    /// Rules: FR-5 Raw order limits. Order unit counts cannot be negative.
    case negativeUnits(grade: EDRawMaterialGrade, units: Int)

    /// Rules: Purchasing Raw Materials. A bid price cannot be negative.
    case negativeBid(grade: EDRawMaterialGrade, bid: Int)

    /// Rules: FR-5 Raw order limits. Total units must fit in an integer.
    case totalUnitsOverflow
}

/// One player's raw-material bids for a month.
///
/// Rules: Purchasing Raw Materials. A player submits units and a bid price for
/// each raw-material grade. Player-wide caps and minimum bid requirements are
/// validated separately by raw-order rules.
public struct EDRawOrder: Codable, Equatable, Hashable, Sendable {
    public private(set) var unitsByGrade: [EDRawMaterialGrade: Int]
    public private(set) var bidsByGrade: [EDRawMaterialGrade: Int]

    private enum CodingKeys: String, CodingKey {
        case unitsByGrade
        case bidsByGrade
    }

    /// Creates an order with grade-specific unit counts and bid prices.
    ///
    /// Rules: Purchasing Raw Materials. Each grade has its own unit count and
    /// per-unit bid; omitted grades default to zero units and a zero bid.
    public init(
        unitsByGrade: [EDRawMaterialGrade: Int] = [:],
        bidsByGrade: [EDRawMaterialGrade: Int] = [:]
    ) throws(EDRawOrderError) {
        for grade in EDRawMaterialGrade.allCases {
            let units = unitsByGrade[grade, default: 0]
            guard units >= 0 else {
                throw .negativeUnits(grade: grade, units: units)
            }

            let bid = bidsByGrade[grade, default: 0]
            guard bid >= 0 else {
                throw .negativeBid(grade: grade, bid: bid)
            }
        }

        self.unitsByGrade = Dictionary(
            uniqueKeysWithValues: EDRawMaterialGrade.allCases.map {
                ($0, unitsByGrade[$0, default: 0])
            }
        )
        self.bidsByGrade = Dictionary(
            uniqueKeysWithValues: EDRawMaterialGrade.allCases.map {
                ($0, bidsByGrade[$0, default: 0])
            }
        )
    }

    /// Returns units ordered for a grade.
    ///
    /// Rules: Purchasing Raw Materials tracks the requested units by grade.
    public func units(for grade: EDRawMaterialGrade) -> Int {
        unitsByGrade[grade, default: 0]
    }

    /// Returns the per-unit bid for a grade.
    ///
    /// Rules: Purchasing Raw Materials records a separate bid price for each
    /// raw-material grade.
    public func bid(for grade: EDRawMaterialGrade) -> Int {
        bidsByGrade[grade, default: 0]
    }

    /// Returns the total units in the order, reporting integer overflow.
    ///
    /// Rules: FR-5 Raw order limits count all grades toward the player's total
    /// monthly order.
    public func totalUnits() throws(EDRawOrderError) -> Int {
        var total = 0
        for grade in EDRawMaterialGrade.allCases {
            let (newTotal, overflow) = total.addingReportingOverflow(units(for: grade))
            guard !overflow else {
                throw .totalUnitsOverflow
            }
            total = newTotal
        }
        return total
    }

    /// Decodes an order and validates nonnegative units and bids.
    ///
    /// Rules: FR-5 Raw order units are nonnegative; bids cannot be negative.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let unitsByGrade = try container.decodeIfPresent(
            [EDRawMaterialGrade: Int].self,
            forKey: .unitsByGrade
        ) ?? [:]
        let bidsByGrade = try container.decodeIfPresent(
            [EDRawMaterialGrade: Int].self,
            forKey: .bidsByGrade
        ) ?? [:]

        do {
            try self.init(unitsByGrade: unitsByGrade, bidsByGrade: bidsByGrade)
        } catch {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Raw order units and bids cannot be negative."
                )
            )
        }
    }
}
