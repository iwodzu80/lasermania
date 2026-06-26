import XCTest
@testable import LasermaniaCore

final class LaserTracerTests: XCTestCase {
    func testStraightBeamStrikesSensor() {
        let sensor = Coord(col: 4, row: 1)
        let grid = makeGrid(
            columns: 6, rows: 3,
            emitterCoord: Coord(col: 0, row: 1), emitterDirection: .right,
            doorCoord: Coord(col: 5, row: 2),
            sensorCoords: [sensor]
        )
        let state = makeState(grid: grid, remainingSensors: [sensor])

        let trace = LaserTracer.trace(state)

        XCTAssertEqual(trace.struckSensors, [sensor])
        XCTAssertEqual(trace.segments.map { $0.coord }, [
            Coord(col: 1, row: 1), Coord(col: 2, row: 1), Coord(col: 3, row: 1)
        ])
        XCTAssertTrue(trace.segments.allSatisfy { $0.incoming == .right && $0.outgoing == .right })
    }

    func testWallBlocksBeamBeforeSensor() {
        let sensor = Coord(col: 4, row: 1)
        let wall = Coord(col: 3, row: 1)
        let grid = makeGrid(
            columns: 6, rows: 3,
            walls: [wall],
            emitterCoord: Coord(col: 0, row: 1), emitterDirection: .right,
            doorCoord: Coord(col: 5, row: 2),
            sensorCoords: [sensor]
        )
        let state = makeState(grid: grid, remainingSensors: [sensor])

        let trace = LaserTracer.trace(state)

        XCTAssertTrue(trace.struckSensors.isEmpty)
        XCTAssertEqual(trace.segments.map { $0.coord }, [
            Coord(col: 1, row: 1), Coord(col: 2, row: 1)
        ])
    }

    func testBoxAbsorbsBeamBeforeSensor() {
        let sensor = Coord(col: 4, row: 1)
        let box = Coord(col: 3, row: 1)
        let grid = makeGrid(
            columns: 6, rows: 3,
            emitterCoord: Coord(col: 0, row: 1), emitterDirection: .right,
            doorCoord: Coord(col: 5, row: 2),
            sensorCoords: [sensor]
        )
        let state = makeState(grid: grid, movables: [box: .box], remainingSensors: [sensor])

        let trace = LaserTracer.trace(state)

        XCTAssertTrue(trace.struckSensors.isEmpty)
        XCTAssertEqual(trace.segments.map { $0.coord }, [
            Coord(col: 1, row: 1), Coord(col: 2, row: 1)
        ])
    }

    func testMirrorSlashReflectsBeamUpwardToSensor() {
        let mirror = Coord(col: 2, row: 2)
        let sensor = Coord(col: 2, row: 0)
        let grid = makeGrid(
            columns: 5, rows: 5,
            emitterCoord: Coord(col: 0, row: 2), emitterDirection: .right,
            doorCoord: Coord(col: 4, row: 4),
            sensorCoords: [sensor]
        )
        let state = makeState(grid: grid, movables: [mirror: .mirrorSlash], remainingSensors: [sensor])

        let trace = LaserTracer.trace(state)

        XCTAssertEqual(trace.struckSensors, [sensor])
        let mirrorSegment = trace.segments.first { $0.coord == mirror }
        XCTAssertEqual(mirrorSegment?.incoming, .right)
        XCTAssertEqual(mirrorSegment?.outgoing, .up)
    }

    func testMirrorBackslashReflectsBeamDownwardToSensor() {
        let mirror = Coord(col: 2, row: 2)
        let sensor = Coord(col: 2, row: 4)
        let grid = makeGrid(
            columns: 5, rows: 5,
            emitterCoord: Coord(col: 0, row: 2), emitterDirection: .right,
            doorCoord: Coord(col: 4, row: 0),
            sensorCoords: [sensor]
        )
        let state = makeState(grid: grid, movables: [mirror: .mirrorBackslash], remainingSensors: [sensor])

        let trace = LaserTracer.trace(state)

        XCTAssertEqual(trace.struckSensors, [sensor])
        let mirrorSegment = trace.segments.first { $0.coord == mirror }
        XCTAssertEqual(mirrorSegment?.incoming, .right)
        XCTAssertEqual(mirrorSegment?.outgoing, .down)
    }

    func testDestroyedSensorPassesThroughLikeFloor() {
        let destroyed = Coord(col: 2, row: 1)
        let active = Coord(col: 5, row: 1)
        let grid = makeGrid(
            columns: 7, rows: 3,
            emitterCoord: Coord(col: 0, row: 1), emitterDirection: .right,
            doorCoord: Coord(col: 6, row: 2),
            sensorCoords: [destroyed, active]
        )
        // Only `active` remains; `destroyed` was already struck in a prior move.
        let state = makeState(grid: grid, remainingSensors: [active])

        let trace = LaserTracer.trace(state)

        XCTAssertEqual(trace.struckSensors, [active])
        let passThrough = trace.segments.first { $0.coord == destroyed }
        XCTAssertEqual(passThrough?.incoming, .right)
        XCTAssertEqual(passThrough?.outgoing, .right)
        XCTAssertEqual(trace.segments.count, 4)
    }

    func testLockedDoorAbsorbsBeam() {
        let sensor = Coord(col: 4, row: 0)
        let door = Coord(col: 3, row: 1)
        let grid = makeGrid(
            columns: 5, rows: 2,
            emitterCoord: Coord(col: 0, row: 1), emitterDirection: .right,
            doorCoord: door,
            sensorCoords: [sensor]
        )
        // `sensor` is far from the beam's path but still remaining, so the door stays locked.
        let state = makeState(grid: grid, remainingSensors: [sensor])

        let trace = LaserTracer.trace(state)

        XCTAssertTrue(trace.struckSensors.isEmpty)
        XCTAssertEqual(trace.segments.map { $0.coord }, [
            Coord(col: 1, row: 1), Coord(col: 2, row: 1)
        ])
    }

    func testUnlockedDoorPassesBeamThrough() {
        let door = Coord(col: 3, row: 1)
        let grid = makeGrid(
            columns: 5, rows: 2,
            emitterCoord: Coord(col: 0, row: 1), emitterDirection: .right,
            doorCoord: door,
            sensorCoords: []
        )
        let state = makeState(grid: grid, remainingSensors: [], remainingCapsules: [])
        XCTAssertTrue(state.doorUnlocked)

        let trace = LaserTracer.trace(state)

        XCTAssertEqual(trace.segments.map { $0.coord }, [
            Coord(col: 1, row: 1), Coord(col: 2, row: 1), door, Coord(col: 4, row: 1)
        ])
        let doorSegment = trace.segments.first { $0.coord == door }
        XCTAssertEqual(doorSegment?.incoming, .right)
        XCTAssertEqual(doorSegment?.outgoing, .right)
    }

    func testCyclingBeamTerminatesWithoutStrikingDistantSensor() {
        let farSensor = Coord(col: 0, row: 0)
        let mirrors: [Coord: MovableKind] = [
            Coord(col: 10, row: 3): .mirrorSlash,
            Coord(col: 13, row: 3): .mirrorSlash,
            Coord(col: 13, row: 1): .mirrorBackslash,
            Coord(col: 10, row: 1): .mirrorSlash,
            Coord(col: 5, row: 3): .mirrorSlash,
            Coord(col: 5, row: 10): .mirrorBackslash,
            Coord(col: 10, row: 10): .mirrorSlash
        ]
        let grid = makeGrid(
            columns: 16, rows: 16,
            emitterCoord: Coord(col: 10, row: 7), emitterDirection: .up,
            doorCoord: Coord(col: 0, row: 15),
            sensorCoords: [farSensor]
        )
        let state = makeState(grid: grid, movables: mirrors, remainingSensors: [farSensor])

        let trace = LaserTracer.trace(state)

        XCTAssertTrue(trace.struckSensors.isEmpty)
        XCTAssertEqual(trace.segments.count, 34)
        XCTAssertEqual(trace.segments.last?.coord, Coord(col: 10, row: 7))
    }
}
