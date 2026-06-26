import XCTest
@testable import LasermaniaCore

final class BFSSolverTests: XCTestCase {
    func testAlreadyWonStateReturnsZero() {
        let grid = makeGrid(
            columns: 3, rows: 3,
            emitterCoord: Coord(col: 0, row: 0), emitterDirection: .right,
            doorCoord: Coord(col: 2, row: 2)
        )
        let state = makeState(grid: grid, crawler: Coord(col: 2, row: 2), remainingSensors: [], remainingCapsules: [])
        XCTAssertTrue(state.isWon)

        XCTAssertEqual(BFSSolver.shortestSolutionLength(from: state), 0)
    }

    func testSingleMoveSolutionReturnsOne() {
        let door = Coord(col: 2, row: 1)
        let grid = makeGrid(
            columns: 4, rows: 3,
            emitterCoord: Coord(col: 0, row: 0), emitterDirection: .right,
            doorCoord: door
        )
        let state = makeState(grid: grid, crawler: Coord(col: 1, row: 1), remainingSensors: [], remainingCapsules: [])

        XCTAssertEqual(BFSSolver.shortestSolutionLength(from: state), 1)
    }

    func testUnsolvableLevelReturnsNil() {
        // The sensor sits off the emitter's row/column and there are no movables
        // to redirect the beam, so it can never be struck and the door never unlocks.
        let sensor = Coord(col: 1, row: 2)
        let grid = makeGrid(
            columns: 3, rows: 3,
            emitterCoord: Coord(col: 0, row: 0), emitterDirection: .right,
            doorCoord: Coord(col: 2, row: 2),
            sensorCoords: [sensor]
        )
        let state = makeState(grid: grid, crawler: Coord(col: 1, row: 1), remainingSensors: [sensor])

        XCTAssertNil(BFSSolver.shortestSolutionLength(from: state))
    }

    func testMultiStepSolutionAccountsForBeamClearingPush() {
        // Crawler must push the box down out of the beam's row before the sensor
        // can be struck, then walk to the door. Optimal: down, right, right, right, down.
        let box = Coord(col: 2, row: 1)
        let sensor = Coord(col: 4, row: 1)
        let grid = makeGrid(
            columns: 6, rows: 3,
            emitterCoord: Coord(col: 0, row: 1), emitterDirection: .right,
            doorCoord: Coord(col: 5, row: 2),
            sensorCoords: [sensor]
        )
        let state = makeState(grid: grid, crawler: Coord(col: 2, row: 0), movables: [box: .box], remainingSensors: [sensor])

        XCTAssertEqual(BFSSolver.shortestSolutionLength(from: state), 5)
    }
}
