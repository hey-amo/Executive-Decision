//
//  Product.swift
//  ExecutiveDecision
//
//  Created by Amarjit on 03/05/2025.
//

enum RawMaterial: Int, CaseIterable {
    case xfine, fine, standard
    
    var openingPrice: Int {
        switch self {
        case .xfine: return 40
        case .fine: return 30
        case .standard: return 20
        }
    }
}

extension RawMaterial: CustomStringConvertible {
    var description: String {
        switch self {
        case .xfine: return "X-Fine"
        case .fine: return "Fine"
        case .standard: return "Standard"
        }
    }
}

enum ProductType: Int, CaseIterable {
    case a,b,c
    
    var openingPrice: Int {
        switch self {
        case .a: return 140
        case .b: return 115
        case .c: return 90
        }
    }
    
    var recipe: Recipe {
        switch self {
        case .a: return Recipe(materials: [.xfine, .xfine, .fine])
        case .b: return Recipe(materials: [.fine, .fine, .standard])
        case .c: return Recipe(materials: [.fine, .standard, .standard])
        }
    }
}

// Recipe defines the raw materials needed for a product
struct Recipe {
    let materials: [RawMaterial]
    
    // Check if we can make this recipe with given materials
    func canProduce(from availableMaterials: [RawMaterial]) -> Bool {
        // Create a mutable copy to track available materials
        var materials = availableMaterials
        
        // First try to use exact materials
        for requiredMaterial in self.materials {
            if let index = materials.firstIndex(of: requiredMaterial) {
                materials.remove(at: index)
            } else {
                // If exact material not found, try substitutions
                switch requiredMaterial {
                case .standard:
                    // Try to substitute with Fine
                    if let index = materials.firstIndex(of: .fine) {
                        materials.remove(at: index)
                    }
                    // Try to substitute with X-Fine
                    else if let index = materials.firstIndex(of: .xfine) {
                        materials.remove(at: index)
                    }
                    else {
                        return false // Cannot produce
                    }
                case .fine:
                    // Try to substitute with X-Fine
                    if let index = materials.firstIndex(of: .xfine) {
                        materials.remove(at: index)
                    }
                    else {
                        return false // Cannot produce
                    }
                case .xfine:
                    return false // Cannot produce, xfine is needed
                }
            }
        }
        
        return true
    }
}

// MARK: Finished Good

// Product struct representing a finished good/product
struct Product {
    let type: ProductType
    let price: Int
    
    // Factory method to create a product if possible
    static func tryCreate(type: ProductType, from materials: [RawMaterial]) -> Product? {
        if type.recipe.canProduce(from: materials) {
            return Product(type: type, price: type.openingPrice)
        }
        return nil
    }
}
