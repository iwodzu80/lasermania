public struct GameState: Equatable, Sendable {
    public let grid: Grid
    public let crawler: Coord
    public let facing: Direction
    public let movables: [Coord: MovableKind]
    public let remainingSensors: Set<Coord>
    public let remainingCapsules: Set<Coord>
    public let totalSensors: Int
    public let totalCapsules: Int
    public let movesUsed: Int

    public init(
        grid: Grid,
        crawler: Coord,
        facing: Direction,
        movables: [Coord: MovableKind],
        remainingSensors: Set<Coord>,
        remainingCapsules: Set<Coord>,
        totalSensors: Int,
        totalCapsules: Int,
        movesUsed: Int
    ) {
        self.grid = grid
        self.crawler = crawler
        self.facing = facing
        self.movables = movables
        self.remainingSensors = remainingSensors
        self.remainingCapsules = remainingCapsules
        self.totalSensors = totalSensors
        self.totalCapsules = totalCapsules
        self.movesUsed = movesUsed
    }

    public var doorUnlocked: Bool {
        remainingSensors.isEmpty && remainingCapsules.isEmpty
    }

    public var isWon: Bool {
        doorUnlocked && crawler == grid.doorCoord
    }

    public var beam: BeamTrace {
        LaserTracer.trace(self)
    }

    public func applying(_ move: Direction) -> GameState? {
        let target = crawler.moved(move)
        guard let targetTerrain = grid.cell(at: target) else { return nil }

        switch targetTerrain {
        case .wall, .block, .emitter:
            return nil
        case .sensorSite:
            if remainingSensors.contains(target) { return nil }
        case .door:
            if !doorUnlocked { return nil }
        case .floor:
            break
        }

        var newMovables = movables
        if let kind = movables[target] {
            let beyond = target.moved(move)
            guard let beyondTerrain = grid.cell(at: beyond), movables[beyond] == nil else { return nil }
            switch beyondTerrain {
            case .wall, .block, .emitter, .sensorSite, .door:
                return nil
            case .floor:
                break
            }
            newMovables.removeValue(forKey: target)
            newMovables[beyond] = kind
        }

        let afterMovement = GameState(
            grid: grid,
            crawler: target,
            facing: move,
            movables: newMovables,
            remainingSensors: remainingSensors,
            remainingCapsules: remainingCapsules,
            totalSensors: totalSensors,
            totalCapsules: totalCapsules,
            movesUsed: movesUsed + 1
        )

        let struckSensors = LaserTracer.trace(afterMovement).struckSensors
        var newRemainingCapsules = remainingCapsules
        newRemainingCapsules.remove(target)

        return GameState(
            grid: grid,
            crawler: target,
            facing: move,
            movables: newMovables,
            remainingSensors: remainingSensors.subtracting(struckSensors),
            remainingCapsules: newRemainingCapsules,
            totalSensors: totalSensors,
            totalCapsules: totalCapsules,
            movesUsed: movesUsed + 1
        )
    }
}
