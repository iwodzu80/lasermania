import XCTest
@testable import LasermaniaCore

final class PushRulesTests: XCTestCase {
    // MARK: - Crawler movement

    func testMoveIntoFloorSucceeds() {
        let grid = makeGrid(
            columns: 4, rows: 3,
            emitterCoord: Coord(col: 0, row: 0), emitterDirection: .right,
            doorCoord: Coord(col: 3, row: 2)
        )
        let state = makeState(grid: grid, crawler: Coord(col: 1, row: 1))

        let next = state.applying(.right)

        XCTAssertEqual(next?.crawler, Coord(col: 2, row: 1))
        XCTAssertEqual(next?.facing, .right)
        XCTAssertEqual(next?.movesUsed, 1)
    }

    func testMoveIntoWallFails() {
        let wall = Coord(col: 2, row: 1)
        let grid = makeGrid(
            columns: 4, rows: 3,
            walls: [wall],
            emitterCoord: Coord(col: 0, row: 0), emitterDirection: .right,
            doorCoord: Coord(col: 3, row: 2)
        )
        let state = makeState(grid: grid, crawler: Coord(col: 1, row: 1))

        XCTAssertNil(state.applying(.right))
    }

    func testMoveIntoEmitterFails() {
        let grid = makeGrid(
            columns: 4, rows: 3,
            emitterCoord: Coord(col: 2, row: 1), emitterDirection: .right,
            doorCoord: Coord(col: 3, row: 2)
        )
        let state = makeState(grid: grid, crawler: Coord(col: 1, row: 1))

        XCTAssertNil(state.applying(.right))
    }

    func testMoveOntoActiveSensorFails() {
        let sensor = Coord(col: 2, row: 1)
        let grid = makeGrid(
            columns: 4, rows: 3,
            emitterCoord: Coord(col: 0, row: 0), emitterDirection: .right,
            doorCoord: Coord(col: 3, row: 2),
            sensorCoords: [sensor]
        )
        let state = makeState(grid: grid, crawler: Coord(col: 1, row: 1), remainingSensors: [sensor])

        XCTAssertNil(state.applying(.right))
    }

    func testMoveOntoDestroyedSensorSucceeds() {
        let sensor = Coord(col: 2, row: 1)
        let grid = makeGrid(
            columns: 4, rows: 3,
            emitterCoord: Coord(col: 0, row: 0), emitterDirection: .right,
            doorCoord: Coord(col: 3, row: 2),
            sensorCoords: [sensor]
        )
        let state = makeState(grid: grid, crawler: Coord(col: 1, row: 1), remainingSensors: [])

        let next = state.applying(.right)

        XCTAssertEqual(next?.crawler, sensor)
    }

    func testMoveOntoLockedDoorFails() {
        let door = Coord(col: 2, row: 1)
        let sensor = Coord(col: 3, row: 0)
        let grid = makeGrid(
            columns: 4, rows: 3,
            emitterCoord: Coord(col: 0, row: 0), emitterDirection: .right,
            doorCoord: door,
            sensorCoords: [sensor]
        )
        let state = makeState(grid: grid, crawler: Coord(col: 1, row: 1), remainingSensors: [sensor])

        XCTAssertFalse(state.doorUnlocked)
        XCTAssertNil(state.applying(.right))
    }

    func testMoveOntoUnlockedDoorSucceeds() {
        let door = Coord(col: 2, row: 1)
        let grid = makeGrid(
            columns: 4, rows: 3,
            emitterCoord: Coord(col: 0, row: 0), emitterDirection: .right,
            doorCoord: door
        )
        let state = makeState(grid: grid, crawler: Coord(col: 1, row: 1), remainingSensors: [], remainingCapsules: [])

        XCTAssertTrue(state.doorUnlocked)
        let next = state.applying(.right)

        XCTAssertEqual(next?.crawler, door)
        XCTAssertTrue(next?.isWon ?? false)
    }

    func testMoveOntoDoorFailsWhileCapsulesRemainEvenIfSensorsCleared() {
        let door = Coord(col: 2, row: 1)
        let capsule = Coord(col: 3, row: 0)
        let grid = makeGrid(
            columns: 4, rows: 3,
            emitterCoord: Coord(col: 0, row: 0), emitterDirection: .right,
            doorCoord: door
        )
        let state = makeState(grid: grid, crawler: Coord(col: 1, row: 1), remainingSensors: [], remainingCapsules: [capsule])

        XCTAssertFalse(state.doorUnlocked)
        XCTAssertNil(state.applying(.right))
    }

    func testMovingOntoCapsuleCollectsIt() {
        let capsule = Coord(col: 2, row: 1)
        let grid = makeGrid(
            columns: 4, rows: 3,
            emitterCoord: Coord(col: 0, row: 0), emitterDirection: .right,
            doorCoord: Coord(col: 3, row: 2)
        )
        let state = makeState(grid: grid, crawler: Coord(col: 1, row: 1), remainingCapsules: [capsule])

        let next = state.applying(.right)

        XCTAssertEqual(next?.remainingCapsules.isEmpty, true)
    }

    // MARK: - Pushing movables

    func testPushBoxIntoFloorSucceeds() {
        let box = Coord(col: 2, row: 1)
        let grid = makeGrid(
            columns: 5, rows: 3,
            emitterCoord: Coord(col: 0, row: 0), emitterDirection: .right,
            doorCoord: Coord(col: 4, row: 2)
        )
        let state = makeState(grid: grid, crawler: Coord(col: 1, row: 1), movables: [box: .box])

        let next = state.applying(.right)

        XCTAssertEqual(next?.crawler, box)
        XCTAssertEqual(next?.movables, [Coord(col: 3, row: 1): .box])
    }

    func testPushBoxIntoWallFails() {
        let box = Coord(col: 2, row: 1)
        let wall = Coord(col: 3, row: 1)
        let grid = makeGrid(
            columns: 5, rows: 3,
            walls: [wall],
            emitterCoord: Coord(col: 0, row: 0), emitterDirection: .right,
            doorCoord: Coord(col: 4, row: 2)
        )
        let state = makeState(grid: grid, crawler: Coord(col: 1, row: 1), movables: [box: .box])

        XCTAssertNil(state.applying(.right))
    }

    func testPushBoxIntoAnotherMovableFails() {
        let box = Coord(col: 2, row: 1)
        let otherBox = Coord(col: 3, row: 1)
        let grid = makeGrid(
            columns: 5, rows: 3,
            emitterCoord: Coord(col: 0, row: 0), emitterDirection: .right,
            doorCoord: Coord(col: 4, row: 2)
        )
        let state = makeState(grid: grid, crawler: Coord(col: 1, row: 1), movables: [box: .box, otherBox: .box])

        XCTAssertNil(state.applying(.right))
    }

    func testPushBoxOntoSensorSiteAlwaysFails() {
        let box = Coord(col: 2, row: 1)
        let sensor = Coord(col: 3, row: 1)
        let grid = makeGrid(
            columns: 5, rows: 3,
            emitterCoord: Coord(col: 0, row: 0), emitterDirection: .right,
            doorCoord: Coord(col: 4, row: 2),
            sensorCoords: [sensor]
        )

        let withActiveSensor = makeState(grid: grid, crawler: Coord(col: 1, row: 1), movables: [box: .box], remainingSensors: [sensor])
        XCTAssertNil(withActiveSensor.applying(.right))

        let withDestroyedSensor = makeState(grid: grid, crawler: Coord(col: 1, row: 1), movables: [box: .box], remainingSensors: [])
        XCTAssertNil(withDestroyedSensor.applying(.right))
    }

    func testPushBoxOntoDoorAlwaysFails() {
        let box = Coord(col: 2, row: 1)
        let door = Coord(col: 3, row: 1)
        let grid = makeGrid(
            columns: 5, rows: 3,
            emitterCoord: Coord(col: 0, row: 0), emitterDirection: .right,
            doorCoord: door
        )

        let locked = makeState(grid: grid, crawler: Coord(col: 1, row: 1), movables: [box: .box], remainingSensors: [Coord(col: 4, row: 0)])
        XCTAssertNil(locked.applying(.right))

        let unlocked = makeState(grid: grid, crawler: Coord(col: 1, row: 1), movables: [box: .box], remainingSensors: [], remainingCapsules: [])
        XCTAssertNil(unlocked.applying(.right))
    }

    func testPushBoxOntoEmitterAlwaysFails() {
        let box = Coord(col: 2, row: 1)
        let emitter = Coord(col: 3, row: 1)
        let grid = makeGrid(
            columns: 5, rows: 3,
            emitterCoord: emitter, emitterDirection: .down,
            doorCoord: Coord(col: 4, row: 2)
        )
        let state = makeState(grid: grid, crawler: Coord(col: 1, row: 1), movables: [box: .box])

        XCTAssertNil(state.applying(.right))
    }

    func testPushMirrorBehavesLikeBox() {
        let mirror = Coord(col: 2, row: 1)
        let grid = makeGrid(
            columns: 5, rows: 3,
            emitterCoord: Coord(col: 0, row: 0), emitterDirection: .right,
            doorCoord: Coord(col: 4, row: 2)
        )
        let state = makeState(grid: grid, crawler: Coord(col: 1, row: 1), movables: [mirror: .mirrorSlash])

        let next = state.applying(.right)

        XCTAssertEqual(next?.movables, [Coord(col: 3, row: 1): .mirrorSlash])
    }

    func testPushThatClearsBeamPathDestroysSensorInSameMove() {
        let box = Coord(col: 2, row: 1)
        let sensor = Coord(col: 4, row: 1)
        let grid = makeGrid(
            columns: 6, rows: 3,
            emitterCoord: Coord(col: 0, row: 1), emitterDirection: .right,
            doorCoord: Coord(col: 5, row: 2),
            sensorCoords: [sensor]
        )
        // Crawler stands above the box and pushes it down, off the beam's row.
        let state = makeState(grid: grid, crawler: Coord(col: 2, row: 0), movables: [box: .box], remainingSensors: [sensor])

        let next = state.applying(.down)

        XCTAssertEqual(next?.movables, [Coord(col: 2, row: 2): .box])
        XCTAssertEqual(next?.remainingSensors.isEmpty, true)
    }

    func testFailedMoveLeavesOriginalStateUntouched() {
        let wall = Coord(col: 2, row: 1)
        let grid = makeGrid(
            columns: 4, rows: 3,
            walls: [wall],
            emitterCoord: Coord(col: 0, row: 0), emitterDirection: .right,
            doorCoord: Coord(col: 3, row: 2)
        )
        let state = makeState(grid: grid, crawler: Coord(col: 1, row: 1))

        XCTAssertNil(state.applying(.right))
        XCTAssertEqual(state.crawler, Coord(col: 1, row: 1))
        XCTAssertEqual(state.movesUsed, 0)
    }
}
