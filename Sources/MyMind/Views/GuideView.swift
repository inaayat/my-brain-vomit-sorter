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
                    guideBullet(icon: "brain.head.profile", text: "Menu bar brain icon → Add Note, Add Action, or Open MyMind")
                    guideBullet(icon: "keyboard", text: "Ctrl+Option+N opens the Daily Dump notepad from anywhere")
                    guideBullet(icon: "keyboard", text: "Ctrl+Option+A opens the quick action capture from anywhere")
                    guideBullet(icon: "hand.draw", text: "Drag one item onto another to create a Cluster")
                    guideBullet(icon: "cursorarrow.click.2", text: "Double-click any card to edit inline (text, category, priority, due date)")
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
                    guideText("Your achievement log — builds a brag doc over time.")
                    guideBullet(icon: "plus", text: "'Log Win' button in the Wins view — record a win directly without completing a task")
                    guideBullet(icon: "checkmark.circle", text: "Completing any item also prompts you to log a win")
                    guideBullet(icon: "link", text: "Attach an artifact URL (PR, doc, slide deck) to any win")
                    guideBullet(icon: "sparkles", text: "AI Analyze in Daily Dump can also suggest wins from your notes")
                }

                guideSection(title: "Daily Dump", color: Theme.purple) {
                    guideText("A freeform daily notepad for brain-dumping throughout the day.")
                    guideBullet(icon: "list.bullet.rectangle.portrait", text: "Sidebar icon opens the full notepad view")
                    guideBullet(icon: "keyboard", text: "Ctrl+Option+N or menu bar → 'Add Note' for quick bullet entry")
                    guideBullet(icon: "number", text: "Type #tag-name or start with * for auto-bullets")
                    guideBullet(icon: "magnifyingglass", text: "Filter tags with the search field (appears with 8+ tags)")
                    guideBullet(icon: "hand.tap", text: "Click a tag pill to filter bullets; double-click to rename it everywhere")
                    guideBullet(icon: "arrow.triangle.merge", text: "Drag one tag onto another to merge them (fewer bullets → more bullets)")
                    guideBullet(icon: "sparkles", text: "'Analyze with AI' parses into actions, brainstorms, wins, or resources")
                    guideBullet(icon: "tag", text: "AI also suggests tags for untagged bullets — accept with one click")
                    guideBullet(icon: "lock", text: "Past days auto-lock — click 'Unlock' to edit them")
                }

                guideSection(title: "Capture Options", color: Theme.blueDark) {
                    guideText("When typing a new thought, expanded options appear:")
                    guideBullet(icon: "tag", text: "Category pills: Auto, Action, Brainstorm, Resource")
                    guideBullet(icon: "calendar", text: "'Set due date' button — starts blank, click to add, X to clear")
                    guideBullet(icon: "arrow.up", text: "Items due today or tomorrow are auto-promoted to high priority")
                    guideBullet(icon: "link", text: "URL + URL title fields")
                    guideBullet(icon: "rectangle.3.group", text: "Add to cluster (type-to-search)")
                    guideBullet(icon: "bookmark", text: "Link existing resource (dropdown)")
                    guideText("Press Enter to submit. Shift+Enter for a new line.")
                }

                guideSection(title: "Sidebar", color: Theme.textMuted) {
                    guideBullet(icon: "square.grid.2x2", text: "Feed — main view with filter cards")
                    guideBullet(icon: "list.bullet.rectangle.portrait", text: "Daily Dump — freeform notepad with tag search")
                    guideBullet(icon: "rectangle.3.group", text: "Clusters — manage, merge, delete clusters")
                    guideBullet(icon: "checkmark.circle", text: "Completed — all finished items")
                    guideBullet(icon: "trophy.fill", text: "Wins — your achievement log")
                    guideBullet(icon: "brain.head.profile", text: "This guide (you're here)")
                    guideBullet(icon: "switch.2", text: "Bro Mode toggle at the bottom — switches to Apple dark mode aesthetic")
                }

                guideSection(title: "Bro Mode", color: Theme.textMuted) {
                    guideText("Toggle at the bottom of the sidebar switches between the default warm aesthetic and a monochrome Apple dark mode look.")
                    guideBullet(icon: "moon.fill", text: "Uses Apple's native dark mode system colors")
                    guideBullet(icon: "circle.fill", text: "All category colors become uniform grey — only icon shape distinguishes types")
                    guideBullet(icon: "switch.2", text: "Toggle text shows 'bro mode' to activate, 'girls just wanna have fun' to switch back")
                    guideText("Your preference persists across app restarts.")
                }

                guideSection(title: "AI Setup", color: Theme.textMuted) {
                    guideText("AI categorizes items and names clusters. Powered by local Ollama (free, private, no API key).")
                    guideText("Install: brew install ollama && ollama pull llama3.2")
                    guideText("Run: ollama serve (or launch the Ollama Mac app)")
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
