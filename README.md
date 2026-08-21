# screenshot-clipboard-sync (macOS)

> 🚀 **Auto-save clipboard screenshots to `/tmp` and attach the file path for instant terminal paste.**  
> 截图自动存入 `/tmp` 临时目录，并把路径注入剪贴板，支持终端（Ghostty / iTerm2 / WezTerm / Terminal）直接右键粘贴图片路径！

---

## ✨ Features (特性)

- ⚡ **Zero-Click Terminal Paste**: Right-click (or `Cmd+V`) in your terminal to instantly paste the latest screenshot's temporary file path (`/tmp/screenshot_YYYYMMDD_HHMMSS.png`).
- 🔄 **Dual-Flavor Clipboard**: Preserves both the image format (for WeChat, Lark, Slack, Figma, etc.) and text format (for terminals and text editors).
- 🧹 **Auto-Cleanup**: All images are saved to `/tmp`, which macOS automatically wipes on system reboot. Zero disk clutter.
- 🎯 **Universal Compatibility**: Works with **PixPin**, **Snipaste**, **CleanShot X**, **macOS native screenshot** (`Cmd+Ctrl+Shift+4`), and browser "Copy Image".
- 🪶 **Ultra Lightweight**: Pure native Swift, compiled to a ~70KB binary, **0% CPU** idle usage.
- 🤖 **Auto-Start**: Managed via macOS native `LaunchAgent` — runs silently on login without extra apps or windows.

---

## 📦 Quick Installation (一键安装)

### Option 1: Clone and install

```bash
git clone https://github.com/xy-tuoren/screenshot-clipboard-sync.git
cd screenshot-clipboard-sync
./install.sh
```

### Option 2: One-line install via curl

```bash
curl -fsSL https://raw.githubusercontent.com/xy-tuoren/screenshot-clipboard-sync/main/install.sh | bash
```

---

## ⚙️ Terminal Setup (终端配置)

To enable **Right-click to paste** in your favorite terminal:

### Ghostty
Edit `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty`:
```ini
right-click-action = copy-or-paste
```

### iTerm2
1. Go to **Settings** -> **Pointer** -> **General**.
2. Set **Right button** to **Paste from Clipboard**.

### WezTerm
In `~/.wezterm.lua`:
```lua
local wezterm = require 'wezterm'
local config = wezterm.config_builder()
config.mouse_bindings = {
  {
    event = { Down = { streak = 1, button = 'Right' } },
    mods = 'NONE',
    action = wezterm.action.PasteFrom 'Clipboard',
  },
}
return config
```

---

## 🕹️ Service Management (服务管理)

* **Check status (查看运行状态)**:
  ```bash
  ps aux | grep screenshot-clipboard-sync
  ```

* **Stop service (停止服务)**:
  ```bash
  launchctl unload ~/Library/LaunchAgents/com.user.screenshot-clipboard-sync.plist
  ```

* **Start service (启动服务)**:
  ```bash
  launchctl load ~/Library/LaunchAgents/com.user.screenshot-clipboard-sync.plist
  ```

* **Uninstall (一键卸载)**:
  ```bash
  ./uninstall.sh
  ```

---

## 📄 License

MIT License. Feel free to use, modify, and distribute.
