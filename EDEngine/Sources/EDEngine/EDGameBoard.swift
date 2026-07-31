import Foundation

public enum RawMaterial: Int, Codable, CaseIterable {
    case xfine, fine, standard
    
    public var openingPrice: Int {
        switch self {
        case .xfine: return 40
        case .fine: return 30
        case .standard: return 20
        }
    }
}

extension RawMaterial: CustomStringConvertible {
    public var description: String {
        switch self {
        case .xfine: return "X-Fine"
        case .fine: return "Fine"
        case .standard: return "Standard"
        }
    }
}

public enum ProductType: Int, Codable, CaseIterable {
    case a,b,c
    
    public var openingPrice: Int {
        switch self {
        case .a: return 140
        case .b: return 115
        case .c: return 90
        }
    }
}

public enum EDPlayPhase: CaseIterable, Equatable {
    case purchase
    case manufacture
    case selling

    public static var allPhases: [EDPlayPhase] {
        Self.allCases
    }
}

public struct EDMarketCalculator {
    public static let rawMaterialUnits = Array(0...24)
    public static let rawMaterialMovements = [-10, -9, -8, -7, -6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]

    public static let finishedGoodsUnits = Array(0...16)
    public static let finishedGoodsMovements = [11, 9, 7, 5, 3, 1, -1, -3, -5, -7, -9, -11, -13, -15, -17, -19, -21]

    public static func rawMaterialMovement(for units: Int) -> Int? {
        guard rawMaterialUnits.contains(units) else { return nil }
        return rawMaterialMovements[units]
    }

    public static func finishedGoodsMovement(for units: Int) -> Int? {
        guard finishedGoodsUnits.contains(units) else { return nil }
        return finishedGoodsMovements[units]
    }
}

public enum EDGameRecipe: Equatable {
    case productA
    case productB
    case productC

    public var requiredMaterials: [RawMaterial] {
        switch self {
        case .productA:
            return [.xfine, .xfine, .fine]
        case .productB:
            return [.fine, .fine, .standard]
        case .productC:
            return [.fine, .standard, .standard]
        }
    }

    public static var allRecipes: [EDGameRecipe] {
        [.productA, .productB, .productC]
    }
}

public enum EDGameMonthName: String, CaseIterable {
    case january = "January"
    case february = "February"
    case march = "March"
    case april = "April"
    case may = "May"
    case june = "June"
    case july = "July"
    case august = "August"
    case september = "September"
    case october = "October"
    case november = "November"
    case december = "December"
}

public struct EDGameMonth {
    public let name: String
    public let index: Int

    public init(name: String, index: Int) {
        self.name = name
        self.index = index
    }
}

public struct EDMainBoardReference {
    public let rawMaterialOpeningPrices: [RawMaterial: Int]
    public let finishedGoodsOpeningPrices: [ProductType: Int]
    public let monthNames: [String]
    public let marketCalculatorType: EDMarketCalculator.Type

    public static func standard12MonthReference() -> EDMainBoardReference {
        .init(
            rawMaterialOpeningPrices: Dictionary(uniqueKeysWithValues: RawMaterial.allCases.map { ($0, $0.openingPrice) }),
            finishedGoodsOpeningPrices: Dictionary(uniqueKeysWithValues: ProductType.allCases.map { ($0, $0.openingPrice) }),
            monthNames: EDGameMonthName.allCases.map { $0.rawValue },
            marketCalculatorType: EDMarketCalculator.self
        )
    }
}

// MARK: EDGameSetup

public struct EDGameSetup {
    public let months: [EDGameMonth]
    public let boardReference: EDMainBoardReference
    public let phases: [EDPlayPhase]

    public init(months: [EDGameMonth], boardReference: EDMainBoardReference, phases: [EDPlayPhase] = EDPlayPhase.allPhases) {
        self.months = months
        self.boardReference = boardReference
        self.phases = phases
    }

    public static func makeMonths(count: Int) -> [EDGameMonth] {
        let normalizedCount = min(max(count, 6), 12)
        return Array(EDGameMonthName.allCases.prefix(normalizedCount).enumerated().map { index, month in
            EDGameMonth(name: month.rawValue, index: index + 1)
        })
    }

    public static func standardSetup(monthCount: Int = 12) -> EDGameSetup {
        EDGameSetup(
            months: makeMonths(count: monthCount),
            boardReference: .standard12MonthReference()
        )
    }
}
