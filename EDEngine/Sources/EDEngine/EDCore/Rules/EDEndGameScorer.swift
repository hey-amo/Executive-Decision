// EDEndGameScorer.swift — settles remaining raw certificates and ranks final profits.

/// Errors raised while settling and scoring a completed game.
public enum EDEndGameScorerError: Error, Equatable, Sendable {
    /// Rules: Ending the Game. Scoring is available only after the final month.
    case gameNotComplete

    /// Rules: Ending the Game. The final raw-material sale must fit a whole-dollar amount.
    case rawMaterialSaleOverflow(playerID: EDPlayerState.ID, grade: EDRawMaterialGrade)

    /// Rules: Ending the Game. The total raw-material sale must fit a whole-dollar amount.
    case totalRawMaterialSaleOverflow(playerID: EDPlayerState.ID)

    /// Rules: Ending the Game. Settling sales or loan repayment could not update cash.
    case playerState(playerID: EDPlayerState.ID, error: EDPlayerStateError)

    /// Rules: Ending the Game. Final profit must fit a whole-dollar amount.
    case profitOverflow(playerID: EDPlayerState.ID)
}

/// One player's final settlement and competition ranking.
///
/// Rules: Ending the Game. Final profit is measured against starting cash,
/// after selling remaining raw certificates and repaying any loans.
public struct EDPlayerFinalScore: Codable, Equatable, Hashable, Sendable {
    public let playerID: EDPlayerState.ID
    public let playerName: String
    public let finalPlayerState: EDPlayerState
    public let rawMaterialSaleRevenue: Int
    public let loanRepaymentAmount: Int
    public let profit: Int
    public let rank: Int

    init(
        playerID: EDPlayerState.ID,
        playerName: String,
        finalPlayerState: EDPlayerState,
        rawMaterialSaleRevenue: Int,
        loanRepaymentAmount: Int,
        profit: Int,
        rank: Int
    ) {
        self.playerID = playerID
        self.playerName = playerName
        self.finalPlayerState = finalPlayerState
        self.rawMaterialSaleRevenue = rawMaterialSaleRevenue
        self.loanRepaymentAmount = loanRepaymentAmount
        self.profit = profit
        self.rank = rank
    }
}

/// Final standings and winner identities for a completed game.
///
/// Rules: Ending the Game. All players tied for highest profit are winners.
public struct EDEndGameScore: Codable, Equatable, Hashable, Sendable {
    /// Scores ordered by descending profit, with deterministic player-ID ordering for ties.
    public let rankedPlayers: [EDPlayerFinalScore]

    /// Every player tied for the highest final profit.
    public let winnerIDs: Set<EDPlayerState.ID>

    init(rankedPlayers: [EDPlayerFinalScore], winnerIDs: Set<EDPlayerState.ID>) {
        self.rankedPlayers = rankedPlayers
        self.winnerIDs = winnerIDs
    }
}

/// Settles remaining raw certificates and calculates final profit and ranking.
///
/// Rules: Ending the Game. Remaining raw certificates are sold to the Broker
/// at final-month market prices; loan variation debt is repaid at $125 per
/// $100 borrowed; the highest profit wins, including ties.
public enum EDEndGameScorer {
    /// Scores a completed game without mutating its state.
    ///
    /// Profit is final cash after certificate sale and loan repayment, less
    /// starting cash for the configured player count. Ranks use competition
    /// ranking: tied players share a rank and the next rank skips their places.
    ///
    /// Rules: Ending the Game and Variation 1.
    public static func score(
        gameState: EDGameState
    ) throws(EDEndGameScorerError) -> EDEndGameScore {
        guard gameState.isComplete else {
            throw .gameNotComplete
        }

        let startingCash = gameState.configuration.startingCashPerPlayer

        var scores: [EDPlayerFinalScore] = []
        scores.reserveCapacity(gameState.players.count)

        for player in gameState.players {
            var finalState = player
            var saleRevenue = 0

            for grade in EDRawMaterialGrade.allCases {
                let price = gameState.priceBoard.price(for: grade)
                let units = player.inventory.count(of: grade)
                let (gradeRevenue, revenueOverflow) = units.multipliedReportingOverflow(by: price)
                guard !revenueOverflow else {
                    throw .rawMaterialSaleOverflow(playerID: player.id, grade: grade)
                }
                let (newRevenue, totalOverflow) = saleRevenue.addingReportingOverflow(gradeRevenue)
                guard !totalOverflow else {
                    throw .totalRawMaterialSaleOverflow(playerID: player.id)
                }
                saleRevenue = newRevenue
            }

            if saleRevenue > 0 {
                do {
                    try finalState.addCash(saleRevenue)
                } catch {
                    throw .playerState(playerID: player.id, error: error)
                }
            }
            finalState.inventory = EDInventory()

            let loanRepayment: Int
            do {
                loanRepayment = try finalState.loanRepaymentAmount()
                try finalState.subtractCash(loanRepayment)
            } catch {
                throw .playerState(playerID: player.id, error: error)
            }

            let (profit, profitOverflow) = finalState.cash.balance
                .subtractingReportingOverflow(startingCash)
            guard !profitOverflow else {
                throw .profitOverflow(playerID: player.id)
            }

            scores.append(
                EDPlayerFinalScore(
                    playerID: player.id,
                    playerName: player.name,
                    finalPlayerState: finalState,
                    rawMaterialSaleRevenue: saleRevenue,
                    loanRepaymentAmount: loanRepayment,
                    profit: profit,
                    rank: 0
                )
            )
        }

        scores.sort {
            if $0.profit != $1.profit {
                return $0.profit > $1.profit
            }
            return $0.playerID.uuidString < $1.playerID.uuidString
        }

        var rankedScores: [EDPlayerFinalScore] = []
        rankedScores.reserveCapacity(scores.count)
        var previousProfit: Int?
        var currentRank = 0
        for (index, score) in scores.enumerated() {
            if score.profit != previousProfit {
                currentRank = index + 1
                previousProfit = score.profit
            }
            rankedScores.append(
                EDPlayerFinalScore(
                    playerID: score.playerID,
                    playerName: score.playerName,
                    finalPlayerState: score.finalPlayerState,
                    rawMaterialSaleRevenue: score.rawMaterialSaleRevenue,
                    loanRepaymentAmount: score.loanRepaymentAmount,
                    profit: score.profit,
                    rank: currentRank
                )
            )
        }

        let highestProfit = rankedScores.first?.profit
        let winners = Set(
            rankedScores
                .filter { $0.profit == highestProfit }
                .map(\.playerID)
        )
        return EDEndGameScore(rankedPlayers: rankedScores, winnerIDs: winners)
    }
}
