import SwiftUI

struct GuideView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Hero
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 28))
                            .foregroundStyle(Theme.pink)
                        Text("my-mind")
                            .font(.inter(28, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    Text("Everything in your head, organized — without changing how you think.")
                        .font(.inter(15))
                        .foregroundStyle(Theme.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // The Idea
                guideSection(title: "The Idea", color: Theme.pink) {
                    guideText("Your brain doesn't think in categories. It jumps between tasks, ideas, links, and random observations — all day long.")
                    guideText("my-mind lets you capture everything as it comes, then sorts it for you. Type freely, and the app figures out what's an action item, what's a brainstorm, and what's just worth saving.")
                    guideText("Over time, your scattered thoughts become organized work — without you ever having to stop and file things manually.")
                }

                // Your Daily Workflow
                guideSection(title: "Your Daily Workflow", color: Theme.purple) {
                    numberedStep(num: "1", title: "Brain dump throughout the day", description: "Open the Daily Dump (sidebar or Ctrl+Option+N) and type whatever's on your mind. Use #tags to mark topics. Don't overthink it — just get it out of your head.")
                    numberedStep(num: "2", title: "Let AI sort it out", description: "Hit 'Analyze with AI' and it proposes action items, brainstorms, and wins from your notes. Change the type, pick a cluster, then accept — or dismiss what's not useful.")
                    numberedStep(num: "3", title: "Work from your feed", description: "The Overview shows your actions sorted by priority. Items due today/tomorrow auto-promote to high. Complete them with the circle button and log your wins.")
                    numberedStep(num: "4", title: "Build knowledge over time", description: "Master Docs let you accumulate notes on a topic across days. Click a tag → Master Doc to start building. AI can synthesize messy notes into a clean document when you're ready.")
                }

                // How to Capture
                guideSection(title: "How to Capture", color: Theme.greenDark) {
                    guideText("There are three ways to get thoughts into the app:")
                    guideBullet(icon: "plus.bubble.fill", text: "Capture bar (top of Feed) — type and hit Enter. AI auto-categorizes it as action, brainstorm, or resource.")
                    guideBullet(icon: "list.bullet.rectangle.portrait", text: "Daily Dump — freeform notepad for stream-of-consciousness. Use #tags inline. Analyze later.")
                    guideBullet(icon: "keyboard", text: "Global hotkeys — Ctrl+Option+N (note) or Ctrl+Option+A (action) from anywhere on your Mac, even when the app is hidden.")
                    guideText("You can also set a due date, assign to a cluster, or attach a URL when capturing from the bar.")
                }

                // Organizing with Clusters
                guideSection(title: "Organizing: Clusters", color: Theme.yellowDark) {
                    guideText("Clusters are groups of related items — like folders, but more flexible.")
                    guideBullet(icon: "hand.draw", text: "Drag one item onto another to create a cluster (AI names it)")
                    guideBullet(icon: "plus.circle", text: "Use the + icon on any cluster to bulk-add unclustered items")
                    guideBullet(icon: "rectangle.3.group", text: "Assign items to clusters when capturing, or when accepting AI proposals")
                    guideText("Think of clusters as projects, themes, or contexts — whatever grouping makes sense to you.")
                }

                // Organizing with Tags
                guideSection(title: "Organizing: Tags", color: Theme.purple) {
                    guideText("Tags work across your Daily Dump bullets. Type #project-name in any bullet and it becomes searchable.")
                    guideBullet(icon: "hand.tap", text: "Click a tag pill to see all bullets with that tag across all days")
                    guideBullet(icon: "cursorarrow.click.2", text: "Double-click a tag pill to rename it everywhere")
                    guideBullet(icon: "arrow.triangle.merge", text: "Drag one tag onto another to merge them")
                    guideBullet(icon: "archivebox", text: "Archive old bullets with the archive icon (reversible)")
                    guideText("Tags and clusters serve different purposes: tags organize your raw notes, clusters organize your processed items.")
                }

                // Master Docs
                guideSection(title: "Master Docs", color: Theme.purple) {
                    guideText("Master Docs are persistent documents you build up over time around a topic — like a wiki page for each area of your work.")
                    guideBullet(icon: "doc.text.fill", text: "Create from the sidebar (Master Docs icon) or from any tag search")
                    guideBullet(icon: "plus.circle", text: "When the doc panel is open, + buttons appear on bullets to add them directly")
                    guideBullet(icon: "sparkles", text: "'AI Synthesize' reorganizes your scattered notes into a clean, structured document")
                    guideBullet(icon: "bold", text: "Formatting toolbar for headings, bold, italic, bullets, quotes, code")
                    guideText("Use case: you add notes about 'quarterly-review' over several weeks. When it's time to prep, hit Synthesize and you have a clean starting point.")
                }

                // AI Features
                guideSection(title: "AI (100% Local)", color: Theme.greenDark) {
                    guideText("All AI runs through Ollama on your machine. Nothing leaves your computer. No API key needed.")
                    guideBullet(icon: "sparkles", text: "Auto-categorize — captures are sorted into action/brainstorm/resource")
                    guideBullet(icon: "rectangle.3.group", text: "Auto-cluster — new items are matched to existing clusters or get a new one")
                    guideBullet(icon: "text.quote", text: "Clarity rewrite — proposed items are cleaned up: full sentences, no filler")
                    guideBullet(icon: "arrow.triangle.merge", text: "Redundancy scan — finds duplicate/overlapping items and suggests merges")
                    guideBullet(icon: "doc.text", text: "Doc synthesis — turns scattered Master Doc notes into structured content")
                    guideText("If Ollama isn't running, everything else works normally — AI features just get skipped.")
                }

                // Wins
                guideSection(title: "Tracking Wins", color: Theme.yellowDark) {
                    guideText("Every time you complete an action, the app asks if you want to log a win. Over time this builds a brag doc — great for reviews, standups, or just feeling good about what you've accomplished.")
                    guideBullet(icon: "trophy.fill", text: "Log wins on completion, directly from the Wins view, or via AI analysis")
                    guideBullet(icon: "link", text: "Attach artifact URLs (PRs, docs, slides) to any win")
                }

                // Keyboard Shortcuts
                guideSection(title: "Keyboard Shortcuts", color: Theme.textMuted) {
                    guideBullet(icon: "keyboard", text: "Ctrl+Option+N — Quick note (Daily Dump bullet)")
                    guideBullet(icon: "keyboard", text: "Ctrl+Option+A — Quick action item")
                    guideBullet(icon: "cursorarrow.click.2", text: "Double-click any card — edit inline")
                    guideBullet(icon: "return", text: "Enter — submit capture / new bullet")
                }

                // Sidebar Map
                guideSection(title: "Sidebar", color: Theme.textMuted) {
                    guideBullet(icon: "square.grid.2x2", text: "Feed — your main workspace. Filter by type, complete items, scan for duplicates.")
                    guideBullet(icon: "list.bullet.rectangle.portrait", text: "Daily Dump — freeform notepad with tags, AI analysis, and Master Doc access.")
                    guideBullet(icon: "rectangle.3.group", text: "Clusters — manage groups. Add items, merge clusters, delete.")
                    guideBullet(icon: "checkmark.circle", text: "Completed — everything you've finished.")
                    guideBullet(icon: "trophy.fill", text: "Wins — your achievement log.")
                    guideBullet(icon: "doc.text.fill", text: "Master Docs — persistent topic documents.")
                    guideBullet(icon: "square.and.arrow.up", text: "Export — download all your data as Markdown.")
                    guideBullet(icon: "switch.2", text: "Bro Mode — monochrome Apple dark aesthetic.")
                }

                // Setup
                guideSection(title: "AI Setup (Optional)", color: Theme.textMuted) {
                    guideText("To enable AI features:")
                    guideBullet(icon: "1.circle", text: "Install Ollama: brew install ollama")
                    guideBullet(icon: "2.circle", text: "Pull the model: ollama pull llama3.2")
                    guideBullet(icon: "3.circle", text: "Run it: ollama serve (or launch the Ollama Mac app)")
                    guideText("That's it. The app connects to localhost:11434 automatically.")
                }
            }
            .padding(28)
        }
        .background(Theme.bg)
    }

    @ViewBuilder
    private func guideSection(title: String, color: Color, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.inter(14, weight: .bold))
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
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func numberedStep(num: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(num)
                .font(.inter(14, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(Theme.purple, in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.inter(13, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(description)
                    .font(.inter(12))
                    .foregroundStyle(Theme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
