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
        VStack(alignment: .leading, spacing: 0) {
            // Cluster title — editable
            HStack(spacing: 8) {
                if isEditing {
                    TextField("Cluster name", text: $editTitle)
                        .font(.inter(12, weight: .semibold))
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 200)
                        .onSubmit { saveTitle() }
                    Button("Save") { saveTitle() }
                        .font(.inter(10, weight: .medium))
                        .controlSize(.small)
                    Button("Cancel") { isEditing = false }
                        .font(.inter(10))
                        .controlSize(.small)
                } else {
                    Text(cluster.title)
                        .font(.inter(12, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Theme.purple.opacity(0.12), in: Capsule())
                        .onTapGesture {
                            editTitle = cluster.title
                            isEditing = true
                        }
                    Text("\(cluster.itemCount)")
                        .font(.inter(10))
                        .foregroundStyle(Theme.textMuted)
                }
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Theme.textMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 6)

            // Items connected by a vertical line
            if isExpanded && !cluster.items.isEmpty {
                HStack(alignment: .top, spacing: 0) {
                    // Vertical connector line
                    VStack(spacing: 0) {
                        ForEach(Array(cluster.items.enumerated()), id: \.element.id) { index, _ in
                            Circle()
                                .fill(Theme.purple.opacity(0.5))
                                .frame(width: 6, height: 6)
                            if index < cluster.items.count - 1 {
                                Rectangle()
                                    .fill(Theme.purple.opacity(0.3))
                                    .frame(width: 2, height: 34)
                            }
                        }
                    }
                    .padding(.leading, 20)
                    .padding(.top, 10)

                    // Item pills
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(cluster.items) { item in
                            HStack(spacing: 8) {
                                CategoryBadge(category: item.category)
                                Text(item.text)
                                    .font(.inter(12))
                                    .foregroundStyle(item.done ? Theme.textMuted : Theme.textPrimary)
                                    .lineLimit(2)
                                    .strikethrough(item.done)
                                Spacer()
                                Button {
                                    onItemComplete?(item.id)
                                } label: {
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
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(itemBackground(item.category), in: RoundedRectangle(cornerRadius: 8))
                            .contentShape(Rectangle())
                            .onTapGesture {
                                onItemTap?(item.id)
                            }
                        }
                    }
                    .padding(.leading, 8)
                    .padding(.trailing, 12)
                }
                .padding(.bottom, 10)
            }
        }
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
