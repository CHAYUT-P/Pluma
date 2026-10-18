import SwiftUI
import CoreGraphics

/// Resolves the ink color a pattern fill draws with: explicit `patternColor`
/// wins, otherwise a darkened/lightened derivation of the base tint keeps
/// pattern contrast automatic.
public enum PatternInk {
    public static func resolve(for fill: FillStyle) -> CodableColor {
        if let c = fill.patternColor { return c }
        let base = fill.solidColor
        let lum = 0.2126 * base.red + 0.7152 * base.green + 0.0722 * base.blue
        // Light base → ink in dark; dark base → ink in paper white
        return lum > 0.55
            ? CodableColor(red: base.red * 0.45, green: base.green * 0.45, blue: base.blue * 0.45, opacity: 0.9)
            : CodableColor(red: min(1, base.red + 0.75), green: min(1, base.green + 0.75), blue: min(1, base.blue + 0.75), opacity: 0.9)
    }
}

/// SwiftUI pattern overlay — drawn inside the shape's clip so any fill style
/// (polka dots, grid, stripes, halftone screens…) works on any shape or page.
public struct PatternFillView: View {
    public let style: PatternStyle
    public let scale: Double
    public let ink: Color

    public init(fill: FillStyle) {
        self.style = fill.patternStyle
        self.scale = fill.patternScale
        self.ink = PatternInk.resolve(for: fill).color
    }

    public var body: some View {
        switch style {
        case .halftone:
            HalftonePatternView(ink: ink, spacing: max(6, scale * 0.6), maxRadius: max(1.5, scale * 0.16), ramp: .uniform(0.62))
        case .halftoneFade:
            HalftonePatternView(ink: ink, spacing: max(6, scale * 0.6), maxRadius: max(1.5, scale * 0.16), ramp: .linear(angle: 90, from: 0.95, to: 0.0))
        default:
            Canvas { context, size in
                drawPattern(context: &context, size: size)
            }
            .allowsHitTesting(false)
        }
    }

    private func drawPattern(context: inout GraphicsContext, size: CGSize) {
        let s = CGFloat(max(6, scale))
        switch style {
        case .dots:
            var y: CGFloat = s / 2
            while y < size.height {
                var x: CGFloat = s / 2
                while x < size.width {
                    let r = s * 0.14
                    context.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)), with: .color(ink))
                    x += s
                }
                y += s
            }
        case .grid:
            var p = Path()
            var x: CGFloat = 0
            while x <= size.width { p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: size.height)); x += s }
            var y: CGFloat = 0
            while y <= size.height { p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: size.width, y: y)); y += s }
            context.stroke(p, with: .color(ink.opacity(0.5)), lineWidth: 0.6)
        case .diagonalStripes:
            var p = Path()
            let diag = size.width + size.height
            var t: CGFloat = -size.height
            while t < diag {
                p.move(to: CGPoint(x: t, y: 0))
                p.addLine(to: CGPoint(x: t + size.height, y: size.height))
                t += s
            }
            context.stroke(p, with: .color(ink.opacity(0.6)), lineWidth: max(0.8, s * 0.09))
        case .newspaperColumns:
            var p = Path()
            var x: CGFloat = s
            while x < size.width {
                p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: size.height))
                x += s * 2.2
            }
            context.stroke(p, with: .color(ink.opacity(0.55)), lineWidth: 1.0)
        case .crosshatch:
            var p = Path()
            let diag = size.width + size.height
            var t: CGFloat = -size.height
            while t < diag {
                p.move(to: CGPoint(x: t, y: 0)); p.addLine(to: CGPoint(x: t + size.height, y: size.height))
                p.move(to: CGPoint(x: t + size.height, y: 0)); p.addLine(to: CGPoint(x: t, y: size.height))
                t += s
            }
            context.stroke(p, with: .color(ink.opacity(0.45)), lineWidth: 0.7)
        case .halftone, .halftoneFade:
            break // handled by HalftonePatternView above
        }
    }
}

// MARK: - CoreGraphics variant for ExportEngine / thumbnails

public enum PatternFillCG {
    /// Draws the pattern inside the current CG clip region. Call between
    /// saveGState/clip and restoreGState.
    public static func draw(fill: FillStyle, in rect: CGRect, context: CGContext) {
        let ink = PatternInk.resolve(for: fill).cgColor
        let s = CGFloat(max(6, fill.patternScale))
        context.saveGState()
        context.setFillColor(ink)
        context.setStrokeColor(ink)

        switch fill.patternStyle {
        case .dots:
            var y = rect.minY + s / 2
            while y < rect.maxY {
                var x = rect.minX + s / 2
                while x < rect.maxX {
                    let r = s * 0.14
                    context.fillEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
                    x += s
                }
                y += s
            }
        case .halftone, .halftoneFade:
            let step = max(6, s * 0.6)
            let maxR = max(1.5, s * 0.16)
            var y = rect.minY + step / 2
            var row = 0
            while y < rect.maxY {
                var x = rect.minX + step / 2 + (row % 2 == 0 ? 0 : step / 2)
                while x < rect.maxX {
                    var d = 0.62
                    if fill.patternStyle == .halftoneFade {
                        let t = (y - rect.minY) / max(1, rect.height)
                        d = max(0, 0.95 * (1 - Double(t)))
                    }
                    let r = maxR * CGFloat(d)
                    if r > 0.15 {
                        context.fillEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
                    }
                    x += step
                }
                y += step * 0.87
                row += 1
            }
        case .grid:
            context.setLineWidth(0.6)
            context.setAlpha(0.5)
            var x = rect.minX
            while x <= rect.maxX {
                context.move(to: CGPoint(x: x, y: rect.minY)); context.addLine(to: CGPoint(x: x, y: rect.maxY))
                x += s
            }
            var y = rect.minY
            while y <= rect.maxY {
                context.move(to: CGPoint(x: rect.minX, y: y)); context.addLine(to: CGPoint(x: rect.maxX, y: y))
                y += s
            }
            context.strokePath()
        case .diagonalStripes:
            context.setLineWidth(max(0.8, s * 0.09))
            context.setAlpha(0.6)
            var t = rect.minX - rect.height
            while t < rect.maxX + rect.height {
                context.move(to: CGPoint(x: t, y: rect.minY))
                context.addLine(to: CGPoint(x: t + rect.height, y: rect.maxY))
                t += s
            }
            context.strokePath()
        case .newspaperColumns:
            context.setLineWidth(1.0)
            context.setAlpha(0.55)
            var x = rect.minX + s
            while x < rect.maxX {
                context.move(to: CGPoint(x: x, y: rect.minY)); context.addLine(to: CGPoint(x: x, y: rect.maxY))
                x += s * 2.2
            }
            context.strokePath()
        case .crosshatch:
            context.setLineWidth(0.7)
            context.setAlpha(0.45)
            var t = rect.minX - rect.height
            while t < rect.maxX + rect.height {
                context.move(to: CGPoint(x: t, y: rect.minY)); context.addLine(to: CGPoint(x: t + rect.height, y: rect.maxY))
                context.move(to: CGPoint(x: t + rect.height, y: rect.minY)); context.addLine(to: CGPoint(x: t, y: rect.maxY))
                t += s
            }
            context.strokePath()
        }
        context.restoreGState()
    }
}
