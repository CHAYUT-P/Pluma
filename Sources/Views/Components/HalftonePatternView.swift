import SwiftUI

/// Procedural halftone dot screen — the signature Pluma print-shop texture.
///
/// A real halftone screen simulates ink density by varying DOT SIZE on a fixed
/// grid (not opacity), which is exactly what this renders: `density` at each
/// cell maps to the dot's radius. Two density modes:
///   • `uniform(d)` — every dot the same size (classic comic-dot wallpaper)
///   • `linear(angle, from, to)` — a screen ramp, e.g. dots shrinking left→right
///
/// Drawn with `Canvas` so a full-sidebar field costs one render pass.
public struct HalftonePatternView: View {
    public enum DensityRamp {
        case uniform(Double)
        /// Dots ramp `from`→`to` density along `angle` degrees (0 = left→right).
        case linear(angle: Double, from: Double, to: Double)
        /// Densest at the view's vertical center, fading to nothing at the edges
        /// — used for toolbar/footer accent strips.
        case verticalBand
    }

    public var ink: Color
    public var spacing: Double
    public var maxRadius: Double
    public var ramp: DensityRamp

    public init(
        ink: Color = Color(hex: "#1C1917"),
        spacing: Double = 12,
        maxRadius: Double = 3.0,
        ramp: DensityRamp = .uniform(0.55)
    ) {
        self.ink = ink
        self.spacing = max(4, spacing)
        self.maxRadius = maxRadius
        self.ramp = ramp
    }

    public var body: some View {
        Canvas { context, size in
            guard size.width > 0, size.height > 0 else { return }
            let step = CGFloat(spacing)
            var y: CGFloat = step / 2
            var row = 0
            while y < size.height {
                var x: CGFloat = step / 2 + (row % 2 == 0 ? 0 : step / 2) // staggered rows = real rosette screen
                while x < size.width {
                    let d = density(atX: x, atY: y, in: size)
                    let r = CGFloat(maxRadius) * CGFloat(d)
                    if r > 0.15 {
                        let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
                        context.fill(Path(ellipseIn: rect), with: .color(ink))
                    }
                    x += step
                }
                y += step * 0.87 // ~30° screen angle rows
                row += 1
            }
        }
        .allowsHitTesting(false)
    }

    private func density(atX x: CGFloat, atY y: CGFloat, in size: CGSize) -> Double {
        switch ramp {
        case .uniform(let d):
            return max(0, min(1, d))
        case .linear(let angle, let from, let to):
            let rad = angle * .pi / 180
            let dir = CGPoint(x: cos(rad), y: sin(rad))
            // Project the point onto the ramp axis, normalized 0…1
            let extent = abs(dir.x) * size.width + abs(dir.y) * size.height
            guard extent > 0 else { return from }
            let origin = CGPoint(
                x: dir.x >= 0 ? 0 : size.width,
                y: dir.y >= 0 ? 0 : size.height
            )
            let t = ((x - origin.x) * dir.x + (y - origin.y) * dir.y) / extent
            return max(0, min(1, from + (to - from) * Double(t)))
        case .verticalBand:
            // 1 at vertical center → 0 at the edges (edge-fade strip)
            let t = abs(y - size.height / 2) / max(1, size.height / 2)
            return max(0, 0.85 * (1 - Double(t)))
        }
    }
}

/// Convenience: the thin halftone accent strip Pluma uses under the toolbar,
/// above footers, and as a section divider. Dots are dense at one edge and
/// dissolve — like the edge of a screened print.
public struct HalftoneEdgeStrip: View {
    public var ink: Color
    public var height: Double

    public init(ink: Color = Color(hex: "#C2410C"), height: Double = 10) {
        self.ink = ink
        self.height = height
    }

    public var body: some View {
        HalftonePatternView(
            ink: ink.opacity(0.55),
            spacing: 9,
            maxRadius: 2.4,
            ramp: .linear(angle: 90, from: 0.9, to: 0.0)
        )
        .frame(height: height)
    }
}
