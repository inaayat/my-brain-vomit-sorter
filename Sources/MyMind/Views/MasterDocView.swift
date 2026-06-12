import SwiftUI

struct MasterDocsListView: View {
    @Bindable var appState: AppState
    @State private var docs: [MasterDoc] = []
    @State private var showNewDoc = false
    @State private var newDocName = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Master Docs")
                        .font(.inter(24, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Button {
                        newDocName = ""
                        showNewDoc = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                            Text("New Doc")
                        }
                        .font(.inter(12, weight: .semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.purple)
                }

                if docs.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 36))
                            .foregroundStyle(Theme.textMuted.opacity(0.4))
                        Text("No master docs yet")
                            .font(.inter(14))
                            .foregroundStyle(Theme.textMuted)
                        Text("Click 'New Doc' to create one, or open a tag in Daily Dump and click 'Master Doc'.")
                            .font(.inter(12))
                            .foregroundStyle(Theme.textMuted)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                } else {
                    ForEach(docs) { doc in
                        Button {
                            appState.selectedDestination = .masterDoc(doc.tag)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "doc.text.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(Theme.purple)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(doc.title)
                                        .font(.inter(14, weight: .semibold))
                                        .foregroundStyle(Theme.textPrimary)
                                    Text("#\(doc.tag) • \(wordCount(doc.content)) words")
                                        .font(.inter(11))
                                        .foregroundStyle(Theme.textMuted)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Theme.textMuted)
                            }
                            .padding(14)
                            .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.radius(10)))
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.radius(10))
                                    .strokeBorder(Theme.cardBorder, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(28)
        }
        .background(Theme.bg)
        .onAppear { docs = (try? Queries.getAllMasterDocs()) ?? [] }
        .sheet(isPresented: $showNewDoc) {
            VStack(spacing: 16) {
                Text("New Master Doc")
                    .font(.inter(16, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                TextField("Topic name (e.g. project-x, quarterly-review)", text: $newDocName)
                    .font(.inter(13))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 300)
                HStack(spacing: 12) {
                    Button("Cancel") { showNewDoc = false }
                        .font(.inter(12))
                        .foregroundStyle(Theme.textMuted)
                        .buttonStyle(.plain)
                    Button("Create") {
                        let tag = newDocName.lowercased()
                            .replacingOccurrences(of: " ", with: "-")
                            .trimmingCharacters(in: .whitespaces)
                        guard !tag.isEmpty else { return }
                        let title = newDocName.trimmingCharacters(in: .whitespaces)
                        try? Queries.upsertMasterDoc(tag: tag, content: "", title: title)
                        showNewDoc = false
                        docs = (try? Queries.getAllMasterDocs()) ?? []
                        appState.selectedDestination = .masterDoc(tag)
                    }
                    .font(.inter(12, weight: .semibold))
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.purple)
                    .disabled(newDocName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .padding(28)
            .frame(width: 380, height: 180)
        }
    }

    private func wordCount(_ text: String) -> Int {
        text.split(separator: " ").count
    }
}

struct MasterDocView: View {
    @Bindable var appState: AppState
    let tag: String
    @State private var doc: MasterDoc?
    @State private var content = ""
    @State private var title = ""
    @State private var isSynthesizing = false
    @State private var synthesizedPreview: String?
    @State private var tagResults: [TagSearchResult] = []
    @State private var selectedBullets: Set<UUID> = []
    @State private var showBulletPicker = false
    @State private var showDeleteConfirm = false
    @State private var fontSize: CGFloat = 13

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider()
            HStack(spacing: 0) {
                editorPanel
                if showBulletPicker {
                    Divider()
                    bulletPickerPanel
                }
            }
        }
        .background(Theme.bg)
        .onAppear { loadDoc() }
        .alert("Delete this master doc?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                if let doc {
                    try? Queries.deleteMasterDoc(id: doc.id)
                }
                appState.selectedDestination = .masterDocs
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete the document for #\(tag). This cannot be undone.")
        }
    }

    private var headerBar: some View {
        HStack(spacing: 12) {
            Button {
                appState.selectedDestination = .masterDocs
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textMuted)
            }
            .buttonStyle(.plain)

            TextField("Document title", text: $title)
                .font(.inter(18, weight: .bold))
                .textFieldStyle(.plain)
                .onSubmit { saveDoc() }

            Text("#\(tag)")
                .font(.inter(12, weight: .semibold))
                .foregroundStyle(Theme.purple)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Theme.purple.opacity(0.1), in: Capsule())

            Spacer()

            Button {
                showBulletPicker.toggle()
                if showBulletPicker { loadBullets() }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle")
                    Text("Add bullets")
                }
                .font(.inter(11, weight: .semibold))
                .foregroundStyle(Theme.purple)
            }
            .buttonStyle(.plain)

            Button {
                synthesize()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                    Text(isSynthesizing ? "Synthesizing..." : "AI Synthesize")
                }
                .font(.inter(11, weight: .semibold))
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.purple)
            .disabled(isSynthesizing || content.isEmpty)

            Button {
                showDeleteConfirm = true
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.pinkDark)
            }
            .buttonStyle(.plain)
            .help("Delete this doc")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Theme.card)
    }

    private var editorPanel: some View {
        VStack(spacing: 0) {
            if let preview = synthesizedPreview {
                VStack(alignment: .leading, spacing: 8) {
                    Text("AI Synthesized Version (preview)")
                        .font(.inter(11, weight: .semibold))
                        .foregroundStyle(Theme.greenDark)
                    ScrollView {
                        Text(preview)
                            .font(.inter(13))
                            .foregroundStyle(Theme.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 200)
                    .padding(10)
                    .background(Theme.greenTint.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
                    HStack(spacing: 12) {
                        Button("Accept") {
                            content = preview
                            synthesizedPreview = nil
                            saveDoc()
                        }
                        .font(.inter(11, weight: .semibold))
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.greenDark)
                        .controlSize(.small)
                        Button("Dismiss") {
                            synthesizedPreview = nil
                        }
                        .font(.inter(11))
                        .foregroundStyle(Theme.textMuted)
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
                Divider()
            }

            formattingToolbar
            Divider()

            TextEditor(text: $content)
                .font(.inter(fontSize))
                .scrollContentBackground(.hidden)
                .padding(16)
                .onChange(of: content) {
                    saveDoc()
                }
        }
    }

    private var formattingToolbar: some View {
        HStack(spacing: 2) {
            formatButton(icon: "bold", tooltip: "Bold") {
                insertMarkdown(prefix: "**", suffix: "**")
            }
            formatButton(icon: "italic", tooltip: "Italic") {
                insertMarkdown(prefix: "*", suffix: "*")
            }
            formatButton(icon: "list.bullet", tooltip: "Bullet list") {
                insertAtLineStart("- ")
            }
            formatButton(icon: "list.number", tooltip: "Numbered list") {
                insertAtLineStart("1. ")
            }

            Divider().frame(height: 18).padding(.horizontal, 6)

            formatButton(icon: "textformat.size.smaller", tooltip: "Decrease font") {
                if fontSize > 10 { fontSize -= 1 }
            }
            Text("\(Int(fontSize))")
                .font(.inter(10))
                .foregroundStyle(Theme.textMuted)
                .frame(width: 20)
            formatButton(icon: "textformat.size.larger", tooltip: "Increase font") {
                if fontSize < 20 { fontSize += 1 }
            }

            Divider().frame(height: 18).padding(.horizontal, 6)

            formatButton(icon: "number", tooltip: "Heading") {
                insertAtLineStart("## ")
            }
            formatButton(icon: "text.quote", tooltip: "Quote") {
                insertAtLineStart("> ")
            }
            formatButton(icon: "chevron.left.forwardslash.chevron.right", tooltip: "Code") {
                insertMarkdown(prefix: "`", suffix: "`")
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Theme.cardBg)
    }

    @ViewBuilder
    private func formatButton(icon: String, tooltip: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(Theme.textPrimary)
                .frame(width: 28, height: 28)
                .background(Theme.softGray.opacity(0.01), in: RoundedRectangle(cornerRadius: 4))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(tooltip)
    }

    private func insertMarkdown(prefix: String, suffix: String) {
        content += "\(prefix)text\(suffix)"
    }

    private func insertAtLineStart(_ marker: String) {
        if content.isEmpty || content.hasSuffix("\n") {
            content += marker
        } else {
            content += "\n\(marker)"
        }
    }

    private var bulletPickerPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Bullets tagged #\(tag)")
                    .font(.inter(12, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                if !selectedBullets.isEmpty {
                    Button {
                        appendSelectedBullets()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                            Text("Add \(selectedBullets.count)")
                        }
                        .font(.inter(11, weight: .semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.purple)
                    .controlSize(.small)
                }
            }
            .padding(12)
            Divider()

            ScrollView {
                VStack(spacing: 4) {
                    ForEach(tagResults) { result in
                        let selected = selectedBullets.contains(result.id)
                        Button {
                            if selected { selectedBullets.remove(result.id) }
                            else { selectedBullets.insert(result.id) }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 14))
                                    .foregroundStyle(selected ? Theme.purple : Theme.textMuted.opacity(0.4))
                                Text(result.bulletText)
                                    .font(.inter(11))
                                    .foregroundStyle(Theme.textPrimary)
                                    .lineLimit(3)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(selected ? Theme.purple.opacity(0.06) : Color.clear)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
            }
        }
        .frame(width: 280)
        .background(Theme.card)
    }

    private func loadDoc() {
        doc = try? Queries.getMasterDoc(tag: tag)
        if let doc {
            content = doc.content
            title = doc.title
        } else {
            title = tag.replacingOccurrences(of: "-", with: " ").capitalized
            content = ""
            try? Queries.upsertMasterDoc(tag: tag, content: "", title: title)
            doc = try? Queries.getMasterDoc(tag: tag)
        }
    }

    private func saveDoc() {
        try? Queries.upsertMasterDoc(tag: tag, content: content, title: title)
    }

    private func loadBullets() {
        tagResults = findBulletsByTag(tag, includeRetired: false)
    }

    private func findBulletsByTag(_ tag: String, includeRetired: Bool) -> [TagSearchResult] {
        let allDumps = (try? Queries.getAllDumps()) ?? []
        var results: [TagSearchResult] = []
        for dump in allDumps {
            let bullets = DumpBullet.parse(from: dump.content)
            for bullet in bullets {
                if !includeRetired && bullet.isRetired { continue }
                if bullet.tags.contains(tag.lowercased()) {
                    results.append(TagSearchResult(
                        id: UUID(),
                        dumpId: dump.id,
                        date: dump.date,
                        dateDisplay: DailyDump.displayDate(dump.date),
                        bulletText: bullet.text,
                        rawLine: bullet.rawLine,
                        isRetired: bullet.isRetired
                    ))
                }
            }
        }
        return results
    }

    private func appendSelectedBullets() {
        let bulletsToAdd = tagResults.filter { selectedBullets.contains($0.id) }
        let newLines = bulletsToAdd.map { "- \($0.bulletText)" }.joined(separator: "\n")
        if content.isEmpty {
            content = newLines
        } else {
            content += "\n\n" + newLines
        }
        selectedBullets.removeAll()
        saveDoc()
    }

    private func synthesize() {
        isSynthesizing = true
        let bullets = tagResults.isEmpty ? findBulletsByTag(tag, includeRetired: false) : tagResults
        let bulletTexts = bullets.map { $0.bulletText }.joined(separator: "\n")
        Task {
            do {
                let result = try await AIService.synthesizeMasterDoc(existingContent: content, bullets: bulletTexts)
                await MainActor.run {
                    synthesizedPreview = result
                    isSynthesizing = false
                }
            } catch {
                await MainActor.run { isSynthesizing = false }
            }
        }
    }
}
