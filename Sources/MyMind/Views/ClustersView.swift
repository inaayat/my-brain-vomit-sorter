import SwiftUI

struct ClustersView: View {
    @Bindable var appState: AppState
    @State private var clusters: [Cluster] = []
    @State private var unclusteredItems: [Item] = []
    @State private var resourceCounts: [String: Int] = [:]
    @State private var mergeMode = false
    @State private var mergeSelection: Set<String> = []
    @State private var addItemsTarget: Cluster? = nil
    @State private var addItemsSelection: Set<String> = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                if clusters.isEmpty && unclusteredItems.isEmpty {
                    emptyState
                } else {
                    if !clusters.isEmpty { clustersSection }
                    if !unclusteredItems.isEmpty { unclusteredSection }
                }
            }
            .padding(28)
        }
        .background(Theme.bg)
        .onAppear { reload() }
        .sheet(item: $addItemsTarget) { cluster in
            addItemsSheet(for: cluster)
        }
    }

    @ViewBuilder
    private func addItemsSheet(for cluster: Cluster) -> some View {
        VStack(spacing: 0) {
            // Header
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 6) {
                    Image(systemName: "rectangle.3.group")
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.yellowDark)
                    Text(cluster.title)
                        .font(.inter(18, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Choose items to add to this cluster")
                        .font(.inter(12))
                        .foregroundStyle(Theme.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .padding(.horizontal, 20)

                Button {
                    addItemsTarget = nil
                    addItemsSelection.removeAll()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Theme.textMuted.opacity(0.5))
                }
                .buttonStyle(.plain)
                .padding(16)
            }
            .background(Theme.clusterBg)

            Divider()

            if unclusteredItems.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "tray")
                        .font(.system(size: 28))
                        .foregroundStyle(Theme.textMuted.opacity(0.4))
                    Text("No unclustered items available")
                        .font(.inter(13))
                        .foregroundStyle(Theme.textMuted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(unclusteredItems) { item in
                            addItemRow(item)
                        }
                    }
                    .padding(16)
                }
            }

            Divider()

            // Footer
            HStack(spacing: 12) {
                if !addItemsSelection.isEmpty {
                    Text("\(addItemsSelection.count) selected")
                        .font(.inter(12, weight: .semibold))
                        .foregroundStyle(Theme.purple)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Theme.purple.opacity(0.1), in: Capsule())
                }
                Spacer()
                Button("Cancel") {
                    addItemsTarget = nil
                    addItemsSelection.removeAll()
                }
                .font(.inter(13))
                .foregroundStyle(Theme.textMuted)
                .buttonStyle(.plain)
                Button {
                    for id in addItemsSelection {
                        try? Queries.assignToCluster(itemId: id, clusterId: cluster.id)
                    }
                    addItemsTarget = nil
                    addItemsSelection.removeAll()
                    reload()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add to Cluster")
                    }
                    .font(.inter(13, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.purple)
                .disabled(addItemsSelection.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Theme.bg)
        }
        .frame(width: 480, height: 520)
        .background(Theme.bg)
    }

    @ViewBuilder
    private func addItemRow(_ item: Item) -> some View {
        let selected = addItemsSelection.contains(item.id)
        let categoryColor: Color = {
            switch item.category {
            case .action: return Theme.greenDark
            case .brainstorm: return Theme.pinkDark
            case .resource: return Theme.blueDark
            case .revisit: return Theme.yellowDark
            }
        }()
        let categoryBg: Color = {
            switch item.category {
            case .action: return Theme.greenTint
            case .brainstorm: return Theme.pinkTint
            case .resource: return Theme.blueTint
            case .revisit: return Theme.yellowDark.opacity(0.15)
            }
        }()

        Button {
            if selected { addItemsSelection.remove(item.id) }
            else { addItemsSelection.insert(item.id) }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(selected ? Theme.purple : Theme.textMuted.opacity(0.4))
                    .animation(.easeInOut(duration: 0.15), value: selected)

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.text)
                        .font(.inter(13))
                        .foregroundStyle(Theme.textPrimary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    Text(item.category.rawValue.capitalized)
                        .font(.inter(10, weight: .semibold))
                        .foregroundStyle(categoryColor)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(categoryBg, in: Capsule())
                }

                Spacer()

                if selected {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Theme.purple.opacity(0.2))
                        .frame(width: 3, height: 36)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: Theme.radius(10))
                    .fill(selected ? Theme.purple.opacity(0.07) : Theme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.radius(10))
                            .strokeBorder(selected ? Theme.purple.opacity(0.3) : Theme.cardBorder, lineWidth: 1)
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: Theme.radius(10)))
            .animation(.easeInOut(duration: 0.15), value: selected)
        }
        .buttonStyle(.plain)
    }

    private var header: some View {
        HStack {
            Text("Clusters")
                .font(.inter(24, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text("\(clusters.count)")
                .font(.inter(11, weight: .bold))
                .foregroundStyle(Theme.textMuted)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Theme.softGray, in: Capsule())
            Spacer()
            if clusters.count >= 2 {
                Button(mergeMode ? (mergeSelection.count >= 2 ? "Merge Selected" : "Done") : "Merge") {
                    if mergeMode && mergeSelection.count >= 2 {
                        performMerge()
                    }
                    mergeMode.toggle()
                    if !mergeMode { mergeSelection.removeAll() }
                }
                .font(.inter(11, weight: .medium))
                .buttonStyle(.borderedProminent)
                .tint(mergeMode ? Theme.purple : Theme.greenDark)
                .controlSize(.small)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "rectangle.3.group")
                .font(.system(size: 36))
                .foregroundStyle(Theme.textMuted.opacity(0.4))
            Text("No clusters yet")
                .font(.inter(14))
                .foregroundStyle(Theme.textMuted)
            Text("Drag one item onto another to create a cluster.")
                .font(.inter(12))
                .foregroundStyle(Theme.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    private var clustersSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            if mergeMode {
                Text("Tap clusters to select, then click 'Merge Selected'")
                    .font(.inter(11))
                    .foregroundStyle(Theme.purple)
            }

            ForEach(clusters) { cluster in
                HStack(spacing: 10) {
                    if mergeMode {
                        Button {
                            if mergeSelection.contains(cluster.id) {
                                mergeSelection.remove(cluster.id)
                            } else {
                                mergeSelection.insert(cluster.id)
                            }
                        } label: {
                            Image(systemName: mergeSelection.contains(cluster.id) ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 18))
                                .foregroundStyle(mergeSelection.contains(cluster.id) ? Theme.purple : Theme.textMuted)
                        }
                        .buttonStyle(.plain)
                    }

                    ClusterCardView(cluster: cluster, onTap: {}, onDropItem: { draggedId in
                        appState.addToClusterFromDrop(draggedId: draggedId, clusterId: cluster.id)
                        reload()
                    }, onChanged: { reload() }, onItemComplete: { itemId in
                        try? Queries.completeItem(id: itemId)
                        reload()
                        appState.refreshCounts()
                        if let completed = try? Queries.getItem(id: itemId) {
                            appState.completedItem = completed
                            appState.showLogWinSheet = true
                        }
                    }, onItemTap: { itemId in
                        appState.navigate(to: .itemDetail(itemId))
                    }, onAddItems: {
                        addItemsSelection.removeAll()
                        addItemsTarget = cluster
                    }, onDelete: {
                        try? Queries.deleteCluster(id: cluster.id)
                        reload()
                        appState.refreshCounts()
                    })
                }
            }
        }
    }

    private var unclusteredSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Unclustered")
                .font(.inter(14, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            Text("Drag items onto each other or onto a cluster above")
                .font(.inter(11))
                .foregroundStyle(Theme.textMuted)

            ForEach(unclusteredItems) { item in
                ItemCardView(item: item, resourceCount: resourceCounts[item.id] ?? 0) {
                    appState.navigate(to: .itemDetail(item.id))
                } onComplete: {
                    try? Queries.completeItem(id: item.id)
                    reload()
                    appState.refreshCounts()
                    if let completed = try? Queries.getItem(id: item.id) {
                        appState.completedItem = completed
                        appState.showLogWinSheet = true
                    }
                } onDrop: { draggedId in
                    appState.createClusterFromDrop(draggedId: draggedId, targetId: item.id)
                    reload()
                }
            }
        }
    }

    private func reload() {
        clusters = (try? Queries.getAllClustersWithItems()) ?? []
        unclusteredItems = (try? Queries.getUnclusteredItems()) ?? []
        resourceCounts = (try? Queries.getResourceCounts(itemIds: unclusteredItems.map(\.id))) ?? [:]
    }

    private func performMerge() {
        guard mergeSelection.count >= 2 else { return }
        let ids = Array(mergeSelection)
        let keepId = ids[0]
        let removeIds = Array(ids.dropFirst())
        try? Queries.mergeClusters(keepId: keepId, removeIds: removeIds)
        mergeSelection.removeAll()
        reload()
    }
}
