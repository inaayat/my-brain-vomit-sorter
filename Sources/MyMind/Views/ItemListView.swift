import SwiftUI

struct ItemListView: View {
    @Bindable var appState: AppState
    let category: Category?
    let title: String
    var showDone: Bool = false

    @State private var vm = ItemListViewModel()
    @State private var searchText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title)
                    .font(.inter(20, weight: .bold))
                    .fontWeight(.bold)
                Spacer()
                TextField("Search...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 180)
                    .onChange(of: searchText) { _, newValue in
                        if newValue.count >= 2 {
                            vm.search(query: newValue)
                        } else {
                            reload()
                        }
                    }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 12)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    if !vm.clusters.isEmpty {
                        ForEach(vm.clusters) { cluster in
                            ClusterCardView(cluster: cluster) {} onDropItem: { draggedId in
                                appState.addToClusterFromDrop(draggedId: draggedId, clusterId: cluster.id)
                                reload()
                            } onChanged: { reload() } onItemComplete: { itemId in try? Queries.completeItem(id: itemId); reload(); appState.refreshCounts() } onItemTap: { itemId in
                                appState.navigate(to: .itemDetail(itemId))
                            }
                        }
                    }

                    let displayItems = vm.items
                    if displayItems.isEmpty && vm.clusters.isEmpty {
                        Text("Nothing here yet")
                            .font(.inter(13))
                            .foregroundStyle(Theme.textMuted)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 40)
                    } else {
                        ForEach(displayItems) { item in
                            ItemCardView(item: item) {
                                appState.navigate(to: .itemDetail(item.id))
                            } onComplete: {
                                vm.toggleComplete(item: item)
                                reload()
                                appState.refreshCounts()
                            } onDrop: { draggedId in
                                appState.createClusterFromDrop(draggedId: draggedId, targetId: item.id)
                                reload()
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .onAppear { reload() }
    }

    private func reload() {
        if showDone {
            vm.loadCompleted()
        } else if category == .resource {
            vm.loadResources()
        } else {
            vm.load(category: category)
        }
    }
}
