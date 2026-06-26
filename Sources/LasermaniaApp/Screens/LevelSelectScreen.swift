import SwiftUI
import Foundation

/// §4.2 Level Select: grid of unlocked levels, gated behind progress.
struct LevelSelectScreen: View {
    @ObservedObject var appState: AppState

    @State private var selectedIndex = 0
    @FocusState private var isFocused: Bool

    private let columns = 5

    private var currentIndex: Int {
        appState.levels.firstIndex { !appState.progress.isSolved($0.id) } ?? 0
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("SELECT LEVEL")
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    Spacer()
                    Button("⟵ Back") { appState.showTitle() }
                        .buttonStyle(.plain)
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: 14, design: .monospaced))
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: columns), spacing: 12) {
                    ForEach(appState.levels.indices, id: \.self) { index in
                        LevelTile(
                            number: index + 1,
                            badge: badge(for: index),
                            isSelected: index == selectedIndex,
                            isUnlocked: appState.isUnlocked(index)
                        )
                        .onTapGesture {
                            selectedIndex = index
                            activate(index)
                        }
                    }
                }

                Text("✔ solved   ★ current   🔒 locked")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))

                if appState.levels.indices.contains(selectedIndex) {
                    let level = appState.levels[selectedIndex]
                    let best = appState.progress.bestMoves(for: level.id)
                    Text("Level \(String(format: "%02d", selectedIndex + 1)) \"\(level.name)\"" + (best.map { " — best: \($0) moves" } ?? ""))
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(28)

            Button(action: { activate(selectedIndex) }) { Color.clear }
                .keyboardShortcut(.defaultAction)
                .allowsHitTesting(false)
        }
        .focusable()
        .focused($isFocused)
        .onAppear { isFocused = true }
        .onMoveCommand { direction in
            guard !appState.levels.isEmpty else { return }
            let count = appState.levels.count
            switch direction {
            case .left:
                selectedIndex = max(0, selectedIndex - 1)
            case .right:
                selectedIndex = min(count - 1, selectedIndex + 1)
            case .up:
                selectedIndex = max(0, selectedIndex - columns)
            case .down:
                selectedIndex = min(count - 1, selectedIndex + columns)
            default:
                break
            }
        }
    }

    private func activate(_ index: Int) {
        guard appState.isUnlocked(index) else { return }
        appState.startLevel(at: index)
    }

    private func badge(for index: Int) -> String? {
        guard appState.levels.indices.contains(index) else { return nil }
        if !appState.isUnlocked(index) { return "🔒" }
        if appState.progress.isSolved(appState.levels[index].id) { return "✔" }
        if index == currentIndex { return "★" }
        return nil
    }
}

private struct LevelTile: View {
    let number: Int
    let badge: String?
    let isSelected: Bool
    let isUnlocked: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text(String(format: "%02d", number))
                .font(.system(size: 16, weight: .bold, design: .monospaced))
            if let badge {
                Text(badge).font(.system(size: 14))
            } else {
                Text(" ").font(.system(size: 14))
            }
        }
        .foregroundColor(isUnlocked ? .white : .white.opacity(0.35))
        .frame(width: 56, height: 56)
        .background(isSelected ? Color.white.opacity(0.2) : Color.white.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? Color.yellow : Color.white.opacity(0.15), lineWidth: isSelected ? 2 : 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .contentShape(Rectangle())
    }
}
