public extension ExecutiveDecisionGame {
    var debugStateDescription: String {
        let divider = String(repeating: "=", count: 60)
        let playerDetails = players.enumerated().map { index, player in
            let rawMaterials = RawMaterial.allCases.map {
                "\($0.debugName): \(player.rawMaterialInventory[$0, default: 0])"
            }.joined(separator: ", ")
            let production = FinishedGood.allCases.map {
                "\($0.debugName): \(player.monthlyGoods.produced[$0, default: 0])"
            }.joined(separator: ", ")
            let offerings = FinishedGood.allCases.map {
                "\($0.debugName): \(player.monthlyGoods.offered[$0, default: 0])"
            }.joined(separator: ", ")
            let sales = FinishedGood.allCases.map {
                "\($0.debugName): \(player.monthlyGoods.sold[$0, default: 0])"
            }.joined(separator: ", ")
            return """
            \(index + 1). \(player.name)\(player.isAI ? " [AI]" : "")\(player.isBankrupt ? " [BANKRUPT]" : "")
               Coins: $\(player.coins)
               Loans: \(player.loans.count)
               Raw materials: \(rawMaterials)
               This month's production: \(production)
               This month's offerings: \(offerings)
               This month's sales: \(sales)
            """
        }.joined(separator: "\n")
        let rawMaterialPrices = RawMaterial.allCases.map {
            "\($0.debugName): $\(marketBoard.price(for: $0))"
        }.joined(separator: ", ")
        let finishedGoodPrices = FinishedGood.allCases.map {
            "\($0.debugName): $\(marketBoard.price(for: $0))"
        }.joined(separator: ", ")
        let activePlayerDescription = activePlayer?.name
            ?? (isPhaseBarrierReached ? "None (phase barrier reached)" : "None (no active turn)")
        let turnOrderDescription = turnOrder.map(String.init).joined(separator: " -> ")
        let readyPlayersDescription = readyPlayerNumbers.sorted().map(String.init).joined(separator: ", ")

        return """
        \(divider)
        EXECUTIVE DECISION — GAME STATE
        \(divider)
        Month: \(currentMonth)/\(duration)
        Players: \(players.count)
        Turn order: \(turnOrderDescription)
        Current player: \(activePlayerDescription)
        Ready players: \(readyPlayersDescription.isEmpty ? "None" : readyPlayersDescription)
        Phase barrier reached: \(isPhaseBarrierReached ? "Yes" : "No")
        Deck: Not tracked (card deck is not implemented)

        Game state: \(gameState)
        Game phase: \(gameState.phaseDescription)
        Raw-material market: \(rawMaterialPrices)
        Finished-good market: \(finishedGoodPrices)

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

private extension RawMaterial {
    var debugName: String {
        switch self {
        case .standard: "Standard"
        case .fine: "Fine"
        case .extraFine: "Extra Fine"
        }
    }
}

private extension FinishedGood {
    var debugName: String {
        rawValue.uppercased()
    }
}
