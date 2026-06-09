# my-mind

A native macOS SwiftUI personal knowledge management app. Capture thoughts, organize them into actions, brainstorms, and resources, cluster related items, and track wins.

## Requirements

- macOS 14+ (Sonoma)
- Swift 5.9+
- Ollama (optional, for local AI without API key)

## Setup

```bash
# Clone
git clone https://github.com/inaayat/my-mind.git
cd my-mind

# Build
swift build

# Run
swift run
```

### Install as app

```bash
# Release build
swift build -c release

# Create app bundle
mkdir -p /Applications/MyMind.app/Contents/MacOS
mkdir -p /Applications/MyMind.app/Contents/Resources
cp .build/arm64-apple-macosx/release/MyMind /Applications/MyMind.app/Contents/MacOS/MyMind
cp icon.icns /Applications/MyMind.app/Contents/Resources/AppIcon.icns
```

### AI Setup (optional)

For AI-powered categorization and clustering, either:

**Option A: Anthropic API key**
```bash
mkdir -p ~/.my-mind
echo '{"apiKey": "sk-ant-..."}' > ~/.my-mind/config.json
```

**Option B: Local Ollama (free, no key needed)**
```bash
brew install ollama
brew services start ollama
ollama pull llama3.2
```
The app auto-detects Ollama and uses it when no API key is set.

## Features

- **Capture** — inline thought capture with AI auto-categorization
- **Actions** — tasks with checkboxes, due dates, completion tracking
- **Brainstorms** — ideas and musings, auto-clustered by AI
- **Resources** — URLs with titles, linked to parent items
- **Clusters** — drag items onto each other to group them; AI names clusters
- **Wins** — log achievements when completing tasks (brag doc)
- **Global hotkey** — Ctrl+Option+M opens floating capture panel
- **Menu bar** — always running, quick access

## Data

All data stored locally at `~/.my-mind/mind.db` (SQLite via GRDB).
Config at `~/.my-mind/config.json`.

## Font

Uses [Inter](https://rsms.me/inter/) — bundled in the app.
