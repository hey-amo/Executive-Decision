import Foundation

/// Helpers for end of game scoring and player ranking.
///
/// This file keeps scoring concerns separate from the core game model and player state.
public extension ExecutiveDecisionGame {
    /// Returns the current players sorted by coin balance descending.
    ///
    /// Use this for end-of-game ranking, where higher cash wins.
    func playersSortedByCoins() -> [Player] {
        players.sorted { lhs, rhs in
            lhs.cash > rhs.cash
        }
    }
}
