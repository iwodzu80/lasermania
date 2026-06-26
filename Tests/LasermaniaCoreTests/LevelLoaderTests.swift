import XCTest
@testable import LasermaniaCore

final class LevelLoaderTests: XCTestCase {
    private let validLayout = [
        "######",
        "#@..S#",
        "#L...#",
        "####D#"
    ]

    // MARK: - Happy path

    func testValidLayoutParsesGridAndState() throws {
        let state = try loadState(layout: validLayout)

        XCTAssertEqual(state.grid.columns, 6)
        XCTAssertEqual(state.grid.rows, 4)
        XCTAssertEqual(state.crawler, Coord(col: 1, row: 1))
        XCTAssertEqual(state.grid.emitterCoord, Coord(col: 1, row: 2))
        XCTAssertEqual(state.grid.emitterDirection, .right)
        XCTAssertEqual(state.grid.doorCoord, Coord(col: 4, row: 3))
        XCTAssertEqual(state.totalSensors, 1)
        // The sensor sits in row 1; the beam travels along row 2 and never reaches it.
        XCTAssertEqual(state.remainingSensors, [Coord(col: 4, row: 1)])
        XCTAssertEqual(state.movesUsed, 0)
        XCTAssertFalse(state.doorUnlocked)
    }

    func testSelectiveSensorSettlingAtLoad() throws {
        let layout = [
            "##########",
            "#@.......#",
            "#L..S..S.#",
            "####D#####"
        ]
        let state = try loadState(layout: layout)

        XCTAssertEqual(state.totalSensors, 2)
        // The beam strikes the first sensor on its unobstructed path and stops there,
        // so the second sensor further down the same row is never evaluated at load.
        XCTAssertEqual(state.remainingSensors, [Coord(col: 7, row: 2)])
        XCTAssertFalse(state.doorUnlocked)
    }

    // MARK: - Structural errors

    func testEmptyLayoutThrows() {
        XCTAssertThrowsError(try loadState(layout: [])) { error in
            XCTAssertEqual(error as? LevelLoadError, .emptyLayout(levelID: "test-level"))
        }
    }

    func testRowLengthMismatchThrows() {
        let layout = [
            "######",
            "#@..S",
            "#L...#",
            "####D#"
        ]
        XCTAssertThrowsError(try loadState(layout: layout)) { error in
            XCTAssertEqual(error as? LevelLoadError, .rowLengthMismatch(levelID: "test-level", row: 1, expected: 6, actual: 5))
        }
    }

    func testUnknownSymbolThrows() {
        let layout = [
            "######",
            "#@X.S#",
            "#L...#",
            "####D#"
        ]
        XCTAssertThrowsError(try loadState(layout: layout)) { error in
            XCTAssertEqual(error as? LevelLoadError, .unknownSymbol(levelID: "test-level", symbol: "X", row: 1, col: 2))
        }
    }

    // MARK: - Legend errors

    func testMissingEmitterLegendThrows() {
        XCTAssertThrowsError(try loadState(legend: [:], layout: validLayout)) { error in
            XCTAssertEqual(error as? LevelLoadError, .missingEmitterLegend(levelID: "test-level", symbol: "L"))
        }
    }

    func testInvalidDirectionThrows() {
        let legend = ["L": LevelDefinition.LegendEntry(type: "emitter", dir: "sideways")]
        XCTAssertThrowsError(try loadState(legend: legend, layout: validLayout)) { error in
            XCTAssertEqual(error as? LevelLoadError, .invalidDirection(levelID: "test-level", value: "sideways"))
        }
    }

    // MARK: - Duplicate entity errors

    func testDuplicateCrawlerThrows() {
        let layout = [
            "######",
            "#@..S#",
            "#L.@.#",
            "####D#"
        ]
        XCTAssertThrowsError(try loadState(layout: layout)) { error in
            XCTAssertEqual(error as? LevelLoadError, .duplicateCrawler(levelID: "test-level"))
        }
    }

    func testDuplicateEmitterThrows() {
        let layout = [
            "######",
            "#@L.S#",
            "#L...#",
            "####D#"
        ]
        XCTAssertThrowsError(try loadState(layout: layout)) { error in
            XCTAssertEqual(error as? LevelLoadError, .duplicateEmitter(levelID: "test-level"))
        }
    }

    func testDuplicateDoorThrows() {
        let layout = [
            "######",
            "#@.DS#",
            "#L...#",
            "####D#"
        ]
        XCTAssertThrowsError(try loadState(layout: layout)) { error in
            XCTAssertEqual(error as? LevelLoadError, .duplicateDoor(levelID: "test-level"))
        }
    }

    // MARK: - Missing entity errors

    func testMissingCrawlerThrows() {
        let layout = [
            "######",
            "#...S#",
            "#L...#",
            "####D#"
        ]
        XCTAssertThrowsError(try loadState(layout: layout)) { error in
            XCTAssertEqual(error as? LevelLoadError, .missingCrawler(levelID: "test-level"))
        }
    }

    func testMissingEmitterThrows() {
        let layout = [
            "######",
            "#@..S#",
            "#....#",
            "####D#"
        ]
        XCTAssertThrowsError(try loadState(layout: layout)) { error in
            XCTAssertEqual(error as? LevelLoadError, .missingEmitter(levelID: "test-level"))
        }
    }

    func testMissingDoorThrows() {
        let layout = [
            "######",
            "#@..S#",
            "#L...#",
            "####.#"
        ]
        XCTAssertThrowsError(try loadState(layout: layout)) { error in
            XCTAssertEqual(error as? LevelLoadError, .missingDoor(levelID: "test-level"))
        }
    }

    func testNoSensorsThrows() {
        let layout = [
            "######",
            "#@...#",
            "#L...#",
            "####D#"
        ]
        XCTAssertThrowsError(try loadState(layout: layout)) { error in
            XCTAssertEqual(error as? LevelLoadError, .noSensors(levelID: "test-level"))
        }
    }
}
