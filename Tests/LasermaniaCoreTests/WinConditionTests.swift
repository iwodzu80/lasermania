import XCTest
@testable import LasermaniaCore

final class WinConditionTests: XCTestCase {
    func testDoorUnlockedWhenSensorsAndCapsulesCleared() {
        let grid = makeGrid(
            columns: 3, rows: 3,
            emitterCoord: Coord(col: 0, row: 0), emitterDirection: .right,
            doorCoord: Coord(col: 2, row: 2)
        )
        let state = makeState(grid: grid, remainingSensors: [], remainingCapsules: [])

        XCTAssertTrue(state.doorUnlocked)
    }

    func testDoorLockedWhileSensorsRemain() {
        let sensor = Coord(col: 1, row: 1)
        let grid = makeGrid(
            columns: 3, rows: 3,
            emitterCoord: Coord(col: 0, row: 0), emitterDirection: .right,
            doorCoord: Coord(col: 2, row: 2),
            sensorCoords: [sensor]
        )
        let state = makeState(grid: grid, remainingSensors: [sensor], remainingCapsules: [])

        XCTAssertFalse(state.doorUnlocked)
    }

    func testDoorLockedWhileCapsulesRemain() {
        let capsule = Coord(col: 1, row: 0)
        let grid = makeGrid(
            columns: 3, rows: 3,
            emitterCoord: Coord(col: 0, row: 0), emitterDirection: .right,
            doorCoord: Coord(col: 2, row: 2)
        )
        let state = makeState(grid: grid, remainingSensors: [], remainingCapsules: [capsule])

        XCTAssertFalse(state.doorUnlocked)
    }

    func testLevelWithNoCapsulesOnlyRequiresSensorsCleared() {
        let grid = makeGrid(
            columns: 3, rows: 3,
            emitterCoord: Coord(col: 0, row: 0), emitterDirection: .right,
            doorCoord: Coord(col: 2, row: 2)
        )
        let state = makeState(grid: grid, remainingSensors: [], remainingCapsules: [], totalCapsules: 0)

        XCTAssertEqual(state.totalCapsules, 0)
        XCTAssertTrue(state.doorUnlocked)
    }

    func testIsWonRequiresBothUnlockedAndCrawlerAtDoor() {
        let door = Coord(col: 2, row: 2)
        let sensor = Coord(col: 1, row: 1)
        let grid = makeGrid(
            columns: 3, rows: 3,
            emitterCoord: Coord(col: 0, row: 0), emitterDirection: .right,
            doorCoord: door,
            sensorCoords: [sensor]
        )

        let lockedAtDoor = makeState(grid: grid, crawler: door, remainingSensors: [sensor])
        XCTAssertFalse(lockedAtDoor.doorUnlocked)
        XCTAssertFalse(lockedAtDoor.isWon)

        let unlockedNotAtDoor = makeState(grid: grid, crawler: Coord(col: 0, row: 0), remainingSensors: [])
        XCTAssertTrue(unlockedNotAtDoor.doorUnlocked)
        XCTAssertFalse(unlockedNotAtDoor.isWon)

        let unlockedAtDoor = makeState(grid: grid, crawler: door, remainingSensors: [])
        XCTAssertTrue(unlockedAtDoor.doorUnlocked)
        XCTAssertTrue(unlockedAtDoor.isWon)
    }

    func testEndToEndSolvedLevelReachesWinState() throws {
        // Mirrors the shipped "First Light" level. The sensor sits in the
        // emitter's unobstructed line of fire, so it's destroyed at load;
        // the remaining puzzle is collecting the capsule before the door.
        let layout = [
            "#########",
            "#@..C...#",
            "#.......#",
            "#L.....S#",
            "#######D#"
        ]
        var state = try loadState(layout: layout)
        XCTAssertFalse(state.isWon)
        XCTAssertEqual(state.totalSensors, 1)
        XCTAssertEqual(state.totalCapsules, 1)

        let moves: [Direction] = [.right, .right, .right, .down, .down, .right, .right, .right, .down]
        for move in moves {
            guard let next = state.applying(move) else {
                XCTFail("Move \(move) was rejected at moves used \(state.movesUsed)")
                return
            }
            state = next
        }

        XCTAssertTrue(state.remainingCapsules.isEmpty)
        XCTAssertTrue(state.remainingSensors.isEmpty)
        XCTAssertTrue(state.isWon)
        XCTAssertEqual(state.movesUsed, 9)
    }
}
