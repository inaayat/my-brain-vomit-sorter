import SwiftUI

struct EditSheet: View {
    @Bindable var appState: AppState
    @Environment(\.dismiss) private var dismiss
    let item: Item

    @State private var text: String = ""
    @State private var selectedCategory: Category = .brainstorm
    @State private var dueDate: Date = Date()
    @State private var hasDueDate = false
    @State private var urlText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Edit item")
                .font(.inter(15, weight: .semibold))

            TextEditor(text: $text)
                .font(.inter(14))
                .frame(minHeight: 80, maxHeight: 120)
                .padding(4)
                .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 6) {
                Text("CATEGORY")
                    .font(.inter(10))
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    PillButton(label: "Brainstorm", isSelected: selectedCategory == .brainstorm) { selectedCategory = .brainstorm }
                    PillButton(label: "Action", isSelected: selectedCategory == .action) { selectedCategory = .action }
                    PillButton(label: "Revisit", isSelected: selectedCategory == .revisit) { selectedCategory = .revisit }
                    PillButton(label: "Resource", isSelected: selectedCategory == .resource) { selectedCategory = .resource }
                }
            }

            HStack {
                Toggle("Due date", isOn: $hasDueDate)
                    .controlSize(.small)
                if hasDueDate {
                    DatePicker("", selection: $dueDate, displayedComponents: .date)
                        .labelsHidden()
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("LINK OR RESOURCE (optional)")
                    .font(.inter(10))
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                TextField("Paste a URL...", text: $urlText)
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.escape)
                Button("Save") { save() }
                    .buttonStyle(.borderedProminent)
                    .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
                    .keyboardShortcut(.return, modifiers: .command)
            }
        }
        .padding(20)
        .frame(width: 440)
        .onAppear {
            text = item.text
            selectedCategory = item.category
            hasDueDate = item.dueDate != nil
            dueDate = item.dueDate ?? Date()
            urlText = item.url ?? ""
        }
    }

    private func save() {
        var updated = item
        updated.text = text.trimmingCharacters(in: .whitespaces)
        updated.category = selectedCategory
        updated.dueDate = hasDueDate ? dueDate : nil
        updated.url = urlText.isEmpty ? nil : urlText
        try? Queries.updateItem(updated)
        appState.refreshCounts()
        dismiss()
    }
}
