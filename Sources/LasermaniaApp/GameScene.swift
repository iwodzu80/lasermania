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
    private let crawlerBody = SKShapeNode(circleOfRadius: 1)
    private let crawlerFacingDot = SKShapeNode(circleOfRadius: 1)

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
        backgroundColor = palette.background

        crawlerBody.strokeColor = .clear
        crawlerFacingDot.strokeColor = .clear
        crawlerNode.addChild(crawlerBody)
        crawlerNode.addChild(crawlerFacingDot)

        boardNode.addChild(terrainLayer)
        boardNode.addChild(sensorsLayer)
        boardNode.addChild(doorLayer)
        boardNode.addChild(beamLayer)
        boardNode.addChild(movablesLayer)
        boardNode.addChild(capsulesLayer)
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
                    tile.fillColor = palette.floor
                case .wall:
                    tile.fillColor = palette.wall
                case .emitter(let direction):
                    tile.fillColor = palette.floor
                    tile.addChild(emitterMarker(direction: direction))
                case .sensorSite:
                    tile.fillColor = palette.sensorPad
                case .door:
                    tile.fillColor = palette.floor
                }
                terrainLayer.addChild(tile)
            }
        }
    }

    private func emitterMarker(direction: Direction) -> SKShapeNode {
        let dot = SKShapeNode(circleOfRadius: tileSize * 0.12)
        dot.position = offset(for: direction, distance: tileSize * 0.28)
        dot.fillColor = palette.emitter
        dot.strokeColor = .clear
        return dot
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
            let dot = SKShapeNode(circleOfRadius: tileSize * 0.22)
            dot.position = point(for: coord, in: state.grid)
            dot.fillColor = palette.sensorActive
            dot.strokeColor = .clear
            if !settings.reduceMotion {
                let pulse = SKAction.sequence([
                    SKAction.scale(to: 1.25, duration: 0.5),
                    SKAction.scale(to: 1.0, duration: 0.5)
                ])
                dot.run(SKAction.repeatForever(pulse))
            }
            sensorsLayer.addChild(dot)
        }
    }

    private func renderDoor(_ state: GameState) {
        doorLayer.removeAllChildren()
        let grid = state.grid
        let panel = SKShapeNode(rectOf: CGSize(width: tileSize * 0.8, height: tileSize * 0.8))
        panel.position = point(for: grid.doorCoord, in: grid)
        panel.strokeColor = .clear
        panel.fillColor = state.doorUnlocked ? palette.doorOpen : palette.doorLocked
        panel.alpha = state.doorUnlocked ? 0.5 : 1.0
        doorLayer.addChild(panel)
    }

    private func renderBeam(_ state: GameState) {
        beamLayer.removeAllChildren()
        let grid = state.grid
        let trace = state.beam
        guard !trace.segments.isEmpty else { return }

        var points = [point(for: grid.emitterCoord, in: grid)]
        points.append(contentsOf: trace.segments.map { point(for: $0.coord, in: grid) })

        for i in 0..<(points.count - 1) {
            addBeamLine(from: points[i], to: points[i + 1])
        }
        if let last = points.last {
            addBeamDot(at: last)
        }
    }

    private func addBeamLine(from: CGPoint, to: CGPoint) {
        let path = CGMutablePath()
        path.move(to: from)
        path.addLine(to: to)
        let line = SKShapeNode(path: path)
        line.strokeColor = palette.beam
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
        dot.fillColor = palette.beam
        dot.strokeColor = .clear
        dot.glowWidth = tileSize * 0.2
        beamLayer.addChild(dot)
    }

    private func renderMovables(_ state: GameState) {
        movablesLayer.removeAllChildren()
        for (coord, kind) in state.movables {
            let node: SKShapeNode
            switch kind {
            case .box:
                node = SKShapeNode(rectOf: CGSize(width: tileSize * 0.7, height: tileSize * 0.7), cornerRadius: tileSize * 0.08)
                node.fillColor = palette.box
                node.strokeColor = .clear
            case .mirrorSlash, .mirrorBackslash:
                let half = tileSize * 0.35
                let path = CGMutablePath()
                if kind == .mirrorSlash {
                    path.move(to: CGPoint(x: -half, y: -half))
                    path.addLine(to: CGPoint(x: half, y: half))
                } else {
                    path.move(to: CGPoint(x: -half, y: half))
                    path.addLine(to: CGPoint(x: half, y: -half))
                }
                node = SKShapeNode(path: path)
                node.strokeColor = palette.mirror
                node.lineWidth = max(2, tileSize * 0.12)
                node.lineCap = .round
            }
            node.position = point(for: coord, in: state.grid)
            movablesLayer.addChild(node)
        }
    }

    private func renderCapsules(_ state: GameState) {
        capsulesLayer.removeAllChildren()
        for coord in state.remainingCapsules {
            let capsule = SKShapeNode(circleOfRadius: tileSize * 0.18)
            capsule.position = point(for: coord, in: state.grid)
            capsule.fillColor = palette.capsule
            capsule.strokeColor = .clear
            capsulesLayer.addChild(capsule)
        }
    }

    private func renderCrawler(_ state: GameState) {
        let target = point(for: state.crawler, in: state.grid)
        let bodyRadius = tileSize * 0.32
        let dotRadius = tileSize * 0.08

        crawlerBody.path = CGPath(ellipseIn: CGRect(x: -bodyRadius, y: -bodyRadius, width: bodyRadius * 2, height: bodyRadius * 2), transform: nil)
        crawlerBody.fillColor = palette.crawler

        crawlerFacingDot.path = CGPath(ellipseIn: CGRect(x: -dotRadius, y: -dotRadius, width: dotRadius * 2, height: dotRadius * 2), transform: nil)
        crawlerFacingDot.fillColor = palette.background
        crawlerFacingDot.position = offset(for: state.facing, distance: tileSize * 0.24)

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
