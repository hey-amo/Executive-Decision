/// Actor boundary for accessing the game’s value-type state.
public actor EDEngine {
    private var state: EDGameState

    /// Creates an engine around a validated game state.
    ///
    /// Rules: FR-16 The engine can resume from a serialized game state.
    public init(state: EDGameState) {
        self.state = state
    }

    /// Returns an immutable value snapshot of the current game state.
    ///
    /// Rules: FR-16 Persistence snapshots the complete game state.
    public func snapshot() -> EDGameState {
        state
    }

    /// Replaces the current game with a validated value state.
    ///
    /// Rules: FR-16 The engine resumes from a complete persisted game state.
    public func changeState(to newState: EDGameState) {
        state = newState
    }
}
