import SwiftUI

struct AskAIView: View {
    @State private var vm = AskAIViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Ask AI")
                    .font(.inter(20, weight: .bold))
                    .fontWeight(.bold)
                Text("Ask anything about your thoughts, tasks, and ideas")
                    .font(.inter(11))
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 20)

            presetButtons

            HStack(spacing: 8) {
                TextField("Ask me anything about your brain...", text: $vm.question)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { vm.ask() }
                Button("Ask") { vm.ask() }
                    .buttonStyle(.borderedProminent)
                    .disabled(vm.question.trimmingCharacters(in: .whitespaces).isEmpty || vm.isLoading)
            }

            if vm.isLoading {
                HStack {
                    ProgressView()
                        .controlSize(.small)
                    Text("Thinking...")
                        .font(.inter(11))
                        .foregroundStyle(.secondary)
                }
            } else if !vm.currentAnswer.isEmpty {
                Text(vm.currentAnswer)
                    .font(.inter(13))
                    .textSelection(.enabled)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.indigo.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
                    .overlay(alignment: .leading) {
                        Rectangle().fill(.indigo).frame(width: 3)
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                    }
            }

            if vm.history.count > 1 {
                Divider()
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(vm.history.dropFirst()) { exchange in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(exchange.question)
                                    .font(.inter(11))
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.indigo)
                                Text(exchange.answer)
                                    .font(.inter(11))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(4)
                            }
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 6))
                            .opacity(0.7)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: 600)
    }

    private var presetButtons: some View {
        FlowLayout(spacing: 6) {
            ForEach(Array(zip(vm.presetLabels, vm.presets)), id: \.0) { label, preset in
                Button(label) { vm.askPreset(preset) }
                    .font(.inter(11))
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        for (index, origin) in result.origins.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y), proposal: .unspecified)
        }
    }

    private func computeLayout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, origins: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var origins: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            origins.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), origins)
    }
}
