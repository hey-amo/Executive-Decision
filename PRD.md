# Executive Decision Engine: PRD and Branch Plan

Unofficial hobby Swift implementation of Sid Sackson's *Executive Decision*. Scope of this document: the **game engine only** (no UI). Version 0.1.

## 3. Branch Brief Template (paste per task)

```
You are working on the Executive Decision Swift engine. Follow AGENTS.md strictly.

BRANCH: feature/ED-### - <slug>
DEPENDS ON: <merged branch ids>
GOAL: <one sentence>
IN SCOPE: <files/types to create or change>
OUT OF SCOPE: <explicit exclusions>
PUBLIC API (exact signatures where known):
<code block>
RULES REFERENCE: <quote or paraphrase the relevant rulebook text>
ACCEPTANCE CRITERIA:
- [ ] <testable bullet>
- [ ] <testable bullet>
TESTS TO WRITE: <list, including rulebook examples>
DELIVERABLE: code + tests, `swift build` and `swift test` green in Swift 6 mode, summary of design decisions and any rule ambiguity you had to resolve.
If the work exceeds ~300 changed lines, stop and propose a split.
```

## 4. Product Requirements

### 4.1 Purpose

A deterministic, testable Swift engine that implements the complete rules of *Executive Decision*, so a separate UI layer can drive solo play against AI avatars and local pass-and-play.

### 4.2 Goals

- Faithful implementation of the base rules and both variations.
- Pure, deterministic rules core that is trivially unit-testable.
- Hidden-information correctness: bids stay secret until revealed; the engine can hand a UI a *view* that never leaks another player's secrets (needed for pass-and-play).
- Pluggable player agents (human via UI, AI personas) behind one protocol.
- Local save and resume.
- Swift 6 strict concurrency, no data races by construction.

### 4.3 Non-goals

UI of any kind, internet multiplayer, cloud backup, accounts, analytics, monetisation, art and avatar assets (the engine only exposes persona identity and behaviour).

### 4.4 Players

2 to 6 participants, any mix of humans and AI. Humans share one device (pass-and-play).

### 4.5 Functional requirements

- 4.5.1: **FR-1 Setup.** Configurable player count (2-6) and month count (default 12). Starting cash by player count: 2 = $900, 3 = $600, 4 = $450, 5 = $350, 6 = $300.
- 4.5.2: **FR-2 Opening prices.** Raw: XFine $40, Fine $30, Standard $20. Goods: A $140, B $115, C $90.
- 4.5.3: **FR-3 Recipes.** A = XFine, XFine, Fine. B = Fine, Fine, Standard. C = Fine, Standard, Standard.
- 4.5.4: **FR-4 Market calculator.** Raw movement = units - 10 for 0...24 units (-10 to +14). Goods movement = 11 - 2 x units for 0...16 units (+11 to -21). Movement is applied to the *previous* market price.
- 4.5.5: **FR-5 Raw order limits.** Total units per player per month: 2p = 18, 3p = 12, 4p = 9, 5p = 7, 6p = 6. In a 2-player game, at most 12 units of any one grade.
- 4.5.6: **FR-6 Minimum raw bid.** The price the grade would move to if only that player ordered it: previous price + movement(player's own units), floored at $1.
- 4.5.7: **FR-7 Raw pricing.** New price per grade = previous + movement(total ordered units), never below $1. Grades are resolved XFine, Fine, Standard.
- 4.5.8: **FR-8 Raw purchase.** Bid >= market: all units bought at the **bid** price. Bid < market: nothing. If cash cannot cover the total, the player buys nothing that month (base rules).
- 4.5.9: **FR-9 Manufacturing.** 3 raw units per good. Only substitutions: XFine for Fine, Fine for Standard (a higher grade may fill a lower slot, never the reverse).
- 4.5.10: **FR-10 Goods offers.** Per type: units and asking price. A player may not offer more goods than their inventory can produce. Over-offering voids all of that player's offers for the month **and** excludes them from price determination.
- 4.5.11: **FR-11 Goods pricing and sales.** Market = previous + movement(total valid offered units). Bid <= market: all units sold at the **bid** price. Bid > market: none. Sold goods consume the raw certificates needed to make them.
- 4.5.12: **FR-12 Game end.** After the final month, leftover raw is sold to the Broker at the final market price. Profit = final cash - starting cash (less loan repayments in Variation 1). Highest profit wins; ties are reported as ties.
- 4.5.13: **FR-13 Variation 1 (loans).** Shortfalls are covered by loans in $100 increments, only as much as needed. Each $100 costs $125 at the end.
- 4.5.14: **FR-14 Variation 2 (partial purchase).** A raw bid below market still buys units, minus one unit per dollar of shortfall (floor at zero).
- 4.5.15: **FR-15 Hidden information.** Bids and production intentions are secret until the reveal. Raw certificates (inventory) are public. Cash is treated as public by default (configurable).
- 4.5.16: **FR-16 Persistence.** Full game state serialises to a versioned snapshot; the engine can resume from one. Autosave after each phase.
- 4.5.17: **FR-17 Agents.** Every seat is driven by a `PlayerAgent`. The engine does not know whether it is a human or an AI.
- 4.5.18: **FR-18 Events.** The engine publishes an ordered stream of immutable events so any UI can animate or log without polling.
- 4.5.19: **FR-Wallet-Fixes** In the game, players it is possible that a numeric result can result in a coin value below zero, theresfore we need to be able to support subtract below zero. You may initFromCoder or init from some kind of persistence with less than zero.  But you cannot `add` 0 or a negative number.  There needs to be a hard lower integer, lets go with -5000.

### 4.6 Non-functional requirements

- Swift 6 language mode, strict concurrency complete, no warnings.
- Builds and tests on macOS and Linux with no Apple-only frameworks.
- Rules core has no I/O and no hidden dependencies, so a full 12-month game with scripted bids is reproducible byte for byte.
- Rules-core line coverage target: 90% or higher.
- A complete AI-vs-AI game should simulate in well under a second.

## 5. Architecture

### 5.1 Modules (Swift Package targets)

- **EDCore**: domain types and pure rules. Depends on nothing.
- **EDEngine**: game flow (phase machine, session actor, events, hidden-info views). Depends on EDCore.

<!--
- **EDAI**: `PlayerAgent` implementations and personas. Depends on EDCore and EDEngine protocols.
- **EDPersistence**: snapshot codec and repositories. Depends on EDCore and EDEngine.
- **EDTestSupport**: fixtures, scripted agents, builders (test-only).
-->

Dependencies point inward; the UI app (a separate repo or target) depends on EDEngine, EDAI and EDPersistence only through their public protocols.

### 5.2 Core concepts

- Value types: `Money`, `RawGrade`, `GoodType`, `Recipe`, `GameConfig`, `Inventory`, `PlayerState`, `PriceBoard`, `RawOrder`, `GoodsOffer`, `MonthResult`, `GameState`.
- Pure services behind protocols: `MarketCalculating`, `OrderValidating`, `ProductionAllocating`, `RawMarketResolving`, `GoodsMarketResolving`, `Scoring`.
- Orchestration: `GamePhaseReducer` (pure validation of legal phase transitions), `EDMonthResolver` (pure composition of monthly rules), and `GameSession` (the sole session actor; owns state, gates private submissions, invokes resolution at phase boundaries, and publishes events).
- Edges: `PlayerAgent` (async decisions), `GameRepository` (save/load), `RandomSource` (seedable RNG for AI).

### 5.3 EDGameFlow responsibility and rule coordination

`EDGameFlow` coordinates play; it does not reimplement game rules. Rule files
are deterministic operations with explicit inputs and outputs. The flow layer
decides when each operation may run, who may see its inputs and results, and
how its result advances the session.

```text
Caller / UI / simulation driver
    ├── requests a safe view from GameSession
    ├── asks a PlayerAgent for a decision outside GameSession
    └── submits the resulting RawOrder or GoodsOffer
                          │
                          ▼
GameSession actor (EDGameFlow; authoritative session coordinator)
    ├── owns EDGameState, current phase, and pending private submissions
    ├── validates raw submissions through EDCore rules; gates all submissions
    ├── withholds submissions until the reveal/resolution gate
    ├── calls GamePhaseReducer for legal lifecycle transitions
    ├── calls EDMonthResolver at the raw and goods phase boundaries
    └── records and publishes ordered GameEvents / safe PlayerViews
                          │
                          ▼
EDMonthResolver (EDCore; pure staged monthly coordinator)
    ├── raw stage: resolves raw market and purchases
    │       └── returns intermediate player states and raw prices
    └── goods stage: validates offers, resolves market and sales
            └── returns MonthResult + next EDGameState, or a typed error
                          │
                          ▼
Pure EDCore rule functions; no session, agent, event, UI, or I/O dependencies
```

`GameSession` is responsible for coordinating the game lifecycle, not for
containing market arithmetic or duplicating validators and resolvers. Do not
add one actor or coordinator per player, market, or rule file. `GamePhaseReducer`
decides whether a transition is legal; it does not run rules. `EDMonthResolver`
coordinates pure rules in two synchronous stages because goods offers are
chosen only after raw purchases update each player's inventory. It does not
collect secrets, publish events, or perform persistence I/O.

`GameSession` accepts decisions as values. It does not call `PlayerAgent`
implementations while holding or mutating session state. A caller obtains a
`PlayerView`, asks the relevant agent asynchronously, then submits the returned
value. This avoids awaiting external work inside the actor and keeps agents
from receiving references to authoritative game state.

The current `EDEngine` is only a state snapshot/replacement wrapper. ED-023
must replace it or evolve it into `GameSession`; do not leave two actors that
can independently own and mutate the authoritative game state.

### 5.4 Phase flow and gates

For each month:

1. **Raw-order submission.** Collect one `RawOrder` per seat. Keep pending
   orders private; reject submissions for the wrong phase, an unknown seat, or
   a seat that has already submitted.
2. **Raw resolution.** Validate each order through `EDRawOrderValidator`.
   Once every seat has submitted a valid order, call the raw stage of
   `EDMonthResolver`. It derives raw prices from all submitted units and
   resolves purchases against those prices. Retain the intermediate player
   states and raw prices as month progress, then publish the reveal and
   resolved information allowed by `PlayerView` and `GameEvent`.
3. **Goods-offer submission.** Collect one `GoodsOffer` per seat, again keeping
   pending offers private and rejecting duplicate or out-of-phase submissions.
4. **Goods resolution.** Once every seat has submitted, call the goods stage
   of `EDMonthResolver` with the raw-phase progress and offers. Validate each
   player's complete offer against the post-purchase inventory.
   Disqualified players' entire offers are omitted from aggregate market
   totals. Resolve goods prices and sales; inability to deliver all
   certificates for a qualifying sale prohibits that player's entire sale, as
   specified by the amended rules.
5. **Month summary.** Commit the completed `MonthResult` and next state,
   publish the summary, discard the transient month progress, then move to the
   next month's raw-order submission.
6. **Game end.** After the final summary, invoke `EDEndGameScorer` once, store
   the final settlement and standings, publish the finished event, and enter
   the terminal phase. Further submissions or resolution attempts are rejected.

The lifecycle is therefore:

`rawOrderSubmission` -> `rawResolution` -> `goodsOfferSubmission` ->
`goodsResolution` -> `monthSummary` -> next month or `finished`.

### 5.5 Concurrency and isolation

- All state transitions are pure `(State, Input) -> (State, [Event])` functions, so they need no isolation.
- `GameSession` is the only actor holding mutable session state. Its isolated methods accept and return `Sendable` values; mutable submission dictionaries, intermediate month progress, and event continuations stay actor-isolated.
- Agents are asked for decisions with `async` calls by the caller/driver, using a safe `PlayerView`; they return `Sendable` values that are submitted to `GameSession`. The session does not await agent work while coordinating a resolution.
- `GameSession` serializes submissions. A phase resolves exactly once after all seats submit; partial submissions do not advance the phase. If an input fails validation, report a typed error and leave the accepted submissions and phase unchanged.
- No view may expose another seat's pending orders or offers. Reveal events are emitted only after the corresponding collection gate is complete. Public state follows FR-15; each player's private projection includes only that player's unrevealed data.
- Events are delivered through `AsyncStream<GameEvent>`. Events are `Sendable` enums with immutable values and no references to session state. Each committed transition appends events in deterministic order before publishing them.
- Cancellation of an agent decision does not implicitly discard other seats' accepted submissions or advance the phase. The caller may retry that seat; cancellation and retry behavior must be tested without timing-based sleeps.
- Agents may be `actor`s or `Sendable` structs. No shared class instances cross isolation boundaries.

### 5.6 Session state and persistence boundary

- The session actor owns the current `EDGameState`, current month and `GamePhase`,
  pending raw orders or goods offers for the active collection phase, and the
  terminal end-game result once scored.
- Pending submissions and raw-phase progress are keyed by stable player ID and
  are not part of a public state view. Snapshot persistence must nevertheless
  retain enough phase, pending-submission, and intermediate resolution state
  to resume a game without losing accepted decisions or revealing them early;
  schema versioning belongs to `EDPersistence`.
- Rule resolvers are synchronous pure functions and do not perform autosave,
  emit events, or mutate the input game state. `GameSession` commits each
  successful result, produces its ordered events, and invokes any repository
  boundary after the state transition is complete.
- A failed rule resolution commits neither a partial state nor a partial event
  sequence. The session returns a typed failure and remains resumable at a
  well-defined phase.

### 5.7 SOLID mapping

- **S**: calculator, validator, allocator, resolver and scorer are separate types, each with one reason to change.
- **O**: new variations are new policy types (`LoanPolicy`, `PartialFillPolicy`) injected into resolvers; the base resolver code is not edited.
- **L**: any `PlayerAgent` or `GameRepository` is substitutable (human, AI, scripted test agent; file, in-memory).
- **I**: small protocols (`MarketCalculating` is separate from `Scoring`); the UI sees read-only `PlayerView`, not the whole `GameState`.
- **D**: EDEngine depends on protocols; concrete types are chosen in one composition root (`GameFactory`).

## 6. Rule ambiguities and default decisions

The rulebook leaves these open. Each default is implemented behind a policy type so you can change it later without rewriting resolvers. Confirm or override before the relevant branch.

1. **Units beyond the calculator tables** (raw above 24 or goods above 16 total units). Default: extend the pattern linearly (+1 per raw unit, -2 per goods unit). Policy: `OutOfRangePolicy`.
2. **Finished goods price floor.** Rules only state a raw floor of $1. Default: also floor goods at $1. Policy: `PriceFloorPolicy`.
3. **Insufficient-funds player's raw units.** Rules say they cannot buy, but not whether their ordered units still count toward price. Default: they still count (units were announced publicly before payment).
4. **Which raw grades are consumed when substitutions are possible.** Default: use exact-recipe grades first, then the cheapest valid substitution; the allocator must find a feasible assignment across all offered goods jointly (small search). Policy: `ProductionAllocating`.
5. **Unsold goods.** Goods are only "manufactured" when sold, so raw certificates for unsold offers stay in inventory. No finished-goods inventory exists.
6. **Minimum raw bid after January.** Uses the previous month's market price, not the opening price.
7. **Variation 1 plus 2 interaction.** Loan is computed on the total cost of the units actually purchased after partial fill.
8. **Cash visibility.** Default public. Configurable `GameConfig.cashIsPublic`.
9. **Ties.** Reported as shared victory.

## 7. Test strategy

- **Rulebook examples first**: each branch includes tests derived directly from the text (for example raw price 40 with 15 units ordered becomes $45; goods with 0 units offered gives +11; goods with 6 units gives -1).
- **Property tests (hand-rolled generators)**: prices never below floor; total cash plus inventory value is conserved across a purchase; a valid allocation never uses more certificates than owned.
- **Golden game**: a scripted 3-player, 3-month game with fixed bids whose final standings are asserted exactly.
- **Concurrency**: tests run a driver with scripted async agents that respond out of order, then submit their values to `GameSession`, confirming no secret leaks, lost submissions, duplicate resolutions, or deadlocks.
- **Simulation harness**: seeded AI-vs-AI batches to catch crashes and degenerate strategies.

## 8. Branch catalogue

Each entry lists dependencies, scope and acceptance criteria. Names are the exact branch names to use: `feature/ED-###-slug`.

### Phase 0: Foundations

**ED-001 - package-scaffold.** Depends: none. Create the SwiftPM package with targets EDCore, EDEngine, EDAI, EDPersistence, EDTestSupport and matching test targets. Swift 6 language mode and strict concurrency on all. Add a CI workflow (`swift build`, `swift test`, macOS and Linux), `.gitignore`, `AGENTS.md`. Done when: empty package builds with zero warnings and one placeholder test passes.

**ED-002 - money-type.** Depends: 001. `Money` as an `Int`-backed value type (whole dollars), with arithmetic, comparison, `Codable`, `floored(atLeast:)`. Done when: arithmetic, overflow-safe operations and codable round-trip are tested.

**ED-003 - domain-enums-recipes.** Depends: 002. `RawGrade` (standard, fine, xFine), `GoodType` (a, b, c), `Recipe` data, opening prices, substitution relation (`canSubstitute(_:for:)`). Done when: recipes match FR-3 and substitution tests cover only the two legal pairs.

**ED-004 - game-config.** Depends: 003. `GameConfig` (player count 2-6, months, starting cash, per-player order cap, per-grade cap for 2 players, variation flags, cash visibility). Throwing validation. Done when: all rulebook tables are asserted for every player count and invalid counts throw typed errors.

**ED-005 - market-calculator.** Depends: 003. Protocol `MarketCalculating` plus `TableMarketCalculator` for raw and goods movement, with `OutOfRangePolicy` (default linear extension). Done when: every table value from section 4.5 is tested, plus out-of-range cases.

**ED-006 - price-board.** Depends: 002, 003, 005. `PriceBoard` value type: current price per raw grade and good, monthly history, `applying(movement:)` with `PriceFloorPolicy` (raw floor $1, goods floor default $1). Done when: floor behaviour and history append are tested.

### Phase 1: Player state and inputs

**ED-007 - inventory.** Depends: 003. `Inventory` (counts per raw grade) with add, remove (throwing on insufficient), total, and valuation at a `PriceBoard`. Done when: invariants (never negative) tested.

**ED-008 - player-state.** Depends: 002, 004, 007. `PlayerID`, `PlayerState` (name, cash, inventory, loans, starting cash), mutation helpers returning new values. Done when: spend and receive paths tested, including insufficient cash.

**ED-009 - order-and-offer-models.** Depends: 003. `RawOrder` (units and bid per grade), `GoodsOffer` (units and ask per type), plus total-unit helpers. Pure data, `Codable`, `Sendable`. Done when: construction and codable tests pass.

**ED-010 - raw-order-validation.** Depends: 004, 005, 006, 008, 009. `OrderValidating` for raw: total cap, 2-player per-grade cap, minimum bid (FR-6), non-negative units. Typed errors. Done when: every constraint has pass and fail tests, including January versus later months.

### Phase 2: Pure rules resolution

**ED-011 - raw-market-resolution.** Depends: 005, 006, 009. Given all submitted raw orders, compute total units per grade and new prices, resolved XFine, Fine, Standard. Done when: rulebook example, floor at $1 and zero-order cases pass.

**ED-012 - raw-purchase-resolution.** Depends: 008, 010, 011. Decide what each player buys: bid >= market buys all units at bid price; below buys none; insufficient funds buys nothing (FR-8, ambiguity 3). Output: purchases, cash changes, new inventories. Done when: cash and inventory conservation tests pass.

**ED-013 - production-allocator.** Depends: 003, 007. `ProductionAllocating`: given inventory and requested goods counts, return a feasible raw-certificate assignment or nil. Handles substitutions and joint feasibility across A, B and C. Done when: feasibility table tests, impossible requests and substitution preference (ambiguity 4) pass.

**ED-014 - goods-offer-validation.** Depends: 009, 013. Determine whether a player's offers are producible. Over-offering marks the player disqualified for the month. Done when: valid, invalid and boundary cases pass.

**ED-015 - goods-market-resolution.** Depends: 005, 006, 014. Compute goods prices from only valid offers (disqualified players excluded). Done when: rulebook examples (0 units gives +11, 6 units gives -1) and exclusion tests pass.

**ED-016 - goods-sales-resolution.** Depends: 008, 013, 015. Bid <= market sells all units at bid; above sells none. Apply allocator to consume certificates for sold goods and pay cash. Done when: sold units equal consumed recipe certificates and cash is conserved.

**ED-017 - month-resolver.** Depends: 011, 012, 014, 015, 016. Pure staged `EDMonthResolver`. Its raw stage takes the opening state and all raw orders and returns raw market outcomes plus post-purchase player states for the goods decision view. Its goods stage takes that intermediate value and all goods offers, then returns a `MonthResult` and completed next state. It composes existing validators, market, purchase, production/offer eligibility, and sales rules in rulebook order; it does not own phase state, collect submissions, publish events, or perform I/O. Done when: the raw stage supports a goods decision from updated inventory; a scripted full month matches hand-calculated numbers; over-offers are omitted from goods price totals; failed stage resolution returns no partial state.

**ED-018 - endgame-and-scoring.** Depends: 007, 008, 017. Sell leftover raw at final prices, compute profit per player, rank, detect ties. Done when: ranking, tie and zero-profit cases pass.

### Phase 3: Orchestration

**ED-019 - phase-state-machine.** Depends: 017, 018. `GamePhase` and pure `GamePhaseReducer` for legal transitions (raw-order submission, raw resolution, goods-offer submission, goods resolution, month summary, next month, finished). Illegal transitions throw typed errors. Done when: first, middle, and final month transition tables plus rejected transitions are tested.
**ED-020 - game-events.** Depends: 019. Immutable `GameEvent` enum (phase started, submissions revealed, prices posted, purchases made, sales made, month summarised, game finished) and an `EventLog` value. Done when: events round-trip as Codable, event ordering is deterministic, and no event exposes pending private submissions.
**ED-021 - hidden-information-views.** Depends: 019, 020. `PlayerView` projection: public board and certificates, cash according to config, own secrets only, others' pending bids/offers hidden until their reveal gate. Done when: leak tests check every seat before and after each reveal boundary.
**ED-022 - player-agent-protocol.** Depends: 021. `PlayerAgent` with async raw-order and goods-offer decisions using immutable `PlayerView`; agents return Sendable values and do not receive `GameSession` or `EDGameState`. Include `ScriptedAgent` in EDTestSupport. Done when: scripted callers drive deterministic submissions without embedding rule resolution in agents.
**ED-023 - game-session-actor.** Depends: 017, 018, 019, 020, 021, 022. `actor GameSession` is the one authoritative session coordinator: owns `EDGameState`, current phase, accepted private submissions, raw-stage month progress, event log/stream, and final score. It validates raw orders through `EDRawOrderValidator`, rejects duplicate/out-of-phase/unknown-seat input without mutation, calls the raw stage only after every seat has submitted, exposes safe updated-inventory views, then calls the goods stage only after all offers arrive. It invokes `EDEndGameScorer` only after the final month. Done when: a complete scripted game runs; concurrent out-of-order submissions produce exactly one resolution per gate and deterministic results/events; views/events reveal no pending secrets; invalid calls preserve state; cancellation/retry does not deadlock or lose accepted submissions.
**ED-024 - game-factory.** Depends: 023. Composition root: builds a session from validated `EDGameConfig`, seat identities, initial player states, and any session-owned infrastructure dependencies. Agents remain with the external driver; `GameSession` remains the lifecycle coordinator and the factory only wires dependencies. Done when: 2- to 6-seat sessions build, invalid configuration is rejected, and initial player cash matches configuration.

### Phase 4: Variations

**ED-025 - variation-1-loans.** Depends: 012. `LoanPolicy` protocol with `NoLoans` and `BrokerLoans` ($100 increments, minimum needed, $125 per $100 repaid at end). Integrate into purchase resolution and scoring. Done when: increments, repayment and profit-after-loans tests pass.

**ED-026 - variation-2-partial-fill.** Depends: 012. `PartialFillPolicy` with `AllOrNothing` and `ShortfallReduction` (lose one unit per dollar below market). Done when: boundary cases (shortfall equal to or greater than units) pass.

### Phase 5: Persistence

**ED-027 - game-snapshot.** Depends: 023. Codable, versioned `GameSnapshot` (game state, phase, active pending submissions, raw-stage month progress, terminal result/event cursor as required, schema version) with migration hook. Private pending submissions and intermediate progress are stored securely in the snapshot and are never copied into public views/events. Done when: round-trip equality at each phase, resume after raw resolution and mid-submission without loss/leak, and unknown-version rejection are tested.

**ED-028 - repository.** Depends: 027. `GameRepository` protocol, `InMemoryGameRepository` actor and `FileGameRepository` actor (atomic writes, injected directory URL). Done when: save, load, list, delete and corrupted-file handling are tested.

**ED-029 - resume-and-autosave.** Depends: 023, 028. `GameSession.resume(from:)` and an autosave subscriber on the event stream. Done when: a game saved mid-month resumes and finishes with the same result as an uninterrupted run.

### Phase 6: Agents and play modes

**ED-030 - ai-evaluator.** Depends: 005, 013. `MarketEvaluator`: estimates raw cost per good, expected margin and safe bid ranges given a `PlayerView`. Pure and deterministic. Done when: margin calculations match hand examples.

**ED-031 - ai-base-strategy.** Depends: 022, 030. `StrategyAgent` implementing `PlayerAgent` with an injected `RandomSource` and a `Strategy` protocol. Always produces valid orders and offers. Done when: 1,000 seeded random views yield zero validation errors.

**ED-032 - ai-personas.** Depends: 031. Persona strategies (for example Cautious, Aggressive, Copycat) as data plus tuning parameters, each with a stable `PersonaID` and display name for the UI avatar layer. Done when: personas produce measurably different aggregate behaviour in a simulation test.

**ED-033 - solo-and-passplay-setup.** Depends: 024, 032. Setup helpers: `soloGame(humanName:opponents:)` and `passAndPlayGame(names:)`, plus a `HandoffGate` API that tells the UI when to hide one player's view before showing the next. Done when: handoff ordering is tested for every seat count.

**ED-034 - simulation-harness.** Depends: 032. Headless runner for N seeded AI-vs-AI games with summary statistics (win rate, average profit). Done when: a 100-game run is reproducible for a fixed seed and finishes quickly.

**ED-035 - golden-game-and-docs.** Depends: all. Golden 3-player game test, public API doc comments review, `ARCHITECTURE.md` and a UI integration guide. Done when: docs build clean and golden test passes.

## 9. Tracker

Copy into an issue or markdown file and tick as you merge.

- [ ] ED-001 package-scaffold
- [ ] ED-002 money-type
- [ ] ED-003 domain-enums-recipes
- [ ] ED-004 game-config
- [ ] ED-005 market-calculator
- [ ] ED-006 price-board
- [ ] ED-007 inventory
- [ ] ED-008 player-state
- [ ] ED-009 order-and-offer-models
- [ ] ED-010 raw-order-validation
- [ ] ED-011 raw-market-resolution
- [ ] ED-012 raw-purchase-resolution
- [ ] ED-013 production-allocator
- [ ] ED-014 goods-offer-validation
- [ ] ED-015 goods-market-resolution
- [ ] ED-016 goods-sales-resolution
- [ ] ED-017 month-resolver
- [ ] ED-018 endgame-and-scoring
- [ ] ED-019 phase-state-machine
- [ ] ED-020 game-events
- [ ] ED-021 hidden-information-views
- [ ] ED-022 player-agent-protocol
- [ ] ED-023 game-session-actor
- [ ] ED-024 game-factory
- [ ] ED-025 variation-1-loans
- [ ] ED-026 variation-2-partial-fill
- [ ] ED-027 game-snapshot
- [ ] ED-028 repository
- [ ] ED-029 resume-and-autosave
- [ ] ED-030 ai-evaluator
- [ ] ED-031 ai-base-strategy
- [ ] ED-032 ai-personas
- [ ] ED-033 solo-and-passplay-setup
- [ ] ED-034 simulation-harness
- [ ] ED-035 golden-game-and-docs

## 10. Suggested milestones

- **M1 Rules core (ED-001 to ED-018):** you can resolve a full month and score a game from scripted inputs. No concurrency yet.
- **M2 Playable engine (ED-019 to ED-024):** a complete game runs headless with scripted agents.
- **M3 Variations and saves (ED-025 to ED-029).**
- **M4 AI and modes (ED-030 to ED-035):** ready for the UI team.

Branches within a phase marked with no dependency between them (for example ED-005 and ED-007, or ED-025 and ED-026) can be handed to agents in parallel on separate worktrees, since they touch different files.

## 11. Review checklist (per branch)

- Builds in Swift 6 mode with zero warnings on macOS and Linux.
- Only files in scope changed; diff is small.
- No UI imports, no `Date()`, no unseeded randomness, no `@unchecked Sendable`.
- Tests cite the rule they cover and include at least one rulebook example.
- Any resolved ambiguity is noted in the PR and matches section 6, or section 6 is updated.

## 12. Hard rules

Do not change raw material certificate enum's.