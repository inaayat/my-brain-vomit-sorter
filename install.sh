#!/bin/bash
set -e

APP_NAME="MyMind"
BUNDLE_ID="com.igill.mymind"
REPO_URL="https://github.com/inaayat/my-brain-vomit-sorter.git"
INSTALL_DIR="$HOME/my-mind"
APP_PATH="/Applications/$APP_NAME.app"

echo "╔══════════════════════════════════════╗"
echo "║         MyMind Installer             ║"
echo "╚══════════════════════════════════════╝"
echo ""

# Check prerequisites
echo "→ Checking prerequisites..."

if ! xcode-select -p &>/dev/null; then
    echo "  ✗ Xcode Command Line Tools not found. Installing..."
    xcode-select --install
    echo "  Run this script again after the install completes."
    exit 1
fi
echo "  ✓ Xcode Command Line Tools"

if ! command -v swift &>/dev/null; then
    echo "  ✗ Swift not found. Install Xcode Command Line Tools first."
    exit 1
fi
echo "  ✓ Swift $(swift --version 2>&1 | head -1 | sed 's/.*version //' | sed 's/ .*//')"

# Clone or update
echo ""
if [ -d "$INSTALL_DIR/.git" ]; then
    echo "→ Updating existing repo..."
    git -C "$INSTALL_DIR" pull --ff-only
else
    echo "→ Cloning repository..."
    git clone "$REPO_URL" "$INSTALL_DIR"
fi

# Build
echo ""
echo "→ Building (release)..."
cd "$INSTALL_DIR"
swift build -c release 2>&1 | grep -E "^(Build|Linking|error)" || true

BINARY=".build/release/$APP_NAME"
if [ ! -f "$BINARY" ]; then
    BINARY=".build/arm64-apple-macosx/release/$APP_NAME"
fi

if [ ! -f "$BINARY" ]; then
    echo "  ✗ Build failed — binary not found."
    exit 1
fi
echo "  ✓ Build complete"

# Create app bundle
echo ""
echo "→ Installing to $APP_PATH..."

mkdir -p "$APP_PATH/Contents/MacOS"
mkdir -p "$APP_PATH/Contents/Resources"

cp "$BINARY" "$APP_PATH/Contents/MacOS/$APP_NAME"

cat > "$APP_PATH/Contents/Info.plist" << 'PLIST'
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
PLIST

echo "  ✓ App bundle created"

# Launch agent (optional)
echo ""
read -p "→ Launch at login? [y/N] " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    mkdir -p "$HOME/Library/LaunchAgents"
    cat > "$HOME/Library/LaunchAgents/$BUNDLE_ID.plist" << AGENT
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key><string>$BUNDLE_ID</string>
    <key>ProgramArguments</key>
    <array><string>open</string><string>-a</string><string>$APP_PATH</string></array>
    <key>RunAtLoad</key><true/>
</dict>
</plist>
AGENT
    launchctl load "$HOME/Library/LaunchAgents/$BUNDLE_ID.plist" 2>/dev/null || true
    echo "  ✓ Launch agent installed"
fi

# Ollama check
echo ""
if command -v ollama &>/dev/null || [ -d "/Applications/Ollama.app" ]; then
    echo "→ Ollama detected"
    if ollama list 2>/dev/null | grep -q "llama3.2"; then
        echo "  ✓ llama3.2 model ready"
    else
        read -p "  Pull llama3.2 model? (~2GB) [y/N] " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ollama pull llama3.2
            echo "  ✓ llama3.2 pulled"
        fi
    fi
else
    echo "→ Ollama not found (optional — enables free local AI)"
    echo "  Install from: https://ollama.com"
fi

# Done
echo ""
echo "╔══════════════════════════════════════╗"
echo "║            ✓ Installed!              ║"
echo "╚══════════════════════════════════════╝"
echo ""
echo "  Launch:  open -a $APP_PATH"
echo "  Hotkey:  Ctrl+Option+M (grant Accessibility in System Settings)"
echo "  Data:    ~/.my-mind/mind.db"
echo ""

read -p "→ Launch now? [Y/n] " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    open -a "$APP_PATH"
fi
