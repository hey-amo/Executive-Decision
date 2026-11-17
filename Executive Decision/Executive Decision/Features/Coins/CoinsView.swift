//
//  CoinsView.swift
//  Executive Decision
//

import SwiftUI

struct CoinsView: View {
    private(set) var coins: Int

    private var formattedCoins: String {
        coins.formatted(IntegerFormatStyle<Int>.number.grouping(.automatic))
    }

    var body: some View {
        Text(formattedCoins)
            .font(.custom("Georgia-Bold", size: 14))
            .foregroundStyle(coins < 0 ? .red : .black)
            .accessibilityLabel("\(formattedCoins) coins")
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 8) {
        CoinsView(coins: 1_250)
        CoinsView(coins: 0)
        CoinsView(coins: -250)
    }
    .padding()
}
