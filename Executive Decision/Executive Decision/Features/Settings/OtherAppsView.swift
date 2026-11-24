//
//  OtherAppsView.swift
//  Executive Decision
//
//  Created by AD on 24/11/2026.
//

import SwiftUI
import Foundation


// MARK: - Other apps

struct OtherApp: Identifiable {
    let id = UUID()
    let name: String
    let tagline: String
    let iconImageName: String
    let url: URL
}

struct OtherAppsList: View {
    let apps: [OtherApp]

    var body: some View {
        ForEach(apps) { app in
            Link(destination: app.url) {
                HStack(spacing: 12) {
                    Image(app.iconImageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(app.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(app.tagline)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 4)
            }
        }
    }
}
