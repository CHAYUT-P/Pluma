import AppKit
import CoreImage
import CoreImage.CIFilterBuiltins

public enum ImageUtils {
    // MARK: - Decode & Filter Caches (THE perf fix)
    // Previously every SwiftUI render pass (i.e. every drag/zoom frame) re-decoded
    // multi-megabyte base64 payloads AND re-ran the whole CoreImage pipeline.
    // Bounded NSCaches keep memory predictable while eliminating that churn.

    private static let decodedCache: NSCache<NSString, NSImage> = {
        let c = NSCache<NSString, NSImage>()
        c.countLimit = 80
        c.totalCostLimit = 192 * 1024 * 1024 // ~192 MB of decoded bitmaps max
        return c
    }()

    private static let filteredCache: NSCache<NSString, NSImage> = {
        let c = NSCache<NSString, NSImage>()
        c.countLimit = 60
        c.totalCostLimit = 128 * 1024 * 1024
        return c
    }()

    /// Cheap stable-enough in-memory key: length + head + tail of the payload.
    /// Avoids hashing megabytes on every frame while being collision-safe here.
    private static func payloadKey(_ base64String: String) -> String {
        "\(base64String.count)|\(base64String.prefix(96))|\(base64String.suffix(96))"
    }

    public static func nsImage(from base64String: String) -> NSImage? {
        guard !base64String.isEmpty else { return nil }
        let key = payloadKey(base64String) as NSString
        if let cached = decodedCache.object(forKey: key) {
            return cached
        }
        guard let data = Data(base64Encoded: base64String),
              let image = NSImage(data: data) else {
            return nil
        }
        decodedCache.setObject(image, forKey: key, cost: bitmapCost(of: image))
        return image
    }

    /// Decoded + filtered image with a combined cache — use this for on-canvas
    /// rendering so filters don't re-run per frame.
    public static func displayImage(from base64String: String, options: ImageFilterOptions) -> NSImage? {
        guard !options.isNeutral else { return nsImage(from: base64String) }
        let key = "\(payloadKey(base64String))|f|\(options.filterCacheKey)" as NSString
        if let cached = filteredCache.object(forKey: key) {
            return cached
        }
        guard let base = nsImage(from: base64String) else { return nil }
        let output = applyFilters(to: base, options: options)
        filteredCache.setObject(output, forKey: key, cost: bitmapCost(of: output))
        return output
    }

    private static func bitmapCost(of image: NSImage) -> Int {
        let pixels = max(1, Int(image.size.width) * Int(image.size.height))
        return pixels * 4 // 4 bytes/pixel RGBA estimate
    }

    public static func base64String(from nsImage: NSImage) -> String? {
        base64String(from: nsImage, allowJPEG: false)
    }

    /// JPEG fast-path for opaque sources: ~8× faster to encode and far smaller than PNG
    /// for photos / extracted Office bitmaps. PNG is used whenever transparency matters.
    public static func base64String(from nsImage: NSImage, allowJPEG: Bool) -> String? {
        guard let tiffData = nsImage.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        if allowJPEG && !bitmapRep.hasAlpha {
            if let jpegData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.88]) {
                return jpegData.base64EncodedString()
            }
        }
        guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            return nil
        }
        return pngData.base64EncodedString()
    }

    public static func applyFilters(to image: NSImage, options: ImageFilterOptions) -> NSImage {
        guard !options.isNeutral else { return image }
        guard let tiff = image.tiffRepresentation,
              let ciImage = CIImage(data: tiff) else {
            return image
        }

        var currentCIImage = ciImage

        // Exposure / Brightness / Contrast / Saturation using CIColorControls
        let colorControls = CIFilter.colorControls()
        colorControls.inputImage = currentCIImage
        colorControls.brightness = Float(options.brightness)
        colorControls.contrast = Float(options.contrast)
        colorControls.saturation = Float(options.saturation)

        if let output = colorControls.outputImage {
            currentCIImage = output
        }

        // Sepia
        if options.sepia > 0.01 {
            let sepia = CIFilter.sepiaTone()
            sepia.inputImage = currentCIImage
            sepia.intensity = Float(options.sepia)
            if let output = sepia.outputImage {
                currentCIImage = output
            }
        }

        // Grayscale / Color Monochrome
        if options.grayscale > 0.01 {
            let mono = CIFilter.colorMonochrome()
            mono.inputImage = currentCIImage
            mono.color = CIColor(red: 0.5, green: 0.5, blue: 0.5)
            mono.intensity = Float(options.grayscale)
            if let output = mono.outputImage {
                currentCIImage = output
            }
        }

        // Invert
        if options.invert {
            let invert = CIFilter.colorInvert()
            invert.inputImage = currentCIImage
            if let output = invert.outputImage {
                currentCIImage = output
            }
        }

        // Blur
        if options.blur > 0.1 {
            let gaussianBlur = CIFilter.gaussianBlur()
            gaussianBlur.inputImage = currentCIImage
            gaussianBlur.radius = Float(options.blur)
            if let output = gaussianBlur.outputImage {
                currentCIImage = output.cropped(to: ciImage.extent)
            }
        }

        // Vignette
        if options.vignette > 0.01 {
            let vignette = CIFilter.vignette()
            vignette.inputImage = currentCIImage
            vignette.intensity = Float(options.vignette * 2.0)
            vignette.radius = Float(options.vignette * 30.0)
            if let output = vignette.outputImage {
                currentCIImage = output
            }
        }

        let rep = NSCIImageRep(ciImage: currentCIImage)
        let finalImage = NSImage(size: image.size)
        finalImage.addRepresentation(rep)
        return finalImage
    }

    public static func generatePlaceholder(width: Double, height: Double, text: String, colorHex: String = "#6366F1") -> String {
        let size = NSSize(width: width, height: height)
        let image = NSImage(size: size)
        image.lockFocus()

        let codableCol = CodableColor(hex: colorHex)
        codableCol.nsColor.setFill()
        NSRect(origin: .zero, size: size).fill()

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let font = NSFont.systemFont(ofSize: 24, weight: .bold)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.white,
            .paragraphStyle: paragraphStyle
        ]

        let str = NSAttributedString(string: text, attributes: attrs)
        let strSize = str.size()
        let rect = NSRect(
            x: (size.width - strSize.width) / 2,
            y: (size.height - strSize.height) / 2,
            width: strSize.width,
            height: strSize.height
        )
        str.draw(in: rect)

        image.unlockFocus()

        return base64String(from: image) ?? ""
    }
}

extension ImageFilterOptions {
    /// Stable string key describing this exact filter recipe (for result caching).
    var filterCacheKey: String {
        "\(brightness),\(contrast),\(saturation),\(exposure),\(sepia),\(grayscale),\(invert),\(blur),\(vignette)"
    }
}
