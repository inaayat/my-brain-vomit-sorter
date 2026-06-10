import SwiftUI

struct ItemCardView: View {
    let item: Item
    var compact: Bool = false
    var resourceCount: Int = 0
    var onTap: () -> Void
    var onComplete: (() -> Void)?
    var onDrop: ((String) -> Void)?
    var onChange: (() -> Void)?
    var onDelete: (() -> Void)?
    @State private var isDropTarget = false

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            // Draggable content: badge + text — tap opens detail panel
            dragContent
                .draggable(item.id)

            Spacer()

            PriorityPicker(item: item, onChange: { onChange?() })

            if resourceCount > 0 {
                Image(systemName: "link")
                    .font(.inter(10))
                    .foregroundStyle(Theme.blueDark)
            }

            if item.clusterId != nil {
                Button {
                    try? Queries.removeFromCluster(itemId: item.id)
                    onChange?()
                } label: {
                    Text("Decluster")
                        .font(.inter(9, weight: .medium))
                        .foregroundStyle(Theme.textMuted)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.softGray, in: Capsule())
                }
                .buttonStyle(.plain)
            }

            Button {
                onComplete?()
            } label: {
                Circle()
                    .strokeBorder(item.done ? Theme.greenDark : Theme.textMuted, lineWidth: 2)
                    .background(item.done ? Circle().fill(Theme.green) : nil)
                    .frame(width: 22, height: 22)
                    .overlay {
                        if item.done {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 10))
        .contentShape(RoundedRectangle(cornerRadius: 10))
        .onTapGesture {
            onTap()
        }
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(isDropTarget ? Theme.purple : Color.clear, lineWidth: 2)
        )
        .dropDestination(for: String.self) { droppedIds, _ in
            guard let draggedId = droppedIds.first, draggedId != item.id else { return false }
            onDrop?(draggedId)
            return true
        } isTargeted: { targeted in
            isDropTarget = targeted
        }
    }

    private var dragContent: some View {
        HStack(alignment: .center, spacing: 10) {
            CategoryBadge(category: item.category)

            VStack(alignment: .leading, spacing: 3) {
                Text(displayText)
                    .font(.inter(13))
                    .foregroundStyle(item.done ? Theme.textMuted : Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .strikethrough(item.done)
                    .multilineTextAlignment(.leading)
                if item.category == .resource, let url = item.url, !url.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 8))
                        Text(URL(string: url)?.host?.replacingOccurrences(of: "www.", with: "") ?? url)
                            .lineLimit(1)
                    }
                    .font(.inter(10))
                    .foregroundStyle(Theme.blueDark)
                }
            }
        }
        .contentShape(Rectangle())
    }

    private var displayText: String {
        if item.category == .resource, let title = item.urlTitle, !title.isEmpty {
            return title
        }
        return item.text
    }

    private var cardBackground: Color {
        switch item.category {
        case .action: return Color(hex: "#EAF2D9")
        case .brainstorm: return Color(hex: "#FBEAF1")
        case .revisit: return Color(hex: "#FBF5E3")
        case .resource: return Color(hex: "#EEF3FB")
        }
    }

}

struct CategoryBadge: View {
    let category: Category

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: 24, height: 24)
            .background(tint.opacity(0.5), in: RoundedRectangle(cornerRadius: 6))
    }

    private var icon: String {
        switch category {
        case .action: return "bolt.fill"
        case .brainstorm: return "cloud.bolt.fill"
        case .revisit: return "arrow.counterclockwise"
        case .resource: return "link"
        }
    }

    private var color: Color {
        switch category {
        case .action: return Theme.greenDark
        case .brainstorm: return Theme.pinkDark
        case .revisit: return Theme.yellowDark
        case .resource: return Theme.blueDark
        }
    }

    private var tint: Color {
        switch category {
        case .action: return Theme.greenTint
        case .brainstorm: return Theme.pinkTint
        case .revisit: return Theme.yellowTint
        case .resource: return Theme.blueTint
        }
    }
}

struct TagBadge: View {
    let tag: String

    var body: some View {
        Text(tag)
            .font(.inter(9, weight: .medium))
            .foregroundStyle(Theme.textMuted)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(Theme.softGray, in: RoundedRectangle(cornerRadius: 4))
    }
}
