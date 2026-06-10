import SwiftUI

struct ItemDetailView: View {
    @Bindable var appState: AppState
    let itemId: String

    @State private var item: Item?
    @State private var clusteredItems: [Item] = []
    @State private var linkedResources: [Item] = []
    @State private var confirmDelete = false
    @State private var notesText: String = ""
    @State private var notesDirty: Bool = false
    @State private var isAnalyzing: Bool = false
    @State private var suggestions: NoteSuggestionsResult? = nil
    @State private var analysisError: String? = nil
    @State private var showAnalyzePrompt = false
    @State private var resourceInput: String = ""
    @State private var resourceTitle: String = ""
    @State private var resourceSearchResults: [Item] = []

    private var tintColor: Color {
        guard let item else { return Theme.softGray }
        switch item.category {
        case .action: return Theme.greenTint
        case .brainstorm: return Theme.pinkTint
        case .revisit: return Theme.yellowTint
        case .resource: return Theme.blueTint
        }
    }

    var body: some View {
        if let item {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    headerBar(item: item)
                    metaRow(item: item)
                    textContent(item: item)
                    tagsRow(item: item)
                    urlRow(item: item)
                    notesSection
                    suggestionsSection
                    resourcesSection
                    clusteredSection
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(tintColor.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: Theme.radius(14)))
            .onAppear { loadData() }
            .onChange(of: itemId) { _, _ in loadData() }
            .confirmationDialog("Analyze notes with AI?", isPresented: $showAnalyzePrompt) {
                Button("Analyze with AI") { analyzeNotes() }
                Button("No thanks", role: .cancel) {}
            } message: {
                Text("Look for suggested actions and ideas in your notes.")
            }
        } else {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.softGray.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: Theme.radius(14)))
                .onAppear { loadData() }
        }
    }

    private func headerBar(item: Item) -> some View {
        HStack(spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    appState.detailPanelItemId = nil
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.inter(11, weight: .bold))
                    .foregroundStyle(Theme.textMuted)
                    .frame(width: 26, height: 26)
                    .background(Theme.cardBg.opacity(0.8), in: Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            if !item.done {
                Button {
                    try? Queries.completeItem(id: item.id)
                    loadData()
                    appState.refreshCounts()
                    appState.completedItem = item
                    appState.showLogWinSheet = true
                } label: {
                    Label("Complete", systemImage: "checkmark")
                        .font(.inter(12, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.greenDark)
                .controlSize(.small)
            }
            if item.done && (try? Queries.getWin(itemId: item.id)) == nil {
                Button {
                    appState.completedItem = item
                    appState.showLogWinSheet = true
                } label: {
                    Label("Log Win", systemImage: "star")
                        .font(.inter(12, weight: .medium))
                }
                .controlSize(.small)
                .tint(Theme.yellowDark)
            }
            Button("Edit") {
                appState.editingItem = item
                appState.showEditSheet = true
            }
            .font(.inter(12, weight: .medium))
            .controlSize(.small)

            Button(confirmDelete ? "Confirm?" : "Delete") {
                if confirmDelete {
                    try? Queries.deleteItem(id: item.id)
                    withAnimation { appState.detailPanelItemId = nil }
                    appState.refreshCounts()
                } else {
                    confirmDelete = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) { confirmDelete = false }
                }
            }
            .font(.inter(12, weight: .medium))
            .foregroundStyle(confirmDelete ? Theme.pinkDark : Theme.textMuted)
            .controlSize(.small)
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
    }

    private func metaRow(item: Item) -> some View {
        HStack(spacing: 8) {
            categoryPill(item.category)
            if item.done {
                Text("Completed")
                    .font(.inter(11))
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.greenDark)
            }
            Text(item.createdAt.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                .font(.inter(11))
                .foregroundStyle(Theme.textMuted)
        }
        .padding(.horizontal, 20)
    }

    private func categoryPill(_ category: Category) -> some View {
        Text(category.rawValue.uppercased())
            .font(.inter(10, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(categoryDarkColor(category), in: Capsule())
    }

    private func categoryDarkColor(_ category: Category) -> Color {
        switch category {
        case .action: return Theme.greenDark
        case .brainstorm: return Theme.pinkDark
        case .revisit: return Theme.yellowDark
        case .resource: return Theme.blueDark
        }
    }

    private func textContent(item: Item) -> some View {
        Text(item.text)
            .font(.inter(15))
            .foregroundStyle(Theme.textPrimary)
            .textSelection(.enabled)
            .padding(.horizontal, 20)
    }

    @ViewBuilder
    private func tagsRow(item: Item) -> some View {
        let tags = item.parsedTags
        if !tags.isEmpty {
            HStack(spacing: 4) {
                ForEach(tags, id: \.self) { tag in
                    TagBadge(tag: tag)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    @ViewBuilder
    private func urlRow(item: Item) -> some View {
        if let urlString = item.url ?? item.text.range(of: #"https?://\S+"#, options: .regularExpression).map({ String(item.text[$0]) }),
           let url = URL(string: urlString) {
            SwiftUI.Link(destination: url) {
                HStack(spacing: 6) {
                    Image(systemName: "link")
                        .font(.inter(11))
                        .foregroundStyle(Theme.blueDark)
                    Text(url.host?.replacingOccurrences(of: "www.", with: "") ?? urlString)
                        .font(.inter(13, weight: .medium))
                        .foregroundStyle(Theme.blueDark)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var resourcesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("RESOURCES")
                .font(.inter(10, weight: .bold))
                .foregroundStyle(Theme.textMuted)

            if linkedResources.isEmpty {
                Text("No resources attached.")
                    .font(.inter(11))
                    .foregroundStyle(Theme.textMuted)
            } else {
                ForEach(linkedResources) { resource in
                    HStack(spacing: 8) {
                        if let urlString = resource.url, let url = URL(string: urlString) {
                            SwiftUI.Link(destination: url) {
                                HStack(spacing: 6) {
                                    Image(systemName: "link")
                                        .font(.system(size: 11))
                                        .foregroundStyle(Theme.blueDark)
                                    Text(resource.urlTitle ?? url.host ?? urlString)
                                        .font(.inter(12, weight: .medium))
                                        .foregroundStyle(Theme.blueDark)
                                        .lineLimit(1)
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 9))
                                        .foregroundStyle(Theme.textMuted)
                                }
                            }
                        } else {
                            Text(resource.text)
                                .font(.inter(12))
                                .foregroundStyle(Theme.textPrimary)
                                .lineLimit(1)
                            Spacer()
                        }
                        Button {
                            try? Queries.removeLink(fromId: itemId, toId: resource.id)
                            loadData()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.inter(9))
                                .foregroundStyle(Theme.textMuted)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(8)
                    .background(Theme.blueTint, in: RoundedRectangle(cornerRadius: Theme.radius(6)))
                }
            }

            Divider().padding(.top, 4)

            TextField("Paste a URL or search resources...", text: $resourceInput)
                .font(.inter(12))
                .textFieldStyle(.plain)
                .padding(8)
                .background(Theme.cardBg, in: RoundedRectangle(cornerRadius: Theme.radius(6)))
                .overlay(RoundedRectangle(cornerRadius: Theme.radius(6)).strokeBorder(Theme.border, lineWidth: 1))
                .onChange(of: resourceInput) { _, newValue in
                    if !looksLikeURL(newValue) && newValue.count >= 2 {
                        resourceSearchResults = (try? Queries.searchResourceItems(query: newValue)) ?? []
                    } else {
                        resourceSearchResults = []
                    }
                }

            if looksLikeURL(resourceInput) {
                TextField("Name this resource...", text: $resourceTitle)
                    .font(.inter(12))
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(Theme.cardBg, in: RoundedRectangle(cornerRadius: Theme.radius(6)))
                    .overlay(RoundedRectangle(cornerRadius: Theme.radius(6)).strokeBorder(Theme.border, lineWidth: 1))
                    .onSubmit { addNewResource() }

                HStack {
                    Spacer()
                    Button("Add Resource") { addNewResource() }
                        .font(.inter(11, weight: .semibold))
                        .foregroundStyle(Theme.purple)
                        .buttonStyle(.plain)
                        .disabled(resourceTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            if !resourceSearchResults.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(resourceSearchResults) { result in
                        HStack(spacing: 8) {
                            Image(systemName: "link")
                                .font(.system(size: 10))
                                .foregroundStyle(Theme.blueDark)
                            Text(result.urlTitle ?? result.url ?? result.text)
                                .font(.inter(11))
                                .foregroundStyle(Theme.textPrimary)
                                .lineLimit(1)
                            Spacer()
                            Button("Link") {
                                linkExistingResource(result)
                            }
                            .font(.inter(10, weight: .semibold))
                            .foregroundStyle(Theme.purple)
                            .buttonStyle(.plain)
                        }
                        .padding(6)
                        .background(Theme.softGray.opacity(0.3), in: RoundedRectangle(cornerRadius: Theme.radius(4)))
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private var clusteredSection: some View {
        if !clusteredItems.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("CLUSTERED WITH")
                    .font(.inter(10, weight: .bold))
                    .foregroundStyle(Theme.textMuted)
                ForEach(clusteredItems) { other in
                    HStack(spacing: 8) {
                        CategoryBadge(category: other.category)
                        Text(other.text)
                            .font(.inter(11))
                            .foregroundStyle(Theme.textSecondary)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        appState.navigate(to: .itemDetail(other.id))
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var notesSection: some View {
        GeometryReader { geo in
            VStack(alignment: .leading, spacing: 8) {
                Divider().padding(.top, 4)
                Text("NOTES")
                    .font(.inter(10, weight: .bold))
                    .foregroundStyle(Theme.textMuted)

                ZStack(alignment: .topLeading) {
                    TextEditor(text: $notesText)
                        .font(.inter(13))
                        .scrollContentBackground(.hidden)
                        .frame(height: geo.size.height * 0.75)
                        .padding(6)
                        .background(Theme.cardBg, in: RoundedRectangle(cornerRadius: Theme.radius(6)))
                        .overlay(RoundedRectangle(cornerRadius: Theme.radius(6)).strokeBorder(Theme.border, lineWidth: 1))
                        .onChange(of: notesText) { oldValue, newValue in
                        notesDirty = true
                        if newValue.count == oldValue.count + 1,
                           newValue.last == "*" {
                            let beforeAsterisk = newValue.dropLast()
                            if beforeAsterisk.isEmpty || beforeAsterisk.last == "\n" {
                                notesText = String(beforeAsterisk) + "• "
                            }
                        }
                    }
                    if notesText.isEmpty {
                        Text("Add notes, context, or ideas...")
                            .font(.inter(13))
                            .foregroundStyle(Theme.textMuted)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 10)
                            .allowsHitTesting(false)
                    }
                }

                HStack {
                    Spacer()
                    if isAnalyzing {
                        ProgressView().scaleEffect(0.7)
                    }
                    if notesDirty {
                        Button("Save") { saveNotes() }
                            .font(.inter(11, weight: .semibold))
                            .foregroundStyle(Theme.purple)
                            .buttonStyle(.plain)
                    }
                }
            }
        }
        .frame(minHeight: 380)
        .padding(.horizontal, 20)
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private var suggestionsSection: some View {
        if suggestions != nil || analysisError != nil {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("AI SUGGESTIONS")
                        .font(.inter(10, weight: .bold))
                        .foregroundStyle(Theme.purple)
                    Spacer()
                    Button {
                        suggestions = nil
                        analysisError = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(.inter(10))
                            .foregroundStyle(Theme.textMuted)
                    }
                    .buttonStyle(.plain)
                }

                if let error = analysisError {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.inter(11))
                            .foregroundStyle(Theme.pinkDark)
                        Text(error)
                            .font(.inter(12))
                            .foregroundStyle(Theme.pinkDark)
                    }
                } else if let suggestions {
                    if suggestions.actions.isEmpty && suggestions.brainstorms.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle")
                                .font(.inter(11))
                                .foregroundStyle(Theme.textMuted)
                            Text("No actions or ideas noted from these notes.")
                                .font(.inter(12))
                                .foregroundStyle(Theme.textMuted)
                        }
                    } else {
                        if !suggestions.actions.isEmpty {
                            Text("Actions")
                                .font(.inter(10, weight: .semibold))
                                .foregroundStyle(Theme.greenDark)
                            ForEach(suggestions.actions, id: \.self) { text in
                                suggestionRow(text: text, category: .action)
                            }
                        }
                        if !suggestions.brainstorms.isEmpty {
                            Text("Ideas")
                                .font(.inter(10, weight: .semibold))
                                .foregroundStyle(Theme.pinkDark)
                            ForEach(suggestions.brainstorms, id: \.self) { text in
                                suggestionRow(text: text, category: .brainstorm)
                            }
                        }
                    }
                }
            }
            .padding(12)
            .background(Theme.cardBg.opacity(0.8), in: RoundedRectangle(cornerRadius: Theme.radius(8)))
            .overlay(RoundedRectangle(cornerRadius: Theme.radius(8)).strokeBorder(Theme.purple.opacity(0.3), lineWidth: 1))
            .padding(.horizontal, 20)
        }
    }

    private func suggestionRow(text: String, category: Category) -> some View {
        HStack(alignment: .top, spacing: 8) {
            CategoryBadge(category: category)
            Text(text)
                .font(.inter(12))
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Button {
                addSuggestedItem(text: text, category: category)
                self.suggestions = NoteSuggestionsResult(
                    actions: self.suggestions?.actions.filter { $0 != text } ?? [],
                    brainstorms: self.suggestions?.brainstorms.filter { $0 != text } ?? []
                )
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Theme.purple)
            }
            .buttonStyle(.plain)
        }
        .padding(6)
        .background(Theme.softGray.opacity(0.3), in: RoundedRectangle(cornerRadius: Theme.radius(6)))
    }

    private func saveNotes() {
        guard var current = item else { return }
        current.notes = notesText.trimmingCharacters(in: .whitespaces)
        try? Queries.updateItem(current)
        notesDirty = false
        loadData()
        if !notesText.trimmingCharacters(in: .whitespaces).isEmpty {
            showAnalyzePrompt = true
        }
    }

    private func analyzeNotes() {
        guard let item, !notesText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isAnalyzing = true
        suggestions = nil
        analysisError = nil
        Task {
            do {
                let result = try await AIService.analyzeNotes(itemText: item.text, notes: notesText)
                await MainActor.run {
                    suggestions = result
                    isAnalyzing = false
                }
            } catch {
                await MainActor.run {
                    analysisError = error.localizedDescription
                    isAnalyzing = false
                }
            }
        }
    }

    private func addSuggestedItem(text: String, category: Category) {
        let newItem = Item.new(text: text, category: category)
        try? Queries.addItem(newItem)
        appState.refreshCounts()
        Task {
            if let result = try? await AIService.categorize(text: text) {
                var updated = newItem
                updated.category = result.category
                updated.text = result.cleanedText
                if !result.tags.isEmpty,
                   let data = try? JSONEncoder().encode(result.tags),
                   let json = String(data: data, encoding: .utf8) {
                    updated.tags = json
                }
                try? Queries.updateItem(updated)
                _ = try? await AIService.classifyAndCluster(text: updated.text, itemId: updated.id, category: updated.category)
            }
            await MainActor.run { appState.refreshCounts() }
        }
    }

    private func looksLikeURL(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        return trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://")
    }

    private func addNewResource() {
        let url = resourceInput.trimmingCharacters(in: .whitespaces)
        let title = resourceTitle.trimmingCharacters(in: .whitespaces)
        guard !url.isEmpty, !title.isEmpty else { return }

        var newItem = Item.new(text: title, category: .resource)
        newItem.url = url
        newItem.urlTitle = title
        try? Queries.addItem(newItem)
        try? Queries.addLink(Link(fromId: itemId, toId: newItem.id, relationship: "resource", createdAt: Date()))

        resourceInput = ""
        resourceTitle = ""
        loadData()
    }

    private func linkExistingResource(_ resource: Item) {
        try? Queries.addLink(Link(fromId: itemId, toId: resource.id, relationship: "resource", createdAt: Date()))
        resourceInput = ""
        resourceSearchResults = []
        loadData()
    }

    private func loadData() {
        item = try? Queries.getItem(id: itemId)
        notesText = item?.notes ?? ""
        notesDirty = false

        let linked = (try? Queries.getLinkedItems(itemId: itemId)) ?? []
        linkedResources = linked.filter { $0.category == .resource || $0.url != nil }

        if let clusterId = item?.clusterId, let cluster = try? Queries.getCluster(id: clusterId) {
            clusteredItems = cluster.items.filter { $0.id != itemId }
        } else {
            clusteredItems = []
        }
    }
}
