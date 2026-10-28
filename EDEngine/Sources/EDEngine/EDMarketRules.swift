public enum MarketItemCategory: Equatable {
    case rawMaterial
    case finishedGood
}

public protocol MarketItem {
    var openingPrice: Int { get }
    var marketItemCategory: MarketItemCategory { get }
}

public enum RawMaterial: String, CaseIterable, MarketItem {
    case standard
    case fine
    case extraFine

    public var openingPrice: Int {
        switch self {
        case .standard: 20
        case .fine: 30
        case .extraFine: 40
        }
    }

    public var marketItemCategory: MarketItemCategory { .rawMaterial }
}

public protocol RecipeProviding {
    var recipe: Recipe { get }
}

public struct Recipe {
    public let ingredients: [RawMaterial: Int]

    fileprivate init(ingredients: [RawMaterial: Int]) {
        self.ingredients = ingredients
    }

    public func materialsToConsume(from inventory: [RawMaterial: Int]) throws -> [RawMaterial: Int]? {
        guard inventory.values.allSatisfy({ $0 >= 0 }) else {
            throw RecipeError.negativeInventory
        }

        let standardNeeded = ingredients[.standard, default: 0]
        let fineNeeded = ingredients[.fine, default: 0]
        let extraFineNeeded = ingredients[.extraFine, default: 0]

        let standardAvailable = inventory[.standard, default: 0]
        let fineAvailable = inventory[.fine, default: 0]
        let extraFineAvailable = inventory[.extraFine, default: 0]

        let extraFineShortage = max(0, extraFineNeeded - extraFineAvailable)
        let fineShortage = max(0, fineNeeded - fineAvailable)
        let standardShortage = max(0, standardNeeded - standardAvailable)
        let extraFineForFine = max(0, extraFineAvailable - extraFineNeeded)
        let fineForStandard = max(0, fineAvailable - fineNeeded)

        guard extraFineShortage == 0,
              fineShortage <= extraFineForFine,
              standardShortage <= fineForStandard else {
            return nil
        }

        let standardConsumed = min(standardNeeded, standardAvailable)
        let fineConsumed = min(fineNeeded, fineAvailable) + standardShortage
        let extraFineConsumed = extraFineNeeded + fineShortage

        var consumed: [RawMaterial: Int] = [:]
        if standardConsumed > 0 {
            consumed[.standard] = standardConsumed
        }
        if fineConsumed > 0 {
            consumed[.fine] = fineConsumed
        }
        if extraFineConsumed > 0 {
            consumed[.extraFine] = extraFineConsumed
        }
        return consumed
    }
}

public enum RecipeError: Error, Equatable {
    case negativeInventory
}

public enum FinishedGood: String, CaseIterable, MarketItem, RecipeProviding {
    case a
    case b
    case c

    public var openingPrice: Int {
        switch self {
        case .a: 140
        case .b: 115
        case .c: 90
        }
    }

    public var marketItemCategory: MarketItemCategory { .finishedGood }

    public var recipe: Recipe {
        switch self {
        case .a:
            Recipe(ingredients: [.extraFine: 2, .fine: 1])
        case .b:
            Recipe(ingredients: [.fine: 2, .standard: 1])
        case .c:
            Recipe(ingredients: [.fine: 1, .standard: 2])
        }
    }
}

public enum MarketCalculatorError: Error, Equatable {
    case unitCountOutOfRange
    case priceOverflow
}

public struct MarketCalculator {
    public init() {}

    public func movement(for item: any MarketItem, units: Int) throws -> Int {
        switch item.marketItemCategory {
        case .rawMaterial:
            guard (0...24).contains(units) else {
                throw MarketCalculatorError.unitCountOutOfRange
            }
            return units - 10
        case .finishedGood:
            guard (0...16).contains(units) else {
                throw MarketCalculatorError.unitCountOutOfRange
            }
            return 11 - (2 * units)
        }
    }

    public func price(
        for item: any MarketItem,
        units: Int,
        previousPrice: Int? = nil
    ) throws -> Int {
        let change = try movement(for: item, units: units)
        let basePrice = previousPrice ?? item.openingPrice
        let (calculatedPrice, overflow) = basePrice.addingReportingOverflow(change)
        guard !overflow else {
            throw MarketCalculatorError.priceOverflow
        }

        if item.marketItemCategory == .rawMaterial {
            return max(1, calculatedPrice)
        }
        return calculatedPrice
    }
}
