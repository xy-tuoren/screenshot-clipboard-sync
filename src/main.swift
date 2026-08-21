import Cocoa

class ClipboardWatcher {
    private var lastChangeCount: Int
    private let pasteboard = NSPasteboard.general
    private let dateFormatter: DateFormatter

    init() {
        self.lastChangeCount = pasteboard.changeCount
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        
        // Clean up screenshots older than 7 days on startup
        cleanupOldScreenshots()
    }

    func start() {
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
        RunLoop.main.run()
    }

    private func checkClipboard() {
        let currentCount = pasteboard.changeCount
        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount

        guard let types = pasteboard.types else { return }
        let hasImage = types.contains(.png) || types.contains(.tiff)
        let hasFileURL = types.contains(.fileURL) || types.contains(NSPasteboard.PasteboardType("NSFilenamesPboardType"))

        // If clipboard contains an image but does not yet have a file URL object
        // (e.g. macOS native screenshot, WeChat/QQ screenshot, browser copy-image)
        if hasImage && !hasFileURL {
            if let imgData = pasteboard.data(forType: .png) ?? pasteboard.data(forType: .tiff),
               let rep = NSBitmapImageRep(data: imgData),
               let pngData = rep.representation(using: .png, properties: [:]) {
                
                let filename = "/tmp/screenshot_\(dateFormatter.string(from: Date())).png"
                let fileURL = URL(fileURLWithPath: filename)
                
                do {
                    try pngData.write(to: fileURL, options: .atomic)
                    // Set private permissions (0600 - Owner read/write only)
                    try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: filename)
                    
                    // Gold Standard: Write PNG Data + FileURL (NSFilenamesPboardType)
                    // No plain text string is written, avoiding text pollution in browsers!
                    pasteboard.clearContents()
                    
                    let item = NSPasteboardItem()
                    item.setData(pngData, forType: .png)
                    item.setString(fileURL.absoluteString, forType: .fileURL)
                    
                    pasteboard.writeObjects([item])
                    lastChangeCount = pasteboard.changeCount
                } catch {
                    fputs("Failed to save screenshot: \(error)\n", stderr)
                }
            }
        }
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
