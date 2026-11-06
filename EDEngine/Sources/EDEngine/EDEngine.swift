/// Compatibility name for the authoritative game-session actor.
///
/// Rules: FR-15 through FR-17. GameSession is the sole owner of mutable session state.
@available(macOS 10.15, *)
public typealias EDEngine = GameSession
