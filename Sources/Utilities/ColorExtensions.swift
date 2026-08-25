import SwiftUI
import AppKit

public struct CodableColor: Codable, Equatable, Hashable {
    public var red: Double
    public var green: Double
    public var blue: Double
    public var opacity: Double

    public init(red: Double, green: Double, blue: Double, opacity: Double = 1.0) {
        self.red = max(0, min(1, red))
        self.green = max(0, min(1, green))
        self.blue = max(0, min(1, blue))
        self.opacity = max(0, min(1, opacity))
    }

    public init(hex: String, opacity: Double = 1.0) {
        let cleanHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch cleanHex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.red = Double(r) / 255.0
        self.green = Double(g) / 255.0
        self.blue = Double(b) / 255.0
        self.opacity = (cleanHex.count == 8) ? (Double(a) / 255.0) : opacity
    }

    public var hexString: String {
        let r = Int(round(red * 255))
        let g = Int(round(green * 255))
        let b = Int(round(blue * 255))
        if opacity < 0.999 {
            let a = Int(round(opacity * 255))
            return String(format: "#%02X%02X%02X%02X", r, g, b, a)
        } else {
            return String(format: "#%02X%02X%02X", r, g, b)
        }
    }

    public var color: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }

    public var nsColor: NSColor {
        NSColor(srgbRed: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: CGFloat(opacity))
    }

    public var cgColor: CGColor {
        nsColor.cgColor
    }

    public init(color: Color) {
        let nsColor = NSColor(color).usingColorSpace(.sRGB) ?? NSColor.black
        self.red = Double(nsColor.redComponent)
        self.green = Double(nsColor.greenComponent)
        self.blue = Double(nsColor.blueComponent)
        self.opacity = Double(nsColor.alphaComponent)
    }

    public init(nsColor: NSColor) {
        let rgb = nsColor.usingColorSpace(.sRGB) ?? NSColor.black
        self.red = Double(rgb.redComponent)
        self.green = Double(rgb.greenComponent)
        self.blue = Double(rgb.blueComponent)
        self.opacity = Double(rgb.alphaComponent)
    }

    public func withAlphaComponent(_ alpha: Double) -> CodableColor {
        var copy = self
        copy.opacity = max(0, min(1, alpha))
        return copy
    }

    // Classic & Modern Presets
    public static let white = CodableColor(red: 1, green: 1, blue: 1)
    public static let black = CodableColor(red: 0, green: 0, blue: 0)
    public static let clear = CodableColor(red: 0, green: 0, blue: 0, opacity: 0)
    public static let darkGray = CodableColor(red: 0.15, green: 0.15, blue: 0.18)
    public static let lightGray = CodableColor(red: 0.92, green: 0.92, blue: 0.95)

    // Tactile Paper & Editorial Ink Palette
    public static let inkBlack = CodableColor(hex: "#1A1816")
    public static let newsprint = CodableColor(hex: "#F6F3EC")
    public static let parchment = CodableColor(hex: "#EFE8DA")
    public static let kraftPaper = CodableColor(hex: "#D8C7B0")
    public static let terracotta = CodableColor(hex: "#C2410C")
    public static let vintageRed = CodableColor(hex: "#991B1B")
    public static let vintageForest = CodableColor(hex: "#2D4A3E")
    public static let vintageNavy = CodableColor(hex: "#1E293B")
    public static let agedBrass = CodableColor(hex: "#B45309")
    public static let waxSealRed = CodableColor(hex: "#881337")
    public static let washiSage = CodableColor(hex: "#84A98C")
    public static let washiTerracotta = CodableColor(hex: "#E07A5F")
    public static let washiMustard = CodableColor(hex: "#F2CC8F")
    public static let draftBlue = CodableColor(hex: "#1D4ED8")

    // Studio UI Accents
    public static let studioDark = CodableColor(hex: "#1C1B19")
    public static let studioPanel = CodableColor(hex: "#252422")
    public static let studioBorder = CodableColor(hex: "#3D3A37")
    public static let studioAccent = CodableColor(hex: "#D97706")
}

extension NSColor {
    public var codableColor: CodableColor {
        CodableColor(nsColor: self)
    }

    public convenience init(hex: String) {
        let c = CodableColor(hex: hex)
        self.init(srgbRed: CGFloat(c.red), green: CGFloat(c.green), blue: CGFloat(c.blue), alpha: CGFloat(c.opacity))
    }
}

extension Color {
    public init(codableColor: CodableColor) {
        self = codableColor.color
    }

    public init(hex: String) {
        self = CodableColor(hex: hex).color
    }

    public var codableColor: CodableColor {
        CodableColor(color: self)
    }
}
