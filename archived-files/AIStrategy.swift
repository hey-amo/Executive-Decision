//
//  AIStrategy.swift
//  ExecutiveDecision
//
//  Created by Amarjit on 03/05/2025.
//

// #TODO


// Strategy enums to define AI behavior
enum AIBiddingStrategy {
    case aggressive    // Bids high to ensure winning materials
    case conservative  // Bids low to maximize profit margins
    case balanced      // Tries to balance winning materials and profit
}

enum AIProductionStrategy {
    case focusHighEnd   // Focus on making Product A
    case focusMidRange  // Focus on making Product B
    case focusLowEnd    // Focus on making Product C
    case balanced       // Try to make a mix of products
    case opportunistic  // Make whatever seems most profitable
}

// AI Player class for computer opponents
class AIPlayer {
    private let player: Player
    private var biddingStrategy: AIBiddingStrategy
    private var productionStrategy: AIProductionStrategy
    private var adaptiveStrategy: Bool // Whether to adapt strategy based on market
    
    init(player: Player, biddingStrategy: AIBiddingStrategy, productionStrategy: AIProductionStrategy, adaptiveStrategy: Bool = true) {
        self.player = player
        self.biddingStrategy = biddingStrategy
        self.productionStrategy = productionStrategy
        self.adaptiveStrategy = adaptiveStrategy
    }
    
    // Helper method to estimate the value of a raw material based on what it can produce
   private func estimateValueForMaterial(_ material: RawMaterial, currentPrices: [ProductType: Int]) -> Int {
       // Consider which products use this material and their current prices
       var valueEstimate = 0
       
       switch material {
       case .xfine:
           // XFine appears in Product A (2) and could substitute for Fine in Product B
           valueEstimate = (currentPrices[.a] ?? 140) / 3 * 2
       case .fine:
           // Fine appears in Product A (1), Product B (2), and Product C (1)
           valueEstimate = ((currentPrices[.a] ?? 140) / 3) +
                          ((currentPrices[.b] ?? 115) / 3 * 2) / 2 +
                          ((currentPrices[.c] ?? 90) / 3) / 2
       case .standard:
           // Standard appears in Product B (1) and Product C (2)
           valueEstimate = ((currentPrices[.b] ?? 115) / 3) +
                          ((currentPrices[.c] ?? 90) / 3 * 2) / 2
       }
       
       return valueEstimate
   }
    
    
}
