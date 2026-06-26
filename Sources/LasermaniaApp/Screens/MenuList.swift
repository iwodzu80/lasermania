import SwiftUI

/// A vertical list of actions, navigable by arrow keys + Return, or by mouse,
/// per the spec's menu controls. Shared by Title, Pause, Level Complete, and
/// Victory, which are all simple "stack of actions" screens.
struct MenuList: View {
    struct Item {
        let title: String
        let action: () -> Void

        init(_ title: String, action: @escaping () -> Void) {
            self.title = title
            self.action = action
        }
    }

    let items: [Item]

    @State private var selectedIndex = 0
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            Button(action: activateSelected) { Color.clear }
                .keyboardShortcut(.defaultAction)
                .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 14) {
                ForEach(items.indices, id: \.self) { index in
                    MenuRow(title: items[index].title, isSelected: index == selectedIndex)
                        .onTapGesture {
                            selectedIndex = index
                            items[index].action()
                        }
                }
            }
        }
        .focusable()
        .focused($isFocused)
        .onAppear { isFocused = true }
        .onMoveCommand { direction in
            guard !items.isEmpty else { return }
            switch direction {
            case .up:
                selectedIndex = (selectedIndex - 1 + items.count) % items.count
            case .down:
                selectedIndex = (selectedIndex + 1) % items.count
            default:
                break
            }
        }
    }

    private func activateSelected() {
        guard items.indices.contains(selectedIndex) else { return }
        items[selectedIndex].action()
    }
}

private struct MenuRow: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            Text(isSelected ? "▸" : "")
                .frame(width: 20, alignment: .leading)
            Text(title)
                .fontWeight(isSelected ? .bold : .regular)
        }
        .foregroundColor(.white)
        .font(.system(size: 20, design: .monospaced))
        .contentShape(Rectangle())
    }
}
