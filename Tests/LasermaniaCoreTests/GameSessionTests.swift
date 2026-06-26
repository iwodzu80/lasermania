import XCTest
@testable import LasermaniaCore

final class GameSessionTests: XCTestCase {
    private func makeSession(walls: Set<Coord> = []) -> GameSession {
        let grid = makeGrid(
            columns: 4, rows: 3,
            walls: walls,
            emitterCoord: Coord(col: 0, row: 0), emitterDirection: .right,
            doorCoord: Coord(col: 3, row: 2)
        )
        let state = makeState(grid: grid, crawler: Coord(col: 1, row: 1))
        return GameSession(initialState: state, levelID: "test-level")
    }

    func testInitialSessionHasNoHistoryToUndo() {
        let session = makeSession()

        XCTAssertEqual(session.current.crawler, Coord(col: 1, row: 1))
        XCTAssertFalse(session.canUndo)
        XCTAssertEqual(session.movesUsed, 0)
        XCTAssertEqual(session.levelID, "test-level")
    }

    func testApplyValidMoveAdvancesCurrentState() {
        let session = makeSession()

        let result = session.apply(.right)

        XCTAssertTrue(result)
        XCTAssertEqual(session.current.crawler, Coord(col: 2, row: 1))
        XCTAssertEqual(session.movesUsed, 1)
        XCTAssertTrue(session.canUndo)
    }

    func testApplyInvalidMoveLeavesSessionUnchanged() {
        let wall = Coord(col: 2, row: 1)
        let session = makeSession(walls: [wall])

        let result = session.apply(.right)

        XCTAssertFalse(result)
        XCTAssertEqual(session.current.crawler, Coord(col: 1, row: 1))
        XCTAssertEqual(session.movesUsed, 0)
        XCTAssertFalse(session.canUndo)
    }

    func testUndoRevertsToPreviousState() {
        let session = makeSession()
        session.apply(.right)

        session.undo()

        XCTAssertEqual(session.current.crawler, Coord(col: 1, row: 1))
        XCTAssertEqual(session.movesUsed, 0)
        XCTAssertFalse(session.canUndo)
    }

    func testUndoWithNoHistoryIsNoOp() {
        let session = makeSession()

        session.undo()

        XCTAssertEqual(session.current.crawler, Coord(col: 1, row: 1))
        XCTAssertFalse(session.canUndo)
    }

    func testMultipleUndosWalkBackThroughHistory() {
        let session = makeSession()
        session.apply(.right)
        session.apply(.down)

        XCTAssertEqual(session.current.crawler, Coord(col: 2, row: 2))
        XCTAssertTrue(session.canUndo)

        session.undo()
        XCTAssertEqual(session.current.crawler, Coord(col: 2, row: 1))
        XCTAssertTrue(session.canUndo)

        session.undo()
        XCTAssertEqual(session.current.crawler, Coord(col: 1, row: 1))
        XCTAssertFalse(session.canUndo)
    }

    func testRestartDiscardsAllHistory() {
        let session = makeSession()
        session.apply(.right)
        session.apply(.down)

        session.restart()

        XCTAssertEqual(session.current.crawler, Coord(col: 1, row: 1))
        XCTAssertEqual(session.movesUsed, 0)
        XCTAssertFalse(session.canUndo)
    }
}
