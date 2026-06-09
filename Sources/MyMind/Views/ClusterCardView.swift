import SwiftUI

struct ClusterCardView: View {
    let cluster: Cluster
    var onTap: () -> Void
    var onDropItem: ((String) -> Void)?
    var onChanged: (() -> Void)?
    var onItemComplete: ((String) -> Void)?
    var onItemTap: ((String) -> Void)?
    var expandAllCounter: Int = 0
    var collapseAllCounter: Int = 0

    @State private var isDropTarget = false
    @State private var isEditing = false
    @State private var editTitle = ""
    @State private var isExpanded = true

    var body: some View {
        Group {
            if isExpanded {
                expandedLayout
            } else {
                collapsedBar
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isExpanded)
        .onChange(of: expandAllCounter) { withAnimation(.easeInOut(duration: 0.25)) { isExpanded = true } }
        .onChange(of: collapseAllCounter) { withAnimation(.easeInOut(duration: 0.25)) { isExpanded = false } }
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

    // MARK: - Collapsed: slim full-width bar
    private var collapsedBar: some View {
        HStack {
            Text(cluster.title)
                .font(.inter(11, weight: .semibold))
                .foregroundStyle(Theme.yellowDark)
            Spacer()
            Image(systemName: "chevron.down")
                .font(.system(size: 9))
                .foregroundStyle(Theme.textMuted)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background(Color(hex: "#FBF5E3"), in: RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            editTitle = cluster.title
            isEditing = true
        }
        .onTapGesture(count: 1) {
            withAnimation(.easeInOut(duration: 0.25)) { isExpanded = true }
        }
    }

    // MARK: - Expanded: title left, items right (tree)
    private var expandedLayout: some View {
        HStack(alignment: .center, spacing: 12) {
            // Left: title box
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
                        .contentShape(Rectangle())
                        .onTapGesture(count: 2) {
                            editTitle = cluster.title
                            isEditing = true
                        }
                        .onTapGesture(count: 1) {
                            withAnimation(.easeInOut(duration: 0.25)) { isExpanded = false }
                        }
                }
            }

            // Connector lines
            if !cluster.items.isEmpty {
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

                // Items
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(cluster.items) { item in
                        itemRow(item)
                    }
                }
            }
        }
        .padding(8)
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
            PriorityPicker(item: item, onChange: { onChanged?() })
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
