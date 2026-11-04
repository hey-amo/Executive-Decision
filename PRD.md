4. Product Requirements
4.1 Purpose
A deterministic, testable Swift engine that implements the complete rules of Executive Decision, so a separate UI layer can drive solo play against AI avatars and local pass-and-play.
4.2 Goals
• Faithful implementation of the base rules and both variations.
• Pure, deterministic rules core that is trivially unit-testable.
• Hidden-information correctness: bids stay secret until revealed; the engine can hand a UI a view that never leaks another player's secrets (needed for pass-and-play).
• Pluggable player agents (human via UI, AI personas) behind one protocol.
• Local save and resume.
• Swift 6 strict concurrency, no data races by construction.
4.3 Non-goals
UI of any kind, internet multiplayer, cloud backup, accounts, analytics, monetisation, art and avatar assets (the engine only exposes persona identity and behaviour).
4.4 Players
2 to 6 participants, any mix of humans and AI. Humans share one device (pass-and-play).
4.5 Functional requirements
• FR-1 Setup. Configurable player count (2-6) and month count (default 12). Starting cash by player count: 2 = $900, 3 = $600, 4 = $450, 5 = $350, 6 = $300.
• FR-2 Opening prices. Raw: XFine $40, Fine $30, Standard $20. Goods: A $140, B $115, C $90.
• FR-3 Recipes. A = XFine, XFine, Fine. B = Fine, Fine, Standard. C = Fine, Standard, Standard.
• FR-4 Market calculator. Raw movement = units - 10 for 0...24 units (-10 to +14). Goods movement = 11 - 2 x units for 0...16 units (+11 to -21). These ranges are hard limits: totals above 24 raw or 16 goods units count as exactly 24 or 16, and the excess is ignored. Movement is applied to the previous market price.
• FR-5 Raw order limits. Total units per player per month: 2p = 18, 3p = 12, 4p = 9, 5p = 7, 6p = 6. In a 2-player game, at most 12 units of any one grade.
• FR-6 Minimum raw bid. The price the grade would move to if only that player ordered it: previous price + movement(player's own units), floored at $1.
• FR-7 Raw pricing. New price per grade = previous + movement(total ordered units), never below $1. Grades are resolved XFine, Fine, Standard.
• FR-8 Raw purchase. Bid >= market: all units bought at the bid price. Bid < market: nothing. Affordability is checked at resolution, after prices post: if cash cannot cover the successful bids, all of that player's raw purchases for the month are voided (base rules). Passing, or ordering 0 units, is always allowed and counts as 0 units toward the price. Bots use an affordability calculation so they never submit a voided order.
• FR-9 Manufacturing. 3 raw units per good. Only substitutions: XFine for Fine, Fine for Standard (a higher grade may fill a lower slot, never the reverse). A human chooses which grades fill each recipe; bots always use the exact recipe grades.
• FR-10 Goods offers. Per type: units and asking price. A player may not offer more goods than their inventory can produce. Over-offering voids all of that player's offers for the month and excludes them from price determination. Separately, if the certificates a player names cannot actually back the goods sold (a delivery error), that player's sales for the month are voided, but their offers still counted toward the price (section 6, item 10).
• FR-11 Goods pricing and sales. Market = previous + movement(total valid offered units). Bid <= market: all units sold at the bid price. Bid > market: none. Sold goods consume the raw certificates needed to make them. There is no finished-goods inventory: unsold offers consume nothing and the raw certificates stay on hand.
• FR-12 Game end. After the final month, leftover raw is sold to the Broker at the final market price. Profit = final cash - starting cash (less loan repayments in Variation 1). Highest profit wins; tied players share the win. Profit may be negative.
• FR-13 Variation 1 (loans). A setup switch, off by default. When on, a shortfall found at resolution is covered by the smallest number of $100 loans that brings cash to zero or above, and nothing more. Each $100 costs $125 at the end.
• FR-14 Variation 2 (partial purchase). Dropped from scope for now; not implemented.
• FR-15 Hidden information. Bids and production intentions are secret until the reveal. Raw certificates (inventory) are public. Cash and certificates are public; the tally board (bids and planned offers) is private. Cash visibility is a simple setting, public by default.
• FR-16 Persistence. Full game state serialises to a versioned snapshot; the engine can resume from one. Autosave after each phase.
• FR-17 Agents. Every seat is driven by a PlayerAgent. The engine does not know whether it is a human or an AI.
• FR-18 Events. The engine publishes an ordered stream of immutable events so any UI can animate or log without polling.
4.6 Non-functional requirements
• Swift 6 language mode, strict concurrency complete, no warnings.
• Builds and tests on macOS and Linux with no Apple-only frameworks.
• Rules core has no I/O and no hidden dependencies, so a full 12-month game with scripted bids is reproducible byte for byte.
• Rules-core line coverage target: 90% or higher.
• A complete AI-vs-AI game should simulate in well under a second.

Size rule: one concept per branch, roughly 300 changed lines or fewer including tests. If an agent says it needs more, it must stop and propose a split (ED-012a, ED-012b) instead of growing the branch.