// Mini standalone 'partial' view to show coins and only coins

import SwiftUI

struct CoinView: View {
    let coins: Int

    var body: some View {        
        if coins < 0 {  
            Text(coins.formatted(.currency(code: "USD")))
                .foregroundColor(.red)
        } else {
            Text(coins.formatted(.currency(code: "USD")))
        }
    }
}