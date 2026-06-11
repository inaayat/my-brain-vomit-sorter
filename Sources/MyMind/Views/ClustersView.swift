import SwiftUI

struct ClustersView: View {
    @Bindable var appState: AppState
    @State private var clusters: [Cluster] = []
    @State private var unclusteredItems: [Item] = []
    @State private var resourceCounts: [String: Int] = [:]
    @State private var mergeMode = false
    @State private var mergeSelection: Set<String> = []

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
        VStack(alignment: .leading, spacing: 14) {
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
                    })
                }

                // Delete button below each cluster
                if !mergeMode {
                    HStack {
                        Spacer()
                        Button {
                            try? Queries.deleteCluster(id: cluster.id)
                            reload()
                            appState.refreshCounts()
                        } label: {
                            Label("Delete Cluster", systemImage: "trash")
                                .font(.inter(10))
                                .foregroundStyle(Theme.pinkDark)
                        }
                        .buttonStyle(.plain)
                    }
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
