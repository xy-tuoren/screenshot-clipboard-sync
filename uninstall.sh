#!/bin/bash

echo "🗑️ Uninstalling screenshot-clipboard-sync..."

PLIST_PATH="$HOME/Library/LaunchAgents/com.user.screenshot-clipboard-sync.plist"
BIN_PATH="$HOME/.local/bin/screenshot-clipboard-sync"

if [ -f "$PLIST_PATH" ]; then
    echo "⏹️ Stopping daemon service..."
    launchctl unload "$PLIST_PATH" 2>/dev/null || true
    rm -f "$PLIST_PATH"
fi

# Ensure any remaining process is terminated
pkill -f screenshot-clipboard-sync 2>/dev/null || true

if [ -f "$BIN_PATH" ]; then
    echo "🧹 Removing binary..."
    rm -f "$BIN_PATH"
fi

# Clean up temporary log files
rm -f /tmp/screenshot-clipboard-sync.log

echo "✅ Uninstallation complete!"
