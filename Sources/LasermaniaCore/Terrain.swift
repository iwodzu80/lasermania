public enum StaticTerrain: Hashable, Sendable {
    case floor
    case wall            // level boundary: ENDS the beam (no reflection), blocks the vehicle
    case block           // fixed reflector: reflects the beam, blocks the vehicle
    case emitter(Diagonal)
    case sensorSite
    case door
}

/// A pushable object on the board. In the Lasermania remake there is a single
/// kind — a steel block that reflects the diagonal laser off its flat faces.
/// (`mirrorSlash`/`mirrorBackslash` are retained for source compatibility with
/// older tests and are treated identically to `box`.)
public enum MovableKind: Hashable, Sendable {
    case box
    case mirrorSlash
    case mirrorBackslash
}
