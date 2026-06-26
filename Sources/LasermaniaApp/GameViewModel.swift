import Combine
import LasermaniaCore

/// Drives a single level's `GameSession`, publishing state for the gameplay
/// screen's HUD/board and triggering SFX for each kind of move outcome.
public final class GameViewModel: ObservableObject {
    public let level: LevelDefinition
    private let session: GameSession
    private let progress: ProgressStore
    private let audio: AudioManager?

    @Published public private(set) var state: GameState
    @Published public private(set) var justWon = false
    @Published public private(set) var isNewBest = false

    public init(level: LevelDefinition, initialState: GameState, progress: ProgressStore, audio: AudioManager?) {
        self.level = level
        self.session = GameSession(initialState: initialState, levelID: level.id)
        self.progress = progress
        self.audio = audio
        self.state = initialState
    }

    public var canUndo: Bool { session.canUndo }
    public var movesUsed: Int { session.movesUsed }
    public var bestMoves: Int? { progress.bestMoves(for: level.id) }
    public var sensorsDestroyed: Int { state.totalSensors - state.remainingSensors.count }
    public var capsulesCollected: Int { state.totalCapsules - state.remainingCapsules.count }

    public var score: Int {
        Scoring.score(moves: movesUsed, capsulesCollected: capsulesCollected, parMoves: level.parMoves)
    }

    @discardableResult
    public func move(_ direction: Direction) -> Bool {
        guard !state.isWon else { return false }

        let before = state
        guard session.apply(direction) else {
            audio?.play(.invalidMove)
            return false
        }

        state = session.current
        playFeedback(before: before, after: state)

        if state.isWon {
            justWon = true
            isNewBest = progress.recordCompletion(levelID: level.id, moves: state.movesUsed)
            audio?.play(.levelClear)
        }
        return true
    }

    public func undo() {
        guard session.canUndo else { return }
        session.undo()
        state = session.current
        justWon = false
        audio?.play(.undo)
    }

    public func restart() {
        session.restart()
        state = session.current
        justWon = false
    }

    /// Compares before/after snapshots to layer the right SFX: exactly one
    /// movement sound (step/push) plus any number of independent event cues.
    private func playFeedback(before: GameState, after: GameState) {
        guard let audio else { return }

        let target = after.crawler
        switch before.movables[target] {
        case .box:
            audio.play(.pushBox)
        case .mirrorSlash, .mirrorBackslash:
            audio.play(.pushMirror)
        case nil:
            audio.play(.step)
        }

        if before.beam.litCells != after.beam.litCells {
            audio.play(.beamShimmer)
        }
        if before.remainingSensors != after.remainingSensors {
            audio.play(.sensorDestroyed)
        }
        if before.remainingCapsules != after.remainingCapsules {
            audio.play(.capsuleCollected)
        }
        if !before.doorUnlocked && after.doorUnlocked {
            audio.play(.doorUnlock)
        }
    }
}
