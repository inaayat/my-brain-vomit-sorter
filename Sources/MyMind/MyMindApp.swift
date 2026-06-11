import SwiftUI

@main
struct MyMindApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Window("my-mind", id: "main") {
            ContentView()
        }
        .defaultSize(width: 1000, height: 700)

        MenuBarExtra("MyMind", systemImage: "brain.head.profile") {
            Button("Add Note") {
                DailyDumpPanel.shared.toggle()
            }
            .keyboardShortcut("n", modifiers: [.control, .option])

            Button("Add Action") {
                QuickActionPanel.shared.toggle()
            }
            .keyboardShortcut("a", modifiers: [.control, .option])

            Divider()

            Button("Open MyMind") {
                NSApp.activate(ignoringOtherApps: true)
                if let window = NSApp.windows.first(where: { $0.title == "my-mind" }) {
                    window.makeKeyAndOrderFront(nil)
                }
            }

            Divider()

            Button("Quit") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }

}


class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        FontLoader.registerFonts()

        // Initialize database
        _ = DatabaseManager.shared

        // Auto-promote items due today/tomorrow to high priority
        try? Queries.promoteDueSoonToHigh()

        // Register global hotkeys
        HotkeyManager.shared.onHotkey = {
            QuickActionPanel.shared.toggle()
        }
        HotkeyManager.shared.onNotepadHotkey = {
            DailyDumpPanel.shared.toggle()
        }
        HotkeyManager.shared.register()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
