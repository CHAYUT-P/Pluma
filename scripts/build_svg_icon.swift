import Foundation
import AppKit
import WebKit

let svgPath = "/Users/chayut/project/canvas/Resources/AppIcon.svg"
let iconsetPath = "/Users/chayut/project/canvas/Resources/AppIcon.iconset"
let icnsPath = "/Users/chayut/project/canvas/Resources/AppIcon.icns"

guard let svgData = try? Data(contentsOf: URL(fileURLWithPath: svgPath)),
      let svgString = String(data: svgData, encoding: .utf8) else {
    print("Failed to read SVG file")
    exit(1)
}

let fm = FileManager.default
try? fm.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

let html = """
<!DOCTYPE html>
<html>
<head>
<style>
  html, body { margin: 0; padding: 0; width: 1024px; height: 1024px; background: transparent; overflow: hidden; }
  svg { width: 1024px; height: 1024px; display: block; }
</style>
</head>
<body>
\(svgString)
</body>
</html>
"""

let app = NSApplication.shared
app.setActivationPolicy(.prohibited)

let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 1024, height: 1024))
webView.setValue(false, forKey: "drawsBackground")

class NavigationDelegate: NSObject, WKNavigationDelegate {
    var onFinish: (() -> Void)?
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Wait a tiny bit for SVG filters and shadows to rasterize cleanly
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.onFinish?()
        }
    }
}

let delegate = NavigationDelegate()
webView.navigationDelegate = delegate

delegate.onFinish = {
    let config = WKSnapshotConfiguration()
    config.rect = NSRect(x: 0, y: 0, width: 1024, height: 1024)
    config.snapshotWidth = 1024

    webView.takeSnapshot(with: config) { image, error in
        guard let image = image else {
            print("Failed to capture snapshot: \(String(describing: error))")
            exit(1)
        }

        let sizes: [(Int, String)] = [
            (16, "icon_16x16.png"),
            (32, "icon_16x16@2x.png"),
            (32, "icon_32x32.png"),
            (64, "icon_32x32@2x.png"),
            (128, "icon_128x128.png"),
            (256, "icon_128x128@2x.png"),
            (256, "icon_256x256.png"),
            (512, "icon_256x256@2x.png"),
            (512, "icon_512x512.png"),
            (1024, "icon_512x512@2x.png"),
        ]

        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            print("Failed to get bitmap")
            exit(1)
        }

        for (sz, filename) in sizes {
            let resized = NSImage(size: NSSize(width: sz, height: sz))
            resized.lockFocus()
            NSGraphicsContext.current?.imageInterpolation = .high
            image.draw(in: NSRect(x: 0, y: 0, width: sz, height: sz),
                       from: NSRect(x: 0, y: 0, width: 1024, height: 1024),
                       operation: .copy,
                       fraction: 1.0)
            resized.unlockFocus()

            if let rTiff = resized.tiffRepresentation,
               let rBitmap = NSBitmapImageRep(data: rTiff),
               let pngData = rBitmap.representation(using: .png, properties: [:]) {
                let filePath = (iconsetPath as NSString).appendingPathComponent(filename)
                try? pngData.write(to: URL(fileURLWithPath: filePath))
            }
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
        process.arguments = ["-c", "icns", iconsetPath, "-o", icnsPath]
        try? process.run()
        process.waitUntilExit()

        print("Successfully generated vector SVG iconset and AppIcon.icns!")
        exit(0)
    }
}

webView.loadHTMLString(html, baseURL: nil)
app.run()
