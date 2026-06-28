import SwiftUI
import AppKit

/// SwiftUI entry point (§7: "AppMain.swift — SwiftUI WindowGroup hosting
/// SKView"). Replaces the default Edit menu's Undo/Redo command group:
/// without this, AppKit's menu key-equivalent matching consumes `⌘Z`
/// before it ever reaches `GameScene.keyDown`, since SwiftUI's default
/// `WindowGroup` wires Undo to `⌘Z` against an (unused) `NSUndoManager`.
/// §5 requires `⌘Z` to undo a move, same as plain `Z`.
@main
struct LasermaniaMacApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup("Lasermania") {
            ContentView(appState: appState)
                .onAppear {
                    // `swift run` launches the app from Terminal rather than
                    // via Launch Services, so macOS doesn't automatically
                    // hand it keyboard/mouse focus — without this, the
                    // window is visible but inert until manually clicked.
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
        }
        .commands {
            CommandGroup(replacing: .undoRedo) { }
        }
    }
}
