//
//  PlayerAvatarView.swift
//  Executive Decision
//
//  Created by Amarjit on 04/11/2026.
//

import SwiftUI

// Display a single avatar:
// - Avatar in a circle
// - Active state: Stroke to show they are on turn
// - Inactive state: Greyed out with no stroke

struct PlayerAvatarView: View {
    var avatarResource: String = MockPlayer.rex.avatarResource
    var isActive = false
    var size: CGFloat = 56

    var body: some View {
        Image(avatarResource)
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(Circle())
            .saturation(isActive ? 1 : 0)
            .opacity(isActive ? 1 : 0.5)
            .overlay {
                if isActive {
                    Circle()
                        .stroke(PlayerSetupStyle.tomato, lineWidth: 3)
                }
            }
            .accessibilityLabel(avatarResource)
    }
}

#Preview {
    HStack(spacing: 16) {
        PlayerAvatarView(avatarResource: MockPlayer.rex.avatarResource, isActive: true)
        PlayerAvatarView(avatarResource: MockPlayer.saxon.avatarResource, isActive: false)
    }
}
