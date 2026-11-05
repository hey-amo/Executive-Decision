//
//  GameSettingsView.swift
//  Executive Decision
//

import EDEngine
import SwiftUI

struct GameSettingsView: View {
    @State private var enabledSettings: Set<EDGameSetting> = []

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 22) {
                header
                settingsSection

                Text("Settings are temporary and reset when you leave this screen.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(PlayerSetupStyle.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 2)
            }
            .padding(.horizontal, 22)
            .padding(.top, 22)
            .padding(.bottom, 28)
        }
        .background(PlayerSetupStyle.paper.ignoresSafeArea())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("IN-GAME OPTIONS")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(PlayerSetupStyle.mutedInk)

            Text("Game settings")
                .font(.custom("Georgia-Bold", size: 35))
                .foregroundStyle(PlayerSetupStyle.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text("Make the table feel right for you.")
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(PlayerSetupStyle.mutedInk)
        }
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("PREFERENCES")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .tracking(1.3)
                .foregroundStyle(PlayerSetupStyle.mutedInk)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 4)

            ForEach(EDGameSetting.allCases, id: \.self) { setting in
                VStack(spacing: 0) {
                    settingRow(setting)

                    if setting != EDGameSetting.allCases.last {
                        Rectangle()
                            .fill(PlayerSetupStyle.ink.opacity(0.14))
                            .frame(height: 1)
                            .padding(.leading, 56)
                            .padding(.trailing, 16)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(PlayerSetupStyle.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(PlayerSetupStyle.ink, lineWidth: 2)
        }
    }

    private func settingRow(_ setting: EDGameSetting) -> some View {
        Toggle(isOn: binding(for: setting)) {
            HStack(spacing: 12) {
                Image(systemName: icon(for: setting))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(PlayerSetupStyle.tomato)
                    .frame(width: 42, height: 42)
                    .background(PlayerSetupStyle.gold.opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: 11))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title(for: setting))
                        .font(.custom("Georgia-Bold", size: 18))
                        .foregroundStyle(PlayerSetupStyle.ink)

                    Text(description(for: setting))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(PlayerSetupStyle.mutedInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .contentShape(Rectangle())
        }
        .tint(PlayerSetupStyle.tomato)
        .padding(.vertical, 10)
        .accessibilityLabel(title(for: setting))
        .accessibilityHint(description(for: setting))
    }

    private func binding(for setting: EDGameSetting) -> Binding<Bool> {
        Binding(
            get: { enabledSettings.contains(setting) },
            set: { isEnabled in
                if isEnabled {
                    enabledSettings.insert(setting)
                } else {
                    enabledSettings.remove(setting)
                }
            }
        )
    }

    private func title(for setting: EDGameSetting) -> String {
        switch setting {
        case .sound: "Sound effects"
        case .music: "Music"
        case .haptic: "Haptic feedback"
        case .darkMode: "Dark mode"
        }
    }

    private func description(for setting: EDGameSetting) -> String {
        switch setting {
        case .sound: "Hear the sounds of each game action."
        case .music: "Play music while you run the business."
        case .haptic: "Feel a tap for important moments."
        case .darkMode: "Use a darker look while you play."
        }
    }

    private func icon(for setting: EDGameSetting) -> String {
        switch setting {
        case .sound: "speaker.wave.2.fill"
        case .music: "music.note"
        case .haptic: "hand.tap.fill"
        case .darkMode: "moon.stars.fill"
        }
    }
}

#Preview {
    GameSettingsView()
}
