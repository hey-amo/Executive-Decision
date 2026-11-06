# Executive Decision — Amended Rules (Digital Edition)

These rules are the original *Executive Decision* rules (Sid Sackson) with every ambiguity resolved for the digital engine. Where this document and the original differ, **this document wins**. Changes and clarifications are marked **[Amended]** or **[Clarified]**, and every one is listed in the Decision Log at the end.

---

## 1. Game overview

Players run competing businesses. Each month they bid on raw materials, turn them into finished goods, and offer those goods for sale. Prices for both raw materials and finished goods move with total supply and demand across all players. The player with the greatest profit at the end wins.

Each month has three steps:

1. **Purchase** raw material certificates.
2. **Manufacture** finished goods (see 5; this is now a feasibility check, not a separate step).
3. **Sell** finished goods.

---

## 2. Setup

- 2–6 players.
- The number of months is chosen before play. Default is 12. Beginners may use fewer. Minimum is 1.
- Player IDs must be unique.

### 2.1 Starting cash and order limits

| Players | Starting cash | Max total raw units ordered per player per month | Max units of any one grade |
|---|---|---|---|
| 2 | $900 | 18 | 12 |
| 3 | $600 | 12 | no separate limit |
| 4 | $450 | 9 | no separate limit |
| 5 | $350 | 7 | no separate limit |
| 6 | $300 | 6 | no separate limit |

### 2.2 Materials, goods and opening prices

| Raw material | Opening price |
|---|---|
| XFine | $40 |
| Fine | $30 |
| Standard | $20 |

| Finished good | Opening price | Recipe (3 raw certificates) |
|---|---|---|
| A | $140 | XFine, XFine, Fine |
| B | $115 | Fine, Fine, Standard |
| C | $90 | Fine, Standard, Standard |

**[Clarified]** Opening prices apply to month 1 only. From month 2 onward, movement is applied to the previous month’s final price.

### 2.3 The Bank (replaces the Broker)

**[Amended]** There is no Broker. The Broker’s jobs are handled by the engine:

- **Bank / Ledger:** holds each player’s cash and loans, performs all arithmetic and payments. The Bank has unlimited funds.
- **Market price resolver:** totals the units and consults the Market Calculator.

### 2.4 Money

**[Clarified]** All money is whole dollars. No fractions or rounding anywhere.

---

## 3. Market Calculator

Movement is found by looking up the **total units** bid by all players for that item, then adding the movement to the previous price.

### 3.1 Raw materials (units 0–24)

| Units | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Move | −10 | −9 | −8 | −7 | −6 | −5 | −4 | −3 | −2 | −1 | 0 | +1 | +2 | +3 | +4 | +5 | +6 | +7 | +8 | +9 | +10 | +11 | +12 | +13 | +14 |

### 3.2 Finished goods (units 0–16)

| Units | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Move | +11 | +9 | +7 | +5 | +3 | +1 | −1 | −3 | −5 | −7 | −9 | −11 | −13 | −15 | −17 | −19 | −21 |

### 3.3 Hard limits **[Amended]**

The tables are hard limits. The lookup is clamped to the first and last column:

- Raw materials: a total above 24 units uses the 24-unit movement (**+14**).
- Finished goods: a total above 16 units uses the 16-unit movement (**−21**).
- The calculator never extrapolates and never goes below 0 units.
- **Units above the limit are still bought or sold normally.** They just stop moving the price further.

### 3.4 Price floors **[Amended]**

- Raw material and finished-goods prices never fall below **$1**.
- If the calculator would take a price to $0 or below, the price is set to $1.
- The $1 is the new starting point for the next month’s movement (there is no hidden negative price).

---

## 4. Step 1: purchasing raw material certificates

1. **Sealed bids.** Each player secretly submits an order for each grade: a number of units and a price per unit. One price per grade. Ordering 0 units of a grade means no bid on that grade.

2. **Minimum bid [Clarified].** The minimum bid for a grade is the price the grade would move to if **only that player** ordered it, but never less than $1:

   `minimum bid = max($1, current price + movement(player's own units of that grade))`

   Example: XFine is $40. A player orders 4 units. Movement for 4 units is −6, so the minimum bid is $34.

3. **Order limit [Clarified].** The limits in 2.1 apply to the units *ordered*, whether or not the bids later succeed.

4. **Affordability [Amended].** (Loans off.) The engine rejects any order where the worst-case cost exceeds the player’s cash:

   `Σ (units × bid) across all three grades  ≤  cash on hand`

   Because winners pay their bid (see step 6), this is the exact worst case. The old rule “a player without enough funds cannot buy that month” can no longer arise and is kept only as a defensive check. If loans are on (Variation 1), this check is skipped.

5. **Reveal [Clarified].** When all players have submitted, each player’s ordered **unit count for each grade** is announced to everyone. Bid prices stay secret.

6. **Pricing order [Clarified].** Prices resolve in the order **XFine → Fine → Standard**. For each grade: total ordered units → Market Calculator → new price (floored at $1).

7. **Who buys [Clarified].**

   | Player’s bid | Result |
   |---|---|
   | Equal to or higher than market price | Buys **all** units **at the bid price** (not the market price) |
   | Lower than market price | Buys no units (unless Variation 2) |

8. **Settlement.** Players pay the Bank and receive one certificate per unit. Certificates are public.

---

## 5. Step 2: manufacturing

**[Amended]** There is no finished-goods inventory. Manufacturing is not a separate phase. It is a **feasibility check** on the certificates a player already holds, performed when goods are offered (step 3).

- Three certificates make one unit of a good, per the recipe in 2.2.
- **Substitution is upward only [Clarified]:**
  - XFine may replace Fine.
  - Fine may replace Standard.
  - No other substitution is allowed (XFine **cannot** replace Standard; Fine **cannot** replace XFine).
- **Joint feasibility [Clarified].** The engine checks a player’s entire plan (A + B + C together) against their certificates, not each good in isolation.
- **Certificate choice [Clarified].** The engine, not the player, chooses which certificates are used. It uses the exact grade first, then the lowest grade that can legally substitute, so higher-grade certificates are kept.
- Certificates are consumed **only for goods that actually sell** (step 3.5).

---

## 6. Step 3: selling finished goods

1. **Sealed offers.** Each player secretly submits, per good (A, B, C), a number of units and an asking price per unit. The minimum ask is $1. There is no maximum ask. Zero units means no offer.

2. **Over-offer is blocked [Amended].** The engine rejects any offer the player cannot produce from their certificates (joint feasibility, see 5). The original penalty rules are kept only as defensive checks:
   - A player who offers more than they can make sells nothing that month and their offers are ignored when setting prices.
   - A player who cannot deliver the correct certificates for goods sold sells nothing that month.

3. **Reveal [Clarified].** When all players have submitted, each player’s offered unit count per good is announced. Asking prices stay secret.

4. **Pricing.** Prices for A, B and C resolve using the goods section of the Market Calculator (with the hard limit and $1 floor).

5. **Who sells [Clarified].**

   | Player’s ask | Result |
   |---|---|
   | Equal to or lower than market price | Sells **all** units **at the ask price** (not the market price) |
   | Higher than market price | Sells no units. **Nothing was made.** The certificates are kept. |

6. **Settlement.** The Bank pays the player for units sold and removes the certificates used for those units only.

---

## 7. All other months

Each month repeats steps 1–3. Market movement is added to the previous month’s final prices (3.4 floors apply).

**[Clarified]** Purchasing raw materials in the final month is allowed.

**[Clarified]** A player who submits nothing is treated as submitting an empty order or offer (no units).

**[Clarified]** The game contains no randomness. The same inputs always produce the same results.

---

## 8. Ending the game and scoring

1. After the last month, every unused certificate is sold to the Bank at the final month’s raw market price.
2. Unsold goods do not exist (see 5), so there is nothing else to value.
3. Any loans are repaid (see Variation 1).

   `Profit = final cash + certificate buy-back − starting cash − loan repayments`

4. The player with the highest profit wins.
5. **[Clarified]** If two or more players tie for the highest profit, they **share the win**.
6. **[Clarified]** Profit may be negative, and cash may end negative when loans are used.

---

## 9. Information visibility **[Clarified]**

| Public (everyone) | Private (that player only) |
|---|---|
| Current prices and full price history | Tally sheet (own bids, offers, results) |
| Certificates held by every player | Submissions not yet revealed |
| Cash on hand of every player | |
| Loan amounts | |
| Announced unit counts after each reveal | |
| Resolved results | |
| Whether each player has submitted (not what) | |

---

## 10. Variations

Both variations are optional and may be used separately or together.

### 10.1 Variation 1: loans

- If a player cannot pay for their purchase, they must take a loan from the Bank.
- Loans come only in blocks of **$100** ($100, $200, $300…).
- **[Clarified]** There is no limit on the number of blocks.
- **[Clarified]** The engine borrows automatically, **after purchases are resolved**, and only the **minimum number of blocks** that covers the shortfall. Voluntary extra borrowing is not allowed.
- **[Clarified]** With loans on, the affordability check in 4.4 is skipped.
- At game end the player repays **$125 for every $100 borrowed** (whole-dollar arithmetic).

### 10.2 Variation 2: partial fills

- If a bid is below market price, the player does not lose the whole order. They buy part of it at their bid price.
- Units bought = `max(0, units ordered − (market price − bid))`. One unit is lost for each dollar the bid is below market.
- **[Clarified]** The player’s **full ordered quantity** still counts toward the unit totals used to set prices.
- **[Clarified]** When combined with loans, loan size is based on the **reduced** purchase.

---

## 11. Decision Log

| # | Topic | Original rule | Decision |
|---|---|---|---|
| D1 | Broker | A person handles money and certificates. | Replaced by Bank/Ledger and market price resolver. Bank has unlimited funds. |
| D2 | Price paid and received | “All units at bid price.” | Kept literally: winners pay or receive their **bid/ask**, not the market price. |
| D3 | Price floors | Raw floor $1; goods undefined. | $1 floor for raw **and** goods, clamped each month; next movement starts from the clamped value. |
| D4 | Minimum bid | “Price if only that player ordered it.” | `max($1, current + movement(own units))`. |
| D5 | Order limit | “Entire order may not exceed.” | Counted on ordered units. 2-player game also limited to 12 per grade. |
| D6 | Reveal and order | “Announce XFine units,” then others. | All three grades are submitted together. Per-player unit counts are revealed; prices are not. Resolution order XFine → Fine → Standard. |
| D7 | Unsold goods | Unspecified. | Nothing was made. Certificates are kept. No finished-goods inventory. Manufacturing is a feasibility check. |
| D8 | Certificate choice | Player chooses. | Engine chooses: exact grade first, then lowest legal substitute. |
| D9 | Substitution | XFine for Fine, Fine for Standard. | Confirmed as **upward only**. No chaining (XFine cannot replace Standard). |
| D10 | Joint production | Per good, loosely. | Whole plan (A+B+C) must be jointly producible. |
| D11 | Unaffordable raw order | Player prohibited from buying that month. | **Blocked at submission** when `Σ(units × bid) > cash` (loans off). |
| D12 | Goods over-offer | Penalty: no sales and offers ignored. | **Blocked at submission.** Penalty retained only as a defensive check. |
| D13 | Certificate delivery error | Amended rule: no sales. | Unreachable, since the engine allocates certificates. Retained as a defensive check. |
| D14 | Calculator range | Tables 0–24 and 0–16. | **Hard limits.** Index clamped; excess units still trade but move the price no further. |
| D15 | Variation 2 pricing | Unspecified. | Full ordered quantity counts for price discovery. |
| D16 | Variation 1 loans | Blocks of $100; $125 repayment. | Unlimited; auto-borrow minimum blocks after purchases resolve; no voluntary borrowing. |
| D17 | Loans + partial fills | Unspecified. | Loan sized on the reduced purchase. |
| D18 | Scoring | “Most profit.” | `final cash + certificate buy-back − starting cash − loan repayments`. |
| D19 | Ties | Unspecified. | Shared win. |
| D20 | Negative results | Unspecified. | Negative profit and negative final cash allowed. |
| D21 | Final-month purchasing | Unspecified. | Allowed. |
| D22 | Missing submission | Unspecified. | Treated as empty. |
| D23 | Goods ask limits | Unspecified. | Minimum $1, no maximum. |
| D24 | Opening prices | Used in January. | Month 1 only. |
| D25 | Cash visibility | Unspecified. | **Public.** Certificates public. Tally sheet and unrevealed submissions private. |
| D26 | Money type | Unspecified. | Whole dollars only. |
| D27 | Randomness | None in the original. | Confirmed: fully deterministic. |

---

## 12. Worked example (January, 2 players, loans and partial fills off)

Both players start with $900. Opening prices: XFine $40, Fine $30, Standard $20; A $140, B $115, C $90.

**Orders**

| | XFine | Fine | Standard |
|---|---|---|---|
| Player 1 | 2 @ $33 | 1 @ $25 | none |
| Player 2 | 1 @ $32 | 2 @ $30 | none |

Minimum-bid checks: XFine alone, 2 units → −8 → $32 (P1’s $33 is legal). XFine alone, 1 unit → −9 → $31 (P2’s $32 is legal). Fine alone, 1 unit → −9 → $21 (P1’s $25 is legal). Fine alone, 2 units → −8 → $22 (P2’s $30 is legal).

**Prices**

- XFine: 3 units → −7 → **$33**. P1’s bid ($33) is equal, so P1 buys 2 units at $33 = $66. P2’s bid ($32) is below, so P2 buys none.
- Fine: 3 units → −7 → **$23**. P1 buys 1 at $25 = $25. P2 buys 2 at $30 = $60.
- Standard: 0 units → −10 → **$10**.

After purchases: P1 has $809 and holds XFine ×2, Fine ×1. P2 has $840 and holds Fine ×2.

**Goods offers**

- P1 offers A ×1 at $130 (producible: XFine, XFine, Fine).
- P2 offers nothing (two certificates cannot make any good).

**Prices:** A 1 unit → +9 → **$149**; B 0 units → +11 → **$126**; C 0 units → +11 → **$101**.

**Sales:** P1’s ask ($130) is at or below $149, so P1 sells 1 unit **at $130** (the ask, not the market price). P1’s cash is now $939 and the three certificates are consumed.

End of January: P1 $939, no certificates. P2 $840, Fine ×2.
