/// Opening market prices defined by the game rules.
public enum EDOpeningPrices {
    /// Returns the opening price for a raw material.
    ///
    /// Rules: Setup, Raw Materials opening prices.
    public static func rawMaterialPrice(for material: EDRawMaterialGrade) -> Int {
        switch material {
        case .xfine: 40
        case .fine: 30
        case .standard: 20
        }
    }

    /// Returns the opening price for a finished good.
    ///
    /// Rules: Setup, Finished Goods opening prices.
    public static func finishedGoodPrice(for good: EDRecipe) -> Int {
        switch good {
        case .a: 140
        case .b: 115
        case .c: 90
        }
    }
}
