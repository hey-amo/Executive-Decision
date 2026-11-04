# Executive Decision Engine Smoke-Test Plan

## Status

Planning only. No smoke-test behavior has been implemented yet. This plan is
based on the rules in `README.md` and the current `EDEngine` source and tests.

## 1. Purpose and scope

Build a console-driven, rules-based smoke test of the game engine. It will run
without launching or testing the UI, use six bot players, play every month of
one complete game, and verify the end-of-game result.

The test should exercise the real game rules and state transitions. It must not
pass merely by assigning phase values or balances directly to make the output
look complete. Where the engine does not yet support a rules step, record the
gap and implement the required engine behavior before claiming that step passed.

## 2. Rules-derived starting state

- Use the maximum supported count: six players.
- Give each player the rules-defined starting capital of **$300**.
- Use a **12-month game** as the recommended full-game run: this covers
  January through December and tests the complete final-month/end-game path.
  Confirm this duration before implementation if a shorter first run is
  preferred; six months is also supported by the rules.
- Start the three raw-material markets at Standard $20, Fine $30, and Extra
  Fine $40; start finished goods A at $140, B at $115, and C at $90.
- Model the stated stock of 28 certificates for each raw-material grade if
  stock is part of the engine’s intended state.
- Keep optional rules off in the baseline run (loans and partial raw-material
  purchases). They can receive focused follow-up coverage if desired.
- Use fixed player identities and a reproducible turn order so a failure can
  be repeated and compared.

## 3. Bot policy and turn discipline

Use a small, deterministic bot policy that makes legal, explainable decisions.
Log each bot’s decision and its reason (for example: available cash,
inventory, current prices, and production capacity). Keep the policy simple;
the purpose is to exercise game mechanics, not to prove that a strategy wins.

Do not assert a particular raw-material order quantity or market outcome as a
game invariant. The rules make quantity and bid price strategic choices. Check
that each bot's chosen order is legal and that the resulting transaction is
resolved correctly under the rules.

For manufacture, choose goods only when the bot can supply the recipe from its
inventory, allowing only the documented substitutions: Extra Fine for Fine,
and Fine for Standard. For sales, never offer more finished units than were
manufactured and remain unsold.

Only one player may be in an active turn at a time. Await completion of that
player’s decision and resolution before advancing the turn. Raw-material
purchasing may let bots enter a `thinking`/`ready` state concurrently, as the
rules require concealed orders before market resolution, but the market must
not resolve until all six are ready. If concurrent readiness is implemented,
it is a submission barrier, not overlapping player turns or transactions.

## 4. Per-month execution sequence

For every month, print a month-start snapshot and run these steps in order:

1. **Purchase raw materials**
   - Each bot submits quantities and bid prices for the three grades.
   - Enforce the six-player combined limit of six units per player.
   - Collect all submitted orders, total units by grade, and calculate each
     market price from the prior month’s price (or opening price in January).
   - Apply the $1 raw-material price floor.
   - Award all units only when the player’s bid is at least the market price;
     charge the player’s bid price for each purchased unit.
   - Enforce funds and available certificate inventory. Document how the
     engine handles a player who cannot afford the entire purchase; the
     default rules prohibit that purchase.
2. **Manufacture products**
   - Each bot chooses legal production based on its inventory and recipe.
   - Consume the exact required materials, including only allowed substitutions.
   - Record the manufactured inventory for the selling step.
3. **Sell finished goods**
   - Each bot submits legal quantities and asking prices.
   - Calculate each finished-good market price from the previous market price
     and total valid offerings.
   - Sell all units offered at the asking price when asking price is at or
     below market price; otherwise sell none.
   - Credit revenue and consume materials used by sold goods, consistent with
     the game’s inventory model.
4. **Month close**
   - Record each player’s purchase and sale entries on that player’s tally
     sheet.
   - Print a month-close board and player summary.
   - Advance the month only after all players and phases have completed.

After the final month, run the rules-defined end-game processing: sell each
player’s unused raw-material certificates at the final month’s market price,
apply loan repayment only if loans are enabled, calculate final totals, and
announce the winner. Verify the intended behavior of the `endOfYear` state
against the engine lifecycle; do not skip or fabricate it just to reach
`gameOver`.

## 5. Console output requirements

Use or extend `EDGameDebugLogger` to produce readable, chronological console
logs. At minimum, each phase boundary and meaningful transaction should log:

- Month number/name and total game duration.
- Current game phase and active player (or the explicit all-ready barrier
  during raw-material order collection).
- The six players, their cash, and relevant status (including inventory,
  production, loans, and readiness where available).
- A text rendering of the main game board: raw-material and finished-good
  current prices, plus the market change or unit total used to derive them.
- Bot decisions, market calculations, purchases, production, sales, cash
  changes, and end-game accounting.
- Errors with enough context to identify month, player, phase, and attempted
  action; errors must fail the test rather than silently fall back.

Add a console-printing entry point for one player’s tally sheet. It should show
monthly quantities ordered/purchased and offered/sold, their bid/asking prices,
amounts paid/received, and month/year totals. The smoke-test summary should
print all six tally sheets and final standings.

## 6. Structured smoke-test notes

Create `SmokeTestNotes.md` at the repository root when smoke-test
implementation begins. Keep notes factual and categorized; do not record
unobserved assumptions as findings. Suggested structure:

| Category | Month/phase | Observation | Expected rule/behavior | Result/severity | Follow-up |
|---|---|---|---|---|---|
| Setup | — | What was observed | Rule or expected engine behavior | Pass / gap / defect | Action |
| State transition | Month / phase | What was observed | Expected next state | Pass / gap / defect | Action |
| Market | Month / item | Inputs and calculated result | Calculator/rule expectation | Pass / gap / defect | Action |
| Player action | Month / player | Decision and result | Legal-action expectation | Pass / gap / defect | Action |
| Accounting | Month / player | Cash, inventory, and tally change | Conservation/total expectation | Pass / gap / defect | Action |
| End game | Final month | Liquidation, repayment, ranking | End-game rule expectation | Pass / gap / defect | Action |
| Logging | Month / phase | Missing or unclear output | Required log fields | Pass / gap / defect | Action |

Use concise evidence such as the relevant log excerpt or assertion name. Record
the test run/configuration and distinguish an engine defect from a missing
engine capability or an ambiguity in the written rules.

## 7. Verification criteria

The full smoke test passes only if:

- Setup produces exactly six players, each with $300, with the expected initial
  phase, month, settings, and opening market state.
- All 12 months execute in order and each month completes the purchase,
  manufacture, sale, and close steps before advancing.
- Every action is legal; market movements and prices use the README tables;
  purchases, sales, and end-game liquidation follow the stated thresholds.
- Player cash, material inventory, finished goods, and tally entries remain
  consistent with completed transactions.
- The active-turn rule is respected, and no player/phase is silently skipped.
- End-game processing reaches `gameOver`, prints all tally sheets and final
  standings, and produces a winner consistent with the final scoring rule.
- The console output includes all required state/board details, and the notes
  file captures any observed gap or defect in the structured format above.

The smoke test should not be considered proof that a rule works solely because
its final phase was reached: add assertions for the corresponding state and
accounting effects.

## 8. Current implementation gaps and planning risks

These are source-review findings, not results from a smoke-test run:

### 8.1 Starting capital

- ~~`EDGameSetupManager.startGame` creates players with zero coins; it does not
  apply the six-player $300 starting-capital rule.~~

### 8.2 Executive Decision Game

- `ExecutiveDecisionGame` advances through setup, purchase, manufacture,
  selling, month boundaries, end-of-year, and game-over via `advancePhase()`.
  The market board tracks prices and 28 certificates per raw-material grade;
  players track raw-material holdings and a month-scoped production/offering/
  sales ledger. The ledger is not a finished-goods inventory: goods are not
  carried between months.

  Still outstanding:
  - **8.2.1** Readiness is an explicit player acknowledgement, but is not yet
    tied to a submitted order or completed phase action. Players can currently
    mark themselves ready without a transaction to verify.
  - **8.2.2** Raw-material purchases are not resolved against bids, available
    certificate stock, player funds, or player inventory as one game
    transaction.
  - **8.2.3** Production is not yet resolved by applying recipes and permitted
    substitutions to raw-material holdings; recording production does not
    consume those materials.
  - **8.2.4** Finished-good offerings and sales are not yet resolved against
    market prices, and sales do not credit player funds or consume the
    corresponding production.
  - **8.2.5** Month close does not record a completed month's transactions on
    each player's tally sheet.
  - **8.2.6** The final transition to `gameOver` does not liquidate unused raw
    materials or repay enabled loans.
  - ~~**8.2.7** The game does not yet enforce a single active player or wait
    for all players at a simultaneous-order phase barrier.~~
- ~~**8.3** `EDTurnOrderManager` can track a turn order, but it is not connected
  to the game and does not model player readiness or phase barriers.~~ The
  manager is now owned by the game. One active player follows the configured
  order in each purchase, manufacture, and sale phase. `advancePhase()` waits
  until every player is marked ready, then clears readiness for the next phase.
  For concealed purchase orders, this barrier represents collecting every
  player's order before market resolution; it does not mean players act at the
  same time.
~~**8.4** `EDGameDebugLogger` now renders market prices, player raw-material
holdings, the current month's production/offering/sales, active player, turn
order, readiness barrier, and only the current month's tally-sheet entries.~~
- **8.5** The README market calculator supports raw-material totals from 0 to 24.
  Six players may each order up to six units, so a valid combined total could
  exceed that table’s range. The smoke-test bot policy must keep each grade’s
  total in range, or the rules/engine behavior for larger totals must be
  resolved before broader stress coverage.
- **8.6** The stated 28 certificates per grade and the engine’s 12-unit
  `maxMaterialUnitsCanHold` constant need a clear distinction between market
  stock and per-player carrying capacity.
- **8.7** `EDGameState.endOfYear` is now reached after the final month's sale phase and
  advances to `gameOver`. Final raw-material liquidation and loan repayment
  are not implemented yet.
- **8.8** Existing tests cover setup validation, market calculations, recipes,
  substitutions, tallies, wallets, and loans individually. They do not yet
  exercise a complete playable month or game.

## 9. Proposed implementation order

1. Agree on the 12-month baseline and clarify the end-of-year/market-range
   ambiguities above.
2. Fill the engine prerequisites needed for a real full-game run: correct
   starting cash, game state for prices/inventories, and explicit,
   testable phase/turn transitions. Starting cash, board/player state,
   phase/month progression, turn order, and readiness barriers are implemented;
   transaction operations and action-verified readiness remain.
3. Implement and unit-test the purchase, manufacture, sale, month-close, and
   finalization operations using existing rule helpers where possible.
4. Complete `EDGameDebugLogger` with phase snapshots and per-player
   tally-sheet printing. Market-board and current player-inventory rendering
   are now present.
5. Add a deterministic six-bot `EDSmokeTests` scenario that runs all months,
   awaits one active player at a time, logs decisions, and asserts state and
   accounting invariants.
6. Create and populate `SmokeTestNotes.md` with categorized observations from
   actual runs; rerun the smoke test after fixes and preserve any remaining
   gaps as explicit findings.
7. Run the targeted engine tests and the complete smoke test through Swift
   Package Manager; document the exact command and outcome in the test report
   or notes.
