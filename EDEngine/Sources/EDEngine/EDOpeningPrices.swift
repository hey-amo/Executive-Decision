/// Opening market prices defined by the game rules.
public enum EDOpeningPrices {
    /// Raw materials listed in the opening-price table.
    public enum RawMaterial: CaseIterable, Hashable, Sendable {
        case extraFine
        case fine
        case standard
    }

    /// Finished goods listed in the opening-price table.
    public enum FinishedGood: CaseIterable, Hashable, Sendable {
        case a
        case b
        case c
    }

    /// Returns the opening price for a raw material.
    ///
    /// Rules: Setup, Raw Materials opening prices.
    public static func rawMaterialPrice(for material: RawMaterial) -> Int {
        switch material {
        case .extraFine: 40
        case .fine: 30
        case .standard: 20
        }
    }

    /// Returns the opening price for a finished good.
    ///
    /// Rules: Setup, Finished Goods opening prices.
    public static func finishedGoodPrice(for good: FinishedGood) -> Int {
        switch good {
        case .a: 140
        case .b: 115
        case .c: 90
        }
    }
}
