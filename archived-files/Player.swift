//
//  Player.swift
//  ExecutiveDecision
//
//  Created by Amarjit on 03/05/2025.
//

import Foundation
import GameplayKit

class Player: NSObject, Identifiable {
    private(set) var playerId: UUID
    private(set) var cash: Int
    //private(set) var inventory = RawMaterialInventory()
    private(set) var producedGoods: [ProductType: Int] = [:]

    init(playerId: UUID, initialCash: Int = 0) {
        self.playerId = playerId
        self.cash = initialCash
    }
}

// Represents a player's bid for raw materials
struct PlayerRawMaterialBid {
    let material: RawMaterial
    let units: Int
    let bidPrice: Int
    
    // Check if bid is successful compared to market price
    func isSuccessful(marketPrice: Int) -> Bool {
        return bidPrice >= marketPrice
    }
    
    // Calculate the total cost if successful
    func totalCost() -> Int {
        return units * bidPrice
    }
}

// Represents a player's offering of finished goods
struct PlayerProductOffering {
    let productType: ProductType
    let units: Int
    let askPrice: Int
    
    // Check if offering is successful compared to market price
    func isSuccessful(marketPrice: Int) -> Bool {
        return askPrice <= marketPrice
    }
    
    // Calculate the total revenue if successful
    func totalRevenue() -> Int {
        return units * askPrice
    }
}


