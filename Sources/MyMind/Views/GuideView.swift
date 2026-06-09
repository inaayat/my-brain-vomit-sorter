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
                    Text("Your personal thought capture and organization tool.")
                        .font(.inter(14))
                        .foregroundStyle(Theme.textMuted)
                }

                guideSection(title: "Quick Start", color: Theme.purple) {
                    guideBullet(icon: "plus.bubble.fill", text: "Type in the capture bar at the top of Overview to add any thought")
                    guideBullet(icon: "wand.and.stars", text: "AI auto-categorizes into Actions, Brainstorms, or Resources")
                    guideBullet(icon: "keyboard", text: "Press Ctrl+Option+M from anywhere for the floating capture overlay")
                    guideBullet(icon: "hand.draw", text: "Drag one item onto another to create a Cluster")
                }

                guideSection(title: "Overview", color: Theme.textPrimary) {
                    guideText("Your dashboard. Stat cards show counts per category (click to navigate). Below: your items grouped by type with clusters inline.")
                }

                guideSection(title: "Actions", color: Theme.greenDark) {
                    guideText("Concrete tasks. Each has a checkbox on the right \u{2014} click to complete. On completion you can 'Log Win' to record the achievement.")
                }

                guideSection(title: "Brainstorms", color: Theme.pinkDark) {
                    guideText("Ideas, observations, questions. Auto-clustered by AI into themed groups. Drag items onto each other to manually cluster.")
                }

                guideSection(title: "Resources", color: Theme.blueDark) {
                    guideText("URLs and links. When you add a URL to any item, a Resource is auto-created. Shows the URL title (display name) with a clickable link.")
                }

                guideSection(title: "Clusters", color: Theme.yellowDark) {
                    guideText("Groups of related items across any category. Create by dragging items together. Click the title to rename. Expand/collapse with the chevron. Merge clusters from the Clusters page.")
                }

                guideSection(title: "Wins", color: Theme.yellowDark) {
                    guideText("Your brag doc. When completing a task, log what you achieved + link to an artifact (PR, doc, etc). Builds over time for reviews and 1:1s.")
                }

                guideSection(title: "Shortcuts", color: Theme.textMuted) {
                    shortcutRow(keys: "Ctrl + Option + M", description: "Floating capture overlay from anywhere")
                }

                guideSection(title: "AI Setup", color: Theme.textMuted) {
                    guideText("Add your Anthropic key to ~/.my-mind/config.json:")
                    Text("{\"apiKey\": \"sk-ant-...\"}")
                        .font(.inter(11))
                        .foregroundStyle(Theme.textMuted)
                        .padding(8)
                        .background(Theme.softGray, in: RoundedRectangle(cornerRadius: 6))
                    guideText("Or install Ollama for free local AI: brew install ollama && ollama pull llama3.2")
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
