import SwiftUI
import AppKit

class QuickActionPanel: NSPanel {
    static let shared = QuickActionPanel()

    private init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 52),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
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
        let y = screenFrame.midY + 100
        setFrameOrigin(NSPoint(x: x, y: y))

        let hostingView = NSHostingView(rootView: QuickActionOverlay(onDismiss: { [weak self] in
            self?.close()
        }))
        contentView = hostingView
        makeKeyAndOrderFront(nil)
    }
}

struct QuickActionOverlay: View {
    var onDismiss: () -> Void

    @State private var text = ""
    @State private var isSaving = false
    @State private var saved = false
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(Theme.greenDark)
                    .font(.title3)

                TextField("Add an action...", text: $text)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .focused($focused)
                    .onSubmit { save() }

                if isSaving {
                    ProgressView().controlSize(.small)
                } else if saved {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.green)
                } else if !text.trimmingCharacters(in: .whitespaces).isEmpty {
                    Button { save() } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Theme.greenDark)
                    }
                    .buttonStyle(.plain)
                }

                Button { onDismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Theme.textMuted)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 8)
        }
        .onAppear { focused = true }
        .onExitCommand { onDismiss() }
    }

    private func save() {
        let rawText = text.trimmingCharacters(in: .whitespaces)
        guard !rawText.isEmpty, !isSaving else { return }
        isSaving = true

        let item = Item.new(text: rawText, category: .action)
        try? Queries.addItem(item)

        Task {
            _ = try? await AIService.classifyAndCluster(text: rawText, itemId: item.id, category: .action)
        }

        isSaving = false
        saved = true
        text = ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            onDismiss()
        }
    }
}
