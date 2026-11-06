// EDProductionAllocator.swift
// Assigns raw certificates to requested finished goods.

/// A feasible certificate assignment for requested finished goods.
///
/// Rules: FR-9 Manufacturing. Certificates are grouped by good and supplied
/// grade, including legal substitutions.
public struct EDProductionAllocation: Equatable, Hashable, Sendable {
    /// Certificates assigned to each good, grouped by the grade supplied.
    public let certificatesUsedByGood: [EDRecipe: [EDRawMaterialGrade: Int]]

    /// Total certificates used across all goods, grouped by supplied grade.
    public var certificatesUsedByGrade: [EDRawMaterialGrade: Int] {
        var totals = Dictionary(
            uniqueKeysWithValues: EDRawMaterialGrade.allCases.map { ($0, 0) }
        )
        for allocation in certificatesUsedByGood.values {
            for grade in EDRawMaterialGrade.allCases {
                totals[grade, default: 0] += allocation[grade, default: 0]
            }
        }
        return totals
    }

    fileprivate init(certificatesUsedByGood: [EDRecipe: [EDRawMaterialGrade: Int]]) {
        self.certificatesUsedByGood = certificatesUsedByGood
    }
}

/// Errors are not needed for infeasible requests: the allocator returns `nil`.
/// Arithmetic overflow and negative requests are also treated as infeasible.
///
/// Rules: FR-9 Manufacturing requires three legal raw certificates per good.
public enum EDProductionAllocator {
    /// Finds a joint certificate assignment for all requested goods.
    ///
    /// Allocates exact recipe grades first, then uses legal substitutions.
    /// Where a requirement can be covered by multiple remaining grades, the
    /// lower grade is assigned first. The search covers all requested goods
    /// together so one product cannot reserve certificates needed by another.
    ///
    /// Rules: FR-9 Manufacturing permits XFine for Fine and Fine for Standard;
    /// no lower-grade substitution is allowed.
    public static func allocate(
        inventory: EDInventory,
        goodsUnits: [EDRecipe: Int]
    ) -> EDProductionAllocation? {
        for recipe in EDRecipe.allCases where goodsUnits[recipe, default: 0] < 0 {
            return nil
        }

        var remainingRequirements: [EDRecipe: [EDRawMaterialGrade: Int]] = [:]
        for recipe in EDRecipe.allCases {
            let units = goodsUnits[recipe, default: 0]
            var requiredByGrade: [EDRawMaterialGrade: Int] = [:]
            for grade in recipe.rawMaterials {
                let (required, overflow) = requiredByGrade[grade, default: 0]
                    .addingReportingOverflow(units)
                guard !overflow else {
                    return nil
                }
                requiredByGrade[grade] = required
            }
            remainingRequirements[recipe] = requiredByGrade
        }

        var remainingCertificates = inventory.certificatesByGrade
        var usedByGood = Dictionary(
            uniqueKeysWithValues: EDRecipe.allCases.map { recipe in
                (
                    recipe,
                    Dictionary(
                        uniqueKeysWithValues: EDRawMaterialGrade.allCases.map { ($0, 0) }
                    )
                )
            }
        )

        for grade in EDRawMaterialGrade.allCases {
            assign(
                suppliedGrade: grade,
                toRequiredGrade: grade,
                remainingCertificates: &remainingCertificates,
                remainingRequirements: &remainingRequirements,
                usedByGood: &usedByGood
            )
        }

        let substitutions: [(supplied: EDRawMaterialGrade, required: EDRawMaterialGrade)] = [
            (.fine, .standard),
            (.xfine, .fine),
            (.xfine, .standard)
        ]
        for substitution in substitutions {
            assign(
                suppliedGrade: substitution.supplied,
                toRequiredGrade: substitution.required,
                remainingCertificates: &remainingCertificates,
                remainingRequirements: &remainingRequirements,
                usedByGood: &usedByGood
            )
        }

        let allRequirementsMet = remainingRequirements.values.allSatisfy { requirements in
            requirements.values.allSatisfy { $0 == 0 }
        }
        guard allRequirementsMet else {
            return nil
        }

        return EDProductionAllocation(certificatesUsedByGood: usedByGood)
    }

    private static func assign(
        suppliedGrade: EDRawMaterialGrade,
        toRequiredGrade requiredGrade: EDRawMaterialGrade,
        remainingCertificates: inout [EDRawMaterialGrade: Int],
        remainingRequirements: inout [EDRecipe: [EDRawMaterialGrade: Int]],
        usedByGood: inout [EDRecipe: [EDRawMaterialGrade: Int]]
    ) {
        for recipe in EDRecipe.allCases {
            let required = remainingRequirements[recipe]?[requiredGrade, default: 0] ?? 0
            let available = remainingCertificates[suppliedGrade, default: 0]
            let assigned = min(required, available)
            guard assigned > 0 else {
                continue
            }

            remainingRequirements[recipe, default: [:]][requiredGrade] = required - assigned
            remainingCertificates[suppliedGrade] = available - assigned
            usedByGood[recipe, default: [:]][suppliedGrade, default: 0] += assigned
        }
    }
}
