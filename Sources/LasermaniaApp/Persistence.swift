import Foundation
import Combine

public enum ControlScheme: String, CaseIterable, Codable, Hashable {
    case arrows
    case wasd

    public var displayName: String {
        switch self {
        case .arrows: return "Arrows"
        case .wasd: return "WASD"
        }
    }
}

public enum ColorTheme: String, CaseIterable, Codable, Hashable {
    case classic
    case highContrast

    public var displayName: String {
        switch self {
        case .classic: return "Classic"
        case .highContrast: return "High-contrast"
        }
    }
}

/// UserDefaults-backed store for player-configurable settings.
public final class SettingsStore: ObservableObject {
    private enum Keys {
        static let musicVolume = "settings.musicVolume"
        static let sfxVolume = "settings.sfxVolume"
        static let controlScheme = "settings.controlScheme"
        static let colorTheme = "settings.colorTheme"
        static let reduceMotion = "settings.reduceMotion"
    }

    private let defaults: UserDefaults

    @Published public var musicVolume: Double {
        didSet { defaults.set(musicVolume, forKey: Keys.musicVolume) }
    }

    @Published public var sfxVolume: Double {
        didSet { defaults.set(sfxVolume, forKey: Keys.sfxVolume) }
    }

    @Published public var controlScheme: ControlScheme {
        didSet { defaults.set(controlScheme.rawValue, forKey: Keys.controlScheme) }
    }

    @Published public var colorTheme: ColorTheme {
        didSet { defaults.set(colorTheme.rawValue, forKey: Keys.colorTheme) }
    }

    @Published public var reduceMotion: Bool {
        didSet { defaults.set(reduceMotion, forKey: Keys.reduceMotion) }
    }

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.musicVolume = defaults.object(forKey: Keys.musicVolume) as? Double ?? 0.6
        self.sfxVolume = defaults.object(forKey: Keys.sfxVolume) as? Double ?? 0.8
        self.controlScheme = ControlScheme(rawValue: defaults.string(forKey: Keys.controlScheme) ?? "") ?? .arrows
        self.colorTheme = ColorTheme(rawValue: defaults.string(forKey: Keys.colorTheme) ?? "") ?? .classic
        self.reduceMotion = defaults.object(forKey: Keys.reduceMotion) as? Bool ?? false
    }
}

/// UserDefaults-backed store for level completion progress. A level is
/// considered solved once it has a recorded best-moves entry; unlocking is
/// derived from the solved status of the preceding level rather than stored
/// separately, so there is a single source of truth.
public final class ProgressStore: ObservableObject {
    private enum Keys {
        static let bestMoves = "progress.bestMoves"
    }

    private let defaults: UserDefaults

    @Published public private(set) var bestMoves: [String: Int]

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.bestMoves = (defaults.dictionary(forKey: Keys.bestMoves) as? [String: Int]) ?? [:]
    }

    public func isSolved(_ levelID: String) -> Bool {
        bestMoves[levelID] != nil
    }

    public func bestMoves(for levelID: String) -> Int? {
        bestMoves[levelID]
    }

    /// Records a level clear. Returns `true` if this beat (or set) the level's best-moves record.
    @discardableResult
    public func recordCompletion(levelID: String, moves: Int) -> Bool {
        let isNewBest = bestMoves[levelID].map { moves < $0 } ?? true
        if isNewBest {
            bestMoves[levelID] = moves
            persist()
        }
        return isNewBest
    }

    /// A level at `levelIndex` (0-based, in pack order) is unlocked once the
    /// previous level is solved; the first level is always unlocked.
    public func isUnlocked(levelIndex: Int, levelIDs: [String]) -> Bool {
        guard levelIndex > 0 else { return true }
        guard levelIndex - 1 < levelIDs.count else { return false }
        return isSolved(levelIDs[levelIndex - 1])
    }

    public func reset() {
        bestMoves = [:]
        persist()
    }

    private func persist() {
        defaults.set(bestMoves, forKey: Keys.bestMoves)
    }
}
