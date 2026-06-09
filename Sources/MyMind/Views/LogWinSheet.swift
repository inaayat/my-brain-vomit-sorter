import SwiftUI

struct LogWinSheet: View {
    let item: Item
    let onSave: (String?, String?) -> Void
    let onSkip: () -> Void

    @State private var artifact = ""
    @State private var valueAdd = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                    .font(.inter(17, weight: .semibold))
                Text("Log Win")
                    .font(.inter(15, weight: .semibold))
                Spacer()
                Button("Skip") {
                    onSkip()
                    dismiss()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .controlSize(.small)
            }

            Text(item.text)
                .font(.inter(13))
                .foregroundStyle(.secondary)
                .lineLimit(2)

            VStack(alignment: .leading, spacing: 6) {
                Text("Artifact")
                    .font(.inter(11))
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                TextField("Link to PR, doc, dashboard...", text: $artifact)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Value Add")
                    .font(.inter(11))
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                TextField("What did completing this achieve?", text: $valueAdd)
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                Spacer()
                Button("Save Win") {
                    onSave(
                        artifact.trimmingCharacters(in: .whitespaces).isEmpty ? nil : artifact,
                        valueAdd.trimmingCharacters(in: .whitespaces).isEmpty ? nil : valueAdd
                    )
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.yellow)
                .controlSize(.regular)
                .disabled(artifact.trimmingCharacters(in: .whitespaces).isEmpty && valueAdd.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 380)
    }
}
