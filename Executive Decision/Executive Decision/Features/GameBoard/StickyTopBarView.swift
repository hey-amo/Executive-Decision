//
//  StickyTopBarView.swift
//  Executive Decision
//
//  Created by AD on 24/11/2026.
//

import EDEngine
import SwiftUI
import OSLog

private let hudLogger = Logger(subsystem: "GameHUD", category: "StickyHUD")

struct StickyTopBarView: View {
    let players: [MockPlayer]
    
    
    var body: some View {
        VStack {
            HStack(spacing: 12) {
                playerStrip
                
                VStack {
                    iconButton(systemImage: "bell.fill", label: "Notifications") {
                        hudLogger.info("Notifications button tapped")
                    }
                    
                    iconButton(systemImage: "line.3.horizontal", label: "Menu") {
                        hudLogger.info("Menu button tapped")
                    }
                    
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
        }
    }
    
    private var playerStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(players) { player in
                    PlayerHUDView(player: player)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private func iconButton(
        systemImage: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}




// MARK: Preview

#Preview {
    let players: [MockPlayer] = [
        MockPlayer.rex,
        MockPlayer.alex,
        MockPlayer.dean,
        MockPlayer.gordon,
        MockPlayer.morgan,
    ]
    StickyTopBarView(
        players: players
    )
}
