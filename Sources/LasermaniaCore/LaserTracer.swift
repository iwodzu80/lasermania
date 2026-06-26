public struct BeamTrace: Equatable, Sendable {
    public struct Segment: Equatable, Sendable {
        public let coord: Coord
        public let incoming: Direction
        public let outgoing: Direction

        public init(coord: Coord, incoming: Direction, outgoing: Direction) {
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

public enum LaserTracer {
    private struct BeamVisit: Hashable {
        let coord: Coord
        let direction: Direction
    }

    public static func trace(_ state: GameState) -> BeamTrace {
        let grid = state.grid
        var result = BeamTrace()
        var direction = grid.emitterDirection
        var pos = grid.emitterCoord.moved(direction)
        var visited: Set<BeamVisit> = []
        let maxSteps = grid.columns * grid.rows * 4 + 8
        var steps = 0

        while steps < maxSteps {
            steps += 1
            guard grid.isInBounds(pos) else { break }

            let visit = BeamVisit(coord: pos, direction: direction)
            if visited.contains(visit) { break }
            visited.insert(visit)

            guard let terrain = grid.cell(at: pos) else { break }

            if terrain == .wall { break }

            let movableHere = state.movables[pos]
            if movableHere == .box { break }

            if let kind = movableHere {
                let newDirection = kind == .mirrorSlash ? direction.reflectedSlash() : direction.reflectedBackslash()
                result.segments.append(BeamTrace.Segment(coord: pos, incoming: direction, outgoing: newDirection))
                direction = newDirection
                pos = pos.moved(direction)
                continue
            }

            if state.remainingSensors.contains(pos) {
                result.struckSensors.insert(pos)
                break
            }

            if terrain == .door && !state.doorUnlocked { break }

            result.segments.append(BeamTrace.Segment(coord: pos, incoming: direction, outgoing: direction))
            pos = pos.moved(direction)
        }

        return result
    }
}
