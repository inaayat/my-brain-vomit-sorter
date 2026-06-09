import SwiftUI

struct CaptureSheet: View {
    @Bindable var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var text = ""
    @State private var selectedCategory: Category?
    @State private var dueDate: Date?
    @State private var hasDueDate = false
    @State private var urlText = ""
    @State private var urlTitleText = ""
    @State private var isSaving = false
    @State private var errorMessage = ""
    @State private var relatedItems: [Item] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Capture a thought")
                .font(.inter(15, weight: .semibold))

            VStack(alignment: .leading, spacing: 4) {
                Text("TEXT")
                    .font(.inter(10))
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                TextEditor(text: $text)
                    .font(.inter(14))
                    .frame(minHeight: 80, maxHeight: 120)
                    .padding(4)
                    .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 6))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("CATEGORY")
                    .font(.inter(10))
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    PillButton(label: "Auto", isSelected: selectedCategory == nil) { selectedCategory = nil }
                    PillButton(label: "Brainstorm", isSelected: selectedCategory == .brainstorm) { selectedCategory = .brainstorm }
                    PillButton(label: "Action", isSelected: selectedCategory == .action) { selectedCategory = .action }
                    PillButton(label: "Resource", isSelected: selectedCategory == .resource) { selectedCategory = .resource }
                }
            }

            HStack {
                Toggle("Due date", isOn: $hasDueDate)
                    .controlSize(.small)
                if hasDueDate {
                    DatePicker("", selection: Binding(get: { dueDate ?? Date() }, set: { dueDate = $0 }), displayedComponents: .date)
                        .labelsHidden()
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("LINK")
                    .font(.inter(10))
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    Image(systemName: "link")
                        .font(.inter(11))
                        .foregroundStyle(Theme.blueDark)
                    TextField("Paste a URL...", text: $urlText)
                        .textFieldStyle(.roundedBorder)
                }
                if !urlText.trimmingCharacters(in: .whitespaces).isEmpty {
                    TextField("URL title (what to display)...", text: $urlTitleText)
                        .textFieldStyle(.roundedBorder)
                        .padding(.leading, 22)
                }
            }

            if !relatedItems.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("RELATED ITEMS FOUND")
                        .font(.inter(10))
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                    ForEach(relatedItems) { item in
                        HStack(spacing: 6) {
                            CategoryBadge(category: item.category)
                            Text(item.text)
                                .font(.inter(11))
                                .lineLimit(1)
                            Spacer()
                            Button("Link") {
                                // Linking handled after save
                            }
                            .controlSize(.mini)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.inter(11))
                    .foregroundStyle(.red)
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.escape)
                Button(isSaving ? "Saving..." : "Save") { save() }
                    .buttonStyle(.borderedProminent)
                    .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                    .keyboardShortcut(.return, modifiers: .command)
            }
        }
        .padding(20)
        .frame(width: 440)
    }

    private func save() {
        let rawText = text.trimmingCharacters(in: .whitespaces)
        guard !rawText.isEmpty else { return }
        isSaving = true
        errorMessage = ""

        Task {
            do {
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

                let trimmedUrl = urlText.trimmingCharacters(in: .whitespaces)
                let trimmedUrlTitle = urlTitleText.trimmingCharacters(in: .whitespaces)
                var item = Item.new(
                    text: finalText,
                    category: category ?? .brainstorm,
                    dueDate: hasDueDate ? dueDate : nil,
                    url: trimmedUrl.isEmpty ? nil : trimmedUrl,
                    urlTitle: trimmedUrlTitle.isEmpty ? nil : trimmedUrlTitle
                )
                if !tags.isEmpty {
                    item.tags = try? String(data: JSONEncoder().encode(tags), encoding: .utf8)
                }
                try Queries.addItem(item)

                // If URL provided and category is NOT resource, also create a linked resource item
                if !trimmedUrl.isEmpty && (category ?? .brainstorm) != .resource {
                    let resourceItem = Item.new(
                        text: trimmedUrlTitle.isEmpty ? trimmedUrl : trimmedUrlTitle,
                        category: .resource,
                        url: trimmedUrl,
                        urlTitle: trimmedUrlTitle.isEmpty ? nil : trimmedUrlTitle
                    )
                    try Queries.addItem(resourceItem)
                    let link = Link.new(fromId: item.id, toId: resourceItem.id)
                    try Queries.addLink(link)
                }

                Task {
                    _ = try? await AIService.classifyAndCluster(text: finalText, itemId: item.id, category: item.category)
                }

                await MainActor.run {
                    appState.refreshCounts()
                    isSaving = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Save failed: \(error.localizedDescription)"
                    isSaving = false
                }
            }
        }
    }
}

struct PillButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.inter(11))
                .fontWeight(.medium)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(isSelected ? Color.indigo : Color.clear, in: Capsule())
                .foregroundStyle(isSelected ? .white : .primary)
                .overlay(Capsule().strokeBorder(.quaternary, lineWidth: isSelected ? 0 : 1))
        }
        .buttonStyle(.plain)
    }
}
