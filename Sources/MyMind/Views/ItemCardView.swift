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
    @State private var isEditing = false
    @State private var editText = ""
    @State private var editDueDate: Date? = nil
    @State private var editCategory: Category = .brainstorm
    @State private var editPriority: Priority = .medium
    @State private var showDatePicker = false

    var body: some View {
        Group {
            if isEditing {
                editingLayout
            } else {
                normalLayout
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: Theme.radius(10)))
        .contentShape(RoundedRectangle(cornerRadius: Theme.radius(10)))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radius(10))
                .strokeBorder(isDropTarget ? Theme.purple : (isEditing ? Theme.purple.opacity(0.6) : Theme.cardBorder), lineWidth: isDropTarget || isEditing ? 2 : 1)
        )
        .dropDestination(for: String.self) { droppedIds, _ in
            guard let draggedId = droppedIds.first, draggedId != item.id else { return false }
            onDrop?(draggedId)
            return true
        } isTargeted: { targeted in
            isDropTarget = targeted
        }
    }

    // MARK: - Normal (read) layout

    private var normalLayout: some View {
        HStack(alignment: .center, spacing: 10) {
            dragContent
                .contentShape(Rectangle())
                .onTapGesture(count: 2) { enterEditMode() }
                .onTapGesture(count: 1) { if !isEditing { onTap() } }
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
                    .background(Circle().fill(item.done ? Theme.green : Color.clear))
                    .frame(width: 22, height: 22)
                    .overlay {
                        if item.done {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(8)
                    .contentShape(Circle().size(width: 38, height: 38))
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
        }
    }

    // MARK: - Editing layout

    private var editingLayout: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                CategoryBadge(category: editCategory)

                TextEditor(text: $editText)
                    .font(.inter(13))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 20, maxHeight: 80)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                Button("Save") { saveEdit() }
                    .font(.inter(11, weight: .semibold))
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.greenDark)
                    .controlSize(.small)

                Button("Cancel") { isEditing = false }
                    .font(.inter(11, weight: .medium))
                    .controlSize(.small)
            }

            HStack(spacing: 12) {
                // Category picker
                HStack(spacing: 4) {
                    PillButton(label: "Action", isSelected: editCategory == .action) { editCategory = .action }
                    PillButton(label: "Brainstorm", isSelected: editCategory == .brainstorm) { editCategory = .brainstorm }
                    PillButton(label: "Resource", isSelected: editCategory == .resource) { editCategory = .resource }
                }

                Divider().frame(height: 16)

                // Priority picker
                Menu {
                    Button { editPriority = .high } label: { Label("High", systemImage: "arrow.up") }
                    Button { editPriority = .medium } label: { Label("Standard", systemImage: "minus") }
                    Button { editPriority = .backlog } label: { Label("Backlog", systemImage: "arrow.down") }
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: editPriority.isHigh ? "arrow.up" : (editPriority.isBacklog ? "arrow.down" : "minus"))
                            .font(.system(size: 8, weight: .bold))
                        Text(editPriority.isHigh ? "High" : (editPriority.isBacklog ? "Backlog" : "Std"))
                            .font(.inter(8, weight: .medium))
                    }
                    .foregroundStyle(editPriority.isHigh || editPriority.isBacklog ? .white : Theme.textMuted)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(editPriority.isHigh ? Theme.pink : (editPriority.isBacklog ? Theme.yellow : Theme.softGray), in: Capsule())
                }
                .menuStyle(.borderlessButton)
                .fixedSize()

                Divider().frame(height: 16)

                // Due date
                HStack(spacing: 4) {
                    Button {
                        if editDueDate == nil { editDueDate = Date() }
                        showDatePicker.toggle()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 10))
                            if let date = editDueDate {
                                Text(date.formatted(.dateTime.month(.abbreviated).day()))
                                    .font(.inter(10, weight: .medium))
                            } else {
                                Text("Due date")
                                    .font(.inter(10))
                            }
                        }
                        .foregroundStyle(editDueDate != nil ? Theme.textPrimary : Theme.textMuted)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Theme.softGray, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showDatePicker) {
                        VStack(spacing: 8) {
                            DatePicker("", selection: Binding(
                                get: { editDueDate ?? Date() },
                                set: { editDueDate = $0 }
                            ), displayedComponents: .date)
                                .labelsHidden()
                                .datePickerStyle(.graphical)
                            Button("Clear") { editDueDate = nil; showDatePicker = false }
                                .font(.inter(11))
                                .foregroundStyle(Theme.pinkDark)
                        }
                        .padding(12)
                    }

                    if editDueDate != nil {
                        Button {
                            editDueDate = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.textMuted)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Due Date Badge

    @ViewBuilder
    private var dueDateBadge: some View {
        if let dueDate = item.dueDate, !item.done {
            let label = dueDateLabel(dueDate)
            let color = dueDateColor

            Text(label)
                .font(.inter(9, weight: .bold))
                .foregroundStyle(color)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(color.opacity(0.12), in: Capsule())
        }
    }

    private func dueDateLabel(_ date: Date) -> String {
        if item.isOverdue {
            let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
            return days == 1 ? "1d overdue" : "\(days)d overdue"
        } else if item.isDueToday {
            return "Due today"
        } else if item.isDueSoon {
            return "Due tomorrow"
        } else {
            return "Due \(date.formatted(.dateTime.month(.abbreviated).day()))"
        }
    }

    private var dueDateColor: Color {
        if item.isOverdue { return Color(hex: "#D32F2F") }
        if item.isDueToday { return Color(hex: "#E65100") }
        if item.isDueSoon { return Color(hex: "#F57C00") }
        return Theme.textMuted
    }

    // MARK: - Helpers

    private func enterEditMode() {
        editText = item.text
        editCategory = item.category
        editPriority = item.priority
        editDueDate = item.dueDate
        isEditing = true
    }

    private func saveEdit() {
        let trimmed = editText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        var updated = item
        updated.text = trimmed
        updated.category = editCategory
        updated.priority = editPriority
        updated.dueDate = editDueDate
        if let due = updated.dueDate {
            let tomorrow = Calendar.current.date(byAdding: .day, value: 2, to: Calendar.current.startOfDay(for: Date()))!
            if due < tomorrow { updated.priority = .high }
        }
        try? Queries.updateItem(updated)
        isEditing = false
        onChange?()
    }

    private var dragContent: some View {
        HStack(alignment: .center, spacing: 10) {
            CategoryBadge(category: item.category)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(displayText)
                        .font(.inter(13))
                        .foregroundStyle(item.done ? Theme.textMuted : Theme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .strikethrough(item.done)
                        .multilineTextAlignment(.leading)
                    dueDateBadge
                }
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
        if Theme.isBro { return Color(nsColor: .controlBackgroundColor) }
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
            .background(tint.opacity(0.5), in: RoundedRectangle(cornerRadius: Theme.radius(6)))
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
            .background(Theme.softGray, in: RoundedRectangle(cornerRadius: Theme.radius(4)))
    }
}
