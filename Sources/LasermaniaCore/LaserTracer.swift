/// A point on the beam polyline, in cell units. Integer coordinates are cell
/// boundaries; `x = col + 0.5` is a column centre, `y = row` a row's top edge.
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

/// The Lasermania laser as a "half-cell" billiard. The beam leaves the middle
/// of the emitter cell's top (or bottom) edge, travels on 45° diagonals through
/// the lanes between blocks, and reflects off the flat faces of fixed/movable
/// blocks and the screen edges at the cell edge-midpoints — never from cell
/// centres. It passes through capsules (sensors), marking each struck.
public enum LaserTracer {
    private struct BeamVisit: Hashable {
        let x2: Int
        let y2: Int
        let dx: Int
        let dy: Int
    }

    public static func trace(_ state: GameState) -> BeamTrace {
        let grid = state.grid

        func isBlock(_ col: Int, _ row: Int) -> Bool {
            if col < 0 || row < 0 || col >= grid.columns || row >= grid.rows { return true }
            if grid.terrain[row][col] == .wall { return true }
            if state.movables[Coord(col: col, row: row)] != nil { return true }
            return false
        }

        var dx = grid.emitterDirection.step.dc
        var dy = grid.emitterDirection.step.dr
        // Origin: middle of the top edge if firing up, the bottom edge if down.
        var x = Double(grid.emitterCoord.col) + 0.5
        var y = dy < 0 ? Double(grid.emitterCoord.row) : Double(grid.emitterCoord.row + 1)

        var result = BeamTrace(points: [BeamPoint(x: x, y: y)])
        var visited: Set<BeamVisit> = []
        let maxSteps = grid.columns * grid.rows * 16 + 32
        var steps = 0

        while steps < maxSteps {
            steps += 1

            // The (position, direction) state fully determines the future, so a
            // repeat means a cycle — this catches beams trapped reflecting in a
            // pocket, where the position never advances between reflections.
            let visit = BeamVisit(x2: Int((x * 2).rounded()), y2: Int((y * 2).rounded()), dx: dx, dy: dy)
            if visited.contains(visit) { break }
            visited.insert(visit)

            let nx = x + 0.5 * Double(dx)
            let ny = y + 0.5 * Double(dy)

            // Exactly one of nx/ny is an integer: that's the face being crossed.
            let verticalFace = abs(nx - nx.rounded(.down)) < 1e-6
            let col: Int
            let row: Int
            if verticalFace {
                let boundary = Int(nx.rounded())
                col = dx > 0 ? boundary : boundary - 1
                row = Int(ny.rounded(.down))
            } else {
                let boundary = Int(ny.rounded())
                row = dy > 0 ? boundary : boundary - 1
                col = Int(nx.rounded(.down))
            }

            if isBlock(col, row) {
                if verticalFace { dx = -dx } else { dy = -dy }
                continue
            }

            x = nx
            y = ny
            result.points.append(BeamPoint(x: x, y: y))

            let cell = Coord(col: col, row: row)
            result.litCells.insert(cell)
            if state.remainingSensors.contains(cell) {
                result.struckSensors.insert(cell)
            }
        }

        return result
    }
}
