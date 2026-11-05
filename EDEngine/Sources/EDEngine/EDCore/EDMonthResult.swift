// EDMonthResult.swift — the results of resolving a month.

import Foundation

/// Errors raised when constructing a player's resolved monthly results.
public enum EDPlayerMonthResultError: Error, Equatable, Sendable {
    /// Rules: FR-8 Raw purchases cannot contain negative unit counts.
    case negativePurchasedUnits(grade: EDRawMaterialGrade, units: Int)

    /// Rules: FR-8 Raw purchases cannot have a negative total cost.
    case negativeRawPurchaseCost(Int)

    /// Rules: FR-11 Goods sales cannot contain negative unit counts.
    case negativeSoldUnits(good: EDRecipe, units: Int)

    /// Rules: FR-11 Goods sales cannot have negative proceeds.
    case negativeGoodsSalesRevenue(Int)
}

/// One player's completed purchasing and selling totals for a month.
///
/// Rules: FR-8 records raw purchases at the bid price; FR-11 records goods
/// sales at the asking price. These are resolved outcomes, not submitted bids.
public struct EDPlayerMonthResult: Codable, Equatable, Hashable, Sendable {
    public let playerID: UUID
    public let rawUnitsPurchased: [EDRawMaterialGrade: Int]
    public let rawPurchaseCost: Int
    public let finishedGoodsSold: [EDRecipe: Int]
    public let goodsSalesRevenue: Int

    private enum CodingKeys: String, CodingKey {
        case playerID
        case rawUnitsPurchased
        case rawPurchaseCost
        case finishedGoodsSold
        case goodsSalesRevenue
    }

    /// Creates validated monthly purchase and sale results for a player.
    ///
    /// Rules: FR-8 and FR-11. Unspecified grades and goods have zero resolved
    /// units; costs and proceeds are nonnegative whole-dollar amounts.
    public init(
        playerID: UUID,
        rawUnitsPurchased: [EDRawMaterialGrade: Int] = [:],
        rawPurchaseCost: Int = 0,
        finishedGoodsSold: [EDRecipe: Int] = [:],
        goodsSalesRevenue: Int = 0
    ) throws(EDPlayerMonthResultError) {
        for grade in EDRawMaterialGrade.allCases {
            let units = rawUnitsPurchased[grade, default: 0]
            guard units >= 0 else {
                throw .negativePurchasedUnits(grade: grade, units: units)
            }
        }
        guard rawPurchaseCost >= 0 else {
            throw .negativeRawPurchaseCost(rawPurchaseCost)
        }
        for good in EDRecipe.allCases {
            let units = finishedGoodsSold[good, default: 0]
            guard units >= 0 else {
                throw .negativeSoldUnits(good: good, units: units)
            }
        }
        guard goodsSalesRevenue >= 0 else {
            throw .negativeGoodsSalesRevenue(goodsSalesRevenue)
        }

        self.playerID = playerID
        self.rawUnitsPurchased = Dictionary(
            uniqueKeysWithValues: EDRawMaterialGrade.allCases.map {
                ($0, rawUnitsPurchased[$0, default: 0])
            }
        )
        self.rawPurchaseCost = rawPurchaseCost
        self.finishedGoodsSold = Dictionary(
            uniqueKeysWithValues: EDRecipe.allCases.map {
                ($0, finishedGoodsSold[$0, default: 0])
            }
        )
        self.goodsSalesRevenue = goodsSalesRevenue
    }

    /// Net cash change from resolved purchases and sales.
    ///
    /// Rules: FR-8 purchase costs are paid and FR-11 goods-sale proceeds are
    /// received during the month.
    public var cashChange: Int {
        goodsSalesRevenue - rawPurchaseCost
    }

    /// Decodes monthly results and validates all recorded amounts.
    ///
    /// Rules: FR-16 persisted results retain valid raw-purchase and goods-sale
    /// outcomes.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let playerID = try container.decode(UUID.self, forKey: .playerID)
        let rawUnitsPurchased = try container.decode(
            [EDRawMaterialGrade: Int].self,
            forKey: .rawUnitsPurchased
        )
        let rawPurchaseCost = try container.decode(Int.self, forKey: .rawPurchaseCost)
        let finishedGoodsSold = try container.decode(
            [EDRecipe: Int].self,
            forKey: .finishedGoodsSold
        )
        let goodsSalesRevenue = try container.decode(Int.self, forKey: .goodsSalesRevenue)

        do {
            try self.init(
                playerID: playerID,
                rawUnitsPurchased: rawUnitsPurchased,
                rawPurchaseCost: rawPurchaseCost,
                finishedGoodsSold: finishedGoodsSold,
                goodsSalesRevenue: goodsSalesRevenue
            )
        } catch {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Player month result contains a negative amount."
                )
            )
        }
    }
}

/// Completed outcomes for one resolved game month.
///
/// Rules: FR-7 and FR-11 resolve prices, while FR-8 and FR-11 resolve each
/// player's purchases and sales. The result is separate from the next game
/// state.
public struct EDMonthResult: Codable, Equatable, Hashable, Sendable {
    public let monthNumber: Int
    public let closingPrices: EDPriceBoardSnapshot
    public let playerResults: [EDPlayerMonthResult]

    private enum CodingKeys: String, CodingKey {
        case monthNumber
        case closingPrices
        case playerResults
    }

    /// Creates the immutable result of a resolved month.
    ///
    /// Rules: Setup month numbering starts at 1; each player's result is
    /// recorded once per month.
    public init(
        monthNumber: Int,
        closingPrices: EDPriceBoardSnapshot,
        playerResults: [EDPlayerMonthResult]
    ) throws(EDMonthResultError) {
        guard monthNumber > 0 else {
            throw .invalidMonthNumber(monthNumber)
        }

        var playerIDs = Set<UUID>()
        for result in playerResults {
            guard playerIDs.insert(result.playerID).inserted else {
                throw .duplicatePlayerResult(result.playerID)
            }
        }

        self.monthNumber = monthNumber
        self.closingPrices = closingPrices
        self.playerResults = playerResults
    }

    /// Decodes a resolved month and verifies month numbering and unique players.
    ///
    /// Rules: FR-16 Persistence restores complete, consistently indexed
    /// monthly results.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let monthNumber = try container.decode(Int.self, forKey: .monthNumber)
        let closingPrices = try container.decode(
            EDPriceBoardSnapshot.self,
            forKey: .closingPrices
        )
        let playerResults = try container.decode(
            [EDPlayerMonthResult].self,
            forKey: .playerResults
        )

        do {
            try self.init(
                monthNumber: monthNumber,
                closingPrices: closingPrices,
                playerResults: playerResults
            )
        } catch {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Month result has an invalid month number or duplicate players."
                )
            )
        }
    }
}

/// Errors raised when constructing a resolved month.
public enum EDMonthResultError: Error, Equatable, Sendable {
    /// Rules: Setup. Month numbering begins with month 1.
    case invalidMonthNumber(Int)

    /// Rules: A resolved month contains one result per player.
    case duplicatePlayerResult(UUID)
}
