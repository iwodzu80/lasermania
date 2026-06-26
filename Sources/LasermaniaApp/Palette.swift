import SpriteKit

/// Theme-driven colors for `GameScene`. Two themes per the spec's Settings
/// overlay: an atmospheric "Classic" look and a high-contrast accessibility mode.
struct Palette {
    let background: SKColor
    let floor: SKColor
    let wall: SKColor
    let emitter: SKColor
    let sensorPad: SKColor
    let sensorActive: SKColor
    let doorLocked: SKColor
    let doorOpen: SKColor
    let box: SKColor
    let mirror: SKColor
    let capsule: SKColor
    let crawler: SKColor
    let beam: SKColor

    static let classic = Palette(
        background: SKColor(red: 0.05, green: 0.06, blue: 0.09, alpha: 1),
        floor: SKColor(red: 0.14, green: 0.16, blue: 0.20, alpha: 1),
        wall: SKColor(red: 0.30, green: 0.32, blue: 0.36, alpha: 1),
        emitter: SKColor(red: 0.95, green: 0.30, blue: 0.30, alpha: 1),
        sensorPad: SKColor(red: 0.32, green: 0.22, blue: 0.10, alpha: 1),
        sensorActive: SKColor(red: 1.00, green: 0.65, blue: 0.15, alpha: 1),
        doorLocked: SKColor(red: 0.55, green: 0.18, blue: 0.18, alpha: 1),
        doorOpen: SKColor(red: 0.25, green: 0.75, blue: 0.40, alpha: 1),
        box: SKColor(red: 0.55, green: 0.42, blue: 0.27, alpha: 1),
        mirror: SKColor(red: 0.55, green: 0.82, blue: 0.95, alpha: 1),
        capsule: SKColor(red: 0.95, green: 0.85, blue: 0.25, alpha: 1),
        crawler: SKColor(red: 0.25, green: 0.85, blue: 0.65, alpha: 1),
        beam: SKColor(red: 1.00, green: 0.25, blue: 0.25, alpha: 1)
    )

    static let highContrast = Palette(
        background: SKColor.black,
        floor: SKColor(white: 0.14, alpha: 1),
        wall: SKColor.white,
        emitter: SKColor(red: 1.00, green: 0.10, blue: 0.10, alpha: 1),
        sensorPad: SKColor(white: 0.32, alpha: 1),
        sensorActive: SKColor(red: 1.00, green: 0.90, blue: 0.00, alpha: 1),
        doorLocked: SKColor(red: 1.00, green: 0.10, blue: 0.10, alpha: 1),
        doorOpen: SKColor(red: 0.10, green: 1.00, blue: 0.20, alpha: 1),
        box: SKColor(white: 0.78, alpha: 1),
        mirror: SKColor(red: 0.10, green: 0.85, blue: 1.00, alpha: 1),
        capsule: SKColor(red: 1.00, green: 1.00, blue: 0.00, alpha: 1),
        crawler: SKColor(red: 0.10, green: 1.00, blue: 0.55, alpha: 1),
        beam: SKColor(red: 1.00, green: 0.10, blue: 0.10, alpha: 1)
    )

    static func forTheme(_ theme: ColorTheme) -> Palette {
        switch theme {
        case .classic: return .classic
        case .highContrast: return .highContrast
        }
    }
}
