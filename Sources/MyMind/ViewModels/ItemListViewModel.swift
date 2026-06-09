import Foundation

@Observable
final class ItemListViewModel {
    var items: [Item] = []
    var clusters: [Cluster] = []
    var unclusteredItems: [Item] = []

    func load(category: Category?, showDone: Bool = false) {
        do {
            if let category {
                clusters = try Queries.getClusters(category: category)
                unclusteredItems = try Queries.getUnclusteredItems(category: category)
                items = try Queries.getItems(category: category, done: showDone ? true : nil)
            } else {
                items = try Queries.getItems(done: showDone ? true : nil)
                clusters = []
                unclusteredItems = []
            }
        } catch {}
    }

    func loadCompleted() {
        do {
            items = try Queries.getItems(done: true)
            clusters = []
            unclusteredItems = []
        } catch {}
    }

    func loadResources() {
        do {
            items = try Queries.getItems(category: .resource, done: false)
            clusters = try Queries.getClusters(category: .resource)
            unclusteredItems = try Queries.getUnclusteredItems(category: .resource)
        } catch {}
    }

    func search(query: String) {
        guard !query.isEmpty else { return }
        do {
            items = try Queries.searchItems(query: query)
            clusters = []
            unclusteredItems = []
        } catch {}
    }

    func toggleComplete(item: Item) {
        do {
            if item.done {
                try Queries.uncompleteItem(id: item.id)
            } else {
                try Queries.completeItem(id: item.id)
            }
        } catch {}
    }

    func deleteItem(id: String) {
        try? Queries.deleteItem(id: id)
    }
}
