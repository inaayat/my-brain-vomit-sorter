import SwiftUI

struct FocusView: View {
    @State private var focusItems: [(item: Item, reason: String)] = []
    @State private var summary = ""
    @State private var isLoading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("AI Focus")
                    .font(.inter(20, weight: .bold))
                    .fontWeight(.bold)
                Spacer()
                Button {
                    loadFocus()
                } label: {
                    Label("Refresh", systemImage: "sparkle")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(isLoading)
            }
            .padding(.top, 20)

            if isLoading {
                ProgressView("Getting focus suggestions...")
                    .font(.inter(11))
            } else if !summary.isEmpty {
                Text(summary)
                    .font(.inter(13))
                    .foregroundStyle(.indigo)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.indigo.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))

                ForEach(focusItems, id: \.item.id) { entry in
                    HStack(spacing: 10) {
                        Button {
                            try? Queries.completeItem(id: entry.item.id)
                            loadFocus()
                        } label: {
                            Circle()
                                .strokeBorder(.indigo, lineWidth: 2)
                                .frame(width: 16, height: 16)
                        }
                        .buttonStyle(.plain)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.item.text)
                                .font(.inter(13))
                            if !entry.reason.isEmpty {
                                Text(entry.reason)
                                    .font(.inter(11))
                                    .foregroundStyle(.indigo)
                                    .italic()
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            } else {
                Text("Click 'Refresh' to get AI-powered focus suggestions for today.")
                    .font(.inter(13))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: 600)
        .onAppear { loadFocus() }
    }

    private func loadFocus() {
        isLoading = true
        Task {
            do {
                let result = try await AIService.getFocusSuggestions()
                await MainActor.run {
                    focusItems = result.items
                    summary = result.summary
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    summary = "Could not load suggestions."
                    isLoading = false
                }
            }
        }
    }
}
