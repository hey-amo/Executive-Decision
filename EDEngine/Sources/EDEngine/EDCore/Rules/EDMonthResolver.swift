// EDMonthResolver.swift — coordinates raw and goods rule stages for one month.

import Foundation

/// Errors raised while coordinating one month's pure rule stages.
public enum EDMonthResolverError: Error, Equatable, Sendable {
    case gameComplete
    case submissionsDoNotMatchPlayers
    case rawOrderValidation(playerID: UUID, error: EDRawOrderValidationError)
    case rawMarket(EDRawMarketResolverError)
    case rawPurchase(playerID: UUID, error: EDRawPurchaseResolverError)
    case offerValidation(EDGoodsOfferValidationError)
    case goodsMarket(EDGoodsMarketResolverError)
    case goodsSales(EDGoodsSalesResolverError)
    case playerState(playerID: UUID, error: EDPlayerStateError)
    case priceBoard(EDPriceBoardError)
    case playerMonthResult(EDPlayerMonthResultError)
    case monthResult(EDMonthResultError)
    case gameState(EDGameStateError)
    case mismatchedProgress
}

/// The immutable output of resolving raw orders for the active month.
///
/// Rules: FR-7 and FR-8. Contains the updated raw market and purchased player
/// states needed to request goods offers.
public struct EDMonthRawResolution: Equatable, Hashable, Sendable {
    public let startingGameState: EDGameState
    public let rawMarket: EDRawMarketResolution
    public let purchasesByPlayer: [UUID: EDRawPurchaseResolution]
    public let playerStatesForGoods: [UUID: EDPlayerState]

    fileprivate init(
        startingGameState: EDGameState,
        rawMarket: EDRawMarketResolution,
        purchasesByPlayer: [UUID: EDRawPurchaseResolution],
        playerStatesForGoods: [UUID: EDPlayerState]
    ) {
        self.startingGameState = startingGameState
        self.rawMarket = rawMarket
        self.purchasesByPlayer = purchasesByPlayer
        self.playerStatesForGoods = playerStatesForGoods
    }
}

/// The completed output of resolving both stages of one month.
///
/// Rules: FR-7 through FR-11. Returns the resolved prices, offers, sales,
/// monthly record, and next game state.
public struct EDMonthResolution: Equatable, Sendable {
    public let monthResult: EDMonthResult
    public let nextGameState: EDGameState
    public let offerValidation: EDGoodsOfferValidationResult
    public let goodsMarket: EDGoodsMarketResolution
    public let goodsSales: EDGoodsSalesResolution

    fileprivate init(
        monthResult: EDMonthResult,
        nextGameState: EDGameState,
        offerValidation: EDGoodsOfferValidationResult,
        goodsMarket: EDGoodsMarketResolution,
        goodsSales: EDGoodsSalesResolution
    ) {
        self.monthResult = monthResult
        self.nextGameState = nextGameState
        self.offerValidation = offerValidation
        self.goodsMarket = goodsMarket
        self.goodsSales = goodsSales
    }
}

/// Coordinates the raw and finished-goods rules for a month in two stages.
///
/// Rules: FR-7 through FR-11. Raw purchases are resolved first so goods offers
/// can be decided against the resulting inventory.
public enum EDMonthResolver {
    /// Validates and resolves all raw orders, returning post-purchase states.
    ///
    /// Rules: FR-5 through FR-8. This stage does not mutate the input state.
    public static func resolveRawStage(
        gameState: EDGameState,
        ordersByPlayer: [UUID: EDRawOrder]
    ) throws(EDMonthResolverError) -> EDMonthRawResolution {
        guard !gameState.isComplete else {
            throw .gameComplete
        }
        guard Set(ordersByPlayer.keys) == Set(gameState.players.map(\.id)) else {
            throw .submissionsDoNotMatchPlayers
        }

        for player in gameState.players {
            guard let order = ordersByPlayer[player.id] else {
                throw .submissionsDoNotMatchPlayers
            }
            do {
                try EDRawOrderValidator.validate(
                    order,
                    limits: gameState.configuration.rawOrderLimits,
                    previousPrices: gameState.priceBoard.rawMaterialPrices
                )
            } catch {
                throw .rawOrderValidation(playerID: player.id, error: error)
            }
        }

        let orders = gameState.players.compactMap { ordersByPlayer[$0.id] }
        let rawMarket: EDRawMarketResolution
        do {
            rawMarket = try EDRawMarketResolver.resolve(
                orders: orders,
                previousPrices: gameState.priceBoard.rawMaterialPrices
            )
        } catch {
            throw .rawMarket(error)
        }

        var purchases: [UUID: EDRawPurchaseResolution] = [:]
        var playerStates: [UUID: EDPlayerState] = [:]
        for player in gameState.players {
            guard let order = ordersByPlayer[player.id] else {
                throw .submissionsDoNotMatchPlayers
            }
            do {
                let purchase = try EDRawPurchaseResolver.resolve(
                    order: order,
                    marketPrices: rawMarket.rawMaterialPrices,
                    playerState: player,
                    enabledVariations: gameState.configuration.enabledVariations
                )
                purchases[player.id] = purchase
                playerStates[player.id] = purchase.playerState
            } catch {
                throw .rawPurchase(playerID: player.id, error: error)
            }
        }

        return EDMonthRawResolution(
            startingGameState: gameState,
            rawMarket: rawMarket,
            purchasesByPlayer: purchases,
            playerStatesForGoods: playerStates
        )
    }

    /// Resolves eligible goods offers and returns the completed month value.
    ///
    /// Rules: FR-9 through FR-11. Only valid offers affect goods prices, sales
    /// consume certificates, and the result is returned without mutating input.
    public static func resolveGoodsStage(
        rawResolution: EDMonthRawResolution,
        offersByPlayer: [UUID: EDGoodsOffer]
    ) throws(EDMonthResolverError) -> EDMonthResolution {
        let gameState = rawResolution.startingGameState
        guard !gameState.isComplete else {
            throw .gameComplete
        }
        let playerIDs = Set(gameState.players.map(\.id))
        guard Set(offersByPlayer.keys) == playerIDs,
              Set(rawResolution.playerStatesForGoods.keys) == playerIDs,
              Set(rawResolution.purchasesByPlayer.keys) == playerIDs else {
            throw .submissionsDoNotMatchPlayers
        }
        for player in gameState.players {
            guard let purchase = rawResolution.purchasesByPlayer[player.id],
                  let playerState = rawResolution.playerStatesForGoods[player.id],
                  purchase.playerState == playerState else {
                throw .mismatchedProgress
            }
        }

        let inventories = Dictionary(
            uniqueKeysWithValues: gameState.players.compactMap { player in
                rawResolution.playerStatesForGoods[player.id].map {
                    (player.id, $0.inventory)
                }
            }
        )
        let offerValidation: EDGoodsOfferValidationResult
        do {
            offerValidation = try EDGoodsOfferValidator.validate(
                offersByPlayer: offersByPlayer,
                inventoriesByPlayer: inventories
            )
        } catch {
            throw .offerValidation(error)
        }

        let goodsMarket: EDGoodsMarketResolution
        do {
            goodsMarket = try EDGoodsMarketResolver.resolve(
                validOfferedUnitsByGood: offerValidation.validOfferedUnitsByGood,
                previousPrices: gameState.priceBoard.finishedGoodPrices
            )
        } catch {
            throw .goodsMarket(error)
        }

        let goodsSales: EDGoodsSalesResolution
        do {
            goodsSales = try EDGoodsSalesResolver.resolve(
                eligibleOffersByPlayer: offerValidation.validOffersByPlayer,
                marketPrices: goodsMarket.finishedGoodPrices,
                inventoriesByPlayer: inventories
            )
        } catch {
            throw .goodsSales(error)
        }

        var finalPlayers: [EDPlayerState] = []
        var playerResults: [EDPlayerMonthResult] = []
        for originalPlayer in gameState.players {
            guard var player = rawResolution.playerStatesForGoods[originalPlayer.id],
                  let purchase = rawResolution.purchasesByPlayer[originalPlayer.id],
                  let inventory = goodsSales.updatedInventoriesByPlayer[originalPlayer.id] else {
                throw .submissionsDoNotMatchPlayers
            }
            player.inventory = inventory
            let sales = goodsSales.salesByPlayer[originalPlayer.id]
            let salesRevenue = sales?.goodsSalesRevenue ?? 0
            if salesRevenue > 0 {
                do {
                    try player.addCash(salesRevenue)
                } catch {
                    throw .playerState(playerID: player.id, error: error)
                }
            }
            finalPlayers.append(player)

            do {
                playerResults.append(
                    try EDPlayerMonthResult(
                        playerID: player.id,
                        rawUnitsPurchased: purchase.unitsPurchasedByGrade,
                        rawPurchaseCost: purchase.totalCost,
                        finishedGoodsSold: sales?.finishedGoodsSold ?? [:],
                        goodsSalesRevenue: salesRevenue
                    )
                )
            } catch {
                throw .playerMonthResult(error)
            }
        }

        let movement = EDPriceMovement(
            rawMaterials: rawResolution.rawMarket.movementsByGrade,
            finishedGoods: goodsMarket.movementsByGood
        )
        let updatedPriceBoard: EDPriceBoard
        do {
            updatedPriceBoard = try gameState.priceBoard.applying(movement: movement)
        } catch {
            throw .priceBoard(error)
        }
        guard let closingPrices = updatedPriceBoard.history.last else {
            throw .priceBoard(.priceOverflow)
        }

        let monthResult: EDMonthResult
        do {
            monthResult = try EDMonthResult(
                monthNumber: gameState.currentMonthNumber,
                closingPrices: closingPrices,
                playerResults: playerResults
            )
        } catch {
            throw .monthResult(error)
        }

        let nextGameState: EDGameState
        do {
            nextGameState = try EDGameState(
                configuration: gameState.configuration,
                players: finalPlayers,
                priceBoard: updatedPriceBoard,
                monthResults: gameState.monthResults + [monthResult]
            )
        } catch {
            throw .gameState(error)
        }

        return EDMonthResolution(
            monthResult: monthResult,
            nextGameState: nextGameState,
            offerValidation: offerValidation,
            goodsMarket: goodsMarket,
            goodsSales: goodsSales
        )
    }

}
