// EDGameLog.swift
// A collection on in-game messages and events that are logged for the player to view.
import Foundation

public enum GameLogType: Int, Codable, Sendable {
    case info, warning, error, success
}

public struct EDGameLog: Codable, Sendable {
    private static let maxEntries = 100
    public var entries: [EDGameLogEntry] = []

    public mutating func addEntry(type: GameLogType, message: String) {
        let entry = EDGameLogEntry(type: type, message: message)
        entries.append(entry)

        // remove the oldest entry if we exceed the maximum number of entries
        if entries.count > Self.maxEntries {
            entries.removeFirst()
        }
    }

    public mutating func clear() {
        entries.removeAll()
    }
}

public struct EDGameLogEntry: Codable, Sendable {
    public let type: GameLogType
    public let message: String
    public let timestamp: Date

    public init(type: GameLogType, message: String, timestamp: Date = Date()) {
        self.type = type
        self.message = message
        self.timestamp = timestamp
    }
}