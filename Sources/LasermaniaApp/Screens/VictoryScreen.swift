import SwiftUI
import Foundation

/// §4.6 Victory / Game Complete: shown once the last level's "next" advances
/// past the end of the pack (see `AppState.advanceToNextLevelOrVictory`).
struct VictoryScreen: View {
    @ObservedObject var appState: AppState

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                Text("★  ALL SENSORS NEUTRALIZED  ★")
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)

                VStack(spacing: 10) {
                    Text("You cleared all \(appState.levels.count) levels.")
                    Text("Total moves: \(appState.totalMoves)   Total score: \(formatted(appState.totalScore))")
                }
                .font(.system(size: 15, design: .monospaced))
                .foregroundColor(.white.opacity(0.85))

                MenuList(items: [
                    .init("MAIN MENU") { appState.showTitle() },
                    .init("PLAY AGAIN") { appState.playAgain() }
                ])

                Spacer()
            }
            .padding(28)
        }
    }

    private func formatted(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? String(number)
    }
}
