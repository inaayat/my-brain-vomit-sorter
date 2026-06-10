# my-mind

A native macOS SwiftUI personal knowledge management app. Capture thoughts, track actions, brainstorm ideas, save resources, cluster related items, and log wins.

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

AI powers auto-categorization and clustering.

### Option A: Anthropic API key
```bash
mkdir -p ~/.my-mind
echo '{"apiKey": "sk-ant-..."}' > ~/.my-mind/config.json
```

### Option B: Local Ollama (recommended, free, no API key needed)
1. Download Ollama from [ollama.com](https://ollama.com) and install the Mac app
2. Pull the model:
```bash
ollama pull llama3.2
```
The app checks Ollama first at `localhost:11434` and only falls back to the Anthropic API if Ollama is unavailable.

---

## Features

### Core
| Feature | Description |
|---------|-------------|
| **Capture** | Inline text field at top of Overview. Type a thought, hit enter. AI categorizes it. |
| **Actions** | Tasks with checkboxes. Complete them from any view. Log a "Win" on completion. |
| **Brainstorms** | Ideas and observations. Auto-clustered by AI into themed groups. |
| **Resources** | URLs with display titles. Attach multiple resources to any action or brainstorm. |
| **Notes** | Rich notes field on any item. Bullet points via `*` key. Expands to 75% of the detail panel. |
| **Clusters** | Drag one item onto another to create a group. AI names it. Expand/collapse. |
| **Wins** | Achievement log. When you complete a task, record what you achieved + link to artifact. |
| **Completed** | All done items across all categories. |

### AI Features
- **Auto-categorize**: On every capture (Auto mode), AI picks category (action/brainstorm/resource), cleans text, and generates tags
- **Auto-cluster**: After saving, AI assigns the item to an existing cluster or creates a new one with a generated title
- **Drag-to-cluster title**: When you drag two items together, AI names the new cluster
- **Notes analysis**: Save notes on any item → AI suggests follow-up actions and brainstorm ideas you can add with one click
- **Ollama-first**: Always uses local Ollama (llama3.2) when available; falls back to Anthropic API only if Ollama is down

### UX
- **Global hotkey**: `Ctrl+Option+M` opens a floating capture panel over any app
- **Menu bar**: Brain icon always in menu bar, never fully quits
- **Detail panel**: Click any item → slides in from the right (40% width)
- **Resource linking**: Paste a URL or search existing resources to attach them to any item; link icon shows on cards
- **Drag & drop**: Drag items onto each other to cluster them
- **Inter font**: Clean typography throughout

---

## Data Storage

All data is local:
- **Database**: `~/.my-mind/mind.db` (SQLite)
- **Config**: `~/.my-mind/config.json` (API key)

These are NOT in the git repo — they're personal to each device.

---

## Updating the App

When new changes are pushed to GitHub, pull and rebuild:

```bash
cd ~/my-mind
git pull
swift build -c release
cp .build/arm64-apple-macosx/release/MyMind /Applications/MyMind.app/Contents/MacOS/MyMind
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
```

---

## Project Structure

```
my-mind/
├── Package.swift              # Dependencies (GRDB)
├── Sources/MyMind/
│   ├── MyMindApp.swift        # App entry point, menu bar, window
│   ├── HotkeyManager.swift   # Ctrl+Option+M global hotkey
│   ├── QuickCapturePanel.swift # Floating capture overlay
│   ├── FontLoader.swift       # Inter font registration
│   ├── Models/                # Data models (Item, Cluster, Comment, Link, Win)
│   ├── Database/              # SQLite via GRDB (migrations, queries)
│   ├── AI/                    # Anthropic API + Ollama fallback
│   ├── ViewModels/            # Observable state management
│   └── Views/                 # All SwiftUI views
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
