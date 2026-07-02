import SwiftUI
import AppKit

/// SwiftUI entry point (§7: "AppMain.swift — SwiftUI WindowGroup hosting
/// SKView"). Replaces the default Edit menu's Undo/Redo command group so `⌘Z`
/// reaches `GameScene.keyDown` instead of an unused `NSUndoManager`, and
/// installs an app delegate that promotes the process to a foreground app.
@main
struct LasermaniaMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup("Lasermania") {
            ContentView(appState: appState)
        }
        .commands {
            CommandGroup(replacing: .undoRedo) { }
        }
    }
}

/// Launched from Terminal via `swift run`, the executable starts as a
/// background (accessory) process: its window appears but never becomes the
/// key window, so keyboard events keep going to Terminal instead of the game.
/// Promoting to `.regular` and activating makes it a normal foreground app
/// (Dock icon, menu bar, key window, keyboard focus).
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        DispatchQueue.main.async {
            NSApp.windows.first?.makeKeyAndOrderFront(nil)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
