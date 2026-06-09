import SwiftUI

struct OverviewView: View {
    @Bindable var appState: AppState
    @State private var allItems: [Item] = []
    @State private var allClusters: [Cluster] = []
    @State private var activeFilter: Category? = .action
    @State private var counts: [Category: Int] = [:]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                InlineCaptureView(appState: appState) { reload() }
                filterChips
                itemFeed
            }
            .padding(28)
        }
        .background(Theme.bg)
        .onAppear { reload() }
    }

    private var filterChips: some View {
        HStack(spacing: 14) {
            filterCard(label: "All Open", count: allItems.count, category: nil, icon: "tray.full.fill", tint: Theme.softGray, color: Theme.textPrimary)
            filterCard(label: "Actions", count: counts[.action] ?? 0, category: .action, icon: "bolt.fill", tint: Theme.greenTint, color: Theme.greenDark)
            filterCard(label: "Brainstorms", count: counts[.brainstorm] ?? 0, category: .brainstorm, icon: "cloud.bolt.fill", tint: Theme.pinkTint, color: Theme.pinkDark)
            filterCard(label: "Resources", count: counts[.resource] ?? 0, category: .resource, icon: "bookmark.fill", tint: Theme.blueTint, color: Theme.blueDark)
        }
    }

    @ViewBuilder
    private func filterCard(label: String, count: Int, category: Category?, icon: String, tint: Color, color: Color) -> some View {
        let isActive = activeFilter == category

        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                activeFilter = category
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)
                Text("\(count)")
                    .font(.inter(22, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text(label)
                    .font(.inter(11, weight: .medium))
                    .foregroundStyle(color)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(tint.opacity(isActive ? 0.7 : 0.4), in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isActive ? color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private var itemFeed: some View {
        LazyVStack(alignment: .leading, spacing: 8) {
            if activeFilter == nil {
                // "All Open" — flat list, no clusters, just sorted items
                let items = allOpenItems()
                ForEach(items) { item in
                    ItemCardView(item: item) {
                        appState.navigate(to: .itemDetail(item.id))
                    } onComplete: {
                        try? Queries.completeItem(id: item.id)
                        reload()
                        appState.refreshCounts()
                    } onDrop: { draggedId in
                        appState.createClusterFromDrop(draggedId: draggedId, targetId: item.id)
                        reload()
                    } onChange: {
                        reload()
                    }
                }
                if items.isEmpty {
                    Text("No items yet. Capture a thought above!")
                        .font(.inter(13))
                        .foregroundStyle(Theme.textMuted)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 40)
                }
            } else {
                // High priority items — flag on left, inline with rest of feed
                let highItems = highPriorityItems()
                ForEach(highItems) { item in
                    highFlagRow(item)
                }

                // Filtered by category — show clusters inline
                let filteredClusters = clustersForFilter()
                ForEach(filteredClusters) { cluster in
                    ClusterCardView(cluster: cluster, onTap: {}, onDropItem: { draggedId in
                        appState.addToClusterFromDrop(draggedId: draggedId, clusterId: cluster.id)
                        reload()
                    }, onChanged: { reload() }, onItemComplete: { itemId in
                        try? Queries.completeItem(id: itemId)
                        reload()
                        appState.refreshCounts()
                    }, onItemTap: { itemId in
                        appState.navigate(to: .itemDetail(itemId))
                    })
                }

                let items = filteredItems()
                ForEach(items) { item in
                    ItemCardView(item: item) {
                        appState.navigate(to: .itemDetail(item.id))
                    } onComplete: {
                        try? Queries.completeItem(id: item.id)
                        reload()
                        appState.refreshCounts()
                    } onDrop: { draggedId in
                        appState.createClusterFromDrop(draggedId: draggedId, targetId: item.id)
                        reload()
                    } onChange: {
                        reload()
                    }
                }

                if filteredClusters.isEmpty && items.isEmpty {
                    Text("No items here yet.")
                        .font(.inter(13))
                        .foregroundStyle(Theme.textMuted)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 40)
                }

                // Backlog section
                let backlog = backlogItems()
                if !backlog.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Backlog")
                            .font(.inter(14, weight: .semibold))
                            .foregroundStyle(Theme.yellowDark)
                            .padding(.top, 16)
                        ForEach(backlog) { item in
                            ItemCardView(item: item) {
                                appState.navigate(to: .itemDetail(item.id))
                            } onComplete: {
                                try? Queries.completeItem(id: item.id)
                                reload()
                                appState.refreshCounts()
                            } onDrop: { draggedId in
                                appState.createClusterFromDrop(draggedId: draggedId, targetId: item.id)
                                reload()
                            } onChange: {
                                reload()
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func highFlagRow(_ item: Item) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Text("High")
                .font(.inter(11, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .frame(width: 110)
                .padding(.vertical, 10)
                .background(Theme.pink, in: RoundedRectangle(cornerRadius: 10))

            ItemCardView(item: item) {
                appState.navigate(to: .itemDetail(item.id))
            } onComplete: {
                try? Queries.completeItem(id: item.id)
                reload()
                appState.refreshCounts()
            } onDrop: { draggedId in
                appState.createClusterFromDrop(draggedId: draggedId, targetId: item.id)
                reload()
            } onChange: {
                reload()
            }
        }
    }

    private func allOpenItems() -> [Item] {
        sortItems(allItems.filter { !$0.done && $0.category != .resource })
    }

    private func highPriorityItems() -> [Item] {
        var items = allItems.filter { !$0.done && $0.priority.isHigh }
        if let filter = activeFilter {
            items = items.filter { $0.category == filter }
        }
        return items.sorted { $0.createdAt < $1.createdAt }
    }

    private func filteredItems() -> [Item] {
        var items = allItems.filter { $0.clusterId == nil && !$0.done && !$0.priority.isBacklog && !$0.priority.isHigh }
        if let filter = activeFilter {
            items = items.filter { $0.category == filter }
        }
        return sortItems(items)
    }

    private func backlogItems() -> [Item] {
        var items = allItems.filter { !$0.done && $0.priority.isBacklog }
        if let filter = activeFilter {
            items = items.filter { $0.category == filter }
        }
        return items.sorted { $0.createdAt < $1.createdAt }
    }

    private func sortItems(_ items: [Item]) -> [Item] {
        items.sorted { a, b in
            if a.priority.sortOrder != b.priority.sortOrder {
                return a.priority.sortOrder < b.priority.sortOrder
            }
            if a.category.sortOrder != b.category.sortOrder {
                return a.category.sortOrder < b.category.sortOrder
            }
            return a.createdAt < b.createdAt
        }
    }

    private func clustersForFilter() -> [Cluster] {
        allClusters.compactMap { cluster in
            var openItems = cluster.items.filter { !$0.done && !$0.priority.isBacklog && !$0.priority.isHigh }
            if let filter = activeFilter {
                openItems = openItems.filter { $0.category == filter }
            }
            guard !openItems.isEmpty else { return nil }
            var c = cluster
            c.items = sortItems(openItems)
            c.itemCount = c.items.count
            return c
        }
    }

    private func reload() {
        allItems = (try? Queries.getAllItems().filter { !$0.done }) ?? []
        allClusters = (try? Queries.getAllClustersWithItems()) ?? []
        counts = [:]
        for item in allItems where !item.done {
            counts[item.category, default: 0] += 1
        }
        appState.refreshCounts()
    }

    private func categoryIcon(_ category: Category) -> String {
        switch category {
        case .action: return "bolt.fill"
        case .brainstorm: return "cloud.bolt.fill"
        case .revisit: return "arrow.counterclockwise"
        case .resource: return "link"
        }
    }

    private func chipColor(_ category: Category?) -> Color {
        guard let category else { return Theme.purple }
        switch category {
        case .action: return Theme.greenDark
        case .brainstorm: return Theme.pinkDark
        case .revisit: return Theme.yellowDark
        case .resource: return Theme.blueDark
        }
    }
}
