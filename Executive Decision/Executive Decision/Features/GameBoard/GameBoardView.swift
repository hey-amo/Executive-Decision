//
//  GameBoardView.swift
//  Executive Decision
//

import SwiftUI

struct GameBoardView: View {
    var mockData: GameBoardMockData = .openingBalances

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("EXECUTIVE DECISION")
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
    GameBoardView(mockData: .openingBalances)
}

#Preview("January") {
    GameBoardView(mockData: .january)
}

#Preview("All months") {
    GameBoardView(mockData: .allMonths)
}
