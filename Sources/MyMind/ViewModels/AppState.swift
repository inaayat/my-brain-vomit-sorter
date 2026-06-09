import Foundation
import SwiftUI

enum NavigationDestination: Hashable {
    case overview
    case actions
    case brainstorms
    case resources
    case allItems
    case completed
    case wins
    case clusters
    case guide
    case itemDetail(String)
}

@Observable
final class AppState {
    var selectedDestination: NavigationDestination = .overview
    var lastSection: NavigationDestination = .overview

    func navigate(to dest: NavigationDestination) {
        if case .itemDetail(let id) = dest {
            detailPanelItemId = id
        } else {
            lastSection = dest
            selectedDestination = dest
        }
    }
    var counts: [String: Int] = [:]
    var showEditSheet = false
    var showLogWinSheet = false
    var completedItem: Item?
    var editingItem: Item?
    var searchQuery = ""
    var detailPanelItemId: String?

    func refreshCounts() {
        Task {
            do {
                var counts = try Queries.getCategoryCounts()
                counts["wins"] = try Queries.getWinCount()
                let final = counts
                await MainActor.run { self.counts = final }
            } catch {}
        }
    }

    func createClusterFromDrop(draggedId: String, targetId: String) {
        guard draggedId != targetId else { return }
        do {
            let cluster = try Queries.createClusterFromItems(itemIds: [draggedId, targetId])
            // AI rename in background
            Task {
                let items = [try? Queries.getItem(id: draggedId), try? Queries.getItem(id: targetId)].compactMap { $0 }
                let texts = items.map(\.text)
                if let title = try? await AIService.generateClusterTitle(texts: texts) {
                    try? Queries.renameCluster(id: cluster.id, title: title)
                }
            }
        } catch {}
    }

    func addToClusterFromDrop(draggedId: String, clusterId: String) {
        try? Queries.assignToCluster(itemId: draggedId, clusterId: clusterId)
    }
}
