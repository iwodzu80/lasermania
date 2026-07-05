/// A point on the beam polyline, in cell units. Integer coordinates are cell
/// boundaries; `col + 0.5` is a column centre, `row` a row's top edge.
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

/// The Lasermania laser. The beam leaves the middle of the emitter cell's top
/// edge (bottom edge if it fires downward) and travels on 45° diagonals through
/// the lanes between blocks. At each cell edge it checks the cell it is about to
/// enter: a block reflects it (angle in = angle out — flip the component across
/// that face); the screen edge ends the beam (the border does NOT reflect). It
/// passes through capsules (sensors), marking each struck.
public enum LaserTracer {
    private struct BeamVisit: Hashable {
        let x2: Int
        let y2: Int
        let dx: Int
        let dy: Int
    }

    public static func trace(_ state: GameState) -> BeamTrace {
        let grid = state.grid

        func inBounds(_ col: Int, _ row: Int) -> Bool {
            col >= 0 && row >= 0 && col < grid.columns && row < grid.rows
        }
        // Walls and the board edge end the beam (no reflection).
        func endsBeam(_ col: Int, _ row: Int) -> Bool {
            guard inBounds(col, row) else { return true }
            return grid.terrain[row][col] == .wall
        }
        // Fixed reflector blocks and movable blocks reflect the beam.
        func reflects(_ col: Int, _ row: Int) -> Bool {
            guard inBounds(col, row) else { return false }
            if grid.terrain[row][col] == .block { return true }
            return state.movables[Coord(col: col, row: row)] != nil
        }

        var dx = grid.emitterDirection.step.dc
        var dy = grid.emitterDirection.step.dr
        var x = Double(grid.emitterCoord.col) + 0.5
        var y = dy < 0 ? Double(grid.emitterCoord.row) : Double(grid.emitterCoord.row + 1)

        var result = BeamTrace(points: [BeamPoint(x: x, y: y)])
        var visited: Set<BeamVisit> = []
        let maxSteps = grid.columns * grid.rows * 16 + 32
        var steps = 0

        while steps < maxSteps {
            steps += 1

            let visit = BeamVisit(x2: Int((x * 2).rounded()), y2: Int((y * 2).rounded()), dx: dx, dy: dy)
            if visited.contains(visit) { break }
            visited.insert(visit)

            // The beam sits on a cell edge; find the cell it is about to enter.
            let verticalEdge = abs(x - x.rounded()) < 1e-6
            let col: Int
            let row: Int
            if verticalEdge {
                let boundary = Int(x.rounded())
                col = dx > 0 ? boundary : boundary - 1
                row = Int(y.rounded(.down))
            } else {
                let boundary = Int(y.rounded())
                row = dy > 0 ? boundary : boundary - 1
                col = Int(x.rounded(.down))
            }

            if endsBeam(col, row) {
                // Beam hits a wall or the board edge and stops (no reflection).
                result.points.append(BeamPoint(x: x + 0.5 * Double(dx), y: y + 0.5 * Double(dy)))
                break
            }
            if reflects(col, row) {
                if verticalEdge { dx = -dx } else { dy = -dy }   // reflect off the face
                continue
            }

            let cell = Coord(col: col, row: row)
            result.litCells.insert(cell)
            if state.remainingSensors.contains(cell) {
                result.struckSensors.insert(cell)
            }

            x += 0.5 * Double(dx)
            y += 0.5 * Double(dy)
            result.points.append(BeamPoint(x: x, y: y))
        }

        return result
    }
}
