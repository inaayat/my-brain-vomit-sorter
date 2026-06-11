# my-mind

A native macOS SwiftUI personal knowledge management app. Capture thoughts, track actions, brainstorm ideas, save resources, cluster related items, and log wins.

---

## What It Does

**my-mind** is a single-window desktop app for capturing everything floating in your head and turning it into organized, actionable work.

### Use Cases
- **Brain dump**: Open the Daily Dump notepad and type freely throughout the day. Tag bullets with `#project-name` for instant organization.
- **Task tracking**: Capture action items — AI auto-categorizes them. Set due dates (auto-promotes to high priority when due). Complete and log wins.
- **Idea parking**: Brainstorms get auto-clustered by topic. Drag items together to group manually.
- **Resource saving**: Paste URLs and they're automatically categorized and linked to relevant items.
- **Achievement log**: Every completed task prompts a "win" entry — builds a brag doc over time.
- **Daily review**: Hit "Analyze with AI" on your dump and it proposes actions, brainstorms, wins, and resources to save.

### How It Works
1. Type in the capture bar → AI categorizes and clusters it
2. Use the Daily Dump for freeform brain-dumping → analyze later
3. Set due dates → items auto-promote to high priority when due
4. Complete actions → log wins with artifact URLs
5. Everything is local (SQLite) and private (AI runs via local Ollama)

---

## Install

One command — clones, builds, and installs the app:

```bash
curl -fsSL https://raw.githubusercontent.com/inaayat/my-brain-vomit-sorter/main/install.sh | bash
```

### Requirements
- macOS 14 (Sonoma) or later
- Xcode Command Line Tools (the script will prompt you to install if missing)

The installer will:
1. Clone the repo to `~/my-mind`
2. Build a release binary
3. Create the app bundle at `/Applications/MyMind.app`
4. Optionally set up launch-at-login
5. Optionally pull Ollama's llama3.2 model for free local AI

### After install: Grant Accessibility (for global hotkey)
1. System Settings > Privacy & Security > Accessibility
2. Click + and add `/Applications/MyMind.app`
3. Restart the app

---

## AI Setup (Optional)

AI powers auto-categorization, clustering, and dump analysis. Runs entirely local via Ollama — free, private, no API key needed.

1. Download Ollama from [ollama.com](https://ollama.com) and install the Mac app
2. Pull the model:
```bash
ollama pull llama3.2
```
3. Make sure Ollama is running (`ollama serve` or launch the Mac app)

The app connects to Ollama at `localhost:11434`. If Ollama isn't running, AI features are simply skipped — everything else works normally.

---

## Features

### Core
| Feature | Description |
|---------|-------------|
| **Capture** | Inline text field at top of Overview. Type a thought, hit enter. AI categorizes it. |
| **Actions** | Tasks with checkboxes. Complete them from any view. Log a "Win" on completion. |
| **Brainstorms** | Ideas and observations. Auto-clustered by AI into themed groups. |
| **Resources** | URLs with display titles. Attach multiple resources to any action or brainstorm. |
| **Notes** | Rich notes field on any item. Auto-expands up to 50% of the detail panel. |
| **Clusters** | Drag one item onto another to create a group. AI names it. Expand/collapse. |
| **Daily Dump** | Freeform daily notepad. Auto-dated, bullet-pointed. Use `#tags` to organize. AI parses into action items. |
| **Due Dates** | Set optional due dates on any item. Badge shows next to text (red overdue, orange today/tomorrow). Items due today/tomorrow auto-promote to high priority. |
| **Wins** | Achievement log. Log wins directly from the Wins view, on task completion, or via AI Analyze. Attach artifact URLs. |
| **Completed** | All done items across all categories. |

### Daily Dump
- **Sidebar tab**: Full notepad view with today's editor, past days (read-only with unlock), and tag search
- **Floating panel**: `Ctrl+Option+N` or menu bar → "Add Note" — quick-append a bullet to today's dump
- **Auto-bullets**: Every line starts with "•" automatically (also triggered by typing `*`)
- **#Tags**: Type `#project-name` inline to tag bullets. All tags appear as clickable pills for filtering
- **Tag search/filter**: Search field appears when you have 8+ tags — type to narrow the list
- **Tag rename**: Double-click any tag pill to rename it — applies the change across all days
- **Tag merge**: Drag one tag onto another to merge them (the tag with fewer bullets takes the name of the larger one)
- **Tag click**: Single-click a tag pill to see all bullets with that tag across all days
- **AI Analyze**: Parses your dump into proposed actions, brainstorms, wins, or resources — review and accept individually
- **AI Tag Suggestions**: Analyze also suggests `#tags` for untagged bullets based on patterns — accept with one click

### AI Features (via local Ollama)
- **Auto-categorize**: On every capture (Auto mode), AI picks category (action/brainstorm/resource), cleans text, and generates tags
- **Auto-cluster**: After saving, AI assigns the item to an existing cluster or creates a new one with a generated title
- **Drag-to-cluster title**: When you drag two items together, AI names the new cluster
- **Dump analysis**: AI parses daily dump into actions, brainstorms, wins, and resources + suggests tags for untagged bullets
- **Notes analysis**: Save notes on any item → AI suggests follow-up actions and brainstorm ideas you can add with one click
- **100% local**: All AI runs through Ollama (llama3.2) on your machine — no data leaves your computer

### UX
- **Menu bar**: Brain icon in the menu bar with "Add Note", "Add Action", and "Open MyMind"
- **Global hotkeys**: `Ctrl+Option+N` (Add Note), `Ctrl+Option+A` (Add Action) — requires Accessibility permission
- **Inline editing**: Double-click any card to edit text, category, priority, and due date directly
- **Detail panel**: Click any item → slides in from the right (40% width)
- **Resource linking**: Paste a URL or search existing resources to attach them to any item; link icon shows on cards
- **Log Win on complete**: Completing any item (from feed, clusters, or detail) prompts you to record your achievement
- **Drag & drop**: Drag items onto each other to cluster them
- **Bro Mode**: Toggle at the bottom of the sidebar switches to Apple's native dark mode aesthetic — monochrome, no category colors, same rounded card shapes. Preference persists across restarts.
- **Inter font**: Clean typography throughout

---

## Data Storage

All data is local:
- **Database**: `~/.my-mind/mind.db` (SQLite)

This is NOT in the git repo — it's personal to each device.

---

## Updating the App

When new changes are pushed to GitHub, pull and rebuild:

```bash
cd ~/my-mind
git pull
swift build -c release
cp .build/arm64-apple-macosx/release/MyMind /Applications/MyMind.app/Contents/MacOS/MyMind
cp -R .build/arm64-apple-macosx/release/MyMind_MyMind.bundle /Applications/MyMind.app/Contents/MacOS/
```

Then relaunch the app. Your data in `~/.my-mind/mind.db` is unaffected by updates.

---

## Pushing Changes to GitHub

After making changes to the code:

```bash
cd ~/my-mind

# See what changed
git status
git diff

# Stage and commit
git add -A
git commit -m "Description of what you changed"

# Push to GitHub
git push
```

### Quick one-liner to commit + push:
```bash
cd ~/my-mind && git add -A && git commit -m "Update app" && git push
```

### After rebuilding, update the installed app:
```bash
cd ~/my-mind
swift build -c release
cp .build/arm64-apple-macosx/release/MyMind /Applications/MyMind.app/Contents/MacOS/MyMind
cp -R .build/arm64-apple-macosx/release/MyMind_MyMind.bundle /Applications/MyMind.app/Contents/MacOS/
```

---

## Project Structure

```
my-mind/
├── Package.swift              # Dependencies (GRDB)
├── Sources/MyMind/
│   ├── MyMindApp.swift        # App entry point, menu bar, window management
│   ├── HotkeyManager.swift   # Global hotkeys (Ctrl+Option+N, Ctrl+Option+A)
│   ├── QuickCapturePanel.swift # Floating capture overlay (legacy)
│   ├── QuickActionPanel.swift  # Floating "Add Action" panel
│   ├── DailyDumpPanel.swift    # Floating "Add Note" panel for daily dump
│   ├── FontLoader.swift       # Inter font registration
│   ├── Models/                # Data models (Item, Cluster, Comment, Link, Win, DailyDump)
│   ├── Database/              # SQLite via GRDB (migrations, queries)
│   ├── AI/                    # Anthropic API + Ollama fallback
│   ├── ViewModels/            # Observable state management
│   └── Views/                 # All SwiftUI views (incl. DailyDumpView)
└── Resources/                 # Inter font files (.ttf)
```

---

## Color Palette

| Element | Hex |
|---------|-----|
| Canvas background | `#F5EFE6` |
| Action cards | `#EAF2D9` |
| Brainstorm cards | `#FBEAF1` |
| Resource cards | `#EEF3FB` |
| Cluster cards | `#FBF5E3` |
| Sidebar | `#0F0F10` |
| Accent (purple) | `#A75A8A` |
