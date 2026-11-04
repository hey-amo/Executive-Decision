// EDGameSettings.swift

import Foundation

public enum EDGameSetting: CaseIterable, Hashable, Sendable {
    case sound
    case music
    case haptic
    case darkMode
}

public enum EDPreference: Codable, Equatable, Sendable {
    case sound(enabled: Bool)
    case music(enabled: Bool)
    case haptic(enabled: Bool)
    case darkMode(enabled: Bool)

    public var setting: EDGameSetting {
        switch self {
        case .sound: .sound
        case .music: .music
        case .haptic: .haptic
        case .darkMode: .darkMode
        }
    }

    public var isEnabled: Bool {
        switch self {
        case let .sound(enabled),
             let .music(enabled),
             let .haptic(enabled),
             let .darkMode(enabled):
            enabled
        }
    }
}

public actor EDGameSettings {
    private var enabledSettings: Set<EDGameSetting>

    public init(enabledSettings: Set<EDGameSetting> = []) {
        self.enabledSettings = enabledSettings
    }

    public func isEnabled(_ setting: EDGameSetting) -> Bool {
        enabledSettings.contains(setting)
    }

    @discardableResult
    public func toggle(_ setting: EDGameSetting) -> Bool {
        if enabledSettings.remove(setting) != nil {
            return false
        }
        enabledSettings.insert(setting)
        return true
    }

    public func setEnabled(_ isEnabled: Bool, for setting: EDGameSetting) {
        if isEnabled {
            enabledSettings.insert(setting)
        } else {
            enabledSettings.remove(setting)
        }
    }

    public var preferences: [EDPreference] {
        EDGameSetting.allCases.map { setting in
            let isEnabled = enabledSettings.contains(setting)
            switch setting {
            case .sound: return .sound(enabled: isEnabled)
            case .music: return .music(enabled: isEnabled)
            case .haptic: return .haptic(enabled: isEnabled)
            case .darkMode: return .darkMode(enabled: isEnabled)
            }
        }
    }
}
