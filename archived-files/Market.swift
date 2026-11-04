//
//  Market.swift
//  ExecutiveDecision
//
//  Created by Amarjit on 03/05/2025.
//

// Market price calculator for raw materials and finished goods
struct Market {
    // Raw material price calculator based on units ordered
    static func calculateRawMaterialPriceChange(forUnits units: Int) -> Int {
        let changes = [-10, -9, -8, -7, -6, -5, -4, -3, -2, -1, 0,
                      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
        
        // Ensure we don't go out of bounds
        let index = min(max(0, units), changes.count - 1)
        return changes[index]
    }
    
    // Finished goods price calculator based on units offered
    static func calculateFinishedGoodPriceChange(forUnits units: Int) -> Int {
        let changes = [11, 9, 7, 5, 3, 1, -1, -3, -5, -7, -9, -11, -13, -15, -17, -19, -21]
        
        // Ensure we don't go out of bounds
        let index = min(max(0, units), changes.count - 1)
        return changes[index]
    }
    
    // Prevent prices from going below $1
    static func applyMinimumPrice(_ price: Int) -> Int {
        return max(1, price)
    }
}

// Month-by-month price tracker
class PriceTracker {
    // Price history for raw materials
    private var standardPrices: [Int]
    private var finePrices: [Int]
    private var xFinePrices: [Int]
    
    // Price history for finished goods
    private var productAPrices: [Int]
    private var productBPrices: [Int]
    private var productCPrices: [Int]
    
    // Current month index
    private var currentMonth = 0
    
    init() {
        // Initialize with starting prices
        standardPrices = [RawMaterial.standard.openingPrice]
        finePrices = [RawMaterial.fine.openingPrice]
        xFinePrices = [RawMaterial.xfine.openingPrice]
        
        productAPrices = [ProductType.a.openingPrice]
        productBPrices = [ProductType.b.openingPrice]
        productCPrices = [ProductType.c.openingPrice]
    }
    
    // Get current price for a raw material
    func currentPrice(for material: RawMaterial) -> Int {
        switch material {
        case .standard: return standardPrices[currentMonth]
        case .fine: return finePrices[currentMonth]
        case .xfine: return xFinePrices[currentMonth]
        }
    }
    
    // Get current price for a product
    func currentPrice(for productType: ProductType) -> Int {
        switch productType {
        case .a: return productAPrices[currentMonth]
        case .b: return productBPrices[currentMonth]
        case .c: return productCPrices[currentMonth]
        }
    }
    
    // Update raw material prices based on total units ordered
    func updateRawMaterialPrices(standardUnits: Int, fineUnits: Int, xFineUnits: Int) {
        let standardChange = Market.calculateRawMaterialPriceChange(forUnits: standardUnits)
        let fineChange = Market.calculateRawMaterialPriceChange(forUnits: fineUnits)
        let xFineChange = Market.calculateRawMaterialPriceChange(forUnits: xFineUnits)
        
        let newStandardPrice = Market.applyMinimumPrice(standardPrices[currentMonth] + standardChange)
        let newFinePrice = Market.applyMinimumPrice(finePrices[currentMonth] + fineChange)
        let newXFinePrice = Market.applyMinimumPrice(xFinePrices[currentMonth] + xFineChange)
        
        standardPrices.append(newStandardPrice)
        finePrices.append(newFinePrice)
        xFinePrices.append(newXFinePrice)
    }
    
    // Update finished goods prices based on total units offered
    func updateProductPrices(aUnits: Int, bUnits: Int, cUnits: Int) {
        let aChange = Market.calculateFinishedGoodPriceChange(forUnits: aUnits)
        let bChange = Market.calculateFinishedGoodPriceChange(forUnits: bUnits)
        let cChange = Market.calculateFinishedGoodPriceChange(forUnits: cUnits)
        
        let newAPrice = Market.applyMinimumPrice(productAPrices[currentMonth] + aChange)
        let newBPrice = Market.applyMinimumPrice(productBPrices[currentMonth] + bChange)
        let newCPrice = Market.applyMinimumPrice(productCPrices[currentMonth] + cChange)
        
        productAPrices.append(newAPrice)
        productBPrices.append(newBPrice)
        productCPrices.append(newCPrice)
    }
    
    // Advance to next month
    func advanceMonth() {
        currentMonth += 1
    }
    
    // Get current month (1-based for display purposes)
    func getCurrentMonth() -> Int {
        return currentMonth + 1
    }
    
    // Get price history for a material
    func priceHistory(for material: RawMaterial) -> [Int] {
        switch material {
        case .standard: return standardPrices
        case .fine: return finePrices
        case .xfine: return xFinePrices
        }
    }
    
    // Get price history for a product
    func priceHistory(for productType: ProductType) -> [Int] {
        switch productType {
        case .a: return productAPrices
        case .b: return productBPrices
        case .c: return productCPrices
        }
    }
}
