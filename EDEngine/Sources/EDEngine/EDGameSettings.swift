// In-game settings

public struct EDGameSettings: Sendable {
    public var allowLoans: Bool
    public var allowPartialRawMaterialPurchases: Bool
    public var soundEnabled: Bool
    public var musicEnabled: Bool
    public var hapticFeedbackEnabled: Bool
    public var darkModeEnabled: Bool

    public init(
        allowLoans: Bool = false,
        allowPartialRawMaterialPurchases: Bool = false,
        soundEnabled: Bool = true,
        musicEnabled: Bool = true,
        hapticFeedbackEnabled: Bool = false,
        darkModeEnabled: Bool = false
    ) {
        self.allowLoans = allowLoans
        self.allowPartialRawMaterialPurchases = allowPartialRawMaterialPurchases
        self.soundEnabled = soundEnabled
        self.musicEnabled = musicEnabled
        self.hapticFeedbackEnabled = hapticFeedbackEnabled
        self.darkModeEnabled = darkModeEnabled 
    }

    public mutating func toggleAllowLoans() {
        self.allowLoans.toggle()
    }
    public mutating func toggleAllowPartialRawMaterialPurchases() {
        self.allowPartialRawMaterialPurchases.toggle()
    }
    public mutating func toggleSoundEnabled() {
        self.soundEnabled.toggle()
    }
    public mutating func toggleMusicEnabled() {
        self.musicEnabled.toggle()
    }
    public mutating func toggleDarkModeEnabled() {
        self.darkModeEnabled.toggle()
    }
    public mutating func toggleHapticFeedbackEnabled() {
        self.hapticFeedbackEnabled.toggle()
    }
}
