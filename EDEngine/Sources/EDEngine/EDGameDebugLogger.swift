public extension ExecutiveDecisionGame {
    var debugStateDescription: String {
        let divider = String(repeating: "=", count: 60)
        let playerDetails = players.enumerated().map { index, player in
            """
            \(index + 1). \(player.name)\(player.isAI ? " [AI]" : "")\(player.isBankrupt ? " [BANKRUPT]" : "")
               Coins: $\(player.coins)
               Loans: \(player.loans.count)
               Cards held: Not tracked (player inventory is not implemented)
            """
        }.joined(separator: "\n")

        return """
        \(divider)
        EXECUTIVE DECISION — GAME STATE
        \(divider)
        Month: \(currentMonth)/\(duration)
        Players: \(players.count)
        Current player: Not assigned (turn order is not connected to the game)
        Deck: Not tracked (card deck is not implemented)

        Game state: \(gameState)
        Game phase: \(gameState.phaseDescription)

        PLAYER STATUS
        \(playerDetails.isEmpty ? "No players" : playerDetails)
        \(divider)
        """
    }

    func printDebugState() {
        #if GAME_STATE_DEBUG_LOGGING
        print(debugStateDescription)
        #endif
    }
}

private extension EDGameState {
    var phaseDescription: String {
        switch self {
        case .setup: "Setup"
        case .purchaseRawMaterials: "Purchase raw materials"
        case .manufactureProducts: "Manufacture products"
        case .sellingFinishedGoods: "Sell finished goods"
        case .bidding: "Bidding"
        case .endOfYear: "End of year"
        case .gameOver: "Game over"
        case .takeALoan: "Take a loan"
        }
    }
}
