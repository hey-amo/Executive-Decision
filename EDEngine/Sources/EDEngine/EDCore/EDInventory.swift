// EDInventory.swift — raw certificate counts and inventory operations. 

/// Errors raised by raw-certificate inventory operations.
public enum EDInventoryError: Error, Equatable, Sendable {
    /// Rules: Raw-material certificates cannot have negative counts.
    case negativeCertificateCount(grade: EDRawMaterialGrade, count: Int)

    /// Rules: Inventory operations cannot use negative unit counts.
    case negativeUnitCount(Int)

    /// Rules: A player cannot remove more certificates than they hold.
    case insufficientCertificates(
        grade: EDRawMaterialGrade,
        requested: Int,
        available: Int
    )

    /// Rules: Certificate counts must remain representable as integers.
    case certificateCountOverflow(grade: EDRawMaterialGrade)

    /// Rules: Manufacturing requires the recipe's materials, allowing only
    /// substitutions from a higher grade to a lower grade.
    case insufficientMaterials(recipe: EDRecipe, units: Int)
}

/// A player's raw-material certificate counts.
///
/// Rules: FR-9 Manufacturing and FR-11 Goods sales. Higher-grade certificates
/// may substitute for lower-grade requirements, and sold goods consume the
/// certificates used to make them.
public struct EDInventory: Codable, Equatable, Hashable, Sendable {
    private var extraFineCertificates: Int
    private var fineCertificates: Int
    private var standardCertificates: Int

    private enum CodingKeys: String, CodingKey {
        case extraFineCertificates
        case fineCertificates
        case standardCertificates
    }

    /// Creates an inventory with the supplied certificate counts.
    ///
    /// Rules: Raw-material certificates are counted by grade and cannot be
    /// negative.
    public init() {
        extraFineCertificates = 0
        fineCertificates = 0
        standardCertificates = 0
    }

    /// Creates an inventory with the supplied certificate counts.
    ///
    /// Rules: Raw-material certificates are counted by grade and cannot be
    /// negative.
    public init(
        certificatesByGrade: [EDRawMaterialGrade: Int]
    ) throws(EDInventoryError) {
        for grade in EDRawMaterialGrade.allCases {
            let count = certificatesByGrade[grade, default: 0]
            guard count >= 0 else {
                throw .negativeCertificateCount(grade: grade, count: count)
            }
        }

        extraFineCertificates = certificatesByGrade[.xfine, default: 0]
        fineCertificates = certificatesByGrade[.fine, default: 0]
        standardCertificates = certificatesByGrade[.standard, default: 0]
    }

    /// Returns the number of certificates held at the requested grade.
    ///
    /// Rules: Raw-material certificates are tracked separately by grade.
    public func count(of grade: EDRawMaterialGrade) -> Int {
        switch grade {
        case .xfine: extraFineCertificates
        case .fine: fineCertificates
        case .standard: standardCertificates
        }
    }

    /// Returns all certificate counts, including grades with zero certificates.
    ///
    /// Rules: Raw-material certificates are tracked separately by grade.
    public var certificatesByGrade: [EDRawMaterialGrade: Int] {
        [
            .xfine: extraFineCertificates,
            .fine: fineCertificates,
            .standard: standardCertificates
        ]
    }

    /// Adds certificates of one grade without changing inventory on failure.
    ///
    /// Rules: FR-8 Raw purchases add the purchased certificates to inventory.
    public mutating func add(
        _ count: Int,
        of grade: EDRawMaterialGrade
    ) throws(EDInventoryError) {
        guard count >= 0 else {
            throw .negativeUnitCount(count)
        }

        let (newCount, overflow) = self.count(of: grade).addingReportingOverflow(count)
        guard !overflow else {
            throw .certificateCountOverflow(grade: grade)
        }
        setCount(newCount, of: grade)
    }

    /// Removes certificates of one grade without changing inventory on failure.
    ///
    /// Rules: Raw certificates are spent when resolving purchases or consumed
    /// by production.
    public mutating func remove(
        _ count: Int,
        of grade: EDRawMaterialGrade
    ) throws(EDInventoryError) {
        guard count >= 0 else {
            throw .negativeUnitCount(count)
        }

        let available = self.count(of: grade)
        guard count <= available else {
            throw .insufficientCertificates(
                grade: grade,
                requested: count,
                available: available
            )
        }
        setCount(available - count, of: grade)
    }

    /// Returns whether the inventory can supply the requested number of goods.
    ///
    /// Rules: FR-9 Manufacturing permits only higher-to-lower grade
    /// substitutions.
    public func canProduce(_ recipe: EDRecipe, units: Int = 1) -> Bool {
        guard units >= 0 else {
            return false
        }
        return certificateUse(for: recipe, units: units) != nil
    }

    /// Consumes the certificates needed for sold goods, preserving inventory
    /// unchanged if the complete request cannot be met.
    ///
    /// Rules: FR-9 Manufacturing permits XFine for Fine and Fine for Standard;
    /// FR-11 sold goods consume their raw certificates.
    public mutating func consume(
        _ recipe: EDRecipe,
        units: Int = 1
    ) throws(EDInventoryError) {
        guard units >= 0 else {
            throw .negativeUnitCount(units)
        }
        guard let usedCertificates = certificateUse(for: recipe, units: units) else {
            throw .insufficientMaterials(recipe: recipe, units: units)
        }

        for grade in EDRawMaterialGrade.allCases {
            setCount(count(of: grade) - usedCertificates[grade, default: 0], of: grade)
        }
    }

    /// Decodes persisted inventory while validating certificate counts.
    ///
    /// Rules: FR-16 Persistence preserves valid game state; certificate counts
    /// cannot be negative.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let extraFine = try container.decodeIfPresent(Int.self, forKey: .extraFineCertificates) ?? 0
        let fine = try container.decodeIfPresent(Int.self, forKey: .fineCertificates) ?? 0
        let standard = try container.decodeIfPresent(Int.self, forKey: .standardCertificates) ?? 0

        do {
            try self.init(
                certificatesByGrade: [
                    .xfine: extraFine,
                    .fine: fine,
                    .standard: standard
                ]
            )
        } catch {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Inventory certificate counts cannot be negative."
                )
            )
        }
    }

    /// Encodes the inventory's raw-certificate counts.
    ///
    /// Rules: FR-16 Persistence stores game state for later resumption.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(extraFineCertificates, forKey: .extraFineCertificates)
        try container.encode(fineCertificates, forKey: .fineCertificates)
        try container.encode(standardCertificates, forKey: .standardCertificates)
    }

    private func certificateUse(
        for recipe: EDRecipe,
        units: Int
    ) -> [EDRawMaterialGrade: Int]? {
        var requiredByGrade: [EDRawMaterialGrade: Int] = [:]
        for grade in recipe.rawMaterials {
            let (required, overflow) = requiredByGrade[grade, default: 0]
                .addingReportingOverflow(units)
            guard !overflow else {
                return nil
            }
            requiredByGrade[grade] = required
        }

        var remaining = certificatesByGrade
        for requiredGrade in [EDRawMaterialGrade.standard, .fine, .xfine] {
            var required = requiredByGrade[requiredGrade, default: 0]
            for suppliedGrade in [EDRawMaterialGrade.standard, .fine, .xfine]
            where canSubstitute(suppliedGrade, for: requiredGrade) {
                let available = remaining[suppliedGrade, default: 0]
                let used = min(required, available)
                remaining[suppliedGrade] = available - used
                required -= used
                if required == 0 {
                    break
                }
            }
            guard required == 0 else {
                return nil
            }
        }

        return Dictionary(
            uniqueKeysWithValues: EDRawMaterialGrade.allCases.map {
                ($0, count(of: $0) - remaining[$0, default: 0])
            }
        )
    }

    private func canSubstitute(
        _ suppliedGrade: EDRawMaterialGrade,
        for requiredGrade: EDRawMaterialGrade
    ) -> Bool {
        suppliedGrade == requiredGrade || EDRecipe.canSubstitute(suppliedGrade, for: requiredGrade)
    }

    private mutating func setCount(_ count: Int, of grade: EDRawMaterialGrade) {
        switch grade {
        case .xfine: extraFineCertificates = count
        case .fine: fineCertificates = count
        case .standard: standardCertificates = count
        }
    }
}
