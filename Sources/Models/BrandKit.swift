import SwiftUI

public struct BrandKit: Codable, Identifiable, Equatable {
    public var id: UUID
    public var name: String
    public var colors: [CodableColor]
    public var headingFontName: String
    public var bodyFontName: String
    public var monoFontName: String

    public init(
        id: UUID = UUID(),
        name: String,
        colors: [CodableColor],
        headingFontName: String = "Playfair Display",
        bodyFontName: String = "Inter",
        monoFontName: String = "JetBrains Mono"
    ) {
        self.id = id
        self.name = name
        self.colors = colors
        self.headingFontName = headingFontName
        self.bodyFontName = bodyFontName
        self.monoFontName = monoFontName
    }

    public static let defaults: [BrandKit] = [
        BrandKit(
            name: "Studio Terracotta",
            colors: [
                CodableColor(hex: "#C2410C"),
                CodableColor(hex: "#D97706"),
                CodableColor(hex: "#1C1917"),
                CodableColor(hex: "#78716C"),
                CodableColor(hex: "#FAF7F0")
            ],
            headingFontName: "Playfair Display",
            bodyFontName: "Inter",
            monoFontName: "JetBrains Mono"
        ),
        BrandKit(
            name: "Cyber Neon Glow",
            colors: [
                CodableColor(hex: "#09090B"),
                CodableColor(hex: "#8B5CF6"),
                CodableColor(hex: "#EC4899"),
                CodableColor(hex: "#06B6D4"),
                CodableColor(hex: "#FFFFFF")
            ],
            headingFontName: "SF Pro Display",
            bodyFontName: "SF Pro Text",
            monoFontName: "SF Mono"
        ),
        BrandKit(
            name: "Nordic Minimalist",
            colors: [
                CodableColor(hex: "#0F172A"),
                CodableColor(hex: "#38BDF8"),
                CodableColor(hex: "#64748B"),
                CodableColor(hex: "#E2E8F0"),
                CodableColor(hex: "#F8FAFC")
            ],
            headingFontName: "Helvetica Neue",
            bodyFontName: "Inter",
            monoFontName: "Fira Code"
        )
    ]
}
