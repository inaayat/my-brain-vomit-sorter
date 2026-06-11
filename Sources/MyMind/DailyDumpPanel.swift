import SwiftUI
import AppKit

class DailyDumpPanel: NSPanel {
    static let shared = DailyDumpPanel()

    private init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 52),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )
        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isMovableByWindowBackground = true
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }

    func toggle() {
        if isVisible {
            close()
        } else {
            show()
        }
    }

    func show() {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let screenFrame = screen.visibleFrame
        let x = screenFrame.midX - frame.width / 2
        let y = screenFrame.midY + 140
        setFrameOrigin(NSPoint(x: x, y: y))

        let hostingView = NSHostingView(rootView: DailyDumpOverlay(onDismiss: { [weak self] in
            self?.close()
        }))
        contentView = hostingView
        makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct DailyDumpOverlay: View {
    var onDismiss: () -> Void

    @State private var text = ""
    @State private var saved = false
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                Image(systemName: "list.bullet.rectangle.portrait")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textMuted)
                Text(DailyDump.displayDate(DailyDump.today()))
                    .font(.inter(10, weight: .medium))
                    .foregroundStyle(Theme.textMuted)
                Spacer()
                Button { onDismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Theme.textMuted)
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 6)

            HStack(spacing: 10) {
                Text("•")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.purple)

                TextField("Quick thought...", text: $text)
                    .textFieldStyle(.plain)
                    .font(.inter(14))
                    .focused($focused)
                    .onSubmit { appendBullet() }

                if saved {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.green)
                        .font(.system(size: 16))
                } else if !text.trimmingCharacters(in: .whitespaces).isEmpty {
                    Button { appendBullet() } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Theme.purple)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 12)
        }
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.25), radius: 16, x: 0, y: 6)
        }
        .onAppear { focused = true }
        .onExitCommand { onDismiss() }
    }

    private func appendBullet() {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        try? Queries.appendToDump(date: DailyDump.today(), bullet: trimmed)
        text = ""
        saved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { saved = false }
    }
}
