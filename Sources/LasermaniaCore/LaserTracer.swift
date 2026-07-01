public struct BeamTrace: Equatable, Sendable {
    public struct Segment: Equatable, Sendable {
        public let coord: Coord
        public let incoming: Diagonal
        public let outgoing: Diagonal

        public init(coord: Coord, incoming: Diagonal, outgoing: Diagonal) {
            self.coord = coord
            self.incoming = incoming
            self.outgoing = outgoing
        }
    }

    public var segments: [Segment]
    public var struckSensors: Set<Coord>

    public init(segments: [Segment] = [], struckSensors: Set<Coord> = []) {
        self.segments = segments
        self.struckSensors = struckSensors
    }

    public var litCells: Set<Coord> {
        Set(segments.map { $0.coord })
    }
}

/// Traces the diagonal ("billiard") laser. The beam leaves the emitter on a 45°
/// diagonal and reflects off the flat faces of steel blocks, walls, and the
/// board edges: angle of incidence = angle of reflection. It passes through
/// sensors (marking each struck) so a single beam can clear several at once.
public enum LaserTracer {
    private struct BeamVisit: Hashable {
        let coord: Coord
        let direction: Diagonal
    }

    public static func trace(_ state: GameState) -> BeamTrace {
        let grid = state.grid
        var result = BeamTrace()
        var direction = grid.emitterDirection
        var pos = grid.emitterCoord
        var visited: Set<BeamVisit> = []
        let maxSteps = grid.columns * grid.rows * 8 + 16
        var steps = 0

        func isSolid(_ coord: Coord) -> Bool {
            guard grid.isInBounds(coord) else { return true }   // screen edge reflects
            if grid.terrain[coord.row][coord.col] == .wall { return true }
            if state.movables[coord] != nil { return true }     // steel blocks reflect
            return false
        }

        while steps < maxSteps {
            steps += 1

            // Reflect off whatever is directly ahead on the diagonal.
            if isSolid(pos.moved(direction)) {
                let horizontal = Coord(col: pos.col + direction.step.dc, row: pos.row)
                let vertical = Coord(col: pos.col, row: pos.row + direction.step.dr)
                let solidH = isSolid(horizontal)
                let solidV = isSolid(vertical)
                if solidH && solidV {
                    direction = direction.reversed                 // concave corner
                } else if solidH {
                    direction = direction.flippedHorizontally      // vertical face
                } else if solidV {
                    direction = direction.flippedVertically        // horizontal face
                } else {
                    direction = direction.reversed                 // isolated corner
                }
            }

            let next = pos.moved(direction)
            if isSolid(next) { break }                             // fully boxed in

            let visit = BeamVisit(coord: next, direction: direction)
            if visited.contains(visit) { break }
            visited.insert(visit)

            result.segments.append(BeamTrace.Segment(coord: next, incoming: direction, outgoing: direction))
            pos = next

            if state.remainingSensors.contains(pos) {
                result.struckSensors.insert(pos)                   // pass through, keep going
            }
        }

        return result
    }
}
