#!/bin/bash
set -e

echo "🚀 Installing screenshot-clipboard-sync..."

# Check OS
if [[ "$(uname)" != "Darwin" ]]; then
    echo "❌ Error: screenshot-clipboard-sync is only supported on macOS."
    exit 1
fi

# Check Swift compiler
if ! command -v swiftc &> /dev/null; then
    echo "❌ Error: swiftc compiler not found. Please install Xcode Command Line Tools by running:"
    echo "   xcode-select --install"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
BIN_PATH="$BIN_DIR/screenshot-clipboard-sync"
PLIST_DIR="$HOME/Library/LaunchAgents"
PLIST_PATH="$PLIST_DIR/com.user.screenshot-clipboard-sync.plist"

mkdir -p "$BIN_DIR"
mkdir -p "$PLIST_DIR"

echo "📦 Compiling Swift source..."
swiftc -O -o "$BIN_PATH" "$SCRIPT_DIR/src/main.swift"
chmod +x "$BIN_PATH"

echo "⚙️ Creating LaunchAgent..."
cat << PLIST > "$PLIST_PATH"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.screenshot-clipboard-sync</string>
    <key>ProgramArguments</key>
    <array>
        <string>$BIN_PATH</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardErrorPath</key>
    <string>/tmp/screenshot-clipboard-sync.log</string>
    <key>StandardOutPath</key>
    <string>/tmp/screenshot-clipboard-sync.log</string>
</dict>
</plist>
PLIST

echo "🔄 Restarting background service..."
launchctl unload "$PLIST_PATH" 2>/dev/null || true
launchctl load "$PLIST_PATH"

echo ""
echo "✅ Installation complete!"
echo "✨ screenshot-clipboard-sync is now running in the background and will start on boot."
echo ""
echo "💡 Terminal Tips (e.g., Ghostty):"
echo "   Add \`right-click-action = copy-or-paste\` to your Ghostty config:"
echo "   ~/Library/Application Support/com.mitchellh.ghostty/config.ghostty"
echo ""
