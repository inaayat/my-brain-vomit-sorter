# my-mind

A native macOS SwiftUI personal knowledge management app. Capture thoughts, track actions, brainstorm ideas, save resources, cluster related items, and log wins.

---

## Download & Install on a New Mac

### Prerequisites
- macOS 14 (Sonoma) or later
- Xcode Command Line Tools: `xcode-select --install`
- Homebrew (optional, for Ollama): `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`

### Step 1: Clone the repo
```bash
git clone https://github.com/inaayat/my-mind.git
cd my-mind
```

### Step 2: Build
```bash
swift build -c release
```
This downloads dependencies (GRDB) and compiles the app. Takes ~30-60 seconds on first build.

### Step 3: Install as a macOS app
```bash
# Create the app bundle
mkdir -p /Applications/MyMind.app/Contents/MacOS
mkdir -p /Applications/MyMind.app/Contents/Resources

# Copy the built binary
cp .build/arm64-apple-macosx/release/MyMind /Applications/MyMind.app/Contents/MacOS/MyMind

# Copy the Info.plist (creates it if needed)
cat > /Applications/MyMind.app/Contents/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key><string>MyMind</string>
    <key>CFBundleIdentifier</key><string>com.igill.mymind</string>
    <key>CFBundleName</key><string>MyMind</string>
    <key>CFBundleDisplayName</key><string>MyMind</string>
    <key>CFBundleVersion</key><string>1.0.0</string>
    <key>CFBundleShortVersionString</key><string>1.0.0</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
EOF
```

### Step 4: Launch
```bash
open -a /Applications/MyMind.app
```

### Step 5: Grant Accessibility (for global hotkey)
1. System Settings > Privacy & Security > Accessibility
2. Click + and add `/Applications/MyMind.app`
3. Restart the app

### Step 6: (Optional) Launch at login
```bash
cat > ~/Library/LaunchAgents/com.igill.mymind.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key><string>com.igill.mymind</string>
    <key>ProgramArguments</key>
    <array><string>open</string><string>-a</string><string>/Applications/MyMind.app</string></array>
    <key>RunAtLoad</key><true/>
</dict>
</plist>
EOF
launchctl load ~/Library/LaunchAgents/com.igill.mymind.plist
```

---

## AI Setup (Optional)

AI powers auto-categorization and clustering.

### Option A: Anthropic API key
```bash
mkdir -p ~/.my-mind
echo '{"apiKey": "sk-ant-..."}' > ~/.my-mind/config.json
```

### Option B: Local Ollama (free, no API key needed)
```bash
brew install ollama
brew services start ollama
ollama pull llama3.2
```
The app auto-detects Ollama at `localhost:11434` and uses it when no API key is configured.

---

## Features

### Core
| Feature | Description |
|---------|-------------|
| **Capture** | Inline text field at top of Overview. Type a thought, hit enter. AI categorizes it. |
| **Actions** | Tasks with checkboxes. Complete them from any view. Log a "Win" on completion. |
| **Brainstorms** | Ideas and observations. Auto-clustered by AI into themed groups. |
| **Resources** | URLs with display titles. Auto-created when you add a URL to any item. |
| **Clusters** | Drag one item onto another to create a group. AI names it. Expand/collapse. |
| **Wins** | Achievement log. When you complete a task, record what you achieved + link to artifact. |
| **Completed** | All done items across all categories. |

### AI Features
- **Auto-categorize**: On every capture (Auto mode), AI picks category (action/brainstorm/resource), cleans text, and generates tags
- **Auto-cluster**: After saving, AI assigns the item to an existing cluster or creates a new one with a generated title
- **Drag-to-cluster title**: When you drag two items together, AI names the new cluster
- **Ollama fallback**: Works offline with local llama3.2 model when no Anthropic API key is set

### UX
- **Global hotkey**: `Ctrl+Option+M` opens a floating capture panel over any app
- **Menu bar**: Brain icon always in menu bar, never fully quits
- **Detail panel**: Click any item → slides in from the right (40% width)
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
