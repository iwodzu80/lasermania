import SwiftUI
import AppKit

/// §4.1 Title / Main Menu.
struct TitleScreen: View {
    @ObservedObject var appState: AppState

    @State private var beamPhase = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            backgroundBeam

            VStack(spacing: 36) {
                Spacer()

                VStack(spacing: 8) {
                    Text("L A S E R M A N I A")
                        .font(.system(size: 40, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    Rectangle()
                        .fill(Color.white.opacity(0.6))
                        .frame(width: 320, height: 2)
                    Text("a logic puzzle, reborn")
                        .font(.system(size: 16, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                }

                MenuList(items: [
                    .init("PLAY") { appState.playFromMenu() },
                    .init("LEVEL SELECT") { appState.showLevelSelect() },
                    .init("SETTINGS") { appState.openSettings() },
                    .init("QUIT") { NSApplication.shared.terminate(nil) }
                ])

                Spacer()

                HStack {
                    Text("◂▸ move   ↵ select")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                    Spacer()
                    Text("v1.0   © 2026")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 16)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: true)) {
                beamPhase = true
            }
        }
    }

    /// Subtle looping beam-bounce accent per the mockup's "[DESIGN]" note.
    private var backgroundBeam: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            Path { path in
                path.move(to: CGPoint(x: 0, y: height * 0.2))
                path.addLine(to: CGPoint(x: width * 0.5, y: height * 0.8))
                path.addLine(to: CGPoint(x: width, y: height * 0.2))
            }
            .stroke(Color.red.opacity(0.25), lineWidth: 3)
            .offset(y: beamPhase ? 12 : -12)
        }
        .ignoresSafeArea()
    }
}
