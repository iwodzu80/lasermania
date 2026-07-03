/// A point on the beam polyline, in cell units (`col + 0.5`, `row + 0.5` is a
/// cell centre). The renderer converts these to board pixels.
public struct BeamPoint: Equatable, Sendable {
    public let x: Double
    public let y: Double
    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

public struct BeamTrace: Equatable, Sendable {
    public var points: [BeamPoint]
    public var struckSensors: Set<Coord>
    public var litCells: Set<Coord>

    public init(points: [BeamPoint] = [], struckSensors: Set<Coord> = [], litCells: Set<Coord> = []) {
        self.points = points
        self.struckSensors = struckSensors
        self.litCells = litCells
    }
}

/// Diagonal laser through cell centres. The beam leaves the emitter on a 45°
/// diagonal and reflects off the flat faces of fixed/movable blocks and the
/// board edges (angle in = angle out); a head-on corner sends it back. It
/// passes through capsules (sensors), marking each struck.
public enum LaserTracer {
    private struct BeamVisit: Hashable {
        let col: Int
        let row: Int
        let dir: Diagonal
    }

    public static func trace(_ state: GameState) -> BeamTrace {
        let grid = state.grid

        // Only blocks reflect; the screen edge is NOT a reflector — the beam
        // leaves the board there and stops.
        func isBlock(_ coord: Coord) -> Bool {
            guard grid.isInBounds(coord) else { return false }
            if grid.terrain[coord.row][coord.col] == .wall { return true }
            if state.movables[coord] != nil { return true }
            return false
        }
        func center(_ coord: Coord) -> BeamPoint {
            BeamPoint(x: Double(coord.col) + 0.5, y: Double(coord.row) + 0.5)
        }

        var dir = grid.emitterDirection
        var pos = grid.emitterCoord
        var result = BeamTrace(points: [center(pos)])
        var visited: Set<BeamVisit> = []
        let maxSteps = grid.columns * grid.rows * 8 + 16
        var steps = 0

        while steps < maxSteps {
            steps += 1

            let visit = BeamVisit(col: pos.col, row: pos.row, dir: dir)
            if visited.contains(visit) { break }
            visited.insert(visit)

            let ahead = pos.moved(dir)

            if !grid.isInBounds(ahead) {
                // Beam exits the board through the edge and stops (no reflection).
                result.points.append(BeamPoint(
                    x: Double(pos.col) + 0.5 + 0.5 * Double(dir.step.dc),
                    y: Double(pos.row) + 0.5 + 0.5 * Double(dir.step.dr)))
                break
            }

            if isBlock(ahead) {
                // Angle of incidence = angle of reflection off the block face;
                // a head-on corner sends the beam back.
                let horizontal = Coord(col: pos.col + dir.step.dc, row: pos.row)
                let vertical = Coord(col: pos.col, row: pos.row + dir.step.dr)
                let solidH = isBlock(horizontal)
                let solidV = isBlock(vertical)
                if solidH && solidV {
                    dir = dir.reversed
                } else if solidH {
                    dir = dir.flippedHorizontally
                } else if solidV {
                    dir = dir.flippedVertically
                } else {
                    dir = dir.reversed
                }
                continue
            }

            pos = ahead
            result.points.append(center(pos))
            result.litCells.insert(pos)
            if state.remainingSensors.contains(pos) {
                result.struckSensors.insert(pos)
            }
        }

        return result
    }
}
