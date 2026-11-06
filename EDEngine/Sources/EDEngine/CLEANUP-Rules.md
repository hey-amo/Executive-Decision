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

Pure rules:

~~EDOpeningPrices.swift~~
~~EDMarketCalculator.swift~~
~~EDRawOrderValidator.swift — order limits and minimum bids.~~
~~EDRawMarketResolver.swift — raw-material price changes.~~
~~EDRawPurchaseResolver.swift — successful purchases, funds, and the loan / partial-purchase variations.~~
~~EDProductionAllocator.swift — recipes, substitutions, and certificate use.~~
~~EDGoodsOfferValidator.swift — disqualify over-offers and exclude them from price determination.~~
~~EDGoodsMarketResolver.swift — finished-goods price changes.~~
~~EDGoodsSalesResolver.swift — sales and certificate consumption.~~
EDMonthResolver.swift — combines the pure steps to resolve one month.
~~EDEndGameScorer.swift — final raw-material sale, profit, rankings, and ties~~

Put in EDGameFlow, not EDCore
Phase transitions, the session actor, events, and player-specific views belong
in EDGameFlow. The current `EDEngine` actor only stores/replaces a state
snapshot; the planned `GameSession` should replace or evolve it so there is
one authoritative owner of mutable session state.



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
        ├── runs the raw resolver stage after raw orders are complete
        ├── exposes safe post-purchase views for goods decisions
        ├── runs the goods resolver stage after offers are complete
        └── applies returned state and publishes ordered events

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

`GameSession` is the game-flow coordinator: it owns **when** a rule runs and
controls secret information. `GamePhaseReducer` decides whether a lifecycle
transition is legal. `EDMonthResolver` (not yet implemented) is the pure,
staged monthly coordinator that composes the rule functions. Its raw stage
must finish before the session requests goods offers, since those decisions
depend on post-purchase inventory. Its goods stage runs after every offer is
submitted. Neither coordinator should duplicate the calculations in
individual rule types.

### Intended monthly sequence

| Phase | Responsible rule | What it does |
|---|---|---|
| Setup | `EDGameConfig`, `EDOpeningPrices` | Validates game options and derives starting cash and raw-order limits; establishes opening prices. |
| Raw-order submission | `GameSession` + `EDRawOrderValidator` | Keeps each submission private and accepts it only if limits and minimum bids pass. |
| Raw resolution | `EDMonthResolver` raw stage, `EDRawMarketResolver`, `EDRawPurchaseResolver` | After all raw orders arrive, calculates prices and purchases; returns the updated inventories used for goods decisions. |
| Goods-offer submission | `GameSession` | Collects private offers after exposing each player only their permitted post-purchase view. |
| Manufacturing / offer validation | `EDMonthResolver` goods stage, `EDGoodsOfferValidator`, `EDProductionAllocator` | Jointly checks each complete offer against post-purchase inventory; disqualifies over-offers before pricing. |
| Goods market | `EDGoodsMarketResolver` | Prices only the valid offered units. |
| Goods sales | `EDGoodsSalesResolver` | Resolves qualifying offers, consumes certificates, and reports whole-offer delivery failures. |
| Month close | `EDMonthResolver` goods stage (planned) | Combines the goods results with raw-stage progress, updates game state, and records the closing prices. |
| Game end | `EDEndGameScorer` | Settles remaining raw materials at final-month prices, repays recorded loans, and calculates final profit, ranks, and ties. |

For example, `EDGoodsOfferValidator` should be called only after all goods
offers are available and the post-purchase inventory to validate against is
known. Its `validOfferedUnitsByGood` output is the input the goods-market rule
should use for price determination. The validator does not resolve prices or
sales itself.

### What currently calls the rules

At present, there is no implemented phase controller or `EDMonthResolver`.
`EDEngine` currently stores and replaces an `EDGameState`; it does not collect
orders, advance phases, or invoke the rule functions. Existing rule types are
therefore callable utilities, not an automatically running game. EDGameFlow
and `GameSession` will own submission gates and phase control, while
`EDMonthResolver` will compose the monthly rule functions.
