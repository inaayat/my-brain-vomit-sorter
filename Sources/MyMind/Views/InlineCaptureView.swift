import SwiftUI
import AppKit

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
    @State private var selectedClusterId: String?
    @State private var selectedResourceId: String?
    @State private var allClusters: [Cluster] = []
    @State private var allResources: [Item] = []
    @State private var showDatePopover = false

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
                    .frame(minHeight: 20, maxHeight: 80)
                    .fixedSize(horizontal: false, vertical: true)
                    .onChange(of: text) { _, newValue in
                        if !newValue.isEmpty && !expanded {
                            expanded = true
                            allClusters = (try? Queries.getAllClustersWithItems()) ?? []
                            allResources = (try? Queries.getItems(category: .resource, done: false, limit: 50)) ?? []
                        }
                        // Enter to submit (unless Shift held — allow new lines via Shift+Enter)
                        if newValue.hasSuffix("\n") && !NSEvent.modifierFlags.contains(.shift) {
                            text = String(newValue.dropLast())
                            save()
                        }
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
            .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.radius(10)))
            .overlay(RoundedRectangle(cornerRadius: Theme.radius(10)).strokeBorder(Theme.border, lineWidth: 1))

            if expanded && !text.trimmingCharacters(in: .whitespaces).isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        PillButton(label: "Auto", isSelected: selectedCategory == nil) { selectedCategory = nil }
                        PillButton(label: "Action", isSelected: selectedCategory == .action) { selectedCategory = .action }
                        PillButton(label: "Brainstorm", isSelected: selectedCategory == .brainstorm) { selectedCategory = .brainstorm }
                        PillButton(label: "Resource", isSelected: selectedCategory == .resource) { selectedCategory = .resource }
                    }

                    HStack(spacing: 12) {
                        DatePicker("Due", selection: $dueDate, displayedComponents: .date)
                            .labelsHidden()
                            .controlSize(.small)
                            .frame(maxWidth: 130)
                            .onChange(of: dueDate) { _, _ in hasDueDate = true }

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
                        .foregroundStyle(Theme.textMuted)
                    }

                    // Cluster + Resource linking row
                    HStack(spacing: 12) {
                        // Add to cluster — dropdown
                        HStack(spacing: 4) {
                            Image(systemName: "rectangle.3.group")
                                .font(.system(size: 10))
                                .foregroundStyle(Theme.yellowDark)
                            Picker("Cluster", selection: $selectedClusterId) {
                                Text("Add to cluster...").tag(nil as String?)
                                ForEach(allClusters) { cluster in
                                    Text(cluster.title).tag(cluster.id as String?)
                                }
                            }
                            .frame(maxWidth: 180)
                            .controlSize(.small)
                        }

                        Divider().frame(height: 16)

                        // Link to existing resource
                        HStack(spacing: 4) {
                            Image(systemName: "link")
                                .font(.system(size: 10))
                                .foregroundStyle(Theme.blueDark)
                            Picker("Resource", selection: $selectedResourceId) {
                                Text("Link resource...").tag(nil as String?)
                                ForEach(allResources) { resource in
                                    Text(resource.urlTitle ?? resource.text)
                                        .tag(resource.id as String?)
                                }
                            }
                            .frame(maxWidth: 180)
                            .controlSize(.small)
                        }
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

            // Assign to cluster if selected
            if let clusterId = selectedClusterId {
                try? Queries.assignToCluster(itemId: item.id, clusterId: clusterId)
            }

            // Link to existing resource if selected
            if let resourceId = selectedResourceId {
                let link = Link.new(fromId: item.id, toId: resourceId)
                try? Queries.addLink(link)
            }

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

            // Auto-cluster only if not manually assigned
            if selectedClusterId == nil {
                Task {
                    _ = try? await AIService.classifyAndCluster(text: finalText, itemId: item.id, category: item.category)
                }
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
        selectedClusterId = nil
        selectedResourceId = nil
        expanded = false
    }
}
