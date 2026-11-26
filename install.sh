#!/bin/bash
set -euo pipefail

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

BIN_DIR="$HOME/.local/bin"
BIN_PATH="$BIN_DIR/screenshot-clipboard-sync"
PLIST_DIR="$HOME/Library/LaunchAgents"
PLIST_PATH="$PLIST_DIR/com.user.screenshot-clipboard-sync.plist"
LOG_DIR="$HOME/Library/Logs"
LOG_PATH="$LOG_DIR/screenshot-clipboard-sync.log"
REPO_REF="${SCS_REF:-main}"
RAW_MAIN_SWIFT_URL="https://raw.githubusercontent.com/xy-tuoren/screenshot-clipboard-sync/${REPO_REF}/src/main.swift"

TMP_DIR=""
cleanup() {
    if [[ -n "$TMP_DIR" && -d "$TMP_DIR" ]]; then
        rm -rf "$TMP_DIR"
    fi
}
trap cleanup EXIT

SOURCE_FILE=""
if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [[ -f "$SCRIPT_DIR/src/main.swift" ]]; then
        SOURCE_FILE="$SCRIPT_DIR/src/main.swift"
    fi
fi

if [[ -z "$SOURCE_FILE" ]]; then
    if ! command -v curl &> /dev/null; then
        echo "❌ Error: curl not found. Please clone the repository and run ./install.sh locally."
        exit 1
    fi
    TMP_DIR="$(mktemp -d)"
    SOURCE_FILE="$TMP_DIR/main.swift"
    echo "⬇️ Downloading Swift source..."
    curl -fsSL "$RAW_MAIN_SWIFT_URL" -o "$SOURCE_FILE"
fi

mkdir -p "$BIN_DIR" "$PLIST_DIR" "$LOG_DIR"

echo "📦 Compiling Swift source..."
swiftc -O -o "$BIN_PATH" "$SOURCE_FILE"
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
    <string>$LOG_PATH</string>
    <key>StandardOutPath</key>
    <string>$LOG_PATH</string>
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
