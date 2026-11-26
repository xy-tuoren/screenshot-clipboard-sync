import Cocoa
import Darwin

class ClipboardWatcher {
    private var lastChangeCount: Int
    private let pasteboard = NSPasteboard.general
    private let dateFormatter: DateFormatter
    private let storageDir: URL
    private let retentionSeconds: TimeInterval = 7 * 24 * 60 * 60
    private let cleanupIntervalSeconds: TimeInterval = 6 * 60 * 60

    init() {
        self.lastChangeCount = pasteboard.changeCount
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        self.storageDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("screenshot-clipboard-sync", isDirectory: true)

        ensurePrivateStorageDir()
        // Clean up screenshots older than 7 days on startup
        cleanupOldScreenshots()
    }

    func start() {
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
        Timer.scheduledTimer(withTimeInterval: cleanupIntervalSeconds, repeats: true) { [weak self] _ in
            self?.cleanupOldScreenshots()
        }
        RunLoop.main.run()
    }

    @discardableResult
    private func ensurePrivateStorageDir() -> Bool {
        let fm = FileManager.default
        let path = storageDir.path
        var st = stat()
        if lstat(path, &st) == 0 {
            // Refuse symlinks or non-directories in temp path
            guard (st.st_mode & S_IFMT) == S_IFDIR, st.st_uid == getuid() else {
                fputs("Refusing unsafe storage directory: \(path)\n", stderr)
                return false
            }
            _ = chmod(path, 0o700)
            return true
        }
        do {
            try fm.createDirectory(
                at: storageDir,
                withIntermediateDirectories: true,
                attributes: [.posixPermissions: 0o700]
            )
            _ = chmod(path, 0o700)
            return true
        } catch {
            fputs("Failed to create storage directory: \(error)\n", stderr)
            return false
        }
    }

    private func writePrivateFile(_ data: Data, to fileURL: URL) throws {
        let fd = open(fileURL.path, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0o600)
        guard fd >= 0 else {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno))
        }
        let handle = FileHandle(fileDescriptor: fd, closeOnDealloc: true)
        do {
            try handle.write(contentsOf: data)
        } catch {
            try? FileManager.default.removeItem(at: fileURL)
            throw error
        }
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
            guard ensurePrivateStorageDir() else { return }
            if let imgData = pasteboard.data(forType: .png) ?? pasteboard.data(forType: .tiff),
               let rep = NSBitmapImageRep(data: imgData),
               let pngData = rep.representation(using: .png, properties: [:]) {

                let shortID = String(UUID().uuidString.prefix(8)).lowercased()
                let fileURL = storageDir.appendingPathComponent(
                    "screenshot_\(dateFormatter.string(from: Date()))_\(shortID).png"
                )

                do {
                    try writePrivateFile(pngData, to: fileURL)

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
        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(
            at: storageDir,
            includingPropertiesForKeys: [.contentModificationDateKey, .isSymbolicLinkKey],
            options: .skipsHiddenFiles
        ) else { return }

        let cutoff = Date().addingTimeInterval(-retentionSeconds)
        for file in files where file.lastPathComponent.hasPrefix("screenshot_") && file.pathExtension == "png" {
            if let values = try? file.resourceValues(forKeys: [.contentModificationDateKey, .isSymbolicLinkKey]),
               values.isSymbolicLink != true,
               let modDate = values.contentModificationDate,
               modDate < cutoff {
                try? fileManager.removeItem(at: file)
            }
        }
    }
}

let watcher = ClipboardWatcher()
watcher.start()
