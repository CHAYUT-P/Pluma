import Foundation
import SwiftUI

public enum ShapeKind: String, Codable, CaseIterable {
    case rectangle = "Rectangle"
    case roundedRectangle = "Rounded Card"
    case pill = "Pill / Capsule"
    case washiTape = "Washi Tape"
    case postageStamp = "Postage Stamp"
    case waxSeal = "Wax Seal"
    case tornPaper = "Torn Paper"
    case oxfordBorder = "Newspaper Rule"
    case circle = "Circle / Stamp"
    case triangle = "Triangle"
    case star = "Star Badge"
    case sparkleStar = "4-Point Sparkle"
    case starburst = "Sunburst Badge"
    case polygon = "Hexagon"
    case diamond = "Diamond"
    case heart = "Heart"
    case flower = "Petal Flower"
    case arrow = "Arrow"
    case chevron = "Chevron Arrow"
    case speechBubble = "Speech Bubble"
    case quoteBubble = "Quote Callout"
    case bannerRibbon = "Ribbon Banner"
    case bookmark = "Bookmark Notch"
    case arch = "Arch Doorway"
    case shield = "Shield Badge"
    case tag = "Price Tag"
    case ticket = "Ticket / Coupon"
    case cross = "Plus / Cross"
    case lightning = "Lightning Bolt"
    case crescentMoon = "Crescent Moon"
    case donut = "Ring / Donut"
    case parallelogram = "Parallelogram"
    case trapezoid = "Trapezoid"
    case cloud = "Cloud"
    case badge = "Embossed Seal"
    case line = "Line / Hairline"
}

public struct ShapeContent: Codable, Equatable, Hashable {
    public var kind: ShapeKind
    public var cornerRadius: Double
    public var starPoints: Int
    public var polygonSides: Int
    public var fill: FillStyle
    public var stroke: StrokeStyle

    public init(
        kind: ShapeKind = .roundedRectangle,
        cornerRadius: Double = 12.0,
        starPoints: Int = 5,
        polygonSides: Int = 6,
        fill: FillStyle = .solid(.newsprint),
        stroke: StrokeStyle = StrokeStyle(isEnabled: true, color: .inkBlack, lineWidth: 1.5)
    ) {
        self.kind = kind
        self.cornerRadius = cornerRadius
        self.starPoints = starPoints
        self.polygonSides = polygonSides
        self.fill = fill
        self.stroke = stroke
    }
}

public enum TextAlignmentKind: String, Codable, CaseIterable {
    case left = "Left"
    case center = "Center"
    case right = "Right"
    case justified = "Justified"

    public var textAlignment: TextAlignment {
        switch self {
        case .left: return .leading
        case .center: return .center
        case .right: return .trailing
        case .justified: return .leading
        }
    }

    public var nsTextAlignment: NSTextAlignment {
        switch self {
        case .left: return .left
        case .center: return .center
        case .right: return .right
        case .justified: return .justified
        }
    }
}

public enum TextEffectKind: String, Codable, CaseIterable {
    case none = "None"
    case outline = "Hollow Outline"
    case neon = "Neon Glow"
    case shadow = "Drop Shadow"
    case backgroundPill = "Highlighter Pill"
    case letterpressDeboss = "Letterpress Deboss"
    case stampDistressed = "Rubber Stamp"
}

public struct TextContent: Codable, Equatable, Hashable {
    public var text: String
    public var fontFamily: String
    public var fontSize: Double
    public var fontWeight: Double // 100 to 900
    public var isItalic: Bool
    public var isUnderlined: Bool
    public var alignment: TextAlignmentKind
    public var textColor: CodableColor
    public var useGradient: Bool
    public var textGradient: FillStyle
    public var letterSpacing: Double // Tracking
    public var lineSpacing: Double
    public var effectKind: TextEffectKind
    public var effectColor: CodableColor
    public var effectWidth: Double
    public var outlineColor: CodableColor
    public var outlineWidth: Double
    public var isCurved: Bool
    public var curveAngle: Double
    public var cardBackground: CodableColor?
    public var cardBorderColor: CodableColor?
    public var cardBorderWidth: Double
    public var cardCornerRadius: Double
    public var cardPadding: Double

    public init(
        text: String = "THE DAILY DISPATCH",
        fontFamily: String = "Playfair Display",
        fontSize: Double = 44.0,
        fontWeight: Double = 800,
        isItalic: Bool = false,
        isUnderlined: Bool = false,
        alignment: TextAlignmentKind = .center,
        textColor: CodableColor = .inkBlack,
        useGradient: Bool = false,
        textGradient: FillStyle = .presetSunset(),
        letterSpacing: Double = 1.0,
        lineSpacing: Double = 4.0,
        effectKind: TextEffectKind = .none,
        effectColor: CodableColor = CodableColor(hex: "#C2410C"),
        effectWidth: Double = 2.0,
        outlineColor: CodableColor = .inkBlack,
        outlineWidth: Double = 2.0,
        isCurved: Bool = false,
        curveAngle: Double = 180.0,
        cardBackground: CodableColor? = nil,
        cardBorderColor: CodableColor? = nil,
        cardBorderWidth: Double = 0.0,
        cardCornerRadius: Double = 0.0,
        cardPadding: Double = 0.0
    ) {
        self.text = text
        self.fontFamily = fontFamily
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.isItalic = isItalic
        self.isUnderlined = isUnderlined
        self.alignment = alignment
        self.textColor = textColor
        self.useGradient = useGradient
        self.textGradient = textGradient
        self.letterSpacing = letterSpacing
        self.lineSpacing = lineSpacing
        self.effectKind = effectKind
        self.effectColor = effectColor
        self.effectWidth = effectWidth
        self.outlineColor = outlineColor
        self.outlineWidth = outlineWidth
        self.isCurved = isCurved
        self.curveAngle = curveAngle
        self.cardBackground = cardBackground
        self.cardBorderColor = cardBorderColor
        self.cardBorderWidth = cardBorderWidth
        self.cardCornerRadius = cardCornerRadius
        self.cardPadding = cardPadding
    }
}

public enum ImageContentMode: String, Codable, CaseIterable {
    case fit = "Fit"
    case fill = "Fill / Crop"
    case stretch = "Stretch"
}

public struct ImageContent: Codable, Equatable, Hashable {
    public var imageBase64: String
    public var contentMode: ImageContentMode
    public var cornerRadius: Double
    public var frameKind: ShapeKind?
    public var filter: ImageFilterOptions
    public var stroke: StrokeStyle
    public var originalWidth: Double
    public var originalHeight: Double

    public init(
        imageBase64: String = "",
        contentMode: ImageContentMode = .fill,
        cornerRadius: Double = 4.0,
        frameKind: ShapeKind? = nil,
        filter: ImageFilterOptions = .default,
        stroke: StrokeStyle = StrokeStyle(isEnabled: true, color: .inkBlack, lineWidth: 1.5),
        originalWidth: Double = 800,
        originalHeight: Double = 600
    ) {
        self.imageBase64 = imageBase64
        self.contentMode = contentMode
        self.cornerRadius = cornerRadius
        self.frameKind = frameKind
        self.filter = filter
        self.stroke = stroke
        self.originalWidth = originalWidth
        self.originalHeight = originalHeight
    }
}

public struct IconContent: Codable, Equatable, Hashable {
    public var symbolName: String
    public var primaryColor: CodableColor
    public var secondaryColor: CodableColor
    public var tertiaryColor: CodableColor
    public var isMulticolor: Bool

    public init(
        symbolName: String = "newspaper.fill",
        primaryColor: CodableColor = .inkBlack,
        secondaryColor: CodableColor = .terracotta,
        tertiaryColor: CodableColor = .agedBrass,
        isMulticolor: Bool = false
    ) {
        self.symbolName = symbolName
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.tertiaryColor = tertiaryColor
        self.isMulticolor = isMulticolor
    }
}

public struct DrawingPoint: Codable, Equatable, Hashable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    public init(_ point: CGPoint) {
        self.x = Double(point.x)
        self.y = Double(point.y)
    }

    public var cgPoint: CGPoint {
        CGPoint(x: x, y: y)
    }
}

public struct DrawingContent: Codable, Equatable, Hashable {
    public var points: [DrawingPoint]
    public var strokeColor: CodableColor
    public var lineWidth: Double
    public var isSmooth: Bool

    public init(
        points: [DrawingPoint] = [],
        strokeColor: CodableColor = .inkBlack,
        lineWidth: Double = 3.0,
        isSmooth: Bool = true
    ) {
        self.points = points
        self.strokeColor = strokeColor
        self.lineWidth = lineWidth
        self.isSmooth = isSmooth
    }
}

public enum ElementPayload: Codable, Equatable, Hashable {
    case shape(ShapeContent)
    case text(TextContent)
    case image(ImageContent)
    case icon(IconContent)
    case drawing(DrawingContent)
    case code(CodeContent)
}

/// Anchored-connector metadata (whiteboard arrows glued to two elements).
/// The element carrying this stays geometrically synced to its endpoints.
public struct ConnectorInfo: Codable, Equatable, Hashable {
    public var fromID: UUID
    public var toID: UUID
    public init(fromID: UUID, toID: UUID) {
        self.fromID = fromID
        self.toID = toID
    }
}

public struct CanvasElement: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public var name: String
    public var payload: ElementPayload
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double
    public var rotation: Double // in degrees
    public var opacity: Double
    public var isLocked: Bool
    public var isVisible: Bool
    public var shadow: ShadowEffect
    public var zIndex: Int
    public var groupId: UUID?
    public var backdropBlur: Double
    public var borderGlow: CodableColor?
    /// Mirror flips (optional for JSON backward-compatibility with older projects).
    public var flipH: Bool?
    public var flipV: Bool?
    /// Present when this element is an anchored connector (arrow linked to two elements).
    public var connector: ConnectorInfo?

    public var isFlippedH: Bool { flipH ?? false }
    public var isFlippedV: Bool { flipV ?? false }

    public init(
        id: UUID = UUID(),
        name: String = "Element",
        payload: ElementPayload,
        x: Double,
        y: Double,
        width: Double,
        height: Double,
        rotation: Double = 0.0,
        opacity: Double = 1.0,
        isLocked: Bool = false,
        isVisible: Bool = true,
        shadow: ShadowEffect = .none,
        zIndex: Int = 0,
        groupId: UUID? = nil,
        backdropBlur: Double = 0.0,
        borderGlow: CodableColor? = nil,
        flipH: Bool = false,
        flipV: Bool = false,
        connector: ConnectorInfo? = nil
    ) {
        self.id = id
        self.name = name
        self.payload = payload
        self.x = x
        self.y = y
        self.width = max(5, width)
        self.height = max(5, height)
        self.rotation = rotation
        self.opacity = max(0, min(1, opacity))
        self.isLocked = isLocked
        self.isVisible = isVisible
        self.shadow = shadow
        self.zIndex = zIndex
        self.groupId = groupId
        self.backdropBlur = backdropBlur
        self.borderGlow = borderGlow
        self.flipH = flipH
        self.flipV = flipV
        self.connector = connector
    }

    public var frame: CGRect {
        get { CGRect(x: x, y: y, width: width, height: height) }
        set {
            x = Double(newValue.origin.x)
            y = Double(newValue.origin.y)
            width = Double(newValue.size.width)
            height = Double(newValue.size.height)
        }
    }

    public var center: CGPoint {
        CGPoint(x: x + width / 2.0, y: y + height / 2.0)
    }

    public var bounds: CGRect {
        CGRect(x: 0, y: 0, width: width, height: height)
    }

    /// Axis-aligned bounding box of this element AFTER rotation, in canvas space.
    /// Used for hit-testing, marquee selection, zoom-to-fit and viewport culling.
    public var rotatedCanvasBounds: CGRect {
        let t = rotation.truncatingRemainder(dividingBy: 360.0) * .pi / 180.0
        let c = abs(cos(t))
        let s = abs(sin(t))
        let bw = width * c + height * s
        let bh = width * s + height * c
        return CGRect(
            x: x + width / 2.0 - bw / 2.0,
            y: y + height / 2.0 - bh / 2.0,
            width: bw,
            height: bh
        )
    }
}
