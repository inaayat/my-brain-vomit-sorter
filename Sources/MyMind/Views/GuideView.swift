import SwiftUI

struct GuideView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 28))
                            .foregroundStyle(Theme.pink)
                        Text("my-mind")
                            .font(.inter(28, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    Text("Personal thought capture, organization, and prioritization.")
                        .font(.inter(14))
                        .foregroundStyle(Theme.textMuted)
                }

                guideSection(title: "Quick Start", color: Theme.purple) {
                    guideBullet(icon: "plus.bubble.fill", text: "Type in the capture bar to add a thought — AI auto-categorizes it")
                    guideBullet(icon: "keyboard", text: "Ctrl+Option+M opens the floating capture overlay from anywhere")
                    guideBullet(icon: "hand.draw", text: "Drag one item onto another to create a Cluster")
                    guideBullet(icon: "arrow.up", text: "Click the priority circle to cycle: Standard → High → Backlog")
                }

                guideSection(title: "Feed View", color: Theme.textPrimary) {
                    guideText("The main view shows all open items. Use the filter cards at top to show only Actions, Brainstorms, or Resources. Default opens on Actions.")
                    guideText("'All Open' shows every non-completed, non-resource item as a flat list sorted by priority then category.")
                    guideText("Category filters show clusters inline with their items grouped under the cluster title.")
                }

                guideSection(title: "Item Types", color: Theme.greenDark) {
                    guideBullet(icon: "bolt.fill", text: "Actions — tasks and to-dos. Complete with the checkbox on the right.")
                    guideBullet(icon: "cloud.bolt.fill", text: "Brainstorms — ideas, observations, questions to explore.")
                    guideBullet(icon: "link", text: "Resources — URLs and links. Auto-created when you add a URL to any item.")
                }

                guideSection(title: "Priority", color: Theme.pinkDark) {
                    guideBullet(icon: "arrow.up", text: "High (pink circle) — shows at top of lists")
                    guideBullet(icon: "arrow.up", text: "Standard (gray circle) — normal priority")
                    guideBullet(icon: "arrow.down", text: "Backlog (yellow circle) — shown in separate 'Backlog' section at bottom")
                    guideText("Click the priority button to cycle through states. High-priority items always sort to top.")
                }

                guideSection(title: "Clusters", color: Theme.yellowDark) {
                    guideText("Clusters group related items. Create by dragging one item onto another.")
                    guideBullet(icon: "cursorarrow.click", text: "Single-click cluster title to rename")
                    guideBullet(icon: "cursorarrow.click.2", text: "Double-click cluster title to collapse/expand")
                    guideBullet(icon: "minus.circle", text: "'Decluster' button removes an item from its cluster")
                    guideText("When capturing a new thought, type in the 'Add to cluster...' field to assign directly.")
                }

                guideSection(title: "Wins", color: Theme.yellowDark) {
                    guideText("When you complete any item, you're prompted to 'Log Win' — record what you achieved and link an artifact (URL to PR, doc, etc). Builds your brag doc over time.")
                }

                guideSection(title: "Capture Options", color: Theme.blueDark) {
                    guideText("When typing a new thought, expanded options appear:")
                    guideBullet(icon: "tag", text: "Category pills: Auto, Action, Brainstorm, Resource")
                    guideBullet(icon: "calendar", text: "Due date toggle")
                    guideBullet(icon: "link", text: "URL + URL title fields")
                    guideBullet(icon: "rectangle.3.group", text: "Add to cluster (type-to-search)")
                    guideBullet(icon: "bookmark", text: "Link existing resource (dropdown)")
                }

                guideSection(title: "Sidebar", color: Theme.textMuted) {
                    guideBullet(icon: "square.grid.2x2", text: "Feed — main view with filter cards")
                    guideBullet(icon: "rectangle.3.group", text: "Clusters — manage, merge, delete clusters")
                    guideBullet(icon: "checkmark.circle", text: "Completed — all finished items")
                    guideBullet(icon: "trophy.fill", text: "Wins — your achievement log")
                    guideBullet(icon: "brain.head.profile", text: "This guide (you're here)")
                }

                guideSection(title: "AI Setup", color: Theme.textMuted) {
                    guideText("AI categorizes items and names clusters. Configure in ~/.my-mind/config.json:")
                    Text("{\"apiKey\": \"sk-ant-...\"}")
                        .font(.inter(11))
                        .foregroundStyle(Theme.textMuted)
                        .padding(8)
                        .background(Theme.softGray, in: RoundedRectangle(cornerRadius: 6))
                    guideText("Or use Ollama for free local AI: brew install ollama && ollama pull llama3.2")
                }
            }
            .padding(28)
        }
        .background(Theme.bg)
    }

    @ViewBuilder
    private func guideSection(title: String, color: Color, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.inter(13, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(color, in: Capsule())
            content()
        }
    }

    private func guideText(_ text: String) -> some View {
        Text(text)
            .font(.inter(13))
            .foregroundStyle(Theme.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func guideBullet(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(Theme.purple)
                .frame(width: 16)
            Text(text)
                .font(.inter(13))
                .foregroundStyle(Theme.textSecondary)
        }
    }
}
