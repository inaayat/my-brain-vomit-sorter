import Foundation

@Observable
final class OverviewViewModel {
    var openActions: [Item] = []
    var brainstorms: [Item] = []
    var resources: [Item] = []
    var revisits: [Item] = []
    var allClusters: [Cluster] = []
    var focusItems: [(item: Item, reason: String)] = []
    var focusSummary: String = ""
    var isLoadingFocus = false
    var isLoading = false

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

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning" }
        if hour < 17 { return "Good afternoon" }
        return "Good evening"
    }

    var todayString: String {
        Date().formatted(.dateTime.weekday(.wide).month(.wide).day())
    }

    func load() {
        isLoading = true
        do {
            openActions = try Queries.getOpenActions()
            brainstorms = try Queries.getItems(category: .brainstorm, done: false, limit: 20)
            resources = try Queries.getItems(category: .resource, done: false, limit: 20)
            revisits = try Queries.getItems(category: .revisit, done: false, limit: 10)
            allClusters = try Queries.getAllClustersWithItems()
        } catch {}
        isLoading = false
    }

    func loadFocus() {
        guard !isLoadingFocus else { return }
        isLoadingFocus = true
        Task {
            do {
                let result = try await AIService.getFocusSuggestions()
                await MainActor.run {
                    self.focusItems = result.items
                    self.focusSummary = result.summary
                    self.isLoadingFocus = false
                }
            } catch {
                await MainActor.run {
                    self.focusSummary = "Could not load suggestions."
                    self.isLoadingFocus = false
                }
            }
        }
    }
}
