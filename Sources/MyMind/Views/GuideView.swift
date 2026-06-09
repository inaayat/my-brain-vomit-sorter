import SwiftUI

struct GuideView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 28))
                            .foregroundStyle(Theme.pink)
                        Text("my-mind")
                            .font(.inter(28, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    Text("Your personal thought capture and organization tool, powered by AI.")
                        .font(.inter(14))
                        .foregroundStyle(Theme.textMuted)
                }

                // Quick Start
                guideSection(title: "Quick Start", color: Theme.purple) {
                    guideBullet(icon: "plus.bubble.fill", text: "Type in \"Capture a thought...\" to add anything — tasks, ideas, links, notes")
                    guideBullet(icon: "wand.and.stars", text: "AI auto-categorizes, cleans your text, and groups related items into clusters")
                    guideBullet(icon: "keyboard", text: "Press Ctrl+Option+M from anywhere to open the quick capture overlay")
                }

                // Sections
                guideSection(title: "Overview", color: Theme.textPrimary) {
                    guideText("Your dashboard. Shows stat cards for each category, the inline capture bar, and recent items from all sections at a glance. Click any stat card to jump to that section.")
                }

                guideSection(title: "Actions", color: Theme.greenDark) {
                    guideText("Concrete tasks and to-dos. Each has a checkbox to mark complete. When you complete an action, you'll be prompted to \"Log Win\" — record what you achieved and link to an artifact (PR, doc, etc).")
                }

                guideSection(title: "Brainstorms", color: Theme.pinkDark) {
                    guideText("Ideas, musings, observations, questions. These get auto-clustered by AI into themed groups. Great for capturing random thoughts that may connect later.")
                }

                guideSection(title: "Revisit", color: Theme.yellowDark) {
                    guideText("Things to come back to later — topics to research, decisions to reconsider, items that aren't actionable yet but shouldn't be forgotten.")
                }

                guideSection(title: "Resources", color: Theme.blueDark) {
                    guideText("URLs, links, and references. Any item with a URL shows here — the link is displayed prominently with the domain extracted. Good for articles, docs, and tools to remember.")
                }

                guideSection(title: "Clusters", color: Theme.purple) {
                    guideText("AI groups related items automatically. The Clusters view lets you browse all clusters, rename them, merge similar ones, delete unused ones, or manually assign unclustered items to a group.")
                }

                guideSection(title: "Wins", color: Theme.yellowDark) {
                    guideText("Your brag doc. When you complete a task, log what you achieved and link to the artifact. Over time this builds a record of your impact — great for reviews and 1:1s.")
                }

                guideSection(title: "Ask AI", color: Theme.purple) {
                    guideText("Ask questions about everything you've stored. \"What tasks are overdue?\", \"Summarize my brainstorms about auth\", \"What did I capture last week?\" — the AI searches across all your items to answer.")
                }

                // AI Features
                guideSection(title: "AI Features", color: Theme.pinkDark) {
                    guideBullet(icon: "tag.fill", text: "Auto-categorize: AI picks the right category, generates tags, and cleans up your text")
                    guideBullet(icon: "rectangle.3.group", text: "Auto-cluster: Related items get grouped together with an AI-generated title and summary")
                    guideBullet(icon: "magnifyingglass", text: "Ask AI: Full-text question answering over all your stored items")
                    guideBullet(icon: "star.fill", text: "Log Win: Prompted after completing tasks to build your achievement record")
                }

                // Keyboard Shortcuts
                guideSection(title: "Shortcuts", color: Theme.textSecondary) {
                    shortcutRow(keys: "Ctrl + Option + M", description: "Open quick capture overlay from anywhere")
                    shortcutRow(keys: "Cmd + N", description: "Jump to capture bar")
                }

                // Config
                guideSection(title: "Setup", color: Theme.textMuted) {
                    guideText("AI features require an Anthropic API key. Add it to:")
                    Text("~/.my-mind/config.json")
                        .font(.inter(12, weight: .medium))
                        .padding(8)
                        .background(Theme.softGray, in: RoundedRectangle(cornerRadius: 6))
                    Text("{\"apiKey\": \"sk-ant-...\"}")
                        .font(.inter(11))
                        .foregroundStyle(Theme.textMuted)
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

    private func shortcutRow(keys: String, description: String) -> some View {
        HStack(spacing: 12) {
            Text(keys)
                .font(.inter(11, weight: .semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Theme.softGray, in: RoundedRectangle(cornerRadius: 4))
            Text(description)
                .font(.inter(12))
                .foregroundStyle(Theme.textSecondary)
        }
    }
}
