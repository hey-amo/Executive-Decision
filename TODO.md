# Game Logic TODO

Scope: Swift package game logic only. UI, avatars, local persistence, and online
multiplayer are excluded.

Statuses:
- **Complete**: implemented and covered by tests as a standalone rule or helper.
- **In progress**: a related model or rule primitive exists, but the complete game
  behavior is not yet implemented or connected.

## 1. Game setup and initial state

1.1: **In progress** — Add validated game setup for 2–6 players and a duration of
  6–12 months.
1.2: **In progress** — Assign starting cash by player count ($900, $600, $450,
  $350, or $300).
1.3: **In progress** — Initialize the opening market prices for all raw materials
  and finished goods.
1.4: **In progress** — Model the 28-card supply for each raw-material grade and
  track certificates held by each player.
- **In progress** — Establish a game session with its players, broker/economy,
  settings, market state, and first month. `ExecutiveDecisionGame` currently
  stores basic game fields but does not validate or initialize a playable game.

## 2. Turn order and game progression

2.1: **Complete** — Provide a turn-order helper that can shuffle players, advance
  to the next player, and count completed rounds.
2.2: **In progress** — Connect player turn order to each game phase and track which
  players have submitted or completed their decisions.
2.3: **In progress** — Implement the monthly phase sequence: raw-material orders,
  manufacturing, and finished-goods offers.
2.4: **In progress** — Advance through months using the agreed game duration, carry
  market prices forward, and enter the end-of-game phase at the right time.
- **In progress** — Validate legal game-state transitions; the current state
  enum does not drive or enforce transitions.

## 3. Raw-material market and purchasing

3.1: **Complete** — Define raw-material types, opening prices, calculator movement,
  supported unit ranges, and the $1 minimum price.
3.2: **In progress** — Validate orders against per-player and per-grade unit caps,
  including the two-player per-grade cap.
3.3: **In progress** — Enforce the minimum permitted bid price.
3.4: **In progress** — Aggregate valid player orders by grade and calculate/post
  each month's market price from total demand and the previous month's price.
3.5: **In progress** — Resolve successful purchases at each player's bid price;
  unsuccessful bids buy nothing under the standard rule.
3.6: **In progress** — Apply the affordability rule: if a player cannot pay for
  the total successful purchase, they buy no raw materials that month.
3.7: **In progress** — Implement the optional partial-purchase rule as a setting:
  reduce units by the bid-to-market-price difference and test its boundaries.
3.8: **In progress** — Integrate purchase settlement with wallets, certificates,
  and monthly tally entries.

## 4. Manufacturing and inventory

4.1: **Complete** — Define finished-good recipes A, B, and C.
4.2: **Complete** — Determine whether a recipe can be made from an inventory,
  including the permitted Extra Fine-for-Fine and Fine-for-Standard
  substitutions.
4.3: **In progress** — Track each player's raw-material inventory and update it
  when materials are bought, consumed, or sold at game end.
4.4: **In progress** — Add manufacturing actions that produce only goods supported
  by available materials and consume the recipe materials.
4.5: **In progress** — Cover multiple units, combinations of goods, and inventory
  edge cases with tests.

## 5. Finished-goods market and sales

5.1: **Complete** — Define finished-good opening prices and calculator movement,
  including valid unit ranges.
5.2: **In progress** — Aggregate valid offers and calculate/post monthly finished-
  goods market prices using current market state.
5.3: **In progress** — Resolve sales at the player's asking price when it is at or
  below market price; otherwise sell none of that offer.
5.4: **In progress** — Reject an over-offer when a player offers more goods than
  they can manufacture; disregard all of that player's offers in the month's
  market calculation as the rules specify.
5.5: **In progress** — Settle sale proceeds through wallets, consume certificates
  for sold goods, and record actual units and amounts on the tally.

## 6. Economy, loans, and optional rules

6.1: **Complete** — Provide wallet credit/debit operations with balance bounds and
  delegate notification after successful transactions.
6.2: **In progress** — Create loans only when the loan setting is enabled and a
  player needs funds to complete a raw-material purchase; enforce $100
  increments and borrow only the shortfall.
6.3: **In progress** — Apply the rules' $125 repayment for each $100 borrowed.
  Current repayment code debits the stored loan amount, so the loan amount and
  repayment amount still need an explicit, tested rule.
6.4: **In progress** — Connect the `allowLoans` and
  `allowPartialRawMaterialPurchases` settings to the corresponding game rules.

## 7. Tally and end-of-game results

7.1: **Complete** — Give each player an independent tally sheet with immutable
  monthly order/sale entries, monthly totals, yearly totals, and duplicate-month
  protection.
7.2: **In progress** — Populate tally entries from resolved purchases and sales,
  including unsuccessful quantities and actual amounts paid or received.
7.3: **In progress** — At game end, sell unused raw-material certificates at the
  final month's market price and account for outstanding loan repayments.
7.4: **In progress** — Calculate final company funds and determine the winner from
  the completed game results.

## 8. Rule verification

8.1: **Complete** — Test the market calculator tables and boundaries, recipes and
  allowed substitutions, turn-order helper, wallet operations, and tally
  aggregation.
8.2: **In progress** — Add integration tests for a complete month and full game,
  covering market updates, purchases, production, sales, money, inventory,
  optional rules, and final scoring together.
