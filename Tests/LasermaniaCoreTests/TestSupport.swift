import XCTest
@testable import LasermaniaCore

func makeGrid(
    columns: Int,
    rows: Int,
    walls: Set<Coord> = [],
    emitterCoord: Coord,
    emitterDirection: Direction,
    doorCoord: Coord,
    sensorCoords: Set<Coord> = []
) -> Grid {
    var terrain: [[StaticTerrain]] = Array(repeating: Array(repeating: .floor, count: columns), count: rows)
    for wall in walls {
        terrain[wall.row][wall.col] = .wall
    }
    for sensor in sensorCoords {
        terrain[sensor.row][sensor.col] = .sensorSite
    }
    terrain[emitterCoord.row][emitterCoord.col] = .emitter(emitterDirection)
    terrain[doorCoord.row][doorCoord.col] = .door

    return Grid(
        columns: columns,
        rows: rows,
        terrain: terrain,
        emitterCoord: emitterCoord,
        emitterDirection: emitterDirection,
        doorCoord: doorCoord,
        sensorCoords: sensorCoords
    )
}

func makeState(
    grid: Grid,
    crawler: Coord = Coord(col: 0, row: 0),
    facing: Direction = .right,
    movables: [Coord: MovableKind] = [:],
    remainingSensors: Set<Coord>? = nil,
    remainingCapsules: Set<Coord> = [],
    totalCapsules: Int? = nil,
    movesUsed: Int = 0
) -> GameState {
    let sensors = remainingSensors ?? grid.sensorCoords
    return GameState(
        grid: grid,
        crawler: crawler,
        facing: facing,
        movables: movables,
        remainingSensors: sensors,
        remainingCapsules: remainingCapsules,
        totalSensors: grid.sensorCoords.count,
        totalCapsules: totalCapsules ?? remainingCapsules.count,
        movesUsed: movesUsed
    )
}

func makeLevel(
    id: String = "test-level",
    name: String = "Test Level",
    parMoves: Int? = nil,
    legend: [String: LevelDefinition.LegendEntry] = ["L": LevelDefinition.LegendEntry(type: "emitter", dir: "right")],
    layout: [String]
) -> LevelDefinition {
    LevelDefinition(id: id, name: name, parMoves: parMoves, sensorModel: "A", legend: legend, layout: layout)
}

func loadState(
    legend: [String: LevelDefinition.LegendEntry] = ["L": LevelDefinition.LegendEntry(type: "emitter", dir: "right")],
    layout: [String]
) throws -> GameState {
    try LevelLoader.makeInitialState(from: makeLevel(legend: legend, layout: layout))
}
