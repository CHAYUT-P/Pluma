import SwiftUI
import AppKit

// MARK: - Page Thumbnail Service
// Renders small page previews (Canva-style) with an in-memory cache keyed by
// page identity + content fingerprint, so thumbnails only re-render when the
// page actually changes.

public final class PageThumbnailService {
    public static let shared = PageThumbnailService()

    private struct CacheKey: Hashable {
        let pageID: UUID
        let fingerprint: Int
        let pixelWidth: Int
    }

    private struct CacheEntry {
        let image: NSImage
        let lastAccess: Date
    }

    private var cache: [CacheKey: CacheEntry] = [:]
    private let maxEntries = 120
    private let queue = DispatchQueue(label: "pluma.thumbnails", attributes: .concurrent)

    private init() {}

    /// Stable, CHEAP fingerprint of a page's visual content.
    /// Deliberately avoids hashing huge payloads (image base64) — only cheap markers
    /// (sizes, counts, small strings) so it can run after every confirmed transform.
    public static func fingerprint(of page: CanvasPage) -> Int {
        var hasher = Hasher()
        hasher.combine(page.width)
        hasher.combine(page.height)
        hasher.combine(page.background)
        hasher.combine(page.isTransparent)
        hasher.combine(page.elements.count)
        for el in page.elements {
            hasher.combine(el.id)
            hasher.combine(el.x)
            hasher.combine(el.y)
            hasher.combine(el.width)
            hasher.combine(el.height)
            hasher.combine(el.rotation)
            hasher.combine(el.opacity)
            hasher.combine(el.isVisible)
            hasher.combine(el.zIndex)
            hasher.combine(el.isFlippedH)
            hasher.combine(el.isFlippedV)
            switch el.payload {
            case .image(let img):
                hasher.combine(1)
                hasher.combine(img.imageBase64.count)          // cheap: length only
                hasher.combine(img.cornerRadius)
                hasher.combine(img.contentMode)
                hasher.combine(img.originalWidth)
                hasher.combine(img.originalHeight)
            case .text(let t):
                hasher.combine(2)
                hasher.combine(t.text)
                hasher.combine(t.fontSize)
                hasher.combine(t.fontWeight)
                hasher.combine(t.fontFamily)
                hasher.combine(t.textColor)
                hasher.combine(t.alignment)
                hasher.combine(t.lineSpacing)
                hasher.combine(t.letterSpacing)
                hasher.combine(t.cardBackground)
            case .shape(let s):
                hasher.combine(3)
                hasher.combine(s.kind)
                hasher.combine(s.fill)
                hasher.combine(s.stroke)
                hasher.combine(s.cornerRadius)
            case .icon(let i):
                hasher.combine(4)
                hasher.combine(i.symbolName)
                hasher.combine(i.primaryColor)
            case .drawing(let d):
                hasher.combine(5)
                hasher.combine(d.points.count)
                hasher.combine(d.strokeColor)
                hasher.combine(d.lineWidth)
            case .code(let c):
                hasher.combine(6)
                hasher.combine(c.code)
                hasher.combine(c.language)
                hasher.combine(c.theme)
            }
        }
        return hasher.finalize()
    }

    /// Synchronous cached lookup; renders on miss (fast enough for small thumbnails).
    public func thumbnail(for page: CanvasPage, targetWidth: CGFloat = 150) -> NSImage? {
        let pixelWidth = Int(targetWidth * 2) // 2x for retina crispness
        let key = CacheKey(pageID: page.id, fingerprint: Self.fingerprint(of: page), pixelWidth: pixelWidth)
        if let hit = cache[key] {
            return hit.image
        }
        let scale = Double(pixelWidth) / max(1, page.width)
        guard scale > 0 else { return nil }
        guard let image = ExportEngine.renderImage(page: page, scale: scale) else { return nil }
        // Downsample into a tightly-fitted bitmap for memory efficiency
        let targetH = Int(Double(page.height) * scale)
        if let resized = image.resizedTo(width: pixelWidth, height: targetH) {
            evictIfNeeded()
            cache[key] = CacheEntry(image: resized, lastAccess: Date())
            return resized
        }
        return image
    }

    /// Async variant that never blocks the main thread longer than a render; delivers on main.
    public func thumbnailAsync(for page: CanvasPage, targetWidth: CGFloat = 150, completion: @escaping (NSImage?) -> Void) {
        let pixelWidth = Int(targetWidth * 2)
        let key = CacheKey(pageID: page.id, fingerprint: Self.fingerprint(of: page), pixelWidth: pixelWidth)
        if let hit = cache[key] {
            completion(hit.image)
            return
        }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let scale = Double(pixelWidth) / max(1, page.width)
            var result: NSImage?
            if scale > 0, let rendered = ExportEngine.renderImage(page: page, scale: scale) {
                let targetH = Int(Double(page.height) * scale)
                result = rendered.resizedTo(width: pixelWidth, height: targetH) ?? rendered
            }
            if let result = result {
                self.queue.async(flags: .barrier) {
                    self.evictIfNeeded()
                    self.cache[key] = CacheEntry(image: result, lastAccess: Date())
                }
            }
            DispatchQueue.main.async { completion(result) }
        }
    }

    public func invalidateAll() {
        queue.async(flags: .barrier) { self.cache.removeAll() }
    }

    public func invalidate(pageID: UUID) {
        queue.async(flags: .barrier) {
            self.cache = self.cache.filter { $0.key.pageID != pageID }
        }
    }

    private func evictIfNeeded() {
        guard cache.count >= maxEntries else { return }
        let sorted = cache.sorted { $0.value.lastAccess < $1.value.lastAccess }
        for (key, _) in sorted.prefix(maxEntries / 4) {
            cache.removeValue(forKey: key)
        }
    }
}

extension NSImage {
    /// Downsamples to an exact pixel size, returning a tightly-packed bitmap-backed image.
    func resizedTo(width: Int, height: Int) -> NSImage? {
        guard width > 0, height > 0 else { return nil }
        guard let cg = cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        guard let ctx = CGContext(
            data: nil,
            width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        ctx.interpolationQuality = .medium
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let out = ctx.makeImage() else { return nil }
        return NSImage(cgImage: out, size: NSSize(width: width, height: height))
    }
}
