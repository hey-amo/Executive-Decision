import Foundation

public enum EDGameMessageType: Int, Hashable, Codable, Sendable, Equatable {
    case info, warning, success, other
}

public struct EDGameMessage: Codable, Sendable, Equatable {
    public let id: UUID
    public let type: EDGameMessageType
    public let message: String
    public let timestamp: Date

    public init(id: UUID = UUID(), type: EDGameMessageType, message: String, timestamp: Date = Date()) {
        self.id = id
        self.type = type
        self.message = message
        self.timestamp = timestamp
    }
}