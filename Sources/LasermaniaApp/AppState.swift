import Combine
import LasermaniaCore

public enum Screen: Equatable {
    case title
    case levelSelect
    case gameplay
    case pause
    case levelComplete
    case victory
    case settings
}

/// Top-level navigation and level-loading coordinator. Screens read published
/// state from here and call its action methods rather than reaching into
/// `GameSession`/`GameViewModel` or the persistence stores directly.
public final class AppState: ObservableObject {
    public let settings: SettingsStore
    public let progress: ProgressStore
    public let audio: AudioManager

    @Published public private(set) var screen: Screen = .title
    @Published public private(set) var levels: [LevelDefinition] = []
    @Published public private(set) var currentLevelIndex: Int = 0
    @Published public private(set) var gameViewModel: GameViewModel? = nil
    @Published public private(set) var loadError: String? = nil

    private var settingsReturnScreen: Screen = .title
    private var gameCancellables: Set<AnyCancellable> = []

    public init(settings: SettingsStore = SettingsStore(), progress: ProgressStore = ProgressStore()) {
        self.settings = settings
        self.progress = progress
        self.audio = AudioManager(settings: settings)
        loadLevels()
    }

    private func loadLevels() {
        do {
            levels = try BundledLevels.all()
        } catch {
            loadError = "\(error)"
            levels = []
        }
    }

    public var levelIDs: [String] { levels.map(\.id) }

    public func isUnlocked(_ index: Int) -> Bool {
        progress.isUnlocked(levelIndex: index, levelIDs: levelIDs)
    }

    /// Sum of best-move scores across every solved level, for the Victory screen.
    public var totalScore: Int {
        levels.reduce(0) { sum, level in
            guard let moves = progress.bestMoves(for: level.id),
                  let initial = try? LevelLoader.makeInitialState(from: level) else { return sum }
            return sum + Scoring.score(moves: moves, capsulesCollected: initial.totalCapsules, parMoves: level.parMoves)
        }
    }

    public var totalMoves: Int {
        progress.bestMoves.values.reduce(0, +)
    }

    public func dismissError() {
        loadError = nil
    }

    // MARK: - Title / menu navigation

    public func showTitle() {
        gameViewModel = nil
        audio.playMusic(.menu)
        screen = .title
    }

    public func showLevelSelect() {
        audio.playMusic(.menu)
        screen = .levelSelect
    }

    /// "PLAY" on the title screen: continue at the first unsolved level.
    public func playFromMenu() {
        let index = levels.firstIndex { !progress.isSolved($0.id) } ?? 0
        startLevel(at: index)
    }

    public func playAgain() {
        startLevel(at: 0)
    }

    public func quitToTitle() {
        showTitle()
    }

    // MARK: - Gameplay lifecycle

    public func startLevel(at index: Int) {
        guard levels.indices.contains(index), isUnlocked(index) else { return }
        let level = levels[index]
        do {
            let initial = try LevelLoader.makeInitialState(from: level)
            currentLevelIndex = index
            let viewModel = GameViewModel(level: level, initialState: initial, progress: progress, audio: audio)
            observe(viewModel)
            gameViewModel = viewModel
            audio.playMusic(.gameplay)
            screen = .gameplay
        } catch {
            loadError = "\(error)"
        }
    }

    public func retryCurrentLevel() {
        startLevel(at: currentLevelIndex)
    }

    public func advanceToNextLevelOrVictory() {
        let next = currentLevelIndex + 1
        if levels.indices.contains(next) {
            startLevel(at: next)
        } else {
            gameViewModel = nil
            audio.playMusic(.menu)
            screen = .victory
        }
    }

    public func pauseGameplay() {
        guard screen == .gameplay else { return }
        screen = .pause
    }

    public func resumeGameplay() {
        guard screen == .pause else { return }
        screen = .gameplay
    }

    // MARK: - Gameplay action passthrough

    public func move(_ direction: Direction) {
        guard screen == .gameplay else { return }
        gameViewModel?.move(direction)
    }

    public func undoMove() {
        guard screen == .gameplay else { return }
        gameViewModel?.undo()
    }

    public func restartLevel() {
        guard screen == .gameplay else { return }
        gameViewModel?.restart()
    }

    // MARK: - Settings overlay

    public func openSettings() {
        settingsReturnScreen = screen
        screen = .settings
    }

    public func closeSettings() {
        screen = settingsReturnScreen
    }

    public func resetProgress() {
        progress.reset()
    }

    // MARK: - Win observation

    private func observe(_ viewModel: GameViewModel) {
        gameCancellables.removeAll()
        viewModel.$justWon
            .filter { $0 }
            .sink { [weak self] _ in self?.screen = .levelComplete }
            .store(in: &gameCancellables)
    }
}
