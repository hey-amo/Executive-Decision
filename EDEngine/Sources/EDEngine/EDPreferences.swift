import Foundation

public enum EDPreference: Codable, Sendable {
    case sfx(Int)
    case music(Int)
}
public struct EDPreferenceManager: Codable, Sendable {
    public var sfxVolume: Int
    public var musicVolume: Int

    public init(sfxVolume: Int = 100, musicVolume: Int = 100) {
        self.sfxVolume = sfxVolume
        self.musicVolume = musicVolume
    }

    public mutating func update(setting: EDPreference) {
        switch setting {
        case .sfx(let volume):
            sfxVolume = volume
        case .music(let volume):
            musicVolume = volume
        }
    }

    public enum CodingKeys: String, CodingKey {
        case sfxVolume
        case musicVolume
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sfxVolume = try container.decode(Int.self, forKey: .sfxVolume)
        musicVolume = try container.decode(Int.self, forKey: .musicVolume)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sfxVolume, forKey: .sfxVolume)
        try container.encode(musicVolume, forKey: .musicVolume)
    }
}