import SwiftUI

struct ClusterCardView: View {
    let cluster: Cluster
    var onTap: () -> Void
    var onDropItem: ((String) -> Void)?
    var onChanged: (() -> Void)?
    var onItemComplete: ((String) -> Void)?
    var onItemTap: ((String) -> Void)?

    @State private var isDropTarget = false
    @State private var isEditing = false
    @State private var editTitle = ""
    @State private var isExpanded = true

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Left: cluster title box
            VStack(spacing: 4) {
                if isEditing {
                    TextField("Name", text: $editTitle)
                        .font(.inter(11, weight: .semibold))
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 110)
                        .onSubmit { saveTitle() }
                    Button("Done") { saveTitle() }
                        .font(.inter(9))
                        .controlSize(.small)
                } else {
                    Text(cluster.title)
                        .font(.inter(11, weight: .semibold))
                        .foregroundStyle(Theme.yellowDark)
                        .lineLimit(3)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .frame(width: 110)
                        .background(Color(hex: "#FBF5E3"), in: RoundedRectangle(cornerRadius: 10))
                        .onTapGesture(count: 2) {
                            withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
                        }
                        .onTapGesture(count: 1) {
                            editTitle = cluster.title
                            isEditing = true
                        }
                }
            }

            // Right: items with connector lines
            if isExpanded && !cluster.items.isEmpty {
                HStack(alignment: .top, spacing: 0) {
                    // Vertical + horizontal connector lines
                    VStack(spacing: 0) {
                        ForEach(Array(cluster.items.enumerated()), id: \.element.id) { index, _ in
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 12, height: 1)
                                .frame(height: 44, alignment: .center)
                        }
                    }
                    .overlay(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 1)
                            .padding(.top, 22)
                            .padding(.bottom, 22)
                    }

                    // Item cards
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(cluster.items) { item in
                            itemRow(item)
                        }
                    }
                }
            }
        }
        .padding(8)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isDropTarget ? Theme.purple : Color.clear, lineWidth: isDropTarget ? 2 : 0)
        )
        .dropDestination(for: String.self) { droppedIds, _ in
            guard let draggedId = droppedIds.first else { return false }
            onDropItem?(draggedId)
            return true
        } isTargeted: { targeted in
            isDropTarget = targeted
        }
    }

    @ViewBuilder
    private func itemRow(_ item: Item) -> some View {
        HStack(spacing: 8) {
            CategoryBadge(category: item.category)
            Button { onItemTap?(item.id) } label: {
                Text(item.category == .resource ? (item.urlTitle ?? item.text) : item.text)
                    .font(.inter(12))
                    .foregroundStyle(item.done ? Theme.textMuted : Theme.textPrimary)
                    .lineLimit(2)
                    .strikethrough(item.done)
                    .multilineTextAlignment(.leading)
            }
            .buttonStyle(.plain)
            Spacer()
            // Priority
            Button {
                var updated = item
                switch item.priority {
                case .medium, .low: updated.priority = .high
                case .high: updated.priority = .backlog
                case .backlog: updated.priority = .medium
                }
                try? Queries.updateItem(updated)
                onChanged?()
            } label: {
                Image(systemName: item.priority.isBacklog ? "arrow.down" : "arrow.up")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(item.priority.isHigh || item.priority.isBacklog ? .white : Theme.textMuted)
                    .frame(width: 20, height: 20)
                    .background(item.priority.isHigh ? Theme.pink : (item.priority.isBacklog ? Theme.yellow : Theme.softGray), in: Circle())
            }
            .buttonStyle(.plain)
            // Decluster
            Button {
                try? Queries.removeFromCluster(itemId: item.id)
                onChanged?()
            } label: {
                Text("Decluster")
                    .font(.inter(9, weight: .medium))
                    .foregroundStyle(Theme.textMuted)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Theme.softGray, in: Capsule())
            }
            .buttonStyle(.plain)
            // Complete
            Button { onItemComplete?(item.id) } label: {
                Circle()
                    .strokeBorder(item.done ? Theme.greenDark : Theme.textMuted, lineWidth: 2)
                    .background(item.done ? Circle().fill(Theme.green) : nil)
                    .frame(width: 16, height: 16)
                    .overlay {
                        if item.done {
                            Image(systemName: "checkmark")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(itemBackground(item.category), in: RoundedRectangle(cornerRadius: 8))
    }

    private func itemBackground(_ category: Category) -> Color {
        switch category {
        case .action: return Color(hex: "#EAF2D9")
        case .brainstorm: return Color(hex: "#FBEAF1")
        case .revisit: return Color(hex: "#FBF5E3")
        case .resource: return Color(hex: "#EEF3FB")
        }
    }

    private func saveTitle() {
        let title = editTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }
        try? Queries.renameCluster(id: cluster.id, title: title)
        isEditing = false
        onChanged?()
    }
}
