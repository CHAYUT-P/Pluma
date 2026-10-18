import SwiftUI

public struct GradientStop: Codable, Equatable, Hashable, Identifiable {
    public var id: UUID
    public var color: CodableColor
    public var location: Double // 0.0 to 1.0

    public init(id: UUID = UUID(), color: CodableColor, location: Double) {
        self.id = id
        self.color = color
        self.location = max(0, min(1, location))
    }
}

public enum FillType: String, Codable, CaseIterable {
    case solid = "Solid Color"
    case newsprint = "Newsprint Paper"
    case kraft = "Kraft Paper"
    case vintageParchment = "Aged Parchment"
    case graphPaper = "Drafting Graph"
    case linearGradient = "Linear Gradient"
    case radialGradient = "Radial / Vignette"
    case glass = "Glassmorphism"
    case pattern = "Pattern Grid"
}

public enum PatternStyle: String, Codable, CaseIterable {
    case dots = "Polka Dots"
    case grid = "Grid Lines"
    case diagonalStripes = "Diagonal Stripes"
    case newspaperColumns = "Newspaper Rules"
    case halftone = "Halftone Screen"
    case halftoneFade = "Halftone Fade"
    case crosshatch = "Crosshatch"
}

public struct FillStyle: Codable, Equatable, Hashable {
    public var type: FillType
    public var solidColor: CodableColor
    public var gradientStops: [GradientStop]
    public var gradientAngle: Double // in degrees (0 to 360)
    public var patternStyle: PatternStyle
    public var patternScale: Double // spacing in points (e.g., 20.0)
    /// Ink color for pattern fills. Optional so older saved files decode fine;
    /// nil means "derive from the base tint" at render time.
    public var patternColor: CodableColor?
    public var glassBlur: Double
    public var glassOpacity: Double

    public init(
        type: FillType = .solid,
        solidColor: CodableColor = .newsprint,
        gradientStops: [GradientStop] = [
            GradientStop(color: CodableColor(hex: "#F6F3EC"), location: 0.0),
            GradientStop(color: CodableColor(hex: "#EFE8DA"), location: 1.0)
        ],
        gradientAngle: Double = 90.0,
        patternStyle: PatternStyle = .grid,
        patternScale: Double = 24.0,
        patternColor: CodableColor? = nil,
        glassBlur: Double = 20.0,
        glassOpacity: Double = 0.65
    ) {
        self.type = type
        self.solidColor = solidColor
        self.gradientStops = gradientStops
        self.gradientAngle = gradientAngle
        self.patternStyle = patternStyle
        self.patternScale = patternScale
        self.patternColor = patternColor
        self.glassBlur = glassBlur
        self.glassOpacity = glassOpacity
    }

    public static func solid(_ color: CodableColor) -> FillStyle {
        FillStyle(type: .solid, solidColor: color)
    }

    public static func paperNewsprint() -> FillStyle {
        FillStyle(type: .newsprint, solidColor: .newsprint)
    }

    public static func paperKraft() -> FillStyle {
        FillStyle(type: .kraft, solidColor: .kraftPaper)
    }

    public static func paperParchment() -> FillStyle {
        FillStyle(type: .vintageParchment, solidColor: .parchment)
    }

    public static func paperGraph() -> FillStyle {
        FillStyle(type: .graphPaper, solidColor: CodableColor(hex: "#FAF8F5"))
    }

    public static func linear(from: CodableColor, to: CodableColor, angle: Double = 45.0) -> FillStyle {
        FillStyle(
            type: .linearGradient,
            gradientStops: [
                GradientStop(color: from, location: 0.0),
                GradientStop(color: to, location: 1.0)
            ],
            gradientAngle: angle
        )
    }

    public static func presetSunset() -> FillStyle {
        FillStyle(
            type: .linearGradient,
            gradientStops: [
                GradientStop(color: CodableColor(hex: "#C2410C"), location: 0.0),
                GradientStop(color: CodableColor(hex: "#F59E0B"), location: 1.0)
            ],
            gradientAngle: 135.0
        )
    }

    public static func presetVintageEditorial() -> FillStyle {
        FillStyle(
            type: .linearGradient,
            gradientStops: [
                GradientStop(color: CodableColor(hex: "#2D4A3E"), location: 0.0),
                GradientStop(color: CodableColor(hex: "#1A1816"), location: 1.0)
            ],
            gradientAngle: 120.0
        )
    }

    public static func presetOcean() -> FillStyle {
        FillStyle(
            type: .linearGradient,
            gradientStops: [
                GradientStop(color: CodableColor(hex: "#1E3A8A"), location: 0.0),
                GradientStop(color: CodableColor(hex: "#06B6D4"), location: 1.0)
            ],
            gradientAngle: 90.0
        )
    }

    public static func presetDarkAurora() -> FillStyle {
        FillStyle(
            type: .linearGradient,
            gradientStops: [
                GradientStop(color: CodableColor(hex: "#0F172A"), location: 0.0),
                GradientStop(color: CodableColor(hex: "#1E1B4B"), location: 0.5),
                GradientStop(color: CodableColor(hex: "#065F46"), location: 1.0)
            ],
            gradientAngle: 160.0
        )
    }
}
