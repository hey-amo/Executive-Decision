import Foundation

// Strategy enums to define AI behavior
public enum AIBiddingStrategy {
    case aggressive    // Bids high to ensure winning materials
    case conservative  // Bids low to maximize profit margins
    case balanced      // Tries to balance winning materials and profit
}

public enum AIProductionStrategy {
    case focusHighEnd   // Focus on making Product A
    case focusMidRange  // Focus on making Product B
    case focusLowEnd    // Focus on making Product C
    case balanced       // Try to make a mix of products
    case opportunistic  // Make whatever seems most profitable
}

// AI Player class for computer opponents
public class AIPlayer {
}