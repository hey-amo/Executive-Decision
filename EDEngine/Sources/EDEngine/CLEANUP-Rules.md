Files I’d put in EDCore:
These hold game data and rule calculations, with no actors, I/O, or UI:

Domain types and setup

~~EDGameConfig.swift — player count, month count, and enabled rule variations.~~
~~EDMoney.swift — money values and arithmetic.~~
~~EDRawMaterialGrade.swift — XFine, Fine, Standard.~~
~~EDRecipe.swift — goods A, B, C; required materials and legal substitutions.~~
~~EDInventory.swift — raw certificate counts and inventory operations.~~
~~EDPlayerState.swift — a player’s name, cash, inventory, and loan balance.~~
~~EDPriceBoard.swift — current raw and goods prices, plus monthly history.~~
~~EDRawOrder.swift — raw-material units and bids.~~
~~EDGoodsOffer.swift — goods units and asking prices.~~
~~EDMonthResult.swift — the results of resolving a month.~~
~~EDGameState.swift — the game’s domain state, if represented as a value type.~~
Pure rules

~~EDOpeningPrices.swift~~
~~EDMarketCalculator.swift~~
~~EDRawOrderValidator.swift — order limits and minimum bids.~~
~~EDRawMarketResolver.swift — raw-material price changes.~~
~~EDRawPurchaseResolver.swift — successful purchases, funds, and the loan / partial-purchase variations.~~
~~EDProductionAllocator.swift — recipes, substitutions, and certificate use.~~
~~EDGoodsOfferValidator.swift — disqualify over-offers and exclude them from price determination.~~
~~EDGoodsMarketResolver.swift — finished-goods price changes.~~
~~EDGoodsSalesResolver.swift — sales and certificate consumption.~~
~~EDMonthResolver.swift — combines the pure steps to resolve one month.~~
~~EDEndGameScorer.swift — final raw-material sale, profit, rankings, and ties~~

Put in EDGameFlow, not EDCore
Phase transitions, the session actor, events, and player-specific views belong in EDGameFlow. The current EDEngine.swift is engine/game-flow code.

### Legacy player and wallet actors

`EDPlayer.swift` and `EDWallet.swift` were removed. Neither actor was used by
the game engine; both were only exercised by their tests. `EDPlayer` duplicated
the value state in `EDPlayerState` while adding a per-player actor and tally
sheet. `EDWallet` duplicated cash mutation already provided by `EDMoney` and
`EDPlayerState`.

Use `EDPlayerState` and `EDMoney` directly in Core and pass updated values
between pure rules. When game flow is implemented, one `GameSession` actor
should own mutable session state and the private submissions for each player;
do not recreate an actor per player or a separate wallet actor. `EDTallySheet`
remains a standalone, serializable value model for monthly submissions and
results until the session design determines whether to store it or replace it
with dedicated submission state.
EDTallySheet.swift: keep it in Core only if it is part of the game’s canonical, persisted record. If it’s mainly a UI ledger, keep it outside Core.
Your existing setup, market, recipe, and order-limit code is already close to the proposed Core boundary: EDGameSetup.swift, EDMarketCalculator.swift, EDOpeningPrices.swift, EDRawOrderLimits.swift, and EDRecipe.swift. I’d avoid maintaining separate material/goods enums inside opening prices when those concepts already have domain types.

This follows the rules in GameRules.md, while leaving out EDAI, EDPersistence, and EDTestSupport.

## Rule execution: ownership and timing

Rule files do not run themselves. They expose pure calculations or validation
functions; a game-flow controller must call them at the right phase and pass
their results to the next step. The rules folder is a code organization
boundary, not a scheduler or separate Swift module.

### Intended ownership

```text
EDEngine
└── EDGameFlow (planned)
    └── GameSession / phase controller (planned)
        ├── collects secret player submissions
        ├── decides when submissions are revealed
        └── calls EDMonthResolver at month resolution

EDCore (currently part of the EDEngine target)
├── Models
│   ├── EDGameState, EDPlayerState, EDInventory
│   ├── EDRawOrder, EDGoodsOffer
│   └── EDMonthResult, EDPriceBoard
└── Rules
    ├── input validation
    ├── market and purchase resolution
    ├── production and sales
    └── month and end-game resolution
```

The flow controller owns **when** a rule runs and controls secret information.
The rule types own **what** the game calculates and should remain deterministic
and free of I/O. `EDMonthResolver` is intended to compose the monthly rules;
the phase controller should call it only after the required submissions have
been collected and revealed.

### Intended monthly sequence

| Phase | Responsible rule | What it does |
|---|---|---|
| Setup | `EDGameSetup`, `EDOpeningPrices` | Establishes valid player-count limits and opening prices. |
| Raw bidding | `EDRawOrderValidator` | Checks each player's submitted order and minimum bids before accepting it. |
| Raw reveal and market | `EDRawMarketResolver` | Aggregates revealed orders and calculates updated raw prices. |
| Raw purchases | `EDRawPurchaseResolver` | Applies bids, available cash, and enabled purchase variations to each player. |
| Manufacturing | `EDProductionAllocator` | Checks whether raw certificates can supply the requested recipes and legal substitutions. |
| Goods offer reveal | `EDGoodsOfferValidator` | Checks each complete offer against that player's inventory; over-offers are disqualified and excluded from the valid price totals. |
| Goods market | `EDGoodsMarketResolver` (planned) | Calculates goods prices from the validator's valid per-good totals, never the unfiltered submissions. |
| Goods sales | `EDGoodsSalesResolver` (planned) | Resolves sales and consumes the certificates used for sold goods. |
| Month close | `EDMonthResolver` (planned) | Combines the monthly results, updates game state, and records the closing prices. |
| Game end | `EDEndGameScorer` | Settles remaining raw materials at final-month prices, repays recorded loans, and calculates final profit, ranks, and ties. |

For example, `EDGoodsOfferValidator` should be called only after all goods
offers are available and the inventory to validate against is known. Its
`validOfferedUnitsByGood` output is the input the goods-market rule should use
for price determination. The validator does not resolve prices or sales itself.

### What currently calls the rules

At present, there is no implemented phase controller or `EDMonthResolver`.
`EDEngine` currently stores and replaces an `EDGameState`; it does not collect
orders, advance phases, or invoke the rule functions. Existing rule types are
therefore callable utilities, not an automatically running game. Adding the
planned `EDGameFlow` phase controller and wiring it to `EDMonthResolver` is
what will make the sequence above execute during a game.
