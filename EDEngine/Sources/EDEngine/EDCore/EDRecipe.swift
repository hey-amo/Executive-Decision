/// Required raw materials for one unit of a finished good.
public enum EDRecipe: CaseIterable, Codable, Hashable, Sendable {
    case a
    case b
    case c

    /// Returns the three raw-material units required by the recipe.
    ///
    /// Rules: Manufacturing. Good A requires XFine, XFine, Fine; Good B
    /// requires Fine, Fine, Standard; Good C requires Fine, Standard, Standard.
    public var rawMaterials: [EDRawMaterialGrade] {
        switch self {
        case .a: [.extraFine, .extraFine, .fine]
        case .b: [.fine, .fine, .standard]
        case .c: [.fine, .standard, .standard]
        }
    }

    public static func canSubstitute(
        _ suppliedGrade: EDRawMaterialGrade,
        for requiredGrade: EDRawMaterialGrade
    ) -> Bool {
        switch (suppliedGrade, requiredGrade) {
        case (.extraFine, .fine), (.fine, .standard):
            true
        default:
            false
        }
    }
}
