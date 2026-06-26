public enum LevelLoadError: Error, CustomStringConvertible, Equatable {
    case emptyLayout(levelID: String)
    case rowLengthMismatch(levelID: String, row: Int, expected: Int, actual: Int)
    case unknownSymbol(levelID: String, symbol: Character, row: Int, col: Int)
    case missingEmitterLegend(levelID: String, symbol: Character)
    case invalidDirection(levelID: String, value: String)
    case duplicateCrawler(levelID: String)
    case duplicateEmitter(levelID: String)
    case duplicateDoor(levelID: String)
    case missingCrawler(levelID: String)
    case missingEmitter(levelID: String)
    case missingDoor(levelID: String)
    case noSensors(levelID: String)

    public var description: String {
        switch self {
        case .emptyLayout(let id):
            return "Level '\(id)': layout is empty."
        case .rowLengthMismatch(let id, let row, let expected, let actual):
            return "Level '\(id)': row \(row) has length \(actual), expected \(expected). All rows must be equal length."
        case .unknownSymbol(let id, let symbol, let row, let col):
            return "Level '\(id)': unknown symbol '\(symbol)' at row \(row), col \(col)."
        case .missingEmitterLegend(let id, let symbol):
            return "Level '\(id)': symbol '\(symbol)' needs a legend entry with type \"emitter\" and a \"dir\"."
        case .invalidDirection(let id, let value):
            return "Level '\(id)': invalid direction '\(value)' in legend. Expected up, down, left, or right."
        case .duplicateCrawler(let id):
            return "Level '\(id)': found more than one '@' crawler start. Exactly one is required."
        case .duplicateEmitter(let id):
            return "Level '\(id)': found more than one laser emitter. Exactly one is required."
        case .duplicateDoor(let id):
            return "Level '\(id)': found more than one 'D' door. Exactly one is required."
        case .missingCrawler(let id):
            return "Level '\(id)': missing the '@' crawler start."
        case .missingEmitter(let id):
            return "Level '\(id)': missing a laser emitter."
        case .missingDoor(let id):
            return "Level '\(id)': missing the 'D' door."
        case .noSensors(let id):
            return "Level '\(id)': needs at least one 'S' alarm sensor."
        }
    }
}

public enum LevelLoader {
    public static func makeInitialState(from level: LevelDefinition) throws -> GameState {
        let id = level.id
        guard !level.layout.isEmpty else { throw LevelLoadError.emptyLayout(levelID: id) }

        let rows = level.layout.count
        let columns = Array(level.layout[0]).count
        guard columns > 0 else { throw LevelLoadError.emptyLayout(levelID: id) }

        var terrain: [[StaticTerrain]] = Array(repeating: Array(repeating: .floor, count: columns), count: rows)
        var movables: [Coord: MovableKind] = [:]
        var capsules: Set<Coord> = []
        var sensors: Set<Coord> = []
        var crawlerCoord: Coord?
        var emitterCoord: Coord?
        var emitterDirection: Direction?
        var doorCoord: Coord?

        for (rowIndex, rowString) in level.layout.enumerated() {
            let rowChars = Array(rowString)
            guard rowChars.count == columns else {
                throw LevelLoadError.rowLengthMismatch(levelID: id, row: rowIndex, expected: columns, actual: rowChars.count)
            }

            for (colIndex, symbol) in rowChars.enumerated() {
                let coord = Coord(col: colIndex, row: rowIndex)

                switch symbol {
                case ".":
                    break
                case "#":
                    terrain[rowIndex][colIndex] = .wall
                case "@":
                    guard crawlerCoord == nil else { throw LevelLoadError.duplicateCrawler(levelID: id) }
                    crawlerCoord = coord
                case "L":
                    guard emitterCoord == nil else { throw LevelLoadError.duplicateEmitter(levelID: id) }
                    let direction = try Self.emitterDirection(forSymbol: symbol, legend: level.legend, levelID: id)
                    emitterCoord = coord
                    emitterDirection = direction
                    terrain[rowIndex][colIndex] = .emitter(direction)
                case "S":
                    sensors.insert(coord)
                    terrain[rowIndex][colIndex] = .sensorSite
                case "D":
                    guard doorCoord == nil else { throw LevelLoadError.duplicateDoor(levelID: id) }
                    doorCoord = coord
                    terrain[rowIndex][colIndex] = .door
                case "B":
                    movables[coord] = .box
                case "/":
                    movables[coord] = .mirrorSlash
                case "\\":
                    movables[coord] = .mirrorBackslash
                case "C":
                    capsules.insert(coord)
                default:
                    throw LevelLoadError.unknownSymbol(levelID: id, symbol: symbol, row: rowIndex, col: colIndex)
                }
            }
        }

        guard let crawler = crawlerCoord else { throw LevelLoadError.missingCrawler(levelID: id) }
        guard let emitter = emitterCoord, let direction = emitterDirection else {
            throw LevelLoadError.missingEmitter(levelID: id)
        }
        guard let door = doorCoord else { throw LevelLoadError.missingDoor(levelID: id) }
        guard !sensors.isEmpty else { throw LevelLoadError.noSensors(levelID: id) }

        let grid = Grid(
            columns: columns,
            rows: rows,
            terrain: terrain,
            emitterCoord: emitter,
            emitterDirection: direction,
            doorCoord: door,
            sensorCoords: sensors
        )

        let unsettled = GameState(
            grid: grid,
            crawler: crawler,
            facing: .right,
            movables: movables,
            remainingSensors: sensors,
            remainingCapsules: capsules,
            totalSensors: sensors.count,
            totalCapsules: capsules.count,
            movesUsed: 0
        )

        let struckAtLoad = LaserTracer.trace(unsettled).struckSensors
        var settledCapsules = capsules
        settledCapsules.remove(crawler)

        return GameState(
            grid: grid,
            crawler: crawler,
            facing: .right,
            movables: movables,
            remainingSensors: sensors.subtracting(struckAtLoad),
            remainingCapsules: settledCapsules,
            totalSensors: sensors.count,
            totalCapsules: capsules.count,
            movesUsed: 0
        )
    }

    private static func emitterDirection(
        forSymbol symbol: Character,
        legend: [String: LevelDefinition.LegendEntry]?,
        levelID: String
    ) throws -> Direction {
        guard let entry = legend?[String(symbol)], let dirString = entry.dir else {
            throw LevelLoadError.missingEmitterLegend(levelID: levelID, symbol: symbol)
        }
        guard let direction = Direction(rawValue: dirString) else {
            throw LevelLoadError.invalidDirection(levelID: levelID, value: dirString)
        }
        return direction
    }
}
