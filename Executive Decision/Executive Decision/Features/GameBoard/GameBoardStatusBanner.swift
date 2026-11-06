//
//  GameBoardStatusBanner.swift
//  Executive Decision
//

import SwiftUI

struct GameBoardStatusBanner: View {
    let mockData: GameBoardMockData

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: mockData.activePlayerName == nil ? "info.circle.fill" : "arrow.right.circle.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(PlayerSetupStyle.tomato)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                Text("Month: \(mockData.currentMonthName)")
                    .font(.custom("Georgia-Bold", size: 20))
                    .foregroundStyle(PlayerSetupStyle.ink)

                Text(mockData.activePlayerName.map { "\($0) is on turn" } ?? "Ready to begin")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(PlayerSetupStyle.ink)

                Text(mockData.statusMessage)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(PlayerSetupStyle.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PlayerSetupStyle.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(PlayerSetupStyle.ink.opacity(0.2), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}
