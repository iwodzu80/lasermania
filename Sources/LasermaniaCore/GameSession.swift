public final class GameSession {
    private var history: [GameState]
    public let levelID: String

    public init(initialState: GameState, levelID: String) {
        self.history = [initialState]
        self.levelID = levelID
    }

    public var current: GameState {
        history[history.count - 1]
    }

    public var canUndo: Bool {
        history.count > 1
    }

    public var movesUsed: Int {
        current.movesUsed
    }

    @discardableResult
    public func apply(_ move: Direction) -> Bool {
        guard let next = current.applying(move) else { return false }
        history.append(next)
        return true
    }

    public func undo() {
        guard canUndo else { return }
        history.removeLast()
    }

    public func restart() {
        let initial = history[0]
        history = [initial]
    }
}
