# screenshot-clipboard-sync

[English](README.md) | [简体中文](README_CN.md)

> 🚀 **截图自动存入系统临时目录并挂载文件路径，实现终端（Ghostty / Windows Terminal / iTerm2 / WezTerm）直接右键粘贴图片路径！**

---

## 📖 背景与设计理念

在日常使用终端（如 Ghostty、Windows Terminal 等）配合命令行 AI 工具、Python 脚本、`curl`、`ffmpeg` 处理图片时：
* 很多截图工具（如 Mac 原生截图、微信/QQ 截图、网页复制图片等）写入剪贴板的是**纯位图数据**；
* 终端本质上是字符流设备，右键粘贴只能接收**文本或文件引用**，无法直接接收图片像素，导致右键毫无反应；
* 如果简单地将剪贴板覆写为纯文本路径，又会误伤浏览器和富文本编辑器，导致网页无法上传图片。

**`screenshot-clipboard-sync`** 采用与顶级截图工具一致的**「原生文件对象（File URL / DropList）+ 图片对象」黄金标准设计**：
* 绝不写入纯文本（`text/plain`），**彻底杜绝网页端的文本路径污染**；
* 终端（Ghostty / iTerm2）识别文件对象，**右键自动转译为带转义符的完整文件路径**；
* 网页端（ChatGPT / GitHub / Notion）识别文件对象，**正常触发图片文件上传**；
* 微信、飞书、Slack、Photoshop 等读取图片通道，**正常发送/粘贴高清图片**；
* 访达（Finder）/ 资源管理器中按 `Cmd+V` / `Ctrl+V`，**直接粘贴生成实体图片文件**。

---

## ✨ 核心特性

- ⚡ **零按键粘贴**：截图完成后，在终端直接点击鼠标右键即可粘贴临时文件绝对路径（如 `/tmp/screenshot_20260821_105356.png`）。
- 🔄 **双通道剪贴板（Dual-Flavor）**：同时保留图片通道与文本通道，聊天工具发图与终端贴路径互不冲突。
- 🧹 **重启自动清空**：所有文件存放在系统的临时目录（macOS: `/tmp` / Windows: `%TEMP%`），电脑重启系统自动销毁，零磁盘垃圾。
- 🎯 **全截图工具通用**：完美支持 **PixPin**、**Snipaste**、**CleanShot X**、**Windows 自带截图 (`Win+Shift+S`)**、**macOS 原生截图 (`Cmd+Ctrl+Shift+4`)** 以及浏览器“复制图片”。
- 🪶 **原生极致轻量**：纯原生实现（macOS 使用 Swift，Windows 使用 Win32/.NET API），**0% CPU 占用**，内存仅占用数 MB。
- 🤖 **开机静默自启**：
  - **macOS**：通过原生 `LaunchAgent` 托管，免维护运行。
  - **Windows**：通过当前用户注册表启动项托管，无黑框静默运行。

---

## 🍏 macOS 安装与使用

### 一键安装（推荐）

```bash
curl -fsSL https://raw.githubusercontent.com/xy-tuoren/screenshot-clipboard-sync/main/install.sh | bash
```

或者通过 Git 克隆安装：

```bash
git clone https://github.com/xy-tuoren/screenshot-clipboard-sync.git
cd screenshot-clipboard-sync
./install.sh
```

---

## 🪟 Windows 安装与使用

以普通用户身份打开 **PowerShell** 运行：

```powershell
git clone https://github.com/xy-tuoren/screenshot-clipboard-sync.git
cd screenshot-clipboard-sync\windows
.\install.ps1
```

> **提示**：Windows 版本调用系统自带的 C# 编译器（`csc.exe`），**无需安装 Visual Studio 或任何外部 SDK**，开箱即用。

---

## ⚙️ 终端右键粘贴配置

为了在终端中体验**直接右键粘贴**，请参考以下设置：

### Ghostty (macOS / Windows / Linux)
打开 Ghostty 配置文件（`~/Library/Application Support/com.mitchellh.ghostty/config.ghostty`）添加：
```ini
right-click-action = copy-or-paste
```

### Windows Terminal (Windows)
Windows Terminal 原生支持右键直接粘贴剪贴板文本。

### iTerm2 (macOS)
打开 **Settings** -> **Pointer** -> **General**，将 **Right button** 设置为 **Paste from Clipboard**。

### WezTerm
在 `~/.wezterm.lua` 中添加：
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

## 🕹️ 服务管理命令

### macOS
* **查看运行状态**：`ps aux | grep screenshot-clipboard-sync`
* **停止服务**：`launchctl unload ~/Library/LaunchAgents/com.user.screenshot-clipboard-sync.plist`
* **启动服务**：`launchctl load ~/Library/LaunchAgents/com.user.screenshot-clipboard-sync.plist`
* **一键卸载（自动停止服务并彻底清理）**：`./uninstall.sh`

### Windows (PowerShell)
* **查看运行状态**：
  ```powershell
  Get-Process -Name "screenshot-clipboard-sync" -ErrorAction SilentlyContinue
  ```
* **停止服务**：
  ```powershell
  Stop-Process -Name "screenshot-clipboard-sync" -Force -ErrorAction SilentlyContinue
  ```
* **启动服务**：
  ```powershell
  Start-Process "$env:APPDATA\screenshot-clipboard-sync\screenshot-clipboard-sync.exe"
  ```
* **重启服务**：
  ```powershell
  Stop-Process -Name "screenshot-clipboard-sync" -Force -ErrorAction SilentlyContinue
  Start-Process "$env:APPDATA\screenshot-clipboard-sync\screenshot-clipboard-sync.exe"
  ```
* **一键卸载（自动停止服务并彻底清理）**：
  ```powershell
  .\windows\uninstall.ps1
  ```

---

## 🔗 友链与社区

- [LINUX DO](https://linux.do/) - 新的真理，新的世界

---

## 📄 License

MIT License. 欢迎 Star、Issue 与 Pull Request！
