import SwiftUI

/// §4.7 Settings overlay. Observes `SettingsStore` directly (rather than only
/// `AppState`) so slider/picker/toggle bindings react immediately.
struct SettingsScreen: View {
    @ObservedObject var appState: AppState
    @ObservedObject var settings: SettingsStore

    @State private var showResetConfirm = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Text("SETTINGS")
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    Spacer()
                    Button("⟵ Back") { appState.closeSettings() }
                        .buttonStyle(.plain)
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: 14, design: .monospaced))
                }

                row("Music") {
                    Slider(value: $settings.musicVolume, in: 0...1)
                        .frame(width: 200)
                    Text("\(Int((settings.musicVolume * 100).rounded()))%")
                        .frame(width: 44, alignment: .leading)
                }

                row("SFX") {
                    Slider(value: $settings.sfxVolume, in: 0...1)
                        .frame(width: 200)
                    Text("\(Int((settings.sfxVolume * 100).rounded()))%")
                        .frame(width: 44, alignment: .leading)
                }

                row("Control scheme") {
                    Picker("", selection: $settings.controlScheme) {
                        ForEach(ControlScheme.allCases, id: \.self) { scheme in
                            Text(scheme.displayName).tag(scheme)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                    .labelsHidden()
                }

                row("Color theme") {
                    Picker("", selection: $settings.colorTheme) {
                        ForEach(ColorTheme.allCases, id: \.self) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 220)
                    .labelsHidden()
                }

                row("Reduce motion") {
                    Toggle("", isOn: $settings.reduceMotion)
                        .labelsHidden()
                }

                row("Reset progress") {
                    Button("Reset…") { showResetConfirm = true }
                        .buttonStyle(.bordered)
                }

                Spacer()
            }
            .padding(28)
        }
        .alert("Reset all progress?", isPresented: $showResetConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) { appState.resetProgress() }
        } message: {
            Text("This clears every level's best-move record. This cannot be undone.")
        }
    }

    private func row<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 16) {
            Text(label)
                .frame(width: 150, alignment: .leading)
            content()
        }
        .font(.system(size: 15, design: .monospaced))
        .foregroundColor(.white)
    }
}
