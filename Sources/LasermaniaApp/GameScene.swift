import AppKit
import Foundation
import SpriteKit
import Combine
import LasermaniaCore

/// Renders one level's board: static terrain, the live laser beam, movables,
/// capsules, and the crawler, kept in sync with `GameViewModel.state`.
public final class GameScene: SKScene {
    private let viewModel: GameViewModel
    private let settings: SettingsStore
    private let onPauseToggle: () -> Void
    private var cancellables: Set<AnyCancellable> = []

    /// Set by the hosting `NSViewRepresentable` whenever the Pause overlay is
    /// shown, so movement/undo/restart keys are ignored while the board is
    /// dimmed behind it (the SKView stays mounted; only input is gated here).
    public var isInputPaused = false

    private let boardNode = SKNode()
    private let terrainLayer = SKNode()
    private let sensorsLayer = SKNode()
    private let doorLayer = SKNode()
    private let beamLayer = SKNode()
    private let movablesLayer = SKNode()
    private let capsulesLayer = SKNode()
    private let effectsLayer = SKNode()

    private let crawlerNode = SKNode()

    // Sprites cropped from the original screenshot, bundled as resources.
    private var blockTexture: SKTexture?    // fixed wall blocks (not pushable)
    private var movableTexture: SKTexture?  // the pushable "marked" blocks
    private var capsuleTexture: SKTexture?  // laser-target capsules (dragon eye)
    private var emitterTexture: SKTexture?  // laser source (burger)
    private var vehicleTexture: SKTexture?
    private var baseTexture: SKTexture?

    private var tileSize: CGFloat = 32
    private var previousState: GameState?

    private var palette: Palette { Palette.forTheme(settings.colorTheme) }

    public init(viewModel: GameViewModel, settings: SettingsStore, onPauseToggle: @escaping () -> Void) {
        self.viewModel = viewModel
        self.settings = settings
        self.onPauseToggle = onPauseToggle
        super.init(size: CGSize(width: 960, height: 640))
        scaleMode = .resizeFill
    }

    public required init?(coder: NSCoder) {
        fatalError("GameScene does not support NSCoder")
    }

    deinit {
        repeatTimer?.invalidate()
    }

    public override func didMove(to view: SKView) {
        backgroundColor = .black

        blockTexture = loadTexture("block")
        movableTexture = loadTexture("movable")
        capsuleTexture = loadTexture("capsule")
        emitterTexture = loadTexture("emitter")
        vehicleTexture = loadTexture("vehicle")
        baseTexture = loadTexture("base")

        boardNode.addChild(terrainLayer)
        boardNode.addChild(sensorsLayer)
        boardNode.addChild(doorLayer)
        boardNode.addChild(movablesLayer)
        boardNode.addChild(capsulesLayer)
        boardNode.addChild(beamLayer)     // above blocks so the beam is never hidden
        boardNode.addChild(crawlerNode)
        boardNode.addChild(effectsLayer)
        addChild(boardNode)

        layoutBoard()
        buildTerrain()
        crawlerNode.position = point(for: viewModel.state.crawler, in: viewModel.state.grid)
        render(viewModel.state, previous: nil)
        previousState = viewModel.state

        viewModel.$state
            .dropFirst()
            .sink { [weak self] state in
                guard let self else { return }
                self.render(state, previous: self.previousState)
                self.previousState = state
            }
            .store(in: &cancellables)
    }

    public override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard oldSize != size else { return }
        layoutBoard()
        buildTerrain()
        render(viewModel.state, previous: nil)
    }

    // MARK: - Layout

    private func layoutBoard() {
        let grid = viewModel.state.grid
        guard grid.columns > 0, grid.rows > 0, size.width > 0, size.height > 0 else { return }

        let rawTile = min(size.width / CGFloat(grid.columns), size.height / CGFloat(grid.rows))
        tileSize = max(1, rawTile.rounded(.down))

        let boardWidth = tileSize * CGFloat(grid.columns)
        let boardHeight = tileSize * CGFloat(grid.rows)
        boardNode.position = CGPoint(x: (size.width - boardWidth) / 2, y: (size.height - boardHeight) / 2)
    }

    private func point(for coord: Coord, in grid: Grid) -> CGPoint {
        CGPoint(
            x: (CGFloat(coord.col) + 0.5) * tileSize,
            y: (CGFloat(grid.rows - 1 - coord.row) + 0.5) * tileSize
        )
    }

    /// Screen-space offset, `tileSize`-scaled, for a direction's facing indicator.
    /// Grid `row` increases downward while SpriteKit's y-axis increases upward,
    /// so the vertical component is negated relative to `Direction.step`.
    private func offset(for direction: Direction, distance: CGFloat) -> CGPoint {
        let step = direction.step
        return CGPoint(x: CGFloat(step.dc) * distance, y: CGFloat(-step.dr) * distance)
    }

    // MARK: - Static terrain

    private func buildTerrain() {
        terrainLayer.removeAllChildren()
        let grid = viewModel.state.grid
        let tileBody = CGSize(width: tileSize, height: tileSize)

        for row in 0..<grid.rows {
            for col in 0..<grid.columns {
                let coord = Coord(col: col, row: row)
                let tile = SKShapeNode(rectOf: tileBody)
                tile.position = point(for: coord, in: grid)
                tile.lineWidth = 0
                tile.strokeColor = .clear

                switch grid.terrain[row][col] {
                case .floor:
                    tile.fillColor = .black
                case .wall:
                    // Boundary wall: ends the beam. Drawn as a coloured border bar.
                    tile.fillColor = SKColor(red: 0.55, green: 0.25, blue: 0.6, alpha: 1)
                case .block:
                    // Fixed reflector block: reflects the laser but can't be pushed.
                    tile.fillColor = .black
                    if let texture = blockTexture {
                        tile.addChild(spriteNode(texture))
                    } else {
                        tile.addChild(steelBlockShape())
                    }
                case .emitter(let direction):
                    tile.fillColor = .black
                    tile.addChild(emitterMarker(direction: direction))
                case .sensorSite:
                    tile.fillColor = .black
                case .door:
                    tile.fillColor = .black
                }
                terrainLayer.addChild(tile)
            }
        }
    }

    private static let amber = SKColor(red: 1.0, green: 0.84, blue: 0.3, alpha: 1)

    /// Loads a bundled sprite by name, trying both resource-subdirectory forms
    /// (SwiftPM's `.copy` flattens the path). Nearest-neighbour keeps the retro
    /// pixels crisp when scaled. Returns nil so callers can fall back to shapes.
    private func loadTexture(_ name: String) -> SKTexture? {
        for sub in ["Sprites", "Resources/Sprites"] {
            if let url = Bundle.module.url(forResource: name, withExtension: "png", subdirectory: sub),
               let image = NSImage(contentsOf: url) {
                let texture = SKTexture(image: image)
                texture.filteringMode = .nearest
                return texture
            }
        }
        return nil
    }

    private func spriteNode(_ texture: SKTexture) -> SKSpriteNode {
        let node = SKSpriteNode(texture: texture)
        node.size = CGSize(width: tileSize, height: tileSize)
        return node
    }

    /// The emitter uses the same oval sprite as the sensors (as in the
    /// original). Falls back to an amber ring + a dot on the firing side.
    private func emitterMarker(direction: Diagonal) -> SKNode {
        if let texture = emitterTexture {
            return spriteNode(texture)
        }
        let node = SKNode()
        let ring = SKShapeNode(circleOfRadius: tileSize * 0.30)
        ring.fillColor = .clear
        ring.strokeColor = Self.amber
        ring.lineWidth = max(2, tileSize * 0.08)
        node.addChild(ring)
        let dot = SKShapeNode(circleOfRadius: tileSize * 0.10)
        dot.position = CGPoint(x: CGFloat(direction.step.dc) * tileSize * 0.28,
                               y: CGFloat(-direction.step.dr) * tileSize * 0.28)
        dot.fillColor = Self.amber
        dot.strokeColor = .clear
        node.addChild(dot)
        return node
    }

    // MARK: - Dynamic render

    private func render(_ state: GameState, previous: GameState?) {
        renderSensors(state)
        renderDoor(state)
        renderBeam(state)
        renderMovables(state)
        renderCapsules(state)
        renderCrawler(state)

        guard let previous else { return }

        let struck = previous.remainingSensors.subtracting(state.remainingSensors)
        for coord in struck {
            spawnSensorFlash(at: point(for: coord, in: state.grid))
        }
        if !previous.doorUnlocked && state.doorUnlocked {
            spawnDoorUnlockPulse(state)
        }
        if state.isWon && !previous.isWon {
            spawnWinCelebration()
        }
    }

    private func renderSensors(_ state: GameState) {
        sensorsLayer.removeAllChildren()
        for coord in state.remainingSensors {
            let node: SKNode
            if let texture = capsuleTexture {
                node = spriteNode(texture)
            } else {
                let dot = SKShapeNode(circleOfRadius: tileSize * 0.22)
                dot.fillColor = palette.sensorActive
                dot.strokeColor = .clear
                node = dot
            }
            node.position = point(for: coord, in: state.grid)
            if !settings.reduceMotion {
                let pulse = SKAction.sequence([
                    SKAction.scale(to: 1.12, duration: 0.5),
                    SKAction.scale(to: 1.0, duration: 0.5)
                ])
                node.run(SKAction.repeatForever(pulse))
            }
            sensorsLayer.addChild(node)
        }
    }

    private func renderDoor(_ state: GameState) {
        doorLayer.removeAllChildren()
        let grid = state.grid
        let node: SKNode
        if let texture = baseTexture {
            let sprite = spriteNode(texture)
            sprite.alpha = state.doorUnlocked ? 1.0 : 0.55   // dim until sensors + memories are done
            node = sprite
        } else {
            let panel = SKShapeNode(rectOf: CGSize(width: tileSize * 0.8, height: tileSize * 0.8))
            panel.strokeColor = .clear
            panel.fillColor = state.doorUnlocked ? palette.doorOpen : palette.doorLocked
            panel.alpha = state.doorUnlocked ? 0.5 : 1.0
            node = panel
        }
        node.position = point(for: grid.doorCoord, in: grid)
        doorLayer.addChild(node)
    }

    private func renderBeam(_ state: GameState) {
        beamLayer.removeAllChildren()
        let trace = state.beam
        guard trace.points.count > 1 else { return }

        let rows = state.grid.rows
        let pts = trace.points.map { beamPixel($0, rows: rows) }
        for i in 0..<(pts.count - 1) {
            addBeamLine(from: pts[i], to: pts[i + 1])
        }
        if let last = pts.last {
            addBeamDot(at: last)
        }
    }

    /// Converts a beam point (cell units, y increases downward) to board pixels
    /// (SpriteKit y increases upward).
    private func beamPixel(_ p: BeamPoint, rows: Int) -> CGPoint {
        CGPoint(x: CGFloat(p.x) * tileSize, y: (CGFloat(rows) - CGFloat(p.y)) * tileSize)
    }

    private func addBeamLine(from: CGPoint, to: CGPoint) {
        let path = CGMutablePath()
        path.move(to: from)
        path.addLine(to: to)
        let line = SKShapeNode(path: path)
        line.strokeColor = SKColor(white: 0.95, alpha: 1)
        line.lineWidth = max(2, tileSize * 0.12)
        line.lineCap = .round
        line.glowWidth = tileSize * 0.18
        beamLayer.addChild(line)

        guard !settings.reduceMotion else { return }
        line.alpha = 0.75
        let shimmer = SKAction.sequence([
            SKAction.fadeAlpha(to: 1.0, duration: 0.4),
            SKAction.fadeAlpha(to: 0.75, duration: 0.4)
        ])
        line.run(SKAction.repeatForever(shimmer))
    }

    private func addBeamDot(at position: CGPoint) {
        let dot = SKShapeNode(circleOfRadius: tileSize * 0.15)
        dot.position = position
        dot.fillColor = SKColor(white: 0.95, alpha: 1)
        dot.strokeColor = .clear
        dot.glowWidth = tileSize * 0.2
        beamLayer.addChild(dot)
    }

    /// The pushable blocks — drawn with the "marked" movable sprite so they're
    /// distinguishable from the fixed wall blocks. Falls back to a green block.
    private func renderMovables(_ state: GameState) {
        movablesLayer.removeAllChildren()
        for (coord, _) in state.movables {
            let node: SKNode
            if let texture = movableTexture {
                node = spriteNode(texture)
            } else {
                node = steelBlockShape()
            }
            node.position = point(for: coord, in: state.grid)
            movablesLayer.addChild(node)
        }
    }

    private func steelBlockShape() -> SKNode {
        let side = tileSize * 0.92
        let edge = max(2, tileSize * 0.10)
        let node = SKNode()
        let body = SKShapeNode(rectOf: CGSize(width: side, height: side))
        body.fillColor = SKColor(red: 0.16, green: 0.55, blue: 0.16, alpha: 1)
        body.strokeColor = .clear
        node.addChild(body)
        let top = SKShapeNode(rectOf: CGSize(width: side, height: edge))
        top.fillColor = SKColor(white: 0.85, alpha: 1)
        top.strokeColor = .clear
        top.position = CGPoint(x: 0, y: side / 2 - edge / 2)
        node.addChild(top)
        let bottom = SKShapeNode(rectOf: CGSize(width: side, height: edge))
        bottom.fillColor = SKColor(red: 0.45, green: 0.05, blue: 0.05, alpha: 1)
        bottom.strokeColor = .clear
        bottom.position = CGPoint(x: 0, y: -side / 2 + edge / 2)
        node.addChild(bottom)
        return node
    }

    /// Drive-over collectibles. Unused in the Lasermania levels (capsules are
    /// laser targets, handled as sensors), but kept for the engine's generality.
    private func renderCapsules(_ state: GameState) {
        capsulesLayer.removeAllChildren()
        for coord in state.remainingCapsules {
            let capsule = SKShapeNode(circleOfRadius: tileSize * 0.18)
            capsule.fillColor = palette.capsule
            capsule.strokeColor = .clear
            capsule.position = point(for: coord, in: state.grid)
            capsulesLayer.addChild(capsule)
        }
    }

    private func renderCrawler(_ state: GameState) {
        crawlerNode.removeAllChildren()
        if let texture = vehicleTexture {
            crawlerNode.addChild(spriteNode(texture))
        } else {
            let body = SKShapeNode(circleOfRadius: tileSize * 0.32)
            body.fillColor = palette.crawler
            body.strokeColor = .clear
            crawlerNode.addChild(body)
            let dot = SKShapeNode(circleOfRadius: tileSize * 0.08)
            dot.fillColor = palette.background
            dot.strokeColor = .clear
            dot.position = offset(for: state.facing, distance: tileSize * 0.24)
            crawlerNode.addChild(dot)
        }

        let target = point(for: state.crawler, in: state.grid)
        if settings.reduceMotion {
            crawlerNode.removeAllActions()
            crawlerNode.position = target
        } else {
            crawlerNode.run(SKAction.move(to: target, duration: 0.12))
        }
    }

    // MARK: - One-shot effects

    private func spawnSensorFlash(at position: CGPoint) {
        guard !settings.reduceMotion else { return }
        let flash = SKShapeNode(circleOfRadius: tileSize * 0.4)
        flash.position = position
        flash.fillColor = palette.sensorActive
        flash.strokeColor = .clear
        effectsLayer.addChild(flash)
        flash.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 2.2, duration: 0.3),
                SKAction.fadeOut(withDuration: 0.3)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    private func spawnDoorUnlockPulse(_ state: GameState) {
        guard !settings.reduceMotion else { return }
        let ring = SKShapeNode(circleOfRadius: tileSize * 0.3)
        ring.position = point(for: state.grid.doorCoord, in: state.grid)
        ring.fillColor = .clear
        ring.strokeColor = palette.doorOpen
        ring.lineWidth = 3
        effectsLayer.addChild(ring)
        ring.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 2.5, duration: 0.5),
                SKAction.fadeOut(withDuration: 0.5)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    private func spawnWinCelebration() {
        guard !settings.reduceMotion else { return }
        let burst = SKShapeNode(circleOfRadius: tileSize * 0.5)
        burst.position = crawlerNode.position
        burst.fillColor = palette.crawler
        burst.strokeColor = .clear
        burst.alpha = 0.6
        effectsLayer.addChild(burst)
        burst.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 3.0, duration: 0.6),
                SKAction.fadeOut(withDuration: 0.6)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Input (macOS keyboard)

    /// Virtual key codes (stable across Mac keyboard layouts; these identify
    /// physical key positions, not characters). Arrows and WASD both move.
    private static let movementKeyCodes: [UInt16: Direction] = [
        123: .left, 0: .left,
        124: .right, 2: .right,
        126: .up, 13: .up,
        125: .down, 1: .down
    ]
    private static let undoKeyCode: UInt16 = 6      // Z (works with or without ⌘)
    private static let restartKeyCode: UInt16 = 15  // R
    private static let pauseKeyCodes: Set<UInt16> = [53, 35] // Escape, P

    private static let initialRepeatDelay: TimeInterval = 0.35
    private static let repeatInterval: TimeInterval = 0.12

    /// Movement keys currently held down, in case more than one is pressed at once.
    private var heldMovementKeys: [UInt16: Direction] = [:]
    private var repeatingKeyCode: UInt16?
    private var repeatTimer: Timer?

    public override func keyDown(with event: NSEvent) {
        guard !event.isARepeat else { return }
        let keyCode = event.keyCode

        if Self.pauseKeyCodes.contains(keyCode) {
            onPauseToggle()
            return
        }
        guard !isInputPaused else { return }

        if let direction = Self.movementKeyCodes[keyCode] {
            heldMovementKeys[keyCode] = direction
            beginRepeating(keyCode: keyCode, direction: direction)
            return
        }

        if keyCode == Self.undoKeyCode {
            viewModel.undo()
        } else if keyCode == Self.restartKeyCode {
            viewModel.restart()
        }
    }

    public override func keyUp(with event: NSEvent) {
        let keyCode = event.keyCode
        heldMovementKeys.removeValue(forKey: keyCode)

        guard keyCode == repeatingKeyCode else { return }
        stopRepeating()

        if let (fallbackKeyCode, fallbackDirection) = heldMovementKeys.first {
            beginRepeating(keyCode: fallbackKeyCode, direction: fallbackDirection)
        }
    }

    /// Moves immediately, then arms a one-shot delay before switching to a fast,
    /// fixed-rate repeat, independent of the system's own key-repeat settings.
    private func beginRepeating(keyCode: UInt16, direction: Direction) {
        repeatTimer?.invalidate()
        repeatingKeyCode = keyCode
        viewModel.move(direction)

        repeatTimer = Timer.scheduledTimer(withTimeInterval: Self.initialRepeatDelay, repeats: false) { [weak self] _ in
            guard let self, !self.isInputPaused else { return }
            self.startFastRepeat(direction: direction)
        }
    }

    private func startFastRepeat(direction: Direction) {
        repeatTimer = Timer.scheduledTimer(withTimeInterval: Self.repeatInterval, repeats: true) { [weak self] _ in
            guard let self, !self.isInputPaused else { return }
            self.viewModel.move(direction)
        }
    }

    private func stopRepeating() {
        repeatTimer?.invalidate()
        repeatTimer = nil
        repeatingKeyCode = nil
    }
}
