# Executive Decision Engine: PRD and Branch Plan

Unofficial hobby Swift implementation of Sid Sackson's *Executive Decision*. Scope of this document: the **game engine only** (no UI). Version 0.1.

## 1. How to use this document with an AI coding agent

The plan below is split into tiny, numbered branches (`ED-001`, `ED-002`, ...). You hand the agent **one branch brief at a time**. Each brief is self-contained, so the agent never needs the whole project in its head.

**Workflow**

1. Put the *Repo Rules* (section 2) in an `AGENTS.md` (or `CLAUDE.md`) at the repo root. Agents read it on every task.
2. Start from an up-to-date `main`. Create the branch named in the brief: `feature/ED-012-production-allocator`.
3. Paste the *Branch Brief Template* (section 3) filled in from the branch catalogue (section 8). One branch per prompt.
4. Agent implements, runs `swift build` and `swift test`, and commits with the prefix `ED-012:`.
5. You review the diff, merge to `main` (squash or fast-forward), then start the next branch. Do not stack unmerged branches unless the brief says so.
6. Tick the branch off in the tracker (section 9).

**Size rule:** one concept per branch, roughly 300 changed lines or fewer including tests. If an agent says it needs more, it must stop and propose a split (`ED-012a`, `ED-012b`) instead of growing the branch.

## 2. Repo Rules (paste into AGENTS.md)

- Swift Package, `swift-tools-version: 6.0`, `swiftLanguageModes: [.v6]` on every target. Zero concurrency warnings is a hard requirement.
- **No UI code.** No SwiftUI, UIKit, AppKit, Combine, or `@MainActor` anywhere in the engine. The engine must build and test on Linux.
- Domain types are `struct` or `enum`, `Sendable`, `Equatable`, `Hashable` where sensible, and `Codable` where they are persisted. Prefer value semantics.
- Shared mutable state lives only inside an `actor`. No `@unchecked Sendable`, no `nonisolated(unsafe)`, no global mutable variables, no `DispatchQueue`. Any exception needs a written justification in the PR.
- Rules logic is **pure functions or value-type reducers**: no I/O, no `Date()`, no `Int.random`. Randomness and time enter through injected protocols.
- Depend on protocols at module boundaries (dependency inversion). Concrete wiring happens in one composition root.
- Errors are typed enums (`throws(RulesError)` or a `Result`). No `fatalError` or `try!` in library code.
- Public API gets doc comments that cite the rule being implemented (for example "Rules: Purchasing step").
- Tests use Swift Testing (`import Testing`). Every rule has at least one example test taken from the rulebook, plus edge cases.
- Do not touch files outside the scope listed in the branch brief. Do not rename or reformat unrelated code.
- Commit style: `ED-###: imperative summary`.

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

- **FR-1 Setup.** Configurable player count (2-6) and month count (default 12). Starting cash by player count: 2 = $900, 3 = $600, 4 = $450, 5 = $350, 6 = $300.
- **FR-2 Opening prices.** Raw: XFine $40, Fine $30, Standard $20. Goods: A $140, B $115, C $90.
- **FR-3 Recipes.** A = XFine, XFine, Fine. B = Fine, Fine, Standard. C = Fine, Standard, Standard.
- **FR-4 Market calculator.** Raw movement = units - 10 for 0...24 units (-10 to +14). Goods movement = 11 - 2 x units for 0...16 units (+11 to -21). Movement is applied to the *previous* market price.
- **FR-5 Raw order limits.** Total units per player per month: 2p = 18, 3p = 12, 4p = 9, 5p = 7, 6p = 6. In a 2-player game, at most 12 units of any one grade.
- **FR-6 Minimum raw bid.** The price the grade would move to if only that player ordered it: previous price + movement(player's own units), floored at $1.
- **FR-7 Raw pricing.** New price per grade = previous + movement(total ordered units), never below $1. Grades are resolved XFine, Fine, Standard.
- **FR-8 Raw purchase.** Bid >= market: all units bought at the **bid** price. Bid < market: nothing. If cash cannot cover the total, the player buys nothing that month (base rules).
- **FR-9 Manufacturing.** 3 raw units per good. Only substitutions: XFine for Fine, Fine for Standard (a higher grade may fill a lower slot, never the reverse).
- **FR-10 Goods offers.** Per type: units and asking price. A player may not offer more goods than their inventory can produce. Over-offering voids all of that player's offers for the month **and** excludes them from price determination.
- **FR-11 Goods pricing and sales.** Market = previous + movement(total valid offered units). Bid <= market: all units sold at the **bid** price. Bid > market: none. Sold goods consume the raw certificates needed to make them.
- **FR-12 Game end.** After the final month, leftover raw is sold to the Broker at the final market price. Profit = final cash - starting cash (less loan repayments in Variation 1). Highest profit wins; ties are reported as ties.
- **FR-13 Variation 1 (loans).** Shortfalls are covered by loans in $100 increments, only as much as needed. Each $100 costs $125 at the end.
- **FR-14 Variation 2 (partial purchase).** A raw bid below market still buys units, minus one unit per dollar of shortfall (floor at zero).
- **FR-15 Hidden information.** Bids and production intentions are secret until the reveal. Raw certificates (inventory) are public. Cash is treated as public by default (configurable).
- **FR-16 Persistence.** Full game state serialises to a versioned snapshot; the engine can resume from one. Autosave after each phase.
- **FR-17 Agents.** Every seat is driven by a `PlayerAgent`. The engine does not know whether it is a human or an AI.
- **FR-18 Events.** The engine publishes an ordered stream of immutable events so any UI can animate or log without polling.

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
- **EDAI**: `PlayerAgent` implementations and personas. Depends on EDCore and EDEngine protocols.
- **EDPersistence**: snapshot codec and repositories. Depends on EDCore and EDEngine.
- **EDTestSupport**: fixtures, scripted agents, builders (test-only).

Dependencies point inward; the UI app (a separate repo or target) depends on EDEngine, EDAI and EDPersistence only through their public protocols.

### 5.2 Core concepts

- Value types: `Money`, `RawGrade`, `GoodType`, `Recipe`, `GameConfig`, `Inventory`, `PlayerState`, `PriceBoard`, `RawOrder`, `GoodsOffer`, `MonthResult`, `GameState`.
- Pure services behind protocols: `MarketCalculating`, `OrderValidating`, `ProductionAllocating`, `RawMarketResolving`, `GoodsMarketResolving`, `Scoring`.
- Orchestration: `GamePhase` (state machine reducer, a pure value type) and `GameSession` (an `actor` that owns the current `GameState`, collects secret submissions, advances phases, emits events).
- Edges: `PlayerAgent` (async decisions), `GameRepository` (save/load), `RandomSource` (seedable RNG for AI).

### 5.3 Phase flow per month

`rawBidding` -> `rawReveal and resolution` -> `goodsBidding` -> `goodsReveal and resolution` -> `monthSummary` -> next month or `finished` (with end-game settlement).

### 5.4 Concurrency design

- All state transitions are pure `(State, Input) -> (State, [Event])` functions, so they need no isolation.
- `GameSession` is the only actor holding mutable state. Agents are asked for decisions with `async` calls and return `Sendable` values; secrets are held inside the actor until all seats have submitted.
- Events are delivered through `AsyncStream<GameEvent>`. Events are `Sendable` enums with no references.
- Agents may be `actor`s or `Sendable` structs. No shared class instances cross isolation boundaries.

### 5.5 SOLID mapping

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
- **Concurrency**: tests run `GameSession` with scripted async agents that respond out of order to confirm no secret leaks and no deadlocks.
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

**ED-017 - month-resolver.** Depends: 012, 016. Pure `MonthResolver` that takes a state plus both sets of submissions and returns a `MonthResult` and next state. Done when: a scripted single month matches hand-calculated numbers.

**ED-018 - endgame-and-scoring.** Depends: 007, 008, 017. Sell leftover raw at final prices, compute profit per player, rank, detect ties. Done when: ranking, tie and zero-profit cases pass.

### Phase 3: Orchestration

**ED-019 - phase-state-machine.** Depends: 017, 018. `GamePhase` and a pure reducer for legal transitions (raw bidding, raw resolution, goods bidding, goods resolution, summary, finished). Illegal transitions throw. Done when: full-month transition table tested.

**ED-020 - game-events.** Depends: 019. Immutable `GameEvent` enum (phase started, bids revealed, prices posted, purchases made, sales made, month summarised, game finished) and an `EventLog` value. Done when: events round-trip as Codable and ordering is deterministic.

**ED-021 - hidden-information-views.** Depends: 019, 020. `PlayerView` projection: public board and certificates, own secrets only, others' bids hidden until reveal. Done when: leak tests assert no other seat's pending bids appear in any view.

**ED-022 - player-agent-protocol.** Depends: 021. `PlayerAgent` with `func chooseRawOrder(view:) async -> RawOrder`, `func chooseGoodsOffer(view:) async -> GoodsOffer`, plus `ScriptedAgent` in EDTestSupport. Done when: scripted agents drive a deterministic turn in tests.

**ED-023 - game-session-actor.** Depends: 019, 020, 021, 022. `actor GameSession`: owns `GameState`, collects submissions concurrently from agents, reveals when complete, advances phases, publishes `AsyncStream<GameEvent>`. Done when: a full scripted game completes, with a test that submits out of order and a test that cancels cleanly.

**ED-024 - game-factory.** Depends: 023. Composition root: builds a session from `GameConfig` and seat list. Done when: 2- to 6-seat games build and bad configs throw.

### Phase 4: Variations

**ED-025 - variation-1-loans.** Depends: 012. `LoanPolicy` protocol with `NoLoans` and `BrokerLoans` ($100 increments, minimum needed, $125 per $100 repaid at end). Integrate into purchase resolution and scoring. Done when: increments, repayment and profit-after-loans tests pass.

**ED-026 - variation-2-partial-fill.** Depends: 012. `PartialFillPolicy` with `AllOrNothing` and `ShortfallReduction` (lose one unit per dollar below market). Done when: boundary cases (shortfall equal to or greater than units) pass.

### Phase 5: Persistence

**ED-027 - game-snapshot.** Depends: 023. Codable, versioned `GameSnapshot` (state, config, event log, schema version) with migration hook. Done when: round-trip equality and unknown-version rejection are tested.

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
