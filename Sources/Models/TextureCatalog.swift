import SwiftUI
import AppKit

public enum TextureCategory: String, CaseIterable, Identifiable {
    case paper = "Paper & Parchment"
    case film = "Film Grain"
    case halftone = "Halftone Screen"
    case grit = "Vintage Grit & Ink"
    case plastic = "Plastic & Shrinkwrap"

    public var id: String { rawValue }
}

public struct TexturePreset: Identifiable, Hashable {
    public var id: String { key }
    public var key: String
    public var name: String
    public var category: TextureCategory
    public var description: String
    public var isOverlay: Bool

    public init(key: String, name: String, category: TextureCategory, description: String, isOverlay: Bool = false) {
        self.key = key
        self.name = name
        self.category = category
        self.description = description
        self.isOverlay = isOverlay
    }

    public var imageBase64: String? {
        TextureImageStore.getBase64(for: key)
    }

    public var nsImage: NSImage? {
        TextureImageStore.getImage(for: key)
    }
}

public enum TextureCatalog {
    public static let allTextures: [TexturePreset] = [
        // ── 📜 PAPER & PARCHMENT (8 FREE PAPER HI-RES TEXTURES PACK) ──
        TexturePreset(
            key: "paper_2",
            name: "Aged Archival Paper 02",
            category: .paper,
            description: "Official high-res archival paper with visible deckle texture"
        ),
        TexturePreset(
            key: "paper_3",
            name: "Folded Studio Paper 03",
            category: .paper,
            description: "Tactile folded stationery paper with natural paper grain"
        ),
        TexturePreset(
            key: "paper_4",
            name: "Recycled Kraft Stock 04",
            category: .paper,
            description: "Warm craft pulp paper with visible organic fibers"
        ),
        TexturePreset(
            key: "paper_5",
            name: "Pressed Vellum Card 05",
            category: .paper,
            description: "Heavy pressed fibrous cardstock paper texture"
        ),
        TexturePreset(
            key: "paper_6",
            name: "Cracked Antique Sheet 06",
            category: .paper,
            description: "Worn tea-stained paper with subtle distress lines"
        ),
        TexturePreset(
            key: "paper_7",
            name: "Parchment Document 07",
            category: .paper,
            description: "Crisp fine-tooth drafting paper surface"
        ),
        TexturePreset(
            key: "paper_8",
            name: "Wove Cotton Pulp 08",
            category: .paper,
            description: "Heavy cotton linters wove paper with tactile tooth"
        ),

        // ── 🎞️ FILM GRAIN (SKETCH COAST FILM TEXTURES PACK) ──
        TexturePreset(
            key: "film_2",
            name: "Sketch Coast Film 02",
            category: .film,
            description: "Analog 35mm film grain with silver halide emulsion depth",
            isOverlay: true
        ),
        TexturePreset(
            key: "film_3",
            name: "Sketch Coast Film 03",
            category: .film,
            description: "Cinema gate film exposure and analog dust scratches",
            isOverlay: true
        ),
        TexturePreset(
            key: "film_4",
            name: "Sketch Coast Film 04",
            category: .film,
            description: "High-ISO darkroom silver halide noise texture",
            isOverlay: true
        ),
        TexturePreset(
            key: "film_6",
            name: "Sketch Coast Film 06",
            category: .film,
            description: "Rich analog cinema film grain and vignette atmosphere",
            isOverlay: true
        ),

        // ── 🏁 HALFTONE SCREEN (HALFTONE TEXTURES FREE PACK) ──
        TexturePreset(
            key: "halftone_3",
            name: "Halftone Dots Screen 03",
            category: .halftone,
            description: "Authentic retro comic book rosette halftone screen dots",
            isOverlay: true
        ),
        TexturePreset(
            key: "halftone_4",
            name: "Halftone Dots Screen 04",
            category: .halftone,
            description: "High-contrast newspaper screen matrix print",
            isOverlay: true
        ),
        TexturePreset(
            key: "halftone_6",
            name: "Halftone Dots Screen 06",
            category: .halftone,
            description: "Fine-pitch magazine screen printing dot texture",
            isOverlay: true
        ),
        TexturePreset(
            key: "halftone_8",
            name: "Halftone Dots Screen 08",
            category: .halftone,
            description: "Retro risograph screen mesh dot matrix",
            isOverlay: true
        ),

        // ── 🪵 VINTAGE GRIT & INK (3 FREE VINTAGE GRIT TEXTURES PACK) ──
        TexturePreset(
            key: "grit_1",
            name: "Vintage Dust Grit 01",
            category: .grit,
            description: "Transparent vintage printer grit, ink specks, and grain",
            isOverlay: true
        ),
        TexturePreset(
            key: "grit_2",
            name: "Letterpress Grit 02",
            category: .grit,
            description: "Medium-density analog letterpress distress spatter",
            isOverlay: true
        ),
        TexturePreset(
            key: "grit_3",
            name: "Heavy Ink Distress 03",
            category: .grit,
            description: "Dense authentic woodblock ink wear and speckle grit",
            isOverlay: true
        ),

        // ── 📦 PLASTIC & SHRINKWRAP (FREE PLASTIC TEXTURES VOL. 1 PACK) ──
        TexturePreset(
            key: "plastic_1",
            name: "Plastic Wrap Fold 01",
            category: .plastic,
            description: "Genuine shrinkwrap plastic reflection and sharp folds",
            isOverlay: true
        ),
        TexturePreset(
            key: "plastic_2",
            name: "Plastic Packaging 02",
            category: .plastic,
            description: "Glossy packaging plastic wrinkles and light creases",
            isOverlay: true
        ),
        TexturePreset(
            key: "plastic_3",
            name: "Plastic Crinkle Sheet 03",
            category: .plastic,
            description: "Crinkled plastic mylar film with specular reflections",
            isOverlay: true
        ),
        TexturePreset(
            key: "plastic_4",
            name: "Plastic Sealed Mylar 04",
            category: .plastic,
            description: "Heat-sealed plastic packaging sleeve creases",
            isOverlay: true
        )
    ]
}
