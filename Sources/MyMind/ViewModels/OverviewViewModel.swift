import Foundation

@Observable
final class OverviewViewModel {
    var openActions: [Item] = []
    var brainstorms: [Item] = []
    var resources: [Item] = []
    var allClusters: [Cluster] = []
    var isLoading = false

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning" }
        if hour < 17 { return "Good afternoon" }
        return "Good evening"
    }

    var todayString: String {
        Date().formatted(.dateTime.weekday(.wide).month(.wide).day())
    }

    func clustersFor(category: Category) -> [Cluster] {
        allClusters.compactMap { cluster in
            let filtered = cluster.items.filter { $0.category == category && !$0.done }
            guard !filtered.isEmpty else { return nil }
            var c = cluster
            c.items = filtered
            c.itemCount = filtered.count
            return c
        }
    }

    func load() {
        isLoading = true
        do {
            openActions = try Queries.getOpenActions()
            brainstorms = try Queries.getItems(category: .brainstorm, done: false, limit: 20)
            resources = try Queries.getItems(category: .resource, done: false, limit: 20)
            allClusters = try Queries.getAllClustersWithItems()
        } catch {}
        isLoading = false
    }
}
