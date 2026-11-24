//
//  GameBoardView.swift
//  Executive Decision
//

import SwiftUI

struct GameBoardView: View {
    let players: [MockPlayer]
    var mockData: GameBoardMockData = .openingBalances

    var body: some View {
        StickyTopBarView(players: players)
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Executive Decision")
                        .textCase(.uppercase)
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .tracking(1.6)
                        .foregroundStyle(PlayerSetupStyle.mutedInk)

                    Text("Price level board")
                        .font(.custom("Georgia-Bold", size: 32))
                        .foregroundStyle(PlayerSetupStyle.ink)
                }

                GameBoardStatusBanner(mockData: mockData)
                GameBoardPriceTable(mockData: mockData)
                MarketCalculatorView()
                ProductionChartView()
            }
            .padding(20)
        }
        .background(PlayerSetupStyle.paper.ignoresSafeArea())
    }
}

#Preview("Opening balances") {
    let players = [MockPlayer.alex, MockPlayer.dean, MockPlayer.gordon]
    GameBoardView(players: players, mockData: .openingBalances)
}

#Preview("January") {
    let players = [MockPlayer.alex, MockPlayer.dean, MockPlayer.gordon]
    GameBoardView(players: players, mockData: .january)
}

#Preview("All months, All players") {
    let players = [MockPlayer.alex, MockPlayer.dean, MockPlayer.gordon, MockPlayer.morgan, MockPlayer.rex, MockPlayer.saxon]
    GameBoardView(players: players, mockData: .allMonths)
}
