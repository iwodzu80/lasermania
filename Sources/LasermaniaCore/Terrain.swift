public enum StaticTerrain: Hashable, Sendable {
    case floor
    case wall
    case emitter(Direction)
    case sensorSite
    case door
}

public enum MovableKind: Hashable, Sendable {
    case box
    case mirrorSlash
    case mirrorBackslash
}
