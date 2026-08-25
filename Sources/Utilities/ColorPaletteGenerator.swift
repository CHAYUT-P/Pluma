import SwiftUI
import AppKit

public struct GeneratedPalette: Identifiable, Hashable {
    public var id: String { name }
    public var name: String
    public var colors: [CodableColor]

    public init(name: String, colors: [CodableColor]) {
        self.name = name
        self.colors = colors
    }
}

public final class ColorPaletteGenerator {
    public static let shared = ColorPaletteGenerator()

    private init() {}

    public static let curatedPalettes: [GeneratedPalette] = [
        GeneratedPalette(name: "Terracotta Modern", colors: [
            CodableColor(hex: "#C2410C"),
            CodableColor(hex: "#EA580C"),
            CodableColor(hex: "#F97316"),
            CodableColor(hex: "#FED7AA"),
            CodableColor(hex: "#7C2D12")
        ]),
        GeneratedPalette(name: "Nordic Frost", colors: [
            CodableColor(hex: "#0F172A"),
            CodableColor(hex: "#1E293B"),
            CodableColor(hex: "#38BDF8"),
            CodableColor(hex: "#BAE6FD"),
            CodableColor(hex: "#F0F9FF")
        ]),
        GeneratedPalette(name: "Cyber Neon", colors: [
            CodableColor(hex: "#09090B"),
            CodableColor(hex: "#A855F7"),
            CodableColor(hex: "#EC4899"),
            CodableColor(hex: "#06B6D4"),
            CodableColor(hex: "#10B981")
        ]),
        GeneratedPalette(name: "Earthy Botanical", colors: [
            CodableColor(hex: "#14532D"),
            CodableColor(hex: "#16A34A"),
            CodableColor(hex: "#86EFAC"),
            CodableColor(hex: "#FEF08A"),
            CodableColor(hex: "#78350F")
        ]),
        GeneratedPalette(name: "Sunset Studio", colors: [
            CodableColor(hex: "#4A044E"),
            CodableColor(hex: "#9333EA"),
            CodableColor(hex: "#F43F5E"),
            CodableColor(hex: "#FB923C"),
            CodableColor(hex: "#FEF3C7")
        ]),
        GeneratedPalette(name: "Minimalist Slate", colors: [
            CodableColor(hex: "#18181B"),
            CodableColor(hex: "#3F3F46"),
            CodableColor(hex: "#71717A"),
            CodableColor(hex: "#D4D4D8"),
            CodableColor(hex: "#FAFAFA")
        ])
    ]

    /// Extract 5 dominant colors from an image
    public func extractPalette(from image: NSImage) -> [CodableColor] {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return Self.curatedPalettes[0].colors
        }

        let width = 64
        let height = 64
        var rawData = [UInt8](repeating: 0, count: width * height * 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: &rawData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return Self.curatedPalettes[0].colors
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var buckets: [String: (r: Double, g: Double, b: Double, count: Int)] = [:]

        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * 4
                let a = Double(rawData[offset + 3]) / 255.0
                if a < 0.2 { continue }

                let r = Double(rawData[offset])
                let g = Double(rawData[offset + 1])
                let b = Double(rawData[offset + 2])

                // Quantize to 32-step buckets
                let qr = Int(r / 32) * 32
                let qg = Int(g / 32) * 32
                let qb = Int(b / 32) * 32
                let key = "\(qr)-\(qg)-\(qb)"

                if var item = buckets[key] {
                    item.r += r
                    item.g += g
                    item.b += b
                    item.count += 1
                    buckets[key] = item
                } else {
                    buckets[key] = (r, g, b, 1)
                }
            }
        }

        let sorted = buckets.values.sorted { $0.count > $1.count }
        let top5 = sorted.prefix(5)

        if top5.isEmpty { return Self.curatedPalettes[0].colors }

        return top5.map { item in
            let r = item.r / Double(item.count) / 255.0
            let g = item.g / Double(item.count) / 255.0
            let b = item.b / Double(item.count) / 255.0
            return CodableColor(red: r, green: g, blue: b, opacity: 1.0)
        }
    }
}
