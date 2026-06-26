import SwiftUI

/// §4.4 Pause overlay: dims the board (kept mounted behind it, not unloaded)
/// and offers Resume/Restart/Settings/Quit. Escape resumes in addition to
/// toggling pause from `GameScene`, since once this overlay's `MenuList`
/// takes focus, key codes no longer reach the SpriteKit scene's `keyDown`.
struct PauseOverlay: View {
    @ObservedObject var appState: AppState

    var body: some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea()

            Button(action: { appState.resumeGameplay() }) { Color.clear }
                .keyboardShortcut(.cancelAction)
                .allowsHitTesting(false)

            VStack(spacing: 28) {
                Text("▒▒ PAUSED ▒▒")
                    .font(.system(size: 26, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)

                MenuList(items: [
                    .init("RESUME") { appState.resumeGameplay() },
                    .init("RESTART LEVEL") {
                        appState.resumeGameplay()
                        appState.restartLevel()
                    },
                    .init("SETTINGS") { appState.openSettings() },
                    .init("QUIT TO MENU") { appState.quitToTitle() }
                ])
            }
        }
    }
}
