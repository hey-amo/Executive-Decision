/// Errors raised when validating or updating market prices.
public enum EDPriceBoardError: Error, Equatable, Sendable {
    /// Rules: Market prices and their configured floors must be at least $1.
    case invalidPrice(Int)

    /// Rules: Applying a market movement must not overflow a price value.
    case priceOverflow
}

/// Minimum prices applied when a market movement is resolved.
///
/// Rules: Raw-material prices have a $1 minimum. Finished-good prices use a
/// $1 minimum by default.
public struct EDPriceFloorPolicy: Codable, Equatable, Hashable, Sendable {
    public let rawMaterialMinimum: Int
    public let finishedGoodMinimum: Int

    private enum CodingKeys: String, CodingKey {
        case rawMaterialMinimum
        case finishedGoodMinimum
    }

    /// Creates a floor policy with positive minimum prices.
    ///
    /// Rules: Raw-material prices cannot fall below $1, and finished-good
    /// prices default to a $1 minimum.
    public init(
        rawMaterialMinimum: Int = 1,
        finishedGoodMinimum: Int = 1
    ) throws(EDPriceBoardError) {
        guard rawMaterialMinimum >= 1 else {
            throw .invalidPrice(rawMaterialMinimum)
        }
        guard finishedGoodMinimum >= 1 else {
            throw .invalidPrice(finishedGoodMinimum)
        }
        self.rawMaterialMinimum = rawMaterialMinimum
        self.finishedGoodMinimum = finishedGoodMinimum
    }

    /// The standard game price floors.
    public static let standard = Self(
        uncheckedRawMaterialMinimum: 1,
        finishedGoodMinimum: 1
    )

    private init(
        uncheckedRawMaterialMinimum rawMaterialMinimum: Int,
        finishedGoodMinimum: Int
    ) {
        self.rawMaterialMinimum = rawMaterialMinimum
        self.finishedGoodMinimum = finishedGoodMinimum
    }

    /// Decodes a policy while validating both positive minimum prices.
    ///
    /// Rules: Raw-material and finished-good price floors must be at least $1.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawMaterialMinimum = try container.decode(Int.self, forKey: .rawMaterialMinimum)
        let finishedGoodMinimum = try container.decode(Int.self, forKey: .finishedGoodMinimum)

        do {
            try self.init(
                rawMaterialMinimum: rawMaterialMinimum,
                finishedGoodMinimum: finishedGoodMinimum
            )
        } catch {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Price floors must be at least $1."
                )
            )
        }
    }
}

/// Market movement to apply to each raw-material grade and finished good.
public struct EDPriceMovement: Codable, Equatable, Hashable, Sendable {
    public let rawMaterials: [EDRawMaterialGrade: Int]
    public let finishedGoods: [EDRecipe: Int]

    /// Creates a movement value. Unspecified entries have no movement.
    ///
    /// Rules: Market Calculator. Movement is applied independently to each
    /// raw-material grade and finished good.
    public init(
        rawMaterials: [EDRawMaterialGrade: Int] = [:],
        finishedGoods: [EDRecipe: Int] = [:]
    ) {
        self.rawMaterials = rawMaterials
        self.finishedGoods = finishedGoods
    }
}

/// The market prices recorded at the end of one month.
public struct EDPriceBoardSnapshot: Codable, Equatable, Hashable, Sendable {
    public let rawMaterialPrices: [EDRawMaterialGrade: Int]
    public let finishedGoodPrices: [EDRecipe: Int]

    private enum CodingKeys: String, CodingKey {
        case rawMaterialPrices
        case finishedGoodPrices
    }

    fileprivate init(
        rawMaterialPrices: [EDRawMaterialGrade: Int],
        finishedGoodPrices: [EDRecipe: Int]
    ) {
        self.rawMaterialPrices = rawMaterialPrices
        self.finishedGoodPrices = finishedGoodPrices
    }

    /// Decodes a monthly snapshot while validating every market price.
    ///
    /// Rules: Recorded market prices cannot be below $1.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawMaterialPrices = try container.decode(
            [EDRawMaterialGrade: Int].self,
            forKey: .rawMaterialPrices
        )
        let finishedGoodPrices = try container.decode(
            [EDRecipe: Int].self,
            forKey: .finishedGoodPrices
        )

        do {
            try EDPriceBoard.validate(rawMaterialPrices: rawMaterialPrices)
            try EDPriceBoard.validate(finishedGoodPrices: finishedGoodPrices)
        } catch {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Price snapshot contains an invalid price."
                )
            )
        }
        self.init(
            rawMaterialPrices: rawMaterialPrices,
            finishedGoodPrices: finishedGoodPrices
        )
    }
}

/// Current raw-material and finished-good market prices.
///
/// Rules: FR-2 Opening prices, FR-4 movements applied to previous prices, and
/// FR-7/FR-11 market resolution. Each resolved month appends its closing prices
/// to `history`; the opening prices are held as current prices, not as a month.
public struct EDPriceBoard: Codable, Equatable, Hashable, Sendable {
    public private(set) var rawMaterialPrices: [EDRawMaterialGrade: Int]
    public private(set) var finishedGoodPrices: [EDRecipe: Int]
    public private(set) var history: [EDPriceBoardSnapshot]

    private enum CodingKeys: String, CodingKey {
        case rawMaterialPrices
        case finishedGoodPrices
        case history
    }

    /// Creates a price board with the game's opening market prices.
    ///
    /// Rules: FR-2 Opening prices.
    public init() {
        rawMaterialPrices = Dictionary(
            uniqueKeysWithValues: EDRawMaterialGrade.allCases.map {
                ($0, EDOpeningPrices.rawMaterialPrice(for: $0))
            }
        )
        finishedGoodPrices = Dictionary(
            uniqueKeysWithValues: EDRecipe.allCases.map {
                ($0, EDOpeningPrices.finishedGoodPrice(for: $0))
            }
        )
        history = []
    }

    /// Creates a board from explicit current prices.
    ///
    /// Rules: FR-2 Opening prices. Each market must have a positive price for
    /// every raw-material grade and finished good.
    public init(
        rawMaterialPrices: [EDRawMaterialGrade: Int],
        finishedGoodPrices: [EDRecipe: Int]
    ) throws(EDPriceBoardError) {
        try Self.validate(rawMaterialPrices: rawMaterialPrices)
        try Self.validate(finishedGoodPrices: finishedGoodPrices)
        self.rawMaterialPrices = rawMaterialPrices
        self.finishedGoodPrices = finishedGoodPrices
        history = []
    }

    /// Returns the current market price for a raw-material grade.
    ///
    /// Rules: Raw-material prices are tracked independently by grade.
    public func price(for grade: EDRawMaterialGrade) -> Int {
        rawMaterialPrices[grade, default: 0]
    }

    /// Returns the current market price for a finished good.
    ///
    /// Rules: Finished-good prices are tracked independently by type.
    public func price(for good: EDRecipe) -> Int {
        finishedGoodPrices[good, default: 0]
    }

    /// Applies monthly movement, then returns a new board with the closing
    /// prices appended to its history.
    ///
    /// Rules: FR-4 movement is applied to the previous market price; FR-7 and
    /// FR-11 use a $1 price floor by default.
    public func applying(
        movement: EDPriceMovement,
        floorPolicy: EDPriceFloorPolicy = .standard
    ) throws(EDPriceBoardError) -> Self {
        var updatedRawPrices: [EDRawMaterialGrade: Int] = [:]
        for grade in EDRawMaterialGrade.allCases {
            updatedRawPrices[grade] = try Self.applying(
                movement.rawMaterials[grade, default: 0],
                to: price(for: grade),
                withMinimum: floorPolicy.rawMaterialMinimum
            )
        }

        var updatedGoodPrices: [EDRecipe: Int] = [:]
        for good in EDRecipe.allCases {
            updatedGoodPrices[good] = try Self.applying(
                movement.finishedGoods[good, default: 0],
                to: price(for: good),
                withMinimum: floorPolicy.finishedGoodMinimum
            )
        }

        var updatedBoard = self
        updatedBoard.rawMaterialPrices = updatedRawPrices
        updatedBoard.finishedGoodPrices = updatedGoodPrices
        updatedBoard.history.append(
            EDPriceBoardSnapshot(
                rawMaterialPrices: updatedRawPrices,
                finishedGoodPrices: updatedGoodPrices
            )
        )
        return updatedBoard
    }

    /// Decodes a board and validates current and historical prices.
    ///
    /// Rules: FR-16 Persistence restores valid market prices and monthly history.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawMaterialPrices = try container.decode(
            [EDRawMaterialGrade: Int].self,
            forKey: .rawMaterialPrices
        )
        let finishedGoodPrices = try container.decode(
            [EDRecipe: Int].self,
            forKey: .finishedGoodPrices
        )
        let history = try container.decode([EDPriceBoardSnapshot].self, forKey: .history)

        do {
            try Self.validate(rawMaterialPrices: rawMaterialPrices)
            try Self.validate(finishedGoodPrices: finishedGoodPrices)
            for snapshot in history {
                try Self.validate(rawMaterialPrices: snapshot.rawMaterialPrices)
                try Self.validate(finishedGoodPrices: snapshot.finishedGoodPrices)
            }
        } catch {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Price board contains an invalid price."
                )
            )
        }

        self.rawMaterialPrices = rawMaterialPrices
        self.finishedGoodPrices = finishedGoodPrices
        self.history = history
    }

    private static func applying(
        _ movement: Int,
        to previousPrice: Int,
        withMinimum minimum: Int
    ) throws(EDPriceBoardError) -> Int {
        let (price, overflow) = previousPrice.addingReportingOverflow(movement)
        guard !overflow else {
            throw .priceOverflow
        }
        return max(minimum, price)
    }

    fileprivate static func validate(
        rawMaterialPrices: [EDRawMaterialGrade: Int]
    ) throws(EDPriceBoardError) {
        for grade in EDRawMaterialGrade.allCases {
            guard let price = rawMaterialPrices[grade], price >= 1 else {
                throw .invalidPrice(rawMaterialPrices[grade, default: 0])
            }
        }
    }

    fileprivate static func validate(
        finishedGoodPrices: [EDRecipe: Int]
    ) throws(EDPriceBoardError) {
        for good in EDRecipe.allCases {
            guard let price = finishedGoodPrices[good], price >= 1 else {
                throw .invalidPrice(finishedGoodPrices[good, default: 0])
            }
        }
    }
}
