import XCTest
@testable import LasermaniaCore

final class LevelSolvabilityTests: XCTestCase {
    func testAllBundledLevelsAreSolvableAtPar() throws {
        let levels = try BundledLevels.all()
        XCTAssertFalse(levels.isEmpty)

        for level in levels {
            let initial = try LevelLoader.makeInitialState(from: level)
            let solution = BFSSolver.shortestSolutionLength(from: initial)

            guard let solutionLength = solution else {
                XCTFail("Level '\(level.id)' has no solution.")
                continue
            }

            if let parMoves = level.parMoves {
                XCTAssertEqual(
                    solutionLength, parMoves,
                    "Level '\(level.id)' solves in \(solutionLength) moves but parMoves is \(parMoves)."
                )
            }
        }
    }
}
