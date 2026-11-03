// Mini standalone 'partial' view to show coins and only coins

import SwiftUI

struct CoinView: View {
    let coins: Int

    var body: some View {        
        if coins < 0 {
            Text("$\(coins.formatted(.number.precision(.fractionLength(0))))")
                .foregroundColor(.red)
        } else {
            Text("$\(coins.formatted(.number.precision(.fractionLength(0))))")
        }
    }
}

#Preview {
    CoinView(coins: 101)
}
