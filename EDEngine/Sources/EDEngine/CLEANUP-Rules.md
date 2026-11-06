Files I’d put in EDCore:
These hold game data and rule calculations, with no actors, I/O, or UI:

Domain types and setup

~~EDGameConfig.swift — player count, month count, variations, starting cash, and order limits.~~
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

Use `EDPlayerState` and `EDMoney` directly in Core and pass updated values
between pure rules. When game flow is implemented, one `GameSession` actor
should own mutable session state and the private submissions for each player;
do not recreate an actor per player or a separate wallet actor.
`EDTallySheet` is a serializable value model in `EDCore/Models`: it records
monthly order and offer entries and their outcomes, without depending on a
player actor or UI. GameFlow should own the association between each sheet and
its player and decide when private entries are revealed. Whether the session
persists this model is a storage policy, not a reason to move it out of Core.
`EDGameSetup` was removed because it duplicated setup validation and player-count
lookup alongside `EDGameConfig`. `EDGameConfig` now owns the single validated
setup mapping and exposes the starting cash and raw-order limits derived from
player count. `EDRawOrderLimits` is in `EDCore/Rules`: it expresses the FR-5
order constraints and is consumed by `EDRawOrderValidator`. Opening prices,
market calculation, recipe data, and order validation also belong to the Core
rules boundary; they should use the existing material and good domain types.

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
│   ├── EDMonthResult, EDPriceBoard
│   └── EDTallySheet
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
| Setup | `EDGameConfig`, `EDOpeningPrices` | Validates game options and derives starting cash and raw-order limits; establishes opening prices. |
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
