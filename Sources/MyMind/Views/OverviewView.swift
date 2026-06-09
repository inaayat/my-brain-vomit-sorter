import SwiftUI

struct OverviewView: View {
    @Bindable var appState: AppState
    @State private var vm = OverviewViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                InlineCaptureView(appState: appState) { vm.load() }
                statCards
                actionsSection
                brainstormsSection
                resourcesSection
            }
            .padding(28)
        }
        .background(Theme.bg)
        .onAppear { vm.load() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(vm.greeting)
                .font(.inter(28, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text(vm.todayString)
                .font(.inter(13))
                .foregroundStyle(Theme.textMuted)
        }
    }

    private var statCards: some View {
        HStack(spacing: 16) {
            StatCard(title: "Actions", value: vm.openActions.count, icon: "bolt.fill", color: Theme.greenDark, tint: Theme.greenTint, onTap: { appState.selectedDestination = .actions })
            StatCard(title: "Brainstorms", value: vm.brainstorms.count, icon: "cloud.bolt.fill", color: Theme.pinkDark, tint: Theme.pinkTint, onTap: { appState.selectedDestination = .brainstorms })
            StatCard(title: "Resources", value: vm.resources.count, icon: "bookmark.fill", color: Theme.blueDark, tint: Theme.blueTint, onTap: { appState.selectedDestination = .resources })
            StatCard(title: "Completed", value: appState.counts["completed"] ?? 0, icon: "checkmark.circle.fill", color: Theme.yellowDark, tint: Theme.yellowTint, onTap: { appState.selectedDestination = .completed })
        }
    }

    private var focusSection: some View {
        DashboardSection(title: "AI Focus", icon: "sparkle", color: Theme.purple, tint: Theme.pinkTint) {
            HStack {
                Spacer()
                Button {
                    vm.loadFocus()
                } label: {
                    Text("Get Focus")
                        .font(.inter(11))
                        .fontWeight(.medium)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.purple)
                .controlSize(.small)
                .disabled(vm.isLoadingFocus)
            }

            if vm.isLoadingFocus {
                ProgressView("Thinking...")
                    .font(.inter(11))
                    .foregroundStyle(Theme.textMuted)
            } else if !vm.focusSummary.isEmpty {
                Text(vm.focusSummary)
                    .font(.inter(13))
                    .foregroundStyle(Theme.purple)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.pinkTint.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))

                ForEach(vm.focusItems, id: \.item.id) { entry in
                    FocusItemRow(item: entry.item, reason: entry.reason) {
                        try? Queries.completeItem(id: entry.item.id)
                        vm.load()
                        appState.refreshCounts()
                    } onTap: {
                        appState.navigate(to: .itemDetail(entry.item.id))
                    }
                }
            }
        }
    }

    private var actionsSection: some View {
        DashboardSection(title: "Actions", icon: "bolt.fill", color: Theme.greenDark, tint: Theme.greenTint) {
            ForEach(vm.clustersFor(category: .action)) { cluster in
                ClusterCardView(cluster: cluster, onTap: {}, onDropItem: { draggedId in
                    appState.addToClusterFromDrop(draggedId: draggedId, clusterId: cluster.id)
                    vm.load()
                }, onChanged: { vm.load() }, onItemComplete: { itemId in try? Queries.completeItem(id: itemId); vm.load(); appState.refreshCounts() }, onItemTap: { itemId in
                    appState.navigate(to: .itemDetail(itemId))
                })
            }
            if vm.openActions.isEmpty {
                Text("All clear!")
                    .font(.inter(11))
                    .foregroundStyle(Theme.textMuted)
            } else {
                ForEach(vm.openActions.prefix(8)) { item in
                    ItemCardView(item: item, compact: true) {
                        appState.navigate(to: .itemDetail(item.id))
                    } onComplete: {
                        let wasAction = item.category == .action && !item.done
                        try? Queries.completeItem(id: item.id)
                        vm.load()
                        appState.refreshCounts()
                        if wasAction {
                            appState.completedItem = item
                            appState.showLogWinSheet = true
                        }
                    } onDrop: { draggedId in
                    appState.createClusterFromDrop(draggedId: draggedId, targetId: item.id)
                    vm.load()
                } onDelete: {
                        try? Queries.deleteItem(id: item.id)
                        vm.load()
                        appState.refreshCounts()
                    }
                }
            }
        }
    }

    private var brainstormsSection: some View {
        DashboardSection(title: "Brainstorms", icon: "cloud.bolt.fill", color: Theme.pinkDark, tint: Theme.pinkTint) {
            ForEach(vm.clustersFor(category: .brainstorm)) { cluster in
                ClusterCardView(cluster: cluster, onTap: {}, onDropItem: { draggedId in
                    appState.addToClusterFromDrop(draggedId: draggedId, clusterId: cluster.id)
                    vm.load()
                }, onChanged: { vm.load() }, onItemComplete: { itemId in try? Queries.completeItem(id: itemId); vm.load(); appState.refreshCounts() }, onItemTap: { itemId in
                    appState.navigate(to: .itemDetail(itemId))
                })
            }
            ForEach(vm.brainstorms.prefix(6)) { item in
                ItemCardView(item: item, compact: true) {
                    appState.navigate(to: .itemDetail(item.id))
                } onComplete: {
                    try? Queries.completeItem(id: item.id)
                    vm.load()
                    appState.refreshCounts()
                } onDrop: { draggedId in
                    appState.createClusterFromDrop(draggedId: draggedId, targetId: item.id)
                    vm.load()
                } onDelete: {
                    try? Queries.deleteItem(id: item.id)
                    vm.load()
                    appState.refreshCounts()
                }
            }
            if vm.brainstorms.isEmpty && vm.clustersFor(category: .brainstorm).isEmpty {
                Text("No brainstorms yet")
                    .font(.inter(11))
                    .foregroundStyle(Theme.textMuted)
            }
        }
    }

    private var resourcesSection: some View {
        DashboardSection(title: "Resources", icon: "bookmark.fill", color: Theme.blueDark, tint: Theme.blueTint) {
            if vm.resources.isEmpty {
                Text("No resources saved")
                    .font(.inter(11))
                    .foregroundStyle(Theme.textMuted)
            } else {
                ForEach(vm.resources.prefix(5)) { item in
                    ResourceCardView(item: item) {
                        appState.navigate(to: .itemDetail(item.id))
                    }
                }
            }
        }
    }

    private var revisitSection: some View {
        DashboardSection(title: "Revisit", icon: "arrow.counterclockwise.circle.fill", color: Theme.yellowDark, tint: Theme.yellowTint) {
            if vm.revisits.isEmpty {
                Text("Nothing to revisit")
                    .font(.inter(11))
                    .foregroundStyle(Theme.textMuted)
            } else {
                ForEach(vm.revisits.prefix(5)) { item in
                    ItemCardView(item: item, compact: true) {
                        appState.navigate(to: .itemDetail(item.id))
                    } onComplete: {
                        try? Queries.completeItem(id: item.id)
                        vm.load()
                        appState.refreshCounts()
                    } onDrop: { draggedId in
                    appState.createClusterFromDrop(draggedId: draggedId, targetId: item.id)
                    vm.load()
                } onDelete: {
                        try? Queries.deleteItem(id: item.id)
                        vm.load()
                        appState.refreshCounts()
                    }
                }
            }
        }
    }
}

// MARK: - Dashboard Components

struct StatCard: View {
    let title: String
    let value: Int
    let icon: String
    let color: Color
    var tint: Color = Theme.softGray
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(color)
                    Spacer()
                }
                Text("\(value)")
                    .font(.inter(24, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text(title)
                    .font(.inter(12, weight: .medium))
                    .foregroundStyle(color)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(tint.opacity(0.45), in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

struct DashboardSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    var tint: Color = Theme.cardBg
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.inter(13, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(color, in: Capsule())
                Spacer()
            }

            VStack(alignment: .leading, spacing: 6) {
                content
            }
            .padding(.horizontal, 4)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.45), in: RoundedRectangle(cornerRadius: 14))
    }
}

struct FocusItemRow: View {
    let item: Item
    let reason: String
    let onComplete: () -> Void
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onComplete) {
                Circle()
                    .strokeBorder(Theme.purple, lineWidth: 2)
                    .frame(width: 16, height: 16)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.text)
                    .font(.inter(13))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)
                if !reason.isEmpty {
                    Text(reason)
                        .font(.inter(11))
                        .foregroundStyle(Theme.purple)
                        .italic()
                }
            }
            .onTapGesture(perform: onTap)

            Spacer()
        }
        .padding(.vertical, 4)
    }
}
