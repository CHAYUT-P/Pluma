import Foundation

public enum FontLicenseTier: String, CaseIterable, Identifiable {
    case commercial = "Commercial Use (Free)"
    case personal = "Personal Use (Free)"

    public var id: String { rawValue }
    public var badgeLabel: String {
        switch self {
        case .commercial: return "Commercial Free"
        case .personal: return "Personal Use"
        }
    }
    public var badgeIcon: String {
        switch self {
        case .commercial: return "checkmark.seal.fill"
        case .personal: return "person.fill"
        }
    }
}

public struct FontItem: Identifiable, Hashable {
    public var id: String { name }
    public var name: String
    public var category: String
    public var license: FontLicenseTier

    public init(name: String, category: String, license: FontLicenseTier) {
        self.name = name
        self.category = category
        self.license = license
    }
}

public enum FontCatalog {
    public static let allFonts: [FontItem] = [
        // ── 🏷️ COMMERCIAL USE (FREE FOR ALL WORK) ──
        FontItem(name: "Playfair Display", category: "Editorial Serif", license: .commercial),
        FontItem(name: "Georgia", category: "Classic Serif", license: .commercial),
        FontItem(name: "Bodoni 72", category: "Luxury Serif", license: .commercial),
        FontItem(name: "Didot", category: "High Fashion Serif", license: .commercial),
        FontItem(name: "Baskerville", category: "Book Serif", license: .commercial),
        FontItem(name: "Palatino", category: "Editorial Serif", license: .commercial),
        FontItem(name: "Charter", category: "Literary Serif", license: .commercial),
        FontItem(name: "Times New Roman", category: "Classic Serif", license: .commercial),
        FontItem(name: "Inter", category: "Clean UI Sans", license: .commercial),
        FontItem(name: "Helvetica Neue", category: "Neo-Grotesque", license: .commercial),
        FontItem(name: "SF Pro", category: "Apple System Sans", license: .commercial),
        FontItem(name: "Avenir Next", category: "Geometric Sans", license: .commercial),
        FontItem(name: "Futura", category: "Modernist Sans", license: .commercial),
        FontItem(name: "Optima", category: "Humanist Sans", license: .commercial),
        FontItem(name: "Gill Sans", category: "British Geometric", license: .commercial),
        FontItem(name: "Trebuchet MS", category: "Display Sans", license: .commercial),
        FontItem(name: "Impact", category: "Brutalist Poster", license: .commercial),
        FontItem(name: "Copperplate", category: "Engraved All-Caps", license: .commercial),
        FontItem(name: "Phosphate", category: "Inline Neon Display", license: .commercial),
        FontItem(name: "SF Mono", category: "Code Monospace", license: .commercial),
        FontItem(name: "Menlo", category: "Code Monospace", license: .commercial),
        FontItem(name: "Courier New", category: "Typewriter Mono", license: .commercial),
        FontItem(name: "Monaco", category: "Terminal Mono", license: .commercial),
        FontItem(name: "Snell Roundhand", category: "Calligraphic Script", license: .commercial),
        FontItem(name: "Zapfino", category: "Formal Calligraphy", license: .commercial),

        // ── 🎨 PERSONAL USE (FREE FOR PERSONAL PROJECTS - PIXEL SURPLUS & RETRO FINDS) ──
        FontItem(name: "Lohgant Script", category: "Vintage Upright Script", license: .personal),
        FontItem(name: "Morgan Journey", category: "Organic Hand Lettering", license: .personal),
        FontItem(name: "Wild Youth", category: "Adventure Brush Script", license: .personal),
        FontItem(name: "Billion Dreams", category: "Modern Calligraphy", license: .personal),
        FontItem(name: "Rustico", category: "Distressed Brush Sans", license: .personal),
        FontItem(name: "Butler", category: "High Contrast Modern Serif", license: .personal),
        FontItem(name: "Salmela", category: "Romantic Flourish Script", license: .personal),
        FontItem(name: "Milkshake", category: "Thick Retro Script", license: .personal),
        FontItem(name: "Great Vibes", category: "Flowing Script", license: .personal),
        FontItem(name: "Allura", category: "Handwritten Signature", license: .personal),
        FontItem(name: "Sacramento", category: "Monoline Script", license: .personal),
        FontItem(name: "Pacifico", category: "Casual Surf Script", license: .personal),
        FontItem(name: "Bradley Hand", category: "Casual Handwriting", license: .personal),
        FontItem(name: "Chalkduster", category: "Chalkboard Grit", license: .personal),
        FontItem(name: "Brush Script MT", category: "Midcentury Brush", license: .personal),
        FontItem(name: "Papyrus", category: "Antique Distressed", license: .personal),
        FontItem(name: "Herculanum", category: "Ancient Roman Inscribed", license: .personal)
    ]

    public static var commercialFonts: [FontItem] {
        allFonts.filter { $0.license == .commercial }
    }

    public static var personalFonts: [FontItem] {
        allFonts.filter { $0.license == .personal }
    }
}
