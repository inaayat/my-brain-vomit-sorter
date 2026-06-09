import SwiftUI

struct InlineCaptureView: View {
    @Bindable var appState: AppState
    var onSaved: () -> Void

    @State private var text = ""
    @State private var selectedCategory: Category?
    @State private var expanded = false
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var urlText = ""
    @State private var urlTitleText = ""
    @State private var isSaving = false
    @State private var savedMessage = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "plus.bubble.fill")
                    .foregroundStyle(Theme.purple)
                    .font(.system(size: 17))
                    .padding(.top, 2)

                TextEditor(text: $text)
                    .font(.inter(14))
                    .foregroundStyle(Theme.textPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 20, maxHeight: 120)
                    .fixedSize(horizontal: false, vertical: true)
                    .onChange(of: text) { _, newValue in
                        if !newValue.isEmpty && !expanded { expanded = true }
                    }
                    .overlay(alignment: .topLeading) {
                        if text.isEmpty {
                            Text("Capture a thought...")
                                .font(.inter(14))
                                .foregroundStyle(Theme.textMuted)
                                .allowsHitTesting(false)
                        }
                    }

                if !text.trimmingCharacters(in: .whitespaces).isEmpty {
                    Button {
                        save()
                    } label: {
                        Image(systemName: isSaving ? "hourglass" : "arrow.up.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Theme.purple)
                    }
                    .buttonStyle(.plain)
                    .disabled(isSaving)
                    .padding(.top, 2)
                }
            }
            .padding(12)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.border, lineWidth: 1))

            if expanded && !text.trimmingCharacters(in: .whitespaces).isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        PillButton(label: "Auto", isSelected: selectedCategory == nil) { selectedCategory = nil }
                        PillButton(label: "Action", isSelected: selectedCategory == .action) { selectedCategory = .action }
                        PillButton(label: "Brainstorm", isSelected: selectedCategory == .brainstorm) { selectedCategory = .brainstorm }
                        PillButton(label: "Resource", isSelected: selectedCategory == .resource) { selectedCategory = .resource }
                    }

                    HStack(spacing: 12) {
                        Toggle("Due", isOn: $hasDueDate)
                            .controlSize(.small)
                            .fixedSize()
                        if hasDueDate {
                            DatePicker("", selection: $dueDate, displayedComponents: .date)
                                .labelsHidden()
                                .controlSize(.small)
                        }

                        TextField("URL (optional)", text: $urlText)
                            .textFieldStyle(.roundedBorder)
                            .controlSize(.small)
                            .frame(maxWidth: 200)

                        if !urlText.trimmingCharacters(in: .whitespaces).isEmpty {
                            TextField("URL title", text: $urlTitleText)
                                .textFieldStyle(.roundedBorder)
                                .controlSize(.small)
                                .frame(maxWidth: 150)
                        }

                        Spacer()

                        Button("Cancel") {
                            reset()
                        }
                        .controlSize(.small)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if !savedMessage.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.green)
                    Text(savedMessage)
                        .font(.inter(11))
                        .foregroundStyle(Theme.green)
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: expanded)
        .animation(.easeInOut(duration: 0.2), value: savedMessage)
    }

    private func save() {
        let rawText = text.trimmingCharacters(in: .whitespaces)
        guard !rawText.isEmpty else { return }
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
            try? Queries.addItem(item)

            // If URL provided and category is NOT resource, also create a linked resource item
            if !trimmedUrl.isEmpty && (category ?? .brainstorm) != .resource {
                let resourceItem = Item.new(
                    text: trimmedUrlTitle.isEmpty ? trimmedUrl : trimmedUrlTitle,
                    category: .resource,
                    url: trimmedUrl,
                    urlTitle: trimmedUrlTitle.isEmpty ? nil : trimmedUrlTitle
                )
                try? Queries.addItem(resourceItem)
                let link = Link.new(fromId: item.id, toId: resourceItem.id)
                try? Queries.addLink(link)
            }

            Task {
                _ = try? await AIService.classifyAndCluster(text: finalText, itemId: item.id, category: item.category)
            }

            await MainActor.run {
                let cat = category ?? .brainstorm
                savedMessage = "Saved as \(cat.rawValue)"
                isSaving = false
                reset()
                appState.refreshCounts()
                onSaved()

                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    savedMessage = ""
                }
            }
        }
    }

    private func reset() {
        text = ""
        selectedCategory = nil
        hasDueDate = false
        dueDate = Date()
        urlText = ""
        urlTitleText = ""
        expanded = false
    }
}
