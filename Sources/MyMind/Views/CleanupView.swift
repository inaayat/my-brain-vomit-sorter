import SwiftUI

struct CleanupView: View {
    @Bindable var appState: AppState
    @State private var groups: [ResolvedGroup] = []
    @State private var isScanning = false
    @State private var hasScanned = false

    struct ResolvedGroup: Identifiable {
        let id = UUID()
        let itemIds: [String]
        let items: [Item]
        let reason: String
        let mergedText: String
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                if isScanning { scanningState }
                else if hasScanned && groups.isEmpty { noRedundancies }
                else if !groups.isEmpty { groupsList }
                else { readyState }
            }
            .padding(28)
        }
        .background(Theme.bg)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("AI Cleanup")
                    .font(.inter(24, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Find and merge redundant items")
                    .font(.inter(12))
                    .foregroundStyle(Theme.textMuted)
            }
            Spacer()
            if !isScanning {
                Button {
                    scan()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                        Text(hasScanned ? "Scan Again" : "Scan for Duplicates")
                    }
                    .font(.inter(12, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.purple)
            }
        }
    }

    private var scanningState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Analyzing your items for redundancies...")
                .font(.inter(13))
                .foregroundStyle(Theme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    private var noRedundancies: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 36))
                .foregroundStyle(Theme.greenDark)
            Text("No redundancies found")
                .font(.inter(14, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            Text("Your items are clean — no duplicates detected.")
                .font(.inter(12))
                .foregroundStyle(Theme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    private var readyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 36))
                .foregroundStyle(Theme.purple.opacity(0.5))
            Text("Click 'Scan for Duplicates' to find redundant items")
                .font(.inter(13))
                .foregroundStyle(Theme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    private var groupsList: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Found \(groups.count) redundancy group\(groups.count == 1 ? "" : "s")")
                .font(.inter(13, weight: .semibold))
                .foregroundStyle(Theme.purple)

            ForEach(Array(groups.enumerated()), id: \.element.id) { index, group in
                groupCard(index: index, group: group)
            }
        }
    }

    @ViewBuilder
    private func groupCard(index: Int, group: ResolvedGroup) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(group.reason)
                .font(.inter(11, weight: .semibold))
                .foregroundStyle(Theme.textMuted)

            ForEach(group.items) { item in
                HStack(spacing: 8) {
                    CategoryBadge(category: item.category)
                    Text(item.text)
                        .font(.inter(12))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(2)
                }
                .padding(.leading, 4)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Suggested merge:")
                    .font(.inter(10, weight: .semibold))
                    .foregroundStyle(Theme.greenDark)
                Text(group.mergedText)
                    .font(.inter(12))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.greenTint.opacity(0.3), in: RoundedRectangle(cornerRadius: 6))
            }

            HStack(spacing: 12) {
                Button {
                    acceptMerge(at: index)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.merge")
                        Text("Accept Merge")
                    }
                    .font(.inter(11, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.greenDark)
                .controlSize(.small)

                Button {
                    withAnimation { _ = groups.remove(at: index) }
                } label: {
                    Text("Keep Both")
                        .font(.inter(11))
                        .foregroundStyle(Theme.textMuted)
                }
                .buttonStyle(.plain)

                Button {
                    deleteDuplicates(at: index)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                        Text("Delete Duplicates")
                    }
                    .font(.inter(11))
                    .foregroundStyle(Theme.pinkDark)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: Theme.radius(10)).fill(Theme.card))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radius(10))
                .strokeBorder(Theme.cardBorder, lineWidth: 1)
        )
    }

    private func scan() {
        isScanning = true
        Task {
            do {
                let allItems = (try? Queries.getAllItems().filter { !$0.done }) ?? []
                let input = allItems.map { (id: $0.id, text: $0.text, category: $0.category.rawValue) }
                let results = try await AIService.findRedundancies(items: input)
                await MainActor.run {
                    groups = results.compactMap { group in
                        let items = group.itemIds.compactMap { id in allItems.first(where: { $0.id == id }) }
                        guard items.count >= 2 else { return nil }
                        return ResolvedGroup(itemIds: group.itemIds, items: items, reason: group.reason, mergedText: group.mergedText)
                    }
                    hasScanned = true
                    isScanning = false
                }
            } catch {
                await MainActor.run {
                    hasScanned = true
                    isScanning = false
                }
            }
        }
    }

    private func acceptMerge(at index: Int) {
        let group = groups[index]
        guard let keepItem = group.items.first else { return }
        try? Queries.updateItemText(id: keepItem.id, text: group.mergedText)
        for item in group.items.dropFirst() {
            try? Queries.deleteItem(id: item.id)
        }
        appState.refreshCounts()
        withAnimation { groups.remove(at: index) }
    }

    private func deleteDuplicates(at index: Int) {
        let group = groups[index]
        for item in group.items.dropFirst() {
            try? Queries.deleteItem(id: item.id)
        }
        appState.refreshCounts()
        withAnimation { groups.remove(at: index) }
    }
}
