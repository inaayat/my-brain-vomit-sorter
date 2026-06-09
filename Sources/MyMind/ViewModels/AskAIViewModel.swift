import Foundation

struct AskExchange: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

@Observable
final class AskAIViewModel {
    var question = ""
    var currentAnswer = ""
    var isLoading = false
    var history: [AskExchange] = []

    let presets = [
        "What should I focus on today? Consider priorities and what's been sitting the longest.",
        "What tasks have I been avoiding or deferring? Be honest.",
        "Summarize my brainstorms and identify the most promising patterns or ideas.",
        "What are my North Star goals and how well are my current actions aligned with them?"
    ]

    let presetLabels = [
        "What to focus on?",
        "What am I deferring?",
        "Brainstorm patterns",
        "Goals alignment"
    ]

    func ask() {
        let q = question.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty, !isLoading else { return }
        isLoading = true
        currentAnswer = ""

        Task {
            do {
                let answer = try await AIService.ask(question: q)
                await MainActor.run {
                    self.currentAnswer = answer
                    self.history.insert(AskExchange(question: q, answer: answer), at: 0)
                    self.question = ""
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.currentAnswer = "Error: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }

    func askPreset(_ preset: String) {
        question = preset
        ask()
    }
}
