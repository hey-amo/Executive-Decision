//
//  PlayerAvatarView.swift
//  Executive-Decision

import SwiftUI
import Foundation

// Shows a single player avatar
struct PlayerAvatarView: View {
    var avatarResource: String
    var isHighlighted = false
    var size: CGFloat = 64

    var body: some View {
        Image(avatarResource)
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .stroke(isHighlighted ? Color.blue : Color.clear, lineWidth: 3)
            }
            .accessibilityLabel("Player avatar")
    }
}

#Preview {
    PlayerAvatarView(avatarResource: "avt-1", isHighlighted: true)
}
