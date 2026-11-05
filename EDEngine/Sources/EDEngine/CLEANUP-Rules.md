You can keep one Swift package and make these folders within its existing EDEngine target:


Those folders organize the code; they do not create separate Swift modules or packages.

Files I’d put in EDCore
These hold game data and rule calculations, with no actors, I/O, or UI:

Domain types and setup

~~EDGameConfig.swift — player count, month count, and enabled rule variations.~~
~~EDMoney.swift — money values and arithmetic.~~
~~EDRawMaterialGrade.swift — XFine, Fine, Standard.~~
~~EDRecipe.swift — goods A, B, C; required materials and legal substitutions.~~
~~EDInventory.swift — raw certificate counts and inventory operations.~~
~~EDPlayerState.swift — a player’s name, cash, inventory, and loan balance.~~
EDPriceBoard.swift — current raw and goods prices, plus history if needed.
EDRawOrder.swift — raw-material units and bids.
EDGoodsOffer.swift — goods units and asking prices.
EDMonthResult.swift — the results of resolving a month.
EDGameState.swift — the game’s domain state, if represented as a value type.
Pure rules

EDOpeningPrices.swift
EDMarketCalculator.swift
EDRawOrderValidator.swift — order limits and minimum bids.
EDRawMarketResolver.swift — raw-material price changes.
EDRawPurchaseResolver.swift — successful purchases, funds, and the loan / partial-purchase variations.
EDProductionAllocator.swift — recipes, substitutions, and certificate use.
EDGoodsOfferValidator.swift — disqualify over-offers and exclude them from price determination.
EDGoodsMarketResolver.swift — finished-goods price changes.
EDGoodsSalesResolver.swift — sales and certificate consumption.
EDMonthResolver.swift — combines the pure steps to resolve one month.
EDEndGameScorer.swift — final raw-material sale, profit, rankings, and ties.
A small rules type and its typed errors can share a file; these don’t all need to be one-file-per-type if that feels too fragmented.

Put in EDGameFlow, not EDCore
Phase transitions, the session actor, events, and player-specific views belong in EDGameFlow. The current EDEngine.swift is engine/game-flow code.

A few existing files need splitting or reconsideration:

EDPlayer.swift: keep player state as a value type in Core; actor-based orchestration belongs in GameFlow.
EDWallet.swift: I wouldn’t move this actor into Core; represent cash in EDMoney / EDPlayerState and have pure rule functions update values.
EDGameSettings.swift: sound, music, haptics, and display preferences are app settings, not game rules.
EDTallySheet.swift: keep it in Core only if it is part of the game’s canonical, persisted record. If it’s mainly a UI ledger, keep it outside Core.
Your existing setup, market, recipe, and order-limit code is already close to the proposed Core boundary: EDGameSetup.swift, EDMarketCalculator.swift, EDOpeningPrices.swift, EDRawOrderLimits.swift, and EDRecipe.swift. I’d avoid maintaining separate material/goods enums inside opening prices when those concepts already have domain types.

This follows the rules in GameRules.md, while leaving out EDAI, EDPersistence, and EDTestSupport.