• Swift Package, swift-tools-version: 6.0, swiftLanguageModes: [.v6] on every target. Zero concurrency warnings is a hard requirement.
• No UI code. No SwiftUI, UIKit, AppKit, Combine, or @MainActor anywhere in the engine. The engine must build and test on Linux.
• Domain types are struct or enum, Sendable, Equatable, Hashable where sensible, and Codable where they are persisted. Prefer value semantics.
• Shared mutable state lives only inside an actor. No @unchecked Sendable, no nonisolated(unsafe), no global mutable variables, no DispatchQueue. Any exception needs a written justification in the PR.
• Rules logic is pure functions or value-type reducers: no I/O, no Date(), no Int.random. Randomness and time enter through injected protocols.
• Depend on protocols at module boundaries (dependency inversion). Concrete wiring happens in one composition root.
• Errors are typed enums (throws(RulesError) or a Result). No fatalError or try! in library code.
• Public API gets doc comments that cite the rule being implemented (for example "Rules: Purchasing step").
• Tests use Swift Testing (import Testing). Every rule has at least one example test taken from the rulebook, plus edge cases.
• Do not touch files outside the scope listed in the branch brief. Do not rename or reformat unrelated code.
• Commit style: ED-###: imperative summary.