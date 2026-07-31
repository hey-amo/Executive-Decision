# Executive Decision

An unofficial hobby Swift implementation of the board game by "Sid Sackson".

This will be a minimalist game, with no multiplayer mode.

# Expected Features:

- Simple, minimalist UI
- AI avatars
- Solo play
- Pass-and-play
- Local data save

# Not doing:

- Multiplayer via Internet
- Clouddata backups

--

# Game Overview

In Executive Decision, each player takes the role of a CEO of a manufacturing firm . You need to decide how much of each type of raw materialto buy, how much you are willing to pay for it, how much of each product you are going to make using those raw materials, and how much you are going to sell them for.

In the game Executive Decision, players manage a business by bidding on raw materials and finished goods, aiming to make the most profit. 

Prices fluctuate based on supply and demand, making strategic decision-making crucial. 

Players determine what raw materials they need, how many units of each product they will produce, and what prices they are willing to pay and sell at. 

### Raw Materials:
Players bid on raw materials (Standard, Fine, and Extra Fine) to produce their finished goods. 

### Production:
Players decide how many units of each product (A, B, and C) they will produce based on their raw material purchases. 

### Bidding:
Players bid on the raw materials they want and the prices they are willing to sell their finished goods at. 

### Supply and Demand:
Prices for raw materials and finished goods are determined by the total number of bids and purchases, creating a dynamic pricing environment. 

### Profit:
The goal is to maximise profit by making strategic decisions about raw material purchases, production levels, and selling prices. 

--

# Rules

## SETUP 

The game is for 2-6 players.

Players decide how many months will constitute a game. 
Min 6 months, max 12 months.

Generally a game consists of 12 months; however, beginners may prefer a shorter game until they become familiar with the play. 

Each player receives a `Tally sheet` and the following amount of money:
- 2 players $900 
- 3 players $600 
- 4 players $450
- 5 players $350
- 6 players $300 

One player is chosen to be the Broker; throughout the game, he handles the Raw Material Certificates and money and posts the current Market Prices on the Price Level Board.

### Raw Materials
- XFine, Opening price: $40
- Fine, Opening price: $30
- Standard, Opening price: $20

### Finished Goods 
- A, Opening price: 140
- B, Opening price: 115
- C, Opening price: 90

### Recipes
Good A is made up of { XFine, XFine, Fine }
Good B is made up of { Fine, Fine, Standard }
Good C is made up of { Fine, Standard, Standard }

### Market Calculator 

#### Raw Materials 
Units:      0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24

Movement   -10,-9,-8,-7,-6,-5,-4,-3,-2,-1,0,+1,+2,+3,+4,+5,+6,+7,+8,+9,+10,+11,+12,+13,+14

#### Finished goods
Units: 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16
Movement: +11,+9,+7,+5,+3,+1,-1,-3,-5,-7,-9,-11,-13,-15,-17,-19,-21

--

# How to Play 

Each month of play consists of: 
1. Purchasing Raw Materials which are used in 
2. Manufacturing the products of your choice and 
3. Selling the Finished Goods in an attempt to make the greatest profits for your corporation. 

MONTH I (January) consists of the following, in order: 
I. PURCHASING RAW MATERIAL CERTIFICATES. 

After consulting the Price Level Board (Opening Price column and Market Calculator), each player enters his January order for Raw Materials in the Bid columns on his Tally sheet -secretly recording how many units of each grade he wishes to purchase and the price per unit he is willing to pay. 

The minimum bid price a player may bid for a grade of Raw Materials is the price that grade would change to if only that player ordered it. 

A player may order any or all of the three different grades of Materials but his entire order may not exceed the following: 

Number of Players	 	Total Per Player 
	2 			18 units 
	3			12 units 
	4			 9 Units
	5			 7 units 
	6			 6 Units 

When two play, no player may order more than 12 units of one grade of MaterIal.

When all bids have been recorded. each player, in turn. announces how many units of X-FINE Material he has ordered.

Broker totals announced units and consults Market Calculator (Raw Materials section) for price change. Amount shown on Calculator is added to or subtracted from Opening Price and resulting Market Price for X-FINE is posted in January column of Price Level Board. Market Prices for FINE and STANDARD Materials are then determined in the same manner. 
 
Raw Material prices never drop below $1 per unit. If Market Calculator indicates that a particular Raw Material will drop to $0 or below, the Market Price of that Material is stabilized at $1 until demand forces the price up again.

After the current Market Prices have been posted, each player determines which Raw Materials he has been successful in purchasing according to the following chart: 

PLAYER'S BID 					PLAYER'S PURCHASE 	
Equal to or higher than Market Price 		All Units at Bid Price
Lower than Market Price 			No Units
 
After adjusting his Tally sheet by crossing out any unsuccessful bids, each player totals his purchases, pays the Broker and receives one Raw Material Certificate for each unit purchased. 

These Certificates are placed face up in front of player so all other players may see them.
 
If a player does not have sufficient funds to pay the Broker for the total amount of his purchase, he is prohibited from buying any Raw Materials in that month.
 
2. MANUFACTURING. After consulting the Production Chart on the Price Level Board, each player secretly decides on the amounts and kinds of Finished Goods he intends to manufacture from the Raw Materials he has on hand. 

Three units of Raw Material are required to manufacture one unit of Finished Goods as shown on Production Chart. 

If a player is unable to supply the Raw Materials specified on the Chart, he may still manufacture his Goods by substituting an equal number of units of another Raw Material. 

He may either substitute X -FINE for FINE or FINE for STANDARD; these are the only substitutions permitted.

3. SELLING THE FINISHED GOODS. After consulting the Price Level Board (Opening Price column and Market Calculator), each player enters his January offering of Finished Goods in the Bid columns of his Tally sheet secretly recording how many units of each of the Finished Goods he wishes to sell and the price per unit he is willing to accept. 

A player may not offer more units of Finished Goods than he is able to manufacture from Raw Materials he has on hand. 

After all players have entered their bids, Market Prices for the Finished Goods are determined in same manner as for Purchasing Raw Material Certificates except that Finished Goods section of Market Calculator is used. 
 
After Market Prices have been posted, each player determines which finished Goods he has succeeded in selling according to the following chart: 

PLAYER'S BID 					GOODS SOLD
Equal to or lower than Market Price 		All Units at Bid Price
Higher than Market Price 			No Units

After adjusting their Tally sheets by crossing out any overestimated bids, players total their sales. 

The Broker pays each player for units sold and collects the Raw Materials Certificates used in manufacturing the sold Goods.
 
If a player has offered more units of Finished Goods than he is able to manufacture from his Raw Materials, he is prohibited from selling any Finished Goods in the month. 

Also, all of his offerings of Finished Goods are disregarded in determining the Market Prices for that month. 

ALL OTHER MONTHS. Each month players purchase Raw Material Certificates, manufacture and sell the Finished Goods in the same manner as for January. 

When determining the current Market Prices, amounts shown on the market calculator are added or subtracted from the previous months's Market Price.

## ENDING THE GAME
Whe the number of months agreed upon has been reached, players sell any unused Raw Material Certificates to the Broker at the final month's market price.  

The player who has made the most profit for their corporation is the winner.

## VARIATIONS
When players become familiar with the basic game, they may wish to try the following variations (which may be used separately or together):
 
### VARIATION I: PURCHASING RAW MATERIAL CERTIFICATES. 
If a player does not have sufficient funds to pay for the total amount of his purchase, he must take a loan from the Broker. Loans are made only in increments of $100 ($100, $200, $300, etc.). A player may only borrow enough to cover the remainder of his payment. 
A record of all loans is kept by the Broker and, at the end of the game, he collects $125 for each $100 borrowed.
 
### VARIATION 2: PURCHASING RAW MATERIAL CERTIFICATES. 
If a player's  bid is lower than Market Price, he is not successful in purchasing his entire order of that grade. He may, however, purchase some of that order at his bid price. He loses one unit for each dollar his Bid Price is below the Market Price. 