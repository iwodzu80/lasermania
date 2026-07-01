public struct Grid: Equatable, Sendable {
    public let columns: Int
    public let rows: Int
    public let terrain: [[StaticTerrain]]
    public let emitterCoord: Coord
    public let emitterDirection: Diagonal
    public let doorCoord: Coord
    public let sensorCoords: Set<Coord>

    public init(
        columns: Int,
        rows: Int,
        terrain: [[StaticTerrain]],
        emitterCoord: Coord,
        emitterDirection: Direction,
        doorCoord: Coord,
        sensorCoords: Set<Coord>
    ) {
        self.columns = columns
        self.rows = rows
        self.terrain = terrain
        self.emitterCoord = emitterCoord
        self.emitterDirection = emitterDirection
        self.doorCoord = doorCoord
        self.sensorCoords = sensorCoords
    }

    public func isInBounds(_ coord: Coord) -> Bool {
        coord.col >= 0 && coord.col < columns && coord.row >= 0 && coord.row < rows
    }

    public func cell(at coord: Coord) -> StaticTerrain? {
        guard isInBounds(coord) else { return nil }
        return terrain[coord.row][coord.col]
    }
}
