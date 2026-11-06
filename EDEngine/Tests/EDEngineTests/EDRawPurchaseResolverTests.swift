import Testing
@testable import EDEngine

@Suite("Raw purchase resolver")
struct EDRawPurchaseResolverTests {
    private let marketPrices: [EDRawMaterialGrade: Int] = [
        .xfine: 40,
        .fine: 30,
        .standard: 20
    ]

    @Test("Purchases all qualifying units at each grade's bid price")
    func purchasesQualifyingOrders() throws {
        let player = try EDPlayerState(
            name: "Alex",
            cashBalance: 500
        )
        let order = try EDRawOrder(
            unitsByGrade: [.xfine: 2, .fine: 3, .standard: 1],
            bidsByGrade: [.xfine: 45, .fine: 30, .standard: 19]
        )

        let result = try EDRawPurchaseResolver.resolve(
            order: order,
            marketPrices: marketPrices,
            playerState: player
        )

        #expect(result.unitsPurchasedByGrade == [.xfine: 2, .fine: 3, .standard: 0])
        #expect(result.totalCost == 180)
        #expect(result.loanAmount == 0)
        #expect(result.playerState.cash.balance == 320)
        #expect(result.playerState.inventory.certificatesByGrade == [
            .xfine: 2,
            .fine: 3,
            .standard: 0
        ])
        #expect(player.cash.balance == 500)
        #expect(player.inventory == EDInventory())
    }

    @Test("Base rules reject below-market bids and cancel all purchases when cash is short")
    func appliesBasePurchaseRules() throws {
        let order = try EDRawOrder(
            unitsByGrade: [.xfine: 2, .fine: 2],
            bidsByGrade: [.xfine: 39, .fine: 30]
        )
        let player = try EDPlayerState(name: "Alex", cashBalance: 50)

        let result = try EDRawPurchaseResolver.resolve(
            order: order,
            marketPrices: marketPrices,
            playerState: player
        )

        #expect(result.unitsPurchasedByGrade == [.xfine: 0, .fine: 0, .standard: 0])
        #expect(result.totalCost == 0)
        #expect(result.playerState == player)
    }

    @Test("Unaffordable qualifying orders cancel as one monthly purchase")
    func cancelsWholePurchaseWhenUnaffordable() throws {
        let player = try EDPlayerState(name: "Alex", cashBalance: 100)
        let order = try EDRawOrder(
            unitsByGrade: [.xfine: 2, .fine: 2],
            bidsByGrade: [.xfine: 50, .fine: 40]
        )

        let result = try EDRawPurchaseResolver.resolve(
            order: order,
            marketPrices: marketPrices,
            playerState: player
        )

        #expect(result.unitsPurchasedByGrade == [.xfine: 0, .fine: 0, .standard: 0])
        #expect(result.totalCost == 0)
        #expect(result.playerState == player)
    }

    @Test("Loan variation borrows the minimum $100 increment needed after costs")
    func takesLoanToCoverPurchase() throws {
        let player = try EDPlayerState(name: "Alex", cashBalance: 75)
        let order = try EDRawOrder(
            unitsByGrade: [.fine: 2],
            bidsByGrade: [.fine: 40]
        )

        let result = try EDRawPurchaseResolver.resolve(
            order: order,
            marketPrices: marketPrices,
            playerState: player,
            enabledVariations: [.loans]
        )

        #expect(result.unitsPurchased(of: .fine) == 2)
        #expect(result.totalCost == 80)
        #expect(result.loanAmount == 100)
        #expect(result.playerState.loanBalance == 100)
        #expect(result.playerState.cash.balance == 95)
        #expect(result.playerState.inventory.count(of: .fine) == 2)
    }

    @Test("Partial-purchase variation loses one unit per dollar below market")
    func partiallyFillsBelowMarketBids() throws {
        let player = try EDPlayerState(name: "Alex", cashBalance: 500)
        let order = try EDRawOrder(
            unitsByGrade: [.xfine: 10, .fine: 2],
            bidsByGrade: [.xfine: 37, .fine: 30]
        )

        let result = try EDRawPurchaseResolver.resolve(
            order: order,
            marketPrices: marketPrices,
            playerState: player,
            enabledVariations: [.partialRawPurchases]
        )

        #expect(result.unitsPurchasedByGrade == [.xfine: 7, .fine: 2, .standard: 0])
        #expect(result.totalCost == 319)
        #expect(result.playerState.cash.balance == 181)
        #expect(result.playerState.inventory.certificatesByGrade == [
            .xfine: 7,
            .fine: 2,
            .standard: 0
        ])
    }

    @Test("Partial fill floors at zero when the bid shortfall exceeds units")
    func partialFillFloorsAtZero() throws {
        let player = try EDPlayerState(name: "Alex", cashBalance: 500)
        let order = try EDRawOrder(
            unitsByGrade: [.xfine: 3],
            bidsByGrade: [.xfine: 10]
        )

        let result = try EDRawPurchaseResolver.resolve(
            order: order,
            marketPrices: marketPrices,
            playerState: player,
            enabledVariations: [.partialRawPurchases]
        )

        #expect(result.unitsPurchased(of: .xfine) == 0)
        #expect(result.totalCost == 0)
        #expect(result.playerState == player)
    }

    @Test("Partial fill safely floors extreme shortfalls at zero")
    func partialFillHandlesExtremeShortfalls() throws {
        let player = try EDPlayerState(name: "Alex", cashBalance: 0)
        let order = try EDRawOrder(
            unitsByGrade: [.xfine: 1],
            bidsByGrade: [.xfine: 0]
        )
        let prices: [EDRawMaterialGrade: Int] = [
            .xfine: Int.max,
            .fine: 30,
            .standard: 20
        ]

        let result = try EDRawPurchaseResolver.resolve(
            order: order,
            marketPrices: prices,
            playerState: player,
            enabledVariations: [.partialRawPurchases, .loans]
        )

        #expect(result.unitsPurchased(of: .xfine) == 0)
        #expect(result.loanAmount == 0)
        #expect(result.playerState == player)
    }

    @Test("Does not borrow when partial fills have zero total cost")
    func zeroCostPartialFillDoesNotBorrow() throws {
        let player = try EDPlayerState(name: "Alex", cashBalance: -100)
        let order = try EDRawOrder(
            unitsByGrade: [.xfine: 2],
            bidsByGrade: [.xfine: 0]
        )

        let result = try EDRawPurchaseResolver.resolve(
            order: order,
            marketPrices: [.xfine: 1, .fine: 30, .standard: 20],
            playerState: player,
            enabledVariations: [.partialRawPurchases, .loans]
        )

        #expect(result.unitsPurchased(of: .xfine) == 1)
        #expect(result.loanAmount == 0)
        #expect(result.totalCost == 0)
        #expect(result.playerState.loanBalance == 0)
        #expect(result.playerState.cash.balance == -100)
        #expect(result.playerState.inventory.count(of: .xfine) == 1)
    }

    @Test("Combines partial fills and loan variation using actual filled cost")
    func combinesVariations() throws {
        let player = try EDPlayerState(name: "Alex", cashBalance: 10)
        let order = try EDRawOrder(
            unitsByGrade: [.xfine: 5],
            bidsByGrade: [.xfine: 39]
        )

        let result = try EDRawPurchaseResolver.resolve(
            order: order,
            marketPrices: marketPrices,
            playerState: player,
            enabledVariations: [.loans, .partialRawPurchases]
        )

        #expect(result.unitsPurchased(of: .xfine) == 4)
        #expect(result.totalCost == 156)
        #expect(result.loanAmount == 200)
        #expect(result.playerState.cash.balance == 54)
        #expect(result.playerState.loanBalance == 200)
    }

    @Test("Rejects missing or nonpositive market prices")
    func validatesMarketPrices() throws {
        let player = try EDPlayerState(name: "Alex", cashBalance: 100)
        let order = try EDRawOrder()

        #expect(throws: EDRawPurchaseResolverError.missingMarketPrice(grade: .standard)) {
            try EDRawPurchaseResolver.resolve(
                order: order,
                marketPrices: [.xfine: 40, .fine: 30],
                playerState: player
            )
        }
        #expect(throws: EDRawPurchaseResolverError.invalidMarketPrice(
            grade: .fine,
            price: 0
        )) {
            try EDRawPurchaseResolver.resolve(
                order: order,
                marketPrices: [.xfine: 40, .fine: 0, .standard: 20],
                playerState: player
            )
        }
    }

    @Test("Reports purchase-cost overflow without changing player state")
    func detectsCostOverflow() throws {
        let player = try EDPlayerState(name: "Alex", cashBalance: 0)
        let order = try EDRawOrder(
            unitsByGrade: [.xfine: Int.max],
            bidsByGrade: [.xfine: Int.max]
        )

        #expect(throws: EDRawPurchaseResolverError.purchaseCostOverflow(grade: .xfine)) {
            try EDRawPurchaseResolver.resolve(
                order: order,
                marketPrices: marketPrices,
                playerState: player
            )
        }
        #expect(player.cash.balance == 0)
        #expect(player.inventory == EDInventory())
    }

    @Test("Reports overflow when valid grade costs overflow their combined total")
    func detectsTotalCostOverflow() throws {
        let player = try EDPlayerState(name: "Alex", cashBalance: 0)
        let bid = Int.max / 2 + 1
        let order = try EDRawOrder(
            unitsByGrade: [.xfine: 1, .fine: 1],
            bidsByGrade: [.xfine: bid, .fine: bid]
        )

        #expect(throws: EDRawPurchaseResolverError.totalCostOverflow) {
            try EDRawPurchaseResolver.resolve(
                order: order,
                marketPrices: marketPrices,
                playerState: player
            )
        }
    }

    @Test("Reports overflow when loan shortfall cannot be represented")
    func detectsLoanShortfallOverflow() throws {
        let player = try EDPlayerState(name: "Alex", cashBalance: EDMoney.minimumBalance)
        let order = try EDRawOrder(
            unitsByGrade: [.xfine: 1],
            bidsByGrade: [.xfine: Int.max]
        )

        #expect(throws: EDRawPurchaseResolverError.loanAmountOverflow) {
            try EDRawPurchaseResolver.resolve(
                order: order,
                marketPrices: marketPrices,
                playerState: player,
                enabledVariations: [.loans]
            )
        }
    }

    @Test("Reports inventory overflow atomically")
    func detectsInventoryOverflow() throws {
        let inventory = try EDInventory(certificatesByGrade: [.xfine: Int.max])
        let player = try EDPlayerState(name: "Alex", cashBalance: 100, inventory: inventory)
        let order = try EDRawOrder(
            unitsByGrade: [.xfine: 1],
            bidsByGrade: [.xfine: 40]
        )

        #expect(throws: EDRawPurchaseResolverError.inventory(
            .certificateCountOverflow(grade: .xfine)
        )) {
            try EDRawPurchaseResolver.resolve(
                order: order,
                marketPrices: marketPrices,
                playerState: player
            )
        }
        #expect(player.cash.balance == 100)
        #expect(player.inventory.count(of: .xfine) == Int.max)
    }
}
