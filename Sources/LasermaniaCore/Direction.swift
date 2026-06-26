public enum Direction: String, CaseIterable, Codable, Hashable, Sendable {
    case up, down, left, right

    public var step: (dc: Int, dr: Int) {
        switch self {
        case .up: return (0, -1)
        case .down: return (0, 1)
        case .left: return (-1, 0)
        case .right: return (1, 0)
        }
    }

    public func reflectedSlash() -> Direction {
        switch self {
        case .up: return .right
        case .right: return .up
        case .down: return .left
        case .left: return .down
        }
    }

    public func reflectedBackslash() -> Direction {
        switch self {
        case .up: return .left
        case .left: return .up
        case .down: return .right
        case .right: return .down
        }
    }
}
