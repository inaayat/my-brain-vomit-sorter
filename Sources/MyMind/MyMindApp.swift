import SwiftUI

@main
struct MyMindApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Window("my-mind", id: "main") {
            ContentView()
        }
        .defaultSize(width: 1000, height: 700)

    }

}


class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        FontLoader.registerFonts()

        // Initialize database
        _ = DatabaseManager.shared

        // Register global hotkey — shows floating capture panel over current screen
        HotkeyManager.shared.onHotkey = {
            QuickCapturePanel.shared.toggle()
        }
        HotkeyManager.shared.register()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
