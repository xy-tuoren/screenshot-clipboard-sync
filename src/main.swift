import Cocoa

class ClipboardWatcher {
    private var lastChangeCount: Int
    private let pasteboard = NSPasteboard.general
    private let dateFormatter: DateFormatter

    init() {
        self.lastChangeCount = pasteboard.changeCount
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
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
        let currentString = pasteboard.string(forType: .string)

        // Only process when clipboard has an image and no text path attached
        if hasImage && (currentString == nil || currentString!.isEmpty) {
            if let imgData = pasteboard.data(forType: .png) ?? pasteboard.data(forType: .tiff),
               let rep = NSBitmapImageRep(data: imgData),
               let pngData = rep.representation(using: .png, properties: [:]) {
                
                let filename = "/tmp/screenshot_\(dateFormatter.string(from: Date())).png"
                let fileURL = URL(fileURLWithPath: filename)
                
                do {
                    try pngData.write(to: fileURL)
                    
                    // Dual-flavor clipboard: Keep PNG image data & add text path
                    pasteboard.clearContents()
                    pasteboard.setData(pngData, forType: .png)
                    pasteboard.setString(filename, forType: .string)
                    lastChangeCount = pasteboard.changeCount
                } catch {
                    fputs("Failed to write screenshot to \(filename): \(error)\n", stderr)
                }
            }
        }
    }
}

let watcher = ClipboardWatcher()
watcher.start()
