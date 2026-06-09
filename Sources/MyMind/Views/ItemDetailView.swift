import SwiftUI

struct ItemDetailView: View {
    @Bindable var appState: AppState
    let itemId: String

    @State private var item: Item?
    @State private var comments: [Comment] = []
    @State private var clusteredItems: [Item] = []
    @State private var linkedResources: [Item] = []
    @State private var newComment = ""
    @State private var confirmDelete = false

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
                    resourcesSection
                    clusteredSection
                    commentsSection
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(tintColor.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .onAppear { loadData() }
            .onChange(of: itemId) { _, _ in loadData() }
        } else {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.softGray.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 14))
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

    @ViewBuilder
    private var resourcesSection: some View {
        if !linkedResources.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("RESOURCES")
                    .font(.inter(10, weight: .bold))
                    .foregroundStyle(Theme.textMuted)
                ForEach(linkedResources) { resource in
                    if let urlString = resource.url, let url = URL(string: urlString) {
                        SwiftUI.Link(destination: url) {
                            HStack(spacing: 8) {
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
                            .padding(8)
                            .background(Color(hex: "#EEF3FB"), in: RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
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

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider().padding(.top, 8)
            Text("NOTES & COMMENTS")
                .font(.inter(10, weight: .bold))
                .foregroundStyle(Theme.textMuted)

            if comments.isEmpty {
                Text("No notes yet.")
                    .font(.inter(11))
                    .foregroundStyle(Theme.textMuted)
            } else {
                ForEach(comments) { comment in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(comment.text)
                            .font(.inter(13))
                            .foregroundStyle(Theme.textPrimary)
                        HStack {
                            Text(comment.createdAt.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                                .font(.inter(10))
                                .foregroundStyle(Theme.textMuted)
                            Spacer()
                            Button {
                                try? Queries.deleteComment(id: comment.id)
                                loadData()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.inter(10))
                                    .foregroundStyle(Theme.textMuted)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(8)
                    .background(Theme.cardBg.opacity(0.6), in: RoundedRectangle(cornerRadius: 6))
                }
            }

            HStack(spacing: 8) {
                TextField("Add a note...", text: $newComment)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { addComment() }
                Button("Add") { addComment() }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.purple)
                    .controlSize(.small)
                    .disabled(newComment.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }

    private func loadData() {
        item = try? Queries.getItem(id: itemId)
        comments = (try? Queries.getComments(itemId: itemId)) ?? []

        // Resources linked to this item
        let linked = (try? Queries.getLinkedItems(itemId: itemId)) ?? []
        linkedResources = linked.filter { $0.category == .resource || $0.url != nil }

        // Other items in the same cluster
        if let clusterId = item?.clusterId, let cluster = try? Queries.getCluster(id: clusterId) {
            clusteredItems = cluster.items.filter { $0.id != itemId }
        } else {
            clusteredItems = []
        }
    }

    private func addComment() {
        let text = newComment.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        let comment = Comment.new(itemId: itemId, text: text)
        try? Queries.addComment(comment)
        newComment = ""
        loadData()
    }
}
