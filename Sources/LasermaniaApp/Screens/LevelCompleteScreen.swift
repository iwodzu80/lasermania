import SwiftUI
import Foundation

/// §4.5 Level Complete: stats for the level just cleared, then Next/Replay/Select.
/// `viewModel` is read once for its frozen post-win stats; no further moves can
/// occur on it once this screen is showing.
struct LevelCompleteScreen: View {
    @ObservedObject var appState: AppState
    let viewModel: GameViewModel

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                Text("✦  LEVEL CLEAR  ✦")
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)

                VStack(spacing: 10) {
                    Text("Level \(String(format: "%02d", appState.currentLevelIndex + 1)) \"\(viewModel.level.name)\"")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)

                    HStack(spacing: 6) {
                        Text("Moves: \(viewModel.movesUsed)")
                        Text("Best: \(viewModel.bestMoves ?? viewModel.movesUsed)")
                        if viewModel.isNewBest {
                            Text("★ NEW BEST!").foregroundColor(.yellow)
                        }
                    }
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(.white.opacity(0.85))

                    Text("Capsules: \(viewModel.capsulesCollected)/\(viewModel.state.totalCapsules)     Score: +\(viewModel.score)")
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(.white.opacity(0.85))
                }

                MenuList(items: [
                    .init("NEXT LEVEL") { appState.advanceToNextLevelOrVictory() },
                    .init("REPLAY") { appState.retryCurrentLevel() },
                    .init("LEVEL SELECT") { appState.showLevelSelect() }
                ])

                Spacer()
            }
            .padding(28)
        }
    }
}
