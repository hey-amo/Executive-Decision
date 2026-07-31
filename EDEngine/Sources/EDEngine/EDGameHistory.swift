import Foundation

public struct EDGameHistory: Codable, Equatable, Sendable {
    public static let maxMessages = 60

    public private(set) var messages: [EDGameMessage]

    public init(messages: [EDGameMessage] = []) {
        self.messages = messages
    }

    public mutating func append(_ message: EDGameMessage) {
        if messages.count >= Self.maxMessages {
            clear()
        }

        messages.append(message)
    }

    public mutating func append(type: EDGameMessageType, message: String, timestamp: Date = Date()) {
        append(EDGameMessage(type: type, message: message, timestamp: timestamp))
    }

    public mutating func clear() {
        messages.removeAll()
    }

    public func serialized() throws -> Data {
        try JSONEncoder().encode(self)
    }

    public static func load(from data: Data) throws -> EDGameHistory {
        try JSONDecoder().decode(EDGameHistory.self, from: data)
    }
}
