# Executive Decision — Swift Package Plan (PRD + Architecture)

> **Status:** Planning only. No production code is written here. Small signature sketches appear in code blocks purely to pin down intent.
> **Scope:** A UI-free Swift 6.x package containing the rules engine, bank arithmetic and game-session coordination for the Sid Sackson game *Executive Decision*. No `@MainActor`, no SwiftUI/UIKit, no GameKit.

---

## 0. Contents

1. Goals and non-goals
2. Amended rules (digital edition) and decision log
3. Architecture overview (diagrams)
4. Package and folder structure
5. File responsibilities
6. Public vs private API surface
7. Data flow: one month, end to end
8. Concurrency, memory and safety rules
9. Information secrecy model
10. Swift file-header rule
11. Testing strategy (stubs, mocks, fakes explained)
12. Golden scenario
13. Milestones
14. Risks and open items

---

## 1. Goals and non-goals

**Goals**

- A deterministic, fully testable engine for 2–6 players over N months (default 12).
- Pure rule logic that does not care who called it. Each rule unit takes plain inputs and returns plain outputs.
- One place for *all* money arithmetic (the **Bank**).
- A session coordinator that collects sealed submissions, decides when to resolve, and publishes ordered events through a protocol the host app supplies.
- Both optional variations (loans, partial fills) as configuration switches.
- Swift 6 strict concurrency, `Sendable` throughout, no singletons, no observers/KVO/Combine, no global mutable state.

**Non-goals**

- UI, artwork, sound, animation, persistence UI.
- Networking or GameKit (a transport can be layered on later, the engine stays pure).
- AI opponents (a bot is just something that calls the same submit API).

---

## 2. Amended rules (digital edition)

The original rules are kept, with the gaps below resolved. This is the rulebook the engine implements.

### 2.1 Setup

| Players | Starting cash | Max total raw units ordered per month | Max units of one grade |
|---|---|---|---|
| 2 | $900 | 18 | 12 |
| 3 | $600 | 12 | none beyond total |
| 4 | $450 | 9 | none beyond total |
| 5 | $350 | 7 | none beyond total |
| 6 | $300 | 6 | none beyond total |

- Months: configurable, default 12, minimum 1.
- Opening prices apply to month 1 only. Every later month moves from the previous month’s final price.

| Raw material | Opening | Finished good | Opening | Recipe |
|---|---|---|---|---|
| XFine | $40 | A | $140 | XFine, XFine, Fine |
| Fine | $30 | B | $115 | Fine, Fine, Standard |
| Standard | $20 | C | $90 | Fine, Standard, Standard |

### 2.2 Market calculator (hard limits)

Movement is looked up by total units bid across all players, then added to the previous price.

**Raw materials** (index 0–24; movement = `units − 10`)

```text
Units:     0   1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16  17  18  19  20  21  22  23  24
Movement: -10 -9  -8  -7  -6  -5  -4  -3  -2  -1   0  +1  +2  +3  +4  +5  +6  +7  +8  +9 +10 +11 +12 +13 +14
```

**Finished goods** (index 0–16; movement = `11 − 2 × units`)

```text
Units:     0   1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16
Movement: +11 +9  +7  +5  +3  +1  -1  -3  -5  -7  -9 -11 -13 -15 -17 -19 -21
```

**Hard limit rule:** the table index is clamped to `0…24` (raw) and `0…16` (goods). A total above the limit uses the last row. Units above the limit are still bought or sold; they simply stop moving the price further. The calculator never extrapolates.

### 2.3 Price floors

- Raw materials and finished goods never fall below **$1**.
- After each month’s movement the result is clamped to $1, and the next month’s movement applies from that clamped value (no hidden negative price).

### 2.4 Phase 1: purchasing raw material certificates

1. All players submit sealed orders for all three grades at once. One `(units, bid)` pair per grade. Zero units means no bid on that grade.
2. **Minimum bid** for a grade = `max($1, currentPrice + movement(only this player's units of that grade))`.
3. **Order cap** counts *ordered* units, whether or not they later win (see table in 2.1).
4. **Funds check at submission (loans off):** the engine rejects an order if `Σ(units × bid)` across all grades exceeds the player’s cash. Because winners pay their *bid*, this is the exact worst-case cost. With loans on, this check is skipped (see 2.8).
5. After all submissions, per-player unit counts for each grade are revealed to everyone. Prices stay hidden.
6. Grades resolve in the order **XFine → Fine → Standard**. For each grade: total units → calculator → new price (floored at $1).
7. A bid **≥ market price** buys all its units **at the bid price**. A bid below market buys nothing (unless partial fills is on, see 2.9).
8. Players pay the Bank and receive certificates. Certificates are public.

### 2.5 Phase 2: manufacturing (no separate step)

There is no finished-goods inventory. Manufacturing is a **feasibility check** on certificates already held, and certificates are consumed only for goods that actually sell.

- Three certificates make one unit of a good, per the recipe.
- **Substitution is upward only:** XFine may replace Fine; Fine may replace Standard. Nothing else (XFine cannot replace Standard, and Fine cannot replace XFine).
- The engine verifies the player’s *whole* goods plan (A + B + C together) is jointly producible.
- The engine, not the player, chooses which certificates are consumed: exact grade first, then the lowest grade that can legally substitute, so the highest-value certificates remain.

### 2.6 Phase 3: selling finished goods

1. Players submit sealed offers: per good `(units, ask)`. The minimum ask is $1 and there is no maximum.
2. **Over-offer is blocked at submission** (consistent with the funds check). The old penalty rules (“prohibited from selling”, “offers ignored for pricing”) remain as defensive validation, but should be unreachable.
3. Unit counts are revealed, then prices for A, B, C resolve using the goods calculator (index clamped to 0–16, floor $1).
4. An ask **≤ market price** sells all units **at the ask price**. An ask above market sells nothing and **nothing was made**: certificates are kept.
5. The Bank pays the player and removes the certificates for the sold units only.

### 2.7 End of game and scoring

- After the final month, unused certificates are sold to the Bank at the final month’s raw market price. Unsold goods do not exist, so there is nothing else to value.
- `Profit = final cash + certificate buy-back − starting cash − loan repayments`.
- Highest profit wins. Equal highest profit is a **shared win** (all tied players are winners).
- Profit may be negative.

### 2.8 Variation 1: loans

- Loans are only available in $100 blocks, no stated cap (unlimited).
- After purchases resolve, if cash is insufficient the engine auto-borrows the **minimum** number of $100 blocks that covers the shortfall. Voluntary extra borrowing is not allowed.
- At game end the Bank collects **$125 per $100 borrowed** (integer arithmetic).
- Final cash can be negative.

### 2.9 Variation 2: partial fills

- If a bid is below market, the player still buys `max(0, units − (marketPrice − bid))` units at the bid price.
- The player’s **full ordered quantity** still counts toward price discovery.
- Combined with loans, loan sizing uses the reduced purchase.

### 2.10 Other rules

- Whole dollars only (`Int`-backed money, no floating point).
- A missing submission is treated as an empty order or offer.
- Purchasing in the final month is allowed.
- The game has no randomness. The same inputs always give the same outputs.
- Player count must be 2–6, with unique `PlayerID`s.

### 2.11 Decision log

| # | Question | Decision |
|---|---|---|
| D1 | Broker role | Not a person. Replaced by **Bank/Ledger** (money, loans, math) and **market price resolver** (totals + calculator). |
| D2 | Price paid | Winners pay/receive their **bid/ask**, not the market price. |
| D3 | Price floors | $1 for raw and goods, clamped each month. |
| D4 | Minimum bid | `max($1, price after moving by only your units)`. |
| D5 | Unsold goods | Nothing was made; certificates kept. No finished-goods inventory. |
| D6 | Unaffordable raw order | Blocked at submission by `Σ(units × bid) ≤ cash` (loans off). |
| D7 | Calculator limits | Hard clamp to table bounds; excess units still trade. |
| D8 | Goods over-offer | Blocked at submission via joint feasibility check. |
| D9 | Cash visibility | Cash on hand and certificates are **public**. Tally sheet and pending submissions are **private**. |
| D10 | Ties | Shared win. |
| D11 | Certificate allocation | Engine chooses, exact grade first, lowest legal substitute next. |
| D12 | Loans | Unlimited, auto-borrow minimum $100 blocks, $125 repayment per $100. |
| D13 | Final-month buying | Allowed. |
| D14 | Missing submissions | Treated as empty. |

---

## 3. Architecture overview

### 3.1 Layering (dependencies point downward only)

```text
┌─────────────────────────────────────────────────────────────┐
│ EDGameFlow                                                  │
│ GameSession (actor) · phase machine · submission collector  │
│ event queue · public/private views                          │
└───────┬─────────────────────────┬───────────────────────────┘
        │ uses protocols          │ publishes via protocol
        ▼                         ▼
┌──────────────────────┐   ┌───────────────────────────┐
│ EDRules              │   │ Host app (outside package)│
│ pure rule units      │   │ PlayerProviding           │
│ validate · resolve   │   │ GameEventSink             │
└───────┬──────────────┘   └───────────────────────────┘
        │
        ▼
┌──────────────────────┐
│ EDBank               │  all arithmetic, ledger state
│ Banking · Ledger     │
└───────┬──────────────┘
        │
        ▼
┌──────────────────────────────────────────────┐
│ EDCore                                       │
│ models · IDs · config · orders · results     │
│ events · tally sheet (no logic, Codable)     │
└──────────────────────────────────────────────┘
```

### 3.2 Who decides, who calculates, who coordinates

```text
 MODELS (EDCore)            RULES (EDRules)              COORDINATION (EDGameFlow)
 ───────────────            ───────────────              ─────────────────────────
 what things ARE            what is LEGAL / what         WHEN things happen and
 (data, no logic)           HAPPENS (pure functions)     in what ORDER

 RawOrder          ───►     RawOrderValidator    ◄────   GameSession asks "is this
 GoodsOffer                 ProductionPlanner            submission legal?"
 PriceBoard                 PriceResolver
 Inventory                  PurchaseResolver     ◄────   GameSession says "everyone
 MonthResult                SaleResolver                 has submitted, resolve"
                            EndGameResolver
                                 │
                                 ▼ every number goes through
                            Banking (EDBank)
```

### 3.3 Phase machine

```text
            ┌──────────────────────────────────────────────┐
            │                                              │
            ▼                                              │
┌────────────────────────┐   all players    ┌─────────────────────────┐
│ awaitingRawOrders(m)   │ ───submitted───► │ awaitingGoodsOffers(m)  │
└────────────────────────┘   resolve raw    └───────────┬─────────────┘
            ▲                                           │ all submitted
            │ month < total                             ▼ resolve goods
            │                                  ┌────────────────────┐
            └──────────────────────────────────│ monthComplete(m)   │
                                               └─────────┬──────────┘
                                                         │ month == total
                                                         ▼
                                               ┌────────────────────┐
                                               │ gameOver           │
                                               └────────────────────┘
```

`monthComplete` is transient. The session immediately emits `monthEnded`, then either starts the next month or finishes the game.

### 3.4 Delegation: self-contained units that report back via protocol

```text
GameSession ──calls──► RawPurchaseResolver ──returns──► RawStageOutcome (value)
     │                       (pure, knows nothing
     │                        about the session)
     │
     └──publishes──► GameEventSink.receive(event)   (host-supplied protocol)
```

Rule units never import `EDGameFlow` and never hold a reference back to the session. They take a value in and return a value out.

---

## 4. Package and folder structure

```text
ExecutiveDecision (Swift package, swift-tools-version 6.0, language mode 6)
├── Package.swift
├── Sources
│   ├── EDCore                         (models only, no behaviour beyond trivial accessors)
│   │   ├── Identity
│   │   │   ├── PlayerID.swift
│   │   │   ├── PlayerProfile.swift
│   │   │   └── AvatarResource.swift
│   │   ├── Money
│   │   │   └── Money.swift
│   │   ├── Materials
│   │   │   ├── RawGrade.swift
│   │   │   ├── GoodKind.swift
│   │   │   ├── Recipe.swift
│   │   │   ├── PerGrade.swift
│   │   │   └── PerGood.swift
│   │   ├── Inventory
│   │   │   └── CertificateHoldings.swift
│   │   ├── Orders
│   │   │   ├── RawOrder.swift
│   │   │   └── GoodsOffer.swift
│   │   ├── Market
│   │   │   ├── MarketPrices.swift
│   │   │   └── PriceBoard.swift
│   │   ├── Configuration
│   │   │   ├── GameConfiguration.swift
│   │   │   ├── GameVariations.swift
│   │   │   └── PlayerCountProfile.swift
│   │   ├── Results
│   │   │   ├── PurchaseResult.swift
│   │   │   ├── SaleResult.swift
│   │   │   ├── MonthResult.swift
│   │   │   └── FinalStandings.swift
│   │   ├── Tally
│   │   │   └── TallySheet.swift
│   │   └── Events
│   │       └── GameEvent.swift
│   │
│   ├── EDBank                         (all arithmetic + money state)
│   │   ├── Banking.swift
│   │   ├── StandardBank.swift
│   │   ├── Ledger.swift
│   │   ├── LoanRecord.swift
│   │   └── LedgerError.swift
│   │
│   ├── EDRules                        (pure, stateless, Sendable)
│   │   ├── Calculator
│   │   │   ├── MarketCalculating.swift
│   │   │   ├── StandardMarketCalculator.swift
│   │   │   └── MovementTables.swift
│   │   ├── Market
│   │   │   ├── MinimumBidCalculator.swift
│   │   │   └── PriceResolver.swift
│   │   ├── Raw
│   │   │   ├── RawOrderValidator.swift
│   │   │   └── RawPurchaseResolver.swift
│   │   ├── Production
│   │   │   └── ProductionPlanner.swift
│   │   ├── Goods
│   │   │   ├── GoodsOfferValidator.swift
│   │   │   └── GoodsSaleResolver.swift
│   │   ├── Scoring
│   │   │   ├── ProfitCalculator.swift
│   │   │   └── EndGameResolver.swift
│   │   └── Errors
│   │       └── RuleViolation.swift
│   │
│   ├── EDGameFlow                     (coordination)
│   │   ├── GameSession.swift
│   │   ├── GameSessionDependencies.swift
│   │   ├── GamePhase.swift
│   │   ├── PhaseMachine.swift
│   │   ├── GameState.swift
│   │   ├── SubmissionCollector.swift
│   │   ├── EventQueue.swift
│   │   ├── PlayerProviding.swift
│   │   ├── GameEventSink.swift
│   │   ├── PublicGameView.swift
│   │   └── SubmissionError.swift
│   │
│   └── EDEngine                       (umbrella product, re-exports the above)
│       └── Exports.swift
│
└── Tests
    ├── EDCoreTests
    ├── EDBankTests
    ├── EDRulesTests
    └── EDGameFlowTests
```

### 4.1 Target dependency graph

```text
EDEngine ──► EDGameFlow ──► EDRules ──► EDBank ──► EDCore
```

No target depends upward. Consumers import `EDEngine` only.

### 4.2 `Package.swift` sketch (intent only)

```swift
// swift-tools-version: 6.0
// Products: one library "EDEngine".
// Targets:  EDCore, EDBank (-> EDCore), EDRules (-> EDBank, EDCore),
//           EDGameFlow (-> EDRules, EDBank, EDCore), EDEngine (-> EDGameFlow).
// Settings: swiftLanguageModes [.v6]; no unsafeFlags; no external dependencies.
// Tests:    Swift Testing (import Testing), one test target per source target.
```

No third-party dependencies. Swift Testing ships with the toolchain.

---

## 5. File responsibilities

### 5.1 EDCore (models)

| File | Responsibility |
|---|---|
| `PlayerID.swift` | Stable, hashable, `Sendable`, `Codable` identifier wrapping a `UUID` or `String`. |
| `PlayerProfile.swift` | Immutable player description: `id`, `displayName`, `avatarResource`. |
| `AvatarResource.swift` | Placeholder wrapper around a string key (e.g. `"avatar_placeholder_1"`). The host maps it to artwork later. The engine never interprets it. |
| `Money.swift` | `Int`-backed whole-dollar value type. Comparable and Codable. **No arithmetic operators are exposed**; arithmetic lives in EDBank. |
| `RawGrade.swift` | Enum `standard`, `fine`, `xFine` plus the upward-substitution relationship (`canSubstitute(for:)`). |
| `GoodKind.swift` | Enum `a`, `b`, `c`. |
| `Recipe.swift` | Maps each `GoodKind` to its three required `RawGrade`s. |
| `PerGrade.swift` | Fixed-shape container with one value per grade. Prevents missing-key optionals from dictionaries. |
| `PerGood.swift` | Same idea for A/B/C. |
| `CertificateHoldings.swift` | Count of certificates per grade held by one player. Public information. |
| `RawOrder.swift` | A player’s sealed raw order: `PerGrade<RawOrderLine>`, with `RawOrderLine(units, bid)`. |
| `GoodsOffer.swift` | A player’s sealed goods offer: `PerGood<GoodsOfferLine>`, with `GoodsOfferLine(units, ask)`. |
| `MarketPrices.swift` | Raw prices and goods prices for one point in time. |
| `PriceBoard.swift` | Opening prices plus month-by-month history of `MarketPrices`. |
| `GameConfiguration.swift` | Player profiles, months, variations, opening prices. Validated at construction. |
| `GameVariations.swift` | `OptionSet` with `loans` and `partialFills`. |
| `PlayerCountProfile.swift` | Starting cash and unit caps for 2–6 players. |
| `PurchaseResult.swift` | Per-player, per-grade outcome of the raw stage (units ordered, units bought, bid, price paid). |
| `SaleResult.swift` | Per-player, per-good outcome of the goods stage. |
| `MonthResult.swift` | Everything notable about one resolved month. |
| `FinalStandings.swift` | Profit per player, winners (possibly several), ordering. |
| `TallySheet.swift` | One player’s private record of their own bids and results per month. |
| `GameEvent.swift` | Enum of ordered, `Sendable`, `Codable` events published by the session. |

### 5.2 EDBank (all arithmetic)

| File | Responsibility |
|---|---|
| `Banking.swift` | Protocol listing every calculation the game needs: line totals, order worst-case cost, apply-movement-with-floor, loan blocks needed, interest owed, profit. |
| `StandardBank.swift` | Default `Banking` implementation using overflow-checked `Int` arithmetic. Stateless `struct`. |
| `Ledger.swift` | Value-type store of each player’s cash and loan balance. Mutating operations (`debit`, `credit`, `borrow`) are transactional: they succeed fully or leave state untouched. Takes a `Banking` at init. |
| `LoanRecord.swift` | Number of $100 blocks borrowed by a player. |
| `LedgerError.swift` | Failure cases: unknown player, insufficient funds, arithmetic overflow. |

### 5.3 EDRules (pure, stateless, `Sendable`)

| File | Responsibility |
|---|---|
| `MarketCalculating.swift` | Protocol: movement for `(kind, totalUnits)`. |
| `StandardMarketCalculator.swift` | Table lookup with the hard-limit index clamp. |
| `MovementTables.swift` | The raw (0–24) and goods (0–16) movement data. Data only. |
| `MinimumBidCalculator.swift` | Computes the legal floor for a bid given current price and the player’s own units. |
| `PriceResolver.swift` | Totals units, asks the calculator, applies via `Banking`, floors at $1, returns the new price. |
| `RawOrderValidator.swift` | Checks caps, per-grade cap (2p), minimum bids, affordability (loans off), positive values. |
| `RawPurchaseResolver.swift` | The whole raw stage: reveal totals, price XFine → Fine → Standard, decide winners, apply partial fills, work out loans, return a value describing outcomes. Does **not** mutate global state. |
| `ProductionPlanner.swift` | Joint feasibility check for A/B/C against holdings with upward substitution, plus deterministic certificate allocation for sold units. |
| `GoodsOfferValidator.swift` | Rejects offers the player cannot produce, and invalid asks. |
| `GoodsSaleResolver.swift` | The whole goods stage: price A, B, C, decide sales at ask, compute certificates to consume. |
| `ProfitCalculator.swift` | Computes per-player profit from final cash, buy-back and loans using `Banking`. |
| `EndGameResolver.swift` | Sells unused certificates at the final price, produces `FinalStandings` with ties. |
| `RuleViolation.swift` | Typed errors for rule failures. |

### 5.4 EDGameFlow (coordination)

| File | Responsibility |
|---|---|
| `GameSession.swift` | The `actor`. Owns `GameState`, accepts submissions, resolves stages when complete, publishes events. The only mutable object in the package. |
| `GameSessionDependencies.swift` | Struct bundling every injected protocol (validator, resolvers, bank, calculator, event sink). Offers a `standard(...)` factory that builds fresh instances. |
| `GamePhase.swift` | Enum of phases with the month index. |
| `PhaseMachine.swift` | Pure function: current phase + facts → next phase. |
| `GameState.swift` | Internal aggregate: configuration, ledger, board, holdings, tally sheets, phase. |
| `SubmissionCollector.swift` | Holds sealed submissions for the current phase and answers “is everyone in?”. Contents are never exposed until resolution. |
| `EventQueue.swift` | Internal FIFO of events, drained by exactly one publisher so ordering survives actor reentrancy. |
| `PlayerProviding.swift` | Protocol that supplies `PlayerProfile`s for a game. |
| `GameEventSink.swift` | Protocol the host implements to receive ordered events. |
| `PublicGameView.swift` | Read-only snapshot of public information (prices, history, certificates, cash, phase, who has submitted). |
| `SubmissionError.swift` | Typed errors returned to callers: wrong phase, unknown player, duplicate submission, wrapped rule violation. |

### 5.5 EDEngine

| File | Responsibility |
|---|---|
| `Exports.swift` | Re-exports the public surface of all targets so consumers write one `import EDEngine`. |

---

## 6. Public vs private API surface

| Concept | Access | Why |
|---|---|---|
| EDCore model types and their stored properties | `public` (read-only, `let`) | Host UI needs to read them; immutability keeps them thread safe. |
| EDCore initialisers with validation | `public` | Invalid values should be impossible to build. |
| `Money` internals | `public` read, `internal` write path | Math goes through Bank only. |
| Rule **protocols** (`MarketCalculating`, `Banking`, resolvers, validators) | `public` | Tests and hosts can substitute them. |
| Rule **default implementations** | `public struct` with `public init` | Hosts can use defaults without extra setup. |
| Helper types, tables, intermediate values | `internal` or `private` | Not part of the contract. |
| `GameSession` | `public actor` | Entry point. |
| `GameState`, `SubmissionCollector`, `EventQueue`, `PhaseMachine` | `internal` | Implementation detail of the session. |
| `PlayerProviding`, `GameEventSink` | `public` protocols | Host implements them. |
| Everything else | default to `internal`/`private` | Promote only when required. |

Use `package` access for anything shared between targets that should not be visible to consumers (for example validators’ helper types).

---

## 7. Data flow: one month, end to end

```text
Host app                    GameSession (actor)              Rules / Bank
────────                    ───────────────────              ────────────
submitRawOrder(p, order) ─► validate phase, player
                            RawOrderValidator ─────────────► caps, min bids, funds
                            ◄──── ok / RuleViolation
                            SubmissionCollector.store
   (repeat for each player)
                            all in? ──yes──►
                            publish rawOrdersRevealed (counts only)
                            RawPurchaseResolver ───────────► PriceResolver ─► Calculator + Bank
                                                             decide winners, partial fills
                                                             loan blocks (Bank)
                            ◄──── RawStageOutcome (value)
                            Ledger debit/borrow, holdings update, price board update
                            publish pricesPosted, purchasesSettled, loanIssued?
                            phase = awaitingGoodsOffers

submitGoodsOffer(p, offer)► GoodsOfferValidator ───────────► ProductionPlanner (joint feasibility)
   (repeat for each player)
                            all in? ──yes──►
                            publish goodsOffersRevealed
                            GoodsSaleResolver ─────────────► PriceResolver, ProductionPlanner (allocation)
                            ◄──── GoodsStageOutcome (value)
                            Ledger credit, consume certificates, board update, tally sheets
                            publish goodsPricesPosted, salesSettled, monthEnded
                            next month, or EndGameResolver ► publish gameEnded(FinalStandings)
```

### 7.1 Event list

```text
gameStarted
monthStarted(month)
rawOrdersRevealed(month, unitsPerPlayerPerGrade)
rawPricesPosted(month, prices)
purchasesSettled(month, [PurchaseResult])
loanIssued(month, player, blocks)           (only if loans on)
goodsOffersRevealed(month, unitsPerPlayerPerGood)
goodsPricesPosted(month, prices)
salesSettled(month, [SaleResult])
monthEnded(month, MonthResult)
gameEnded(FinalStandings)
```

Events are value types, `Sendable` and `Codable`, delivered in order, exactly once.

### 7.2 Production feasibility rule (for `ProductionPlanner`)

Let `needX`, `needF`, `needS` be the grade requirements of the whole plan before substitution, and `x`, `f`, `s` the certificates held. The plan is producible if and only if:

```text
needX                 ≤ x
needX + needF         ≤ x + f
needX + needF + needS ≤ x + f + s
```

Allocation (deterministic): fill `needX` from XFine; fill `needF` from Fine first, then XFine; fill `needS` from Standard first, then Fine, then XFine. This always satisfies the rule when feasible and preserves the highest grades.

---

## 8. Concurrency, memory and safety rules

1. **One mutable owner:** `GameSession` is an `actor`. Everything else is an immutable `struct`/`enum` conforming to `Sendable`.
2. **No `@MainActor`, no `@unchecked Sendable`, no `nonisolated(unsafe)`, no global mutable state, no singletons.** Anything needed is passed in.
3. **No observers:** no Combine, no `NotificationCenter`, no KVO, no `AsyncStream` broadcasters. Output goes through the injected `GameEventSink` protocol. Optional later: an adapter that bridges the sink to an `AsyncStream` can live in a separate target if a host wants it.
4. **Reentrancy:** state is fully committed *before* any `await` on the sink. Events are queued and drained by a single loop so a submission arriving during publication cannot reorder events.
5. **Typed throws:** use `throws(SubmissionError)` / `throws(RuleViolation)` so callers handle exhaustive cases.
6. **No force unwraps, no `try!`, no `fatalError` in library code.** Impossible states are made unrepresentable (`PerGrade`, `PerGood`, validated initialisers).
7. **Arithmetic:** overflow-checked, centralised in `Banking`.
8. **Memory:** no classes outside the actor; no reference cycles possible. The sink is held strongly by the dependencies struct (it is the host’s object; the host decides lifetime). The session never captures `self` in escaping closures.
9. **Determinism:** no `Date()`, no random, no `UUID()` inside rule units. Anything non-deterministic is injected (e.g., ID generation lives in the host or in a provider).
10. **Prefer functional style:** rule units are `(input) -> output` with no hidden state.
11. **Protocols over concrete types** at every seam so tests can substitute stubs.

---

## 9. Information secrecy model

```text
PUBLIC (anyone can read)                PRIVATE (only that player)
────────────────────────                ──────────────────────────
Price board + history                   TallySheet (own bids, results)
Certificates held by each player        Pending, unrevealed submissions
Cash on hand of each player             
Revealed per-player unit counts         
Resolved results and events             
Who has / hasn't submitted              
Loan counts (decision D12 record)        
```

- `PublicGameView` is produced by the session and contains only public data.
- `tallySheet(for:)` returns that player’s sheet. The engine has no concept of authentication, so **the host app is responsible for only showing a tally sheet to its owner** (hot-seat or network). This boundary is documented in the API comments.
- Pending submissions live only inside `SubmissionCollector` and are never exposed through any view.

---

## 10. Swift file-header rule

Every `.swift` file begins with a two-part comment: the file name, then one to three plain-English lines saying what the file does.

```swift
// MinimumBidCalculator.swift
// Works out the lowest legal bid for a raw grade: the price it would move to
// if only this player ordered it, never below $1.
```

Rules:

1. First line is the exact file name.
2. Following lines describe *what it does*, in plain language, no more than three lines.
3. One primary type per file. The file name matches that type.
4. Tests follow the same header rule and add what they verify.
5. Update the header when responsibility changes.

---

## 11. Testing strategy

Use Swift Testing (`import Testing`). All tests run without a UI, network or clock.

### 11.1 Stubs, mocks and fakes (plain English)

| Term | What it is | Example here |
|---|---|---|
| **Stub** | A stand-in that returns fixed, canned answers. | `StubPlayerProvider` returns the same 3 players every time. |
| **Mock** | A stand-in that *records* how it was used so the test can check it. | `RecordingEventSink` stores every event it receives, then the test asserts the order. |
| **Fake** | A simplified but working version. | An in-memory `PlayerProviding` that builds players from a list. |

Convention: declare stubs as `private` inside the test file that uses them. Promote one to a shared `internal` test helper only when three or more files need it.

### 11.2 Sketch of a stub (intent only)

```swift
// A private stub that always returns the same two players, so session tests
// do not depend on any real player source.
private struct StubPlayerProvider: PlayerProviding {
    let profiles: [PlayerProfile]
    func players() async throws -> [PlayerProfile] { profiles }
}
```

```swift
// A private mock that remembers every event, in order, for assertions.
private actor RecordingEventSink: GameEventSink {
    private(set) var events: [GameEvent] = []
    func receive(_ event: GameEvent) async { events.append(event) }
}
```

```swift
// A private stub calculator with a flat movement, to isolate resolver logic
// from the real tables.
private struct StubMarketCalculator: MarketCalculating {
    let movement: Int
    func movement(for kind: MarketKind, totalUnits: Int) -> Int { movement }
}
```

### 11.3 Test plan by target

| Target | Key cases |
|---|---|
| EDCoreTests | Config validation (2–6 players, duplicate IDs, months ≥ 1); `PerGrade`/`PerGood` coverage; Codable round-trips; start cash and caps per player count. |
| EDBankTests | Line totals; overflow detection; floor at $1; loan blocks for shortfalls of $1, $100, $101; interest `$125 per $100`; ledger transactions are all-or-nothing. |
| EDRulesTests | Calculator at 0, 1, 24, 25+, 100 (raw) and 0, 16, 17+ (goods); minimum bid with clamp and floor; validators (caps, 2p grade cap, funds block, over-offer); partial fill arithmetic; loans interaction; feasibility conditions (all three inequalities); allocation prefers exact grade; substitution only upward; EndGame ties and negative profits. |
| EDGameFlowTests | Wrong phase, unknown player, duplicate submission; completion triggers resolution once; event order exactly as 7.1; reentrancy (submit while events are publishing); public view never leaks pending data; full game from month 1 to `gameOver`. |

Property-style checks (hand-rolled, deterministic seeds): the allocator never consumes more than held; feasible plans always allocate; price never below $1; money is conserved except for Bank flows.

---

## 12. Golden scenario (hand-checked, use as an end-to-end test)

Two players, loans off, partial fills off, January. Both start with $900.

**Raw orders**

| | XFine | Fine | Standard |
|---|---|---|---|
| P1 | 2 @ $33 | 1 @ $25 | none |
| P2 | 1 @ $32 | 2 @ $30 | none |

Minimum-bid checks: XFine, 2 units alone → −8 → $32 (P1 bids 33 ✔); XFine, 1 unit → −9 → $31 (P2 bids 32 ✔); Fine, 1 unit → −9 → $21 (P1 bids 25 ✔); Fine, 2 units → −8 → $22 (P2 bids 30 ✔).

**Resolution**

- XFine total 3 units → −7 → **$33**. P1 (33 ≥ 33) buys 2 at $33 = $66. P2 (32 < 33) buys none.
- Fine total 3 units → −7 → **$23**. P1 (25) buys 1 = $25. P2 (30) buys 2 = $60.
- Standard total 0 units → −10 → $10.

**After purchases:** P1 cash $809, holds XFine ×2, Fine ×1. P2 cash $840, holds Fine ×2.

**Goods offers**

- P1 offers A ×1 @ $130. Producible: XFine, XFine, Fine. ✔
- P2 offers nothing (cannot form 3 certificates for any good, since it holds only 2).

**Resolution**

- A total 1 unit → +9 → $149. B total 0 → +11 → $126. C total 0 → +11 → $101.
- P1’s ask $130 ≤ $149 → sells 1 at **$130** (the ask, not the market). Cash $939. Certificates consumed.

**End of January:** P1 $939, no certificates. P2 $840, Fine ×2.

---

## 13. Milestones

| # | Milestone | Done when |
|---|---|---|
| M1 | Package skeleton, EDCore models, `Money`, config validation | Builds under Swift 6 strict concurrency with zero warnings; core tests pass. |
| M2 | EDBank | All arithmetic tests pass, including overflow and loan blocks. |
| M3 | EDRules: calculator, price resolver, minimum bid | Table and clamp tests pass. |
| M4 | EDRules: raw validator and purchase resolver, both variations | Golden scenario raw half passes. |
| M5 | EDRules: production planner, goods validator and resolver | Feasibility/allocation property checks pass; golden scenario goods half passes. |
| M6 | EDRules: scoring and end game | Ties, negatives, loan repayment verified. |
| M7 | EDGameFlow: session, collector, phase machine, event queue | Full 12-month scripted game matches expected events. |
| M8 | Hardening | Reentrancy tests, public-view leak tests, documentation comments on all public API, header rule audit. |

---

## 14. Risks and open items

| Risk | Mitigation |
|---|---|
| Tally sheet privacy depends on the host | Documented boundary; engine never exposes pending data. |
| Hand-written tables have typos | Tables are checked by formulas in tests (`units − 10`, `11 − 2 × units`) *and* by the explicit rows. |
| Actor reentrancy reorders events | Commit-then-queue design plus dedicated reentrancy tests. |
| Feasibility logic subtle | Closed-form inequality plus allocation property tests against brute force on small cases. |
| Variation interplay (loans + partial fills) | Dedicated cross-variation tests. |

**Remaining open items:** none blocking. Future extensions (bots, networking transport, persistence) are intentionally outside this package.
