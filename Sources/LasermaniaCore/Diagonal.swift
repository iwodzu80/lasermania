/// The laser in Lasermania travels on 45° diagonals and bounces off the flat
/// faces of steel blocks and the screen edges, billiard-ball style (angle of
/// incidence = angle of reflection). `Diagonal` is the beam's travel direction;
/// the vehicle still moves orthogonally via `Direction`.
public enum Diagonal: String, CaseIterable, Codable, Hashable, Sendable {
    case ne, nw, se, sw

    /// Grid step. `dr` is positive downward (row index increases downward).
    public var step: (dc: Int, dr: Int) {
        switch self {
        case .ne: return (1, -1)
        case .nw: return (-1, -1)
        case .se: return (1, 1)
        case .sw: return (-1, 1)
        }
    }

    /// Reverse both components — a head-on corner hit sends the beam back.
    public var reversed: Diagonal {
        switch self {
        case .ne: return .sw
        case .sw: return .ne
        case .nw: return .se
        case .se: return .nw
        }
    }

    /// Flip the horizontal component — bounce off a vertical (left/right) face.
    public var flippedHorizontally: Diagonal {
        switch self {
        case .ne: return .nw
        case .nw: return .ne
        case .se: return .sw
        case .sw: return .se
        }
    }

    /// Flip the vertical component — bounce off a horizontal (top/bottom) face.
    public var flippedVertically: Diagonal {
        switch self {
        case .ne: return .se
        case .se: return .ne
        case .nw: return .sw
        case .sw: return .nw
        }
    }
}
