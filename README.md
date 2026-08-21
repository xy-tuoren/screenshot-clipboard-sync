# screenshot-clipboard-sync (macOS & Windows)

[English](README.md) | [简体中文](README_CN.md)

> 🚀 **Auto-save clipboard screenshots to temp directory and attach the file path for instant terminal paste.**  
> 截图自动存入系统临时目录（macOS: `/tmp` / Windows: `%TEMP%`），并把路径注入剪贴板，支持终端（Ghostty / Windows Terminal / iTerm2 / WezTerm）直接右键粘贴图片路径！

---

## ✨ Features (特性)

- ⚡ **Zero-Click Terminal Paste**: Right-click (or `Ctrl+V` / `Cmd+V`) in your terminal to instantly paste the latest screenshot's temporary file path.
- 🔄 **Dual-Flavor Clipboard**: Preserves both the image format (for WeChat, Lark, Slack, Figma, etc.) and text format (for terminals and text editors).
- 🧹 **Auto-Cleanup**: All images are saved to the OS temporary directory (`/tmp` on macOS, `%TEMP%` on Windows), automatically wiped upon reboot. Zero disk clutter.
- 🎯 **Universal Compatibility**: Works with **PixPin**, **Snipaste**, **CleanShot X**, **Windows Snipping Tool (`Win+Shift+S`)**, **macOS native screenshot (`Cmd+Ctrl+Shift+4`)**, and browser "Copy Image".
- 🪶 **Ultra Lightweight**: Pure native implementation (Swift on macOS, Win32/.NET on Windows), **0% CPU** idle usage.
- 🤖 **Auto-Start**:
  - **macOS**: Managed via native `LaunchAgent`.
  - **Windows**: Managed via Windows User Startup Registry.

---

## 🍏 macOS Installation (macOS 一键安装)

### One-line install via curl
```bash
curl -fsSL https://raw.githubusercontent.com/xy-tuoren/screenshot-clipboard-sync/main/install.sh | bash
```

### Or clone and install
```bash
git clone https://github.com/xy-tuoren/screenshot-clipboard-sync.git
cd screenshot-clipboard-sync
./install.sh
```

---

## 🪟 Windows Installation (Windows 一键安装)

Open PowerShell as normal user and run:

```powershell
git clone https://github.com/xy-tuoren/screenshot-clipboard-sync.git
cd screenshot-clipboard-sync\windows
.\install.ps1
```

> **Note**: Windows version uses the built-in C# compiler (`csc.exe`) available on all Windows 10/11 machines. **No Visual Studio or extra SDK installation required!**

---

## ⚙️ Terminal Setup (终端配置)

### Ghostty (macOS / Windows / Linux)
Edit your Ghostty config:
```ini
right-click-action = copy-or-paste
```

### Windows Terminal (Windows)
Windows Terminal natively supports pasting on right-click or `Ctrl+V`.

### iTerm2 (macOS)
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

### macOS
* **Stop service (停止服务)**: `launchctl unload ~/Library/LaunchAgents/com.user.screenshot-clipboard-sync.plist`
* **Start service (启动服务)**: `launchctl load ~/Library/LaunchAgents/com.user.screenshot-clipboard-sync.plist`
* **Uninstall (一键卸载 - 自动停止服务并彻底清理)**:
  ```bash
  ./uninstall.sh
  ```

### Windows (PowerShell)
* **Check status (查看运行状态)**:
  ```powershell
  Get-Process -Name "screenshot-clipboard-sync" -ErrorAction SilentlyContinue
  ```
* **Stop service (停止服务)**:
  ```powershell
  Stop-Process -Name "screenshot-clipboard-sync" -Force -ErrorAction SilentlyContinue
  ```
* **Start service (启动服务)**:
  ```powershell
  Start-Process "$env:APPDATA\screenshot-clipboard-sync\screenshot-clipboard-sync.exe"
  ```
* **Restart service (重启服务)**:
  ```powershell
  Stop-Process -Name "screenshot-clipboard-sync" -Force -ErrorAction SilentlyContinue
  Start-Process "$env:APPDATA\screenshot-clipboard-sync\screenshot-clipboard-sync.exe"
  ```
* **Uninstall (一键卸载 - 自动停止服务并彻底清理)**:
  ```powershell
  .\windows\uninstall.ps1
  ```

---

## 🔗 Links (友链)

- [LINUX DO](https://linux.do/) - 新的真理，新的世界

---

## 📄 License

MIT License. Feel free to use, modify, and distribute.
