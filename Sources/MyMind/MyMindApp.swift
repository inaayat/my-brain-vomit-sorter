import SwiftUI

@main
struct MyMindApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Window("my-mind", id: "main") {
            ContentView()
        }
        .defaultSize(width: 1000, height: 700)

        MenuBarExtra("my-mind", systemImage: "brain.head.profile") {
            Button("Show Window") {
                showMainWindow()
            }
            .keyboardShortcut("m", modifiers: [.control, .option])
            Divider()
            Button("Capture a thought...") {
                showMainWindow()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    NotificationCenter.default.post(name: .showCaptureSheet, object: nil)
                }
            }
            .keyboardShortcut("n", modifiers: [.command])
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: [.command])
        }
    }

    private func showMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { $0.title == "my-mind" || $0.identifier?.rawValue == "main" }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            NSApp.sendAction(#selector(NSApplication.newWindowForTab(_:)), to: nil, from: nil)
        }
    }
}

extension Notification.Name {
    static let showCaptureSheet = Notification.Name("showCaptureSheet")
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
