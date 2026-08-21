import Cocoa

class ClipboardWatcher {
    private var lastChangeCount: Int
    private let pasteboard = NSPasteboard.general
    private let dateFormatter: DateFormatter
    
    private var activeScreenshotData: Data?
    private var activeScreenshotPath: String?

    init() {
        self.lastChangeCount = pasteboard.changeCount
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        
        // Clean up screenshots older than 7 days on startup
        cleanupOldScreenshots()
        
        // Listen for frontmost application focus changes
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(applicationDidActivate(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }

    func start() {
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
        RunLoop.main.run()
    }

    private func isTerminalApp(_ app: NSRunningApplication?) -> Bool {
        guard let app = app else { return false }
        let bundleId = (app.bundleIdentifier ?? "").lowercased()
        let name = (app.localizedName ?? "").lowercased()
        let terms = ["ghostty", "terminal", "iterm", "wezterm", "alacritty", "kitty", "warp", "hyper", "rio"]
        return terms.contains(where: { bundleId.contains($0) || name.contains($0) })
    }

    @objc private func applicationDidActivate(_ notification: Notification) {
        guard let activePath = activeScreenshotPath,
              let activeData = activeScreenshotData else { return }
        
        let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
        let isTerminal = isTerminalApp(app)
        
        // Check if clipboard still holds our screenshot
        guard let types = pasteboard.types,
              types.contains(.png) || types.contains(.tiff) else {
            // User copied something else, reset active screenshot state
            activeScreenshotData = nil
            activeScreenshotPath = nil
            return
        }

        updatePasteboard(pngData: activeData, filePath: activePath, forTerminal: isTerminal)
    }

    private func checkClipboard() {
        let currentCount = pasteboard.changeCount
        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount

        guard let types = pasteboard.types else { return }
        let hasImage = types.contains(.png) || types.contains(.tiff)
        let currentString = pasteboard.string(forType: .string)

        // If user copied a new pure image
        if hasImage && (currentString == nil || currentString!.isEmpty || !currentString!.hasPrefix("/tmp/screenshot_")) {
            if let imgData = pasteboard.data(forType: .png) ?? pasteboard.data(forType: .tiff),
               let rep = NSBitmapImageRep(data: imgData),
               let pngData = rep.representation(using: .png, properties: [:]) {
                
                let filename = "/tmp/screenshot_\(dateFormatter.string(from: Date())).png"
                let fileURL = URL(fileURLWithPath: filename)
                
                do {
                    try pngData.write(to: fileURL, options: .atomic)
                    // Set private permissions (0600 - Owner read/write only)
                    try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: filename)
                    
                    self.activeScreenshotData = pngData
                    self.activeScreenshotPath = filename
                    
                    let frontApp = NSWorkspace.shared.frontmostApplication
                    let isTerminal = isTerminalApp(frontApp)
                    
                    updatePasteboard(pngData: pngData, filePath: filename, forTerminal: isTerminal)
                } catch {
                    fputs("Failed to save screenshot: \(error)\n", stderr)
                }
            }
        } else if !hasImage {
            // Cleared or non-image copied
            activeScreenshotData = nil
            activeScreenshotPath = nil
        }
    }

    private func updatePasteboard(pngData: Data, filePath: String, forTerminal: Bool) {
        pasteboard.clearContents()
        
        let item = NSPasteboardItem()
        item.setData(pngData, forType: .png)
        
        let fileURL = URL(fileURLWithPath: filePath)
        item.setString(fileURL.absoluteString, forType: .fileURL)
        
        if forTerminal {
            // Terminal mode: Include plain text path so right-click pastes the file path
            item.setString(filePath, forType: .string)
        }
        // Non-terminal mode (Browser/Chat): Do NOT attach .string, so web/chat apps paste/upload real image!
        
        pasteboard.writeObjects([item])
        lastChangeCount = pasteboard.changeCount
    }

    private func cleanupOldScreenshots() {
        let tempDir = URL(fileURLWithPath: "/tmp")
        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: [.contentModificationDateKey], options: .skipsHiddenFiles) else { return }
        
        let sevenDaysAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        for file in files where file.lastPathComponent.hasPrefix("screenshot_") && file.pathExtension == "png" {
            if let attributes = try? fileManager.attributesOfItem(atPath: file.path),
               let modDate = attributes[.modificationDate] as? Date,
               modDate < sevenDaysAgo {
                try? fileManager.removeItem(at: file)
            }
        }
    }
}

let watcher = ClipboardWatcher()
watcher.start()
