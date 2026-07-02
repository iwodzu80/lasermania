import SwiftUI
import AppKit
import SpriteKit
import LasermaniaCore
import Foundation

/// §4.3 Gameplay screen: HUD strip, the live SpriteKit board, and a control
/// hint footer. The Pause overlay (§4.4) is drawn on top without tearing down
/// the `SKView`, so the board stays mounted (and visible, dimmed) behind it.
struct GameplayScreen: View {
    @ObservedObject var appState: AppState
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                hud
                Rectangle().fill(Color.white.opacity(0.15)).frame(height: 1)

                GameSceneView(
                    viewModel: viewModel,
                    settings: appState.settings,
                    isPaused: appState.screen == .pause,
                    onPauseToggle: togglePause
                )
                .id(ObjectIdentifier(viewModel))
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Rectangle().fill(Color.white.opacity(0.15)).frame(height: 1)
                controlHint
            }

            if appState.screen == .pause {
                PauseOverlay(appState: appState)
            }
        }
    }

    private func togglePause() {
        switch appState.screen {
        case .gameplay: appState.pauseGameplay()
        case .pause: appState.resumeGameplay()
        default: break
        }
    }

    private var hud: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Lvl \(String(format: "%02d", appState.currentLevelIndex + 1)) \"\(viewModel.level.name)\"")
                Spacer()
                Text("Sensors \(viewModel.sensorsDestroyed)/\(viewModel.state.totalSensors)")
                Spacer()
                Text("Caps \(viewModel.capsulesCollected)/\(viewModel.state.totalCapsules)")
            }
            HStack {
                Text("Moves \(String(format: "%02d", viewModel.movesUsed))")
                Spacer()
                Text("Best \(viewModel.bestMoves.map(String.init) ?? "—")")
                Spacer()
                Button(action: viewModel.undo) {
                    Text("↶ Undo")
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.canUndo)
                .opacity(viewModel.canUndo ? 1 : 0.4)

                Button(action: togglePause) {
                    Text("⏸")
                }
                .buttonStyle(.plain)
            }
        }
        .font(.system(size: 14, design: .monospaced))
        .foregroundColor(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    private var controlHint: some View {
        Text("◂▸▴▾ move/push   Z undo   R restart   Esc menu")
            .font(.system(size: 12, design: .monospaced))
            .foregroundColor(.white.opacity(0.5))
            .padding(.vertical, 8)
    }
}

/// Hosts the SpriteKit board. Identified by the view model's `ObjectIdentifier`
/// (see call site) so a new level — or a replay, which is also a fresh
/// `GameViewModel` — tears down and recreates the scene, while pausing
/// (which only flips `AppState.screen`, never `gameViewModel`) reuses it.
private struct GameSceneView: NSViewRepresentable {
    let viewModel: GameViewModel
    let settings: SettingsStore
    let isPaused: Bool
    let onPauseToggle: () -> Void

    func makeNSView(context: Context) -> SKView {
        let view = BoardSKView(frame: .zero)
        let scene = GameScene(viewModel: viewModel, settings: settings, onPauseToggle: onPauseToggle)
        scene.isInputPaused = isPaused
        view.presentScene(scene)
        return view
    }

    func updateNSView(_ nsView: SKView, context: Context) {
        (nsView.scene as? GameScene)?.isInputPaused = isPaused
        guard !isPaused, nsView.window?.firstResponder !== nsView else { return }
        nsView.window?.makeFirstResponder(nsView)
    }
}

/// An `SKView` that reliably takes keyboard focus. Launched via `swift run`,
/// the window doesn't hand the board first-responder status on its own, so the
/// scene's `keyDown` never fires and the vehicle can't move. This claims focus
/// as soon as the view joins a window and forwards key events to the scene.
private final class BoardSKView: SKView {
    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        DispatchQueue.main.async { [weak self] in
            guard let self, let window = self.window else { return }
            window.makeFirstResponder(self)
        }
    }

    override func keyDown(with event: NSEvent) {
        if let scene { scene.keyDown(with: event) } else { super.keyDown(with: event) }
    }

    override func keyUp(with event: NSEvent) {
        if let scene { scene.keyUp(with: event) } else { super.keyUp(with: event) }
    }
}
