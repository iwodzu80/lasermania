public struct Coord: Hashable, Codable, Sendable {
    public var col: Int
    public var row: Int

    public init(col: Int, row: Int) {
        self.col = col
        self.row = row
    }

    public func moved(_ direction: Direction) -> Coord {
        let step = direction.step
        return Coord(col: col + step.dc, row: row + step.dr)
    }
}
