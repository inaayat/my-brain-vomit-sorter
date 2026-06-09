import SwiftUI
import AppKit

class QuickCapturePanel: NSPanel {
    static let shared = QuickCapturePanel()

    private init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 60),
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
        let y = screenFrame.midY + 100
        setFrameOrigin(NSPoint(x: x, y: y))

        let hostingView = NSHostingView(rootView: QuickCaptureOverlay(onDismiss: { [weak self] in
            self?.close()
        }))
        contentView = hostingView
        makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct QuickCaptureOverlay: View {
    var onDismiss: () -> Void

    @State private var text = ""
    @State private var selectedCategory: Category?
    @State private var isSaving = false
    @State private var savedMessage = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "plus.bubble.fill")
                    .foregroundStyle(Theme.purple)
                    .font(.title3)

                TextField("Capture a thought...", text: $text)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .focused($focused)
                    .onSubmit { save() }

                if isSaving {
                    ProgressView().controlSize(.small)
                } else if !savedMessage.isEmpty {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.green)
                } else if !text.trimmingCharacters(in: .whitespaces).isEmpty {
                    Button { save() } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Theme.purple)
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

            if !text.trimmingCharacters(in: .whitespaces).isEmpty {
                Divider().padding(.horizontal, 12)
                HStack(spacing: 6) {
                    PillButton(label: "Auto", isSelected: selectedCategory == nil) { selectedCategory = nil }
                    PillButton(label: "Action", isSelected: selectedCategory == .action) { selectedCategory = .action }
                    PillButton(label: "Brainstorm", isSelected: selectedCategory == .brainstorm) { selectedCategory = .brainstorm }
                    PillButton(label: "Resource", isSelected: selectedCategory == .resource) { selectedCategory = .resource }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
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

        Task {
            var category = selectedCategory
            var finalText = rawText
            var tags: [String] = []

            if category == nil {
                do {
                    let result = try await AIService.categorize(text: rawText)
                    category = result.category
                    tags = result.tags
                    finalText = result.cleanedText
                } catch {
                    category = .brainstorm
                }
            }

            var item = Item.new(text: finalText, category: category ?? .brainstorm, dueDate: nil, url: nil)
            if !tags.isEmpty {
                item.tags = try? String(data: JSONEncoder().encode(tags), encoding: .utf8)
            }
            try? Queries.addItem(item)

            if let urlMatch = finalText.range(of: #"https?://\S+"#, options: .regularExpression),
               (category ?? .brainstorm) != .resource {
                let url = String(finalText[urlMatch])
                let resourceItem = Item.new(text: url, category: .resource, url: url)
                try? Queries.addItem(resourceItem)
                let link = Link.new(fromId: item.id, toId: resourceItem.id)
                try? Queries.addLink(link)
            }

            Task { _ = try? await AIService.classifyAndCluster(text: finalText, itemId: item.id, category: item.category) }

            await MainActor.run {
                isSaving = false
                savedMessage = "Saved"
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    onDismiss()
                }
            }
        }
    }
}
