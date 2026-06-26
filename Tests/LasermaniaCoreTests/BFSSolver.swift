@testable import LasermaniaCore

/// Breadth-first search over the reachable `GameState` space. Used to verify
/// that levels are solvable and to measure their true shortest solution length.
enum BFSSolver {
    private struct MovableEntry: Hashable {
        let coord: Coord
        let kind: MovableKind
    }

    private struct SearchKey: Hashable {
        let crawler: Coord
        let movables: Set<MovableEntry>
        let remainingSensors: Set<Coord>
        let remainingCapsules: Set<Coord>

        init(_ state: GameState) {
            crawler = state.crawler
            movables = Set(state.movables.map { MovableEntry(coord: $0.key, kind: $0.value) })
            remainingSensors = state.remainingSensors
            remainingCapsules = state.remainingCapsules
        }
    }

    /// Returns the minimum number of moves required to reach `isWon` from
    /// `initial`, or `nil` if no solution exists within `maxDepth` moves.
    static func shortestSolutionLength(from initial: GameState, maxDepth: Int = 200) -> Int? {
        if initial.isWon { return 0 }

        var visited: Set<SearchKey> = [SearchKey(initial)]
        var frontier: [GameState] = [initial]
        var depth = 0

        while !frontier.isEmpty && depth < maxDepth {
            depth += 1
            var nextFrontier: [GameState] = []
            for state in frontier {
                for direction in Direction.allCases {
                    guard let next = state.applying(direction) else { continue }
                    if next.isWon { return depth }
                    let key = SearchKey(next)
                    guard !visited.contains(key) else { continue }
                    visited.insert(key)
                    nextFrontier.append(next)
                }
            }
            frontier = nextFrontier
        }
        return nil
    }
}
