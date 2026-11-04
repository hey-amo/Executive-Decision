//
//  GameState.swift
//  ExecutiveDecision
//
//  Created by Amarjit on 03/05/2025.
//

import Foundation

enum GameState: Int, CaseIterable {
    case idle
}


// Game class to manage the overall game state
class ExecutiveDecisionGame {
    private var players: [Player]
    private var priceTracker = PriceTracker()
    private var currentMonth: Int = 1
    private var totalMonths: Int
    private var isGameOver: Bool = false
    
    init(playerCount: Int, totalMonths: Int) {
        self.totalMonths = totalMonths
        
        // Initialize players with appropriate starting cash
        let initialCash: Int
        switch playerCount {
            case 2: initialCash = 900
            case 3: initialCash = 600
            case 4: initialCash = 450
            case 5: initialCash = 350
            case 6: initialCash = 300
            default: initialCash = 450 // Default to 4 players
        }
        
        self.players = (0..<playerCount).map { _ in Player(playerId: UUID(), initialCash: initialCash) }
    }
    
    // Get player by index
    func getPlayer(at index: Int) -> Player? {
       guard index >= 0 && index < players.count else { return nil }
       return players[index]
    }

    // Get all players
    func getAllPlayers() -> [Player] {
       return players
    }
}
