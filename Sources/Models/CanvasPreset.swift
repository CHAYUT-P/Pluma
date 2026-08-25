import Foundation

public struct CanvasPreset: Identifiable, Equatable, Hashable {
    public var id: String { name }
    public var name: String
    public var category: PresetCategory
    public var width: Double
    public var height: Double
    public var iconName: String
    public var description: String

    public init(name: String, category: PresetCategory, width: Double, height: Double, iconName: String, description: String) {
        self.name = name
        self.category = category
        self.width = width
        self.height = height
        self.iconName = iconName
        self.description = description
    }

    public var aspectRatioFormatted: String {
        let gcd = greatestCommonDivisor(Int(width), Int(height))
        let wRatio = Int(width) / gcd
        let hRatio = Int(height) / gcd
        if wRatio <= 20 && hRatio <= 20 {
            return "\(wRatio):\(hRatio)"
        }
        return "\(Int(width)) × \(Int(height))"
    }

    private func greatestCommonDivisor(_ a: Int, _ b: Int) -> Int {
        var a = a
        var b = b
        while b != 0 {
            let t = b
            b = a % b
            a = t
        }
        return a
    }

    public static let presets: [CanvasPreset] = [
        // Social Media
        CanvasPreset(name: "Instagram Post (Square)", category: .social, width: 1080, height: 1080, iconName: "camera.fill", description: "1080 × 1080 px • 1:1"),
        CanvasPreset(name: "Instagram Portrait", category: .social, width: 1080, height: 1350, iconName: "rectangle.portrait.fill", description: "1080 × 1350 px • 4:5"),
        CanvasPreset(name: "Instagram / TikTok Story", category: .social, width: 1080, height: 1920, iconName: "iphone", description: "1080 × 1920 px • 9:16"),
        CanvasPreset(name: "YouTube Thumbnail", category: .social, width: 1280, height: 720, iconName: "play.rectangle.fill", description: "1280 × 720 px • 16:9"),
        CanvasPreset(name: "Twitter / X Header", category: .social, width: 1500, height: 500, iconName: "bubble.left.and.bubble.right.fill", description: "1500 × 500 px • 3:1"),
        CanvasPreset(name: "Twitter / X Post", category: .social, width: 1200, height: 675, iconName: "text.bubble.fill", description: "1200 × 675 px • 16:9"),
        CanvasPreset(name: "LinkedIn Banner", category: .social, width: 1584, height: 396, iconName: "briefcase.fill", description: "1584 × 396 px • 4:1"),

        // Presentation & Display
        CanvasPreset(name: "Presentation (16:9)", category: .presentation, width: 1920, height: 1080, iconName: "tv.fill", description: "1920 × 1080 px • Full HD"),
        CanvasPreset(name: "4K Presentation / Wallpaper", category: .presentation, width: 3840, height: 2160, iconName: "sparkles.tv.fill", description: "3840 × 2160 px • Ultra HD 4K"),
        CanvasPreset(name: "MacBook Wallpaper", category: .presentation, width: 2880, height: 1800, iconName: "laptopcomputer", description: "2880 × 1800 px • Retina 16:10"),

        // Print & Documents
        CanvasPreset(name: "A4 Document", category: .print, width: 1240, height: 1754, iconName: "doc.text.fill", description: "A4 • 150 DPI"),
        CanvasPreset(name: "US Letter", category: .print, width: 1275, height: 1650, iconName: "doc.fill", description: "8.5 × 11 in • 150 DPI"),
        CanvasPreset(name: "Business Card", category: .print, width: 1050, height: 600, iconName: "creditcard.fill", description: "3.5 × 2 in • 300 DPI"),
        CanvasPreset(name: "Poster (Portrait)", category: .print, width: 1200, height: 1800, iconName: "newspaper.fill", description: "2:3 Poster format"),

        // Whiteboard & Freeform Mindmaps
        CanvasPreset(name: "Infinite Whiteboard (Figma Style)", category: .whiteboard, width: 3600, height: 2400, iconName: "brain.head.profile", description: "3600 × 2400 px • Boundless freeform canvas"),
        CanvasPreset(name: "Mindmap & Brainstorming", category: .whiteboard, width: 3200, height: 2000, iconName: "point.topleft.down.curvedto.point.bottomright.up", description: "3200 × 2000 px • Expansive idea board")
    ]

    public static func a4() -> CanvasPreset {
        CanvasPreset(name: "A4 Document", category: .print, width: 1240, height: 1754, iconName: "doc.text.fill", description: "A4 • 150 DPI")
    }

    public static func whiteboard() -> CanvasPreset {
        CanvasPreset(name: "Infinite Whiteboard", category: .whiteboard, width: 3600, height: 2400, iconName: "brain.head.profile", description: "3600 × 2400 px • Boundless freeform canvas")
    }
}

public enum PresetCategory: String, CaseIterable, Identifiable {
    case whiteboard = "Whiteboard & Mindmap"
    case print = "Print & Documents"
    case presentation = "Presentations & Screens"
    case social = "Social Media"
    case marketing = "Design & Marketing"

    public var id: String { rawValue }
}
