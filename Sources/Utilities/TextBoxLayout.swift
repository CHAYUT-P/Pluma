import CoreGraphics
import SwiftUI

/// Pure layout math for text boxes with internal margins + vertical anchor.
///
/// The element frame is always the FULL box (so the transformer matches the
/// source, e.g. a PowerPoint text frame). The text run lives in the content
/// area `box − insets`, placed vertically per `verticalAnchor` when the box is
/// taller than the content (tight auto-fit boxes are unaffected).
public enum TextBoxLayout {
    /// Content-area size inside the insets (≥1pt so views never collapse).
    public static func contentSize(for content: TextContent, boxSize: CGSize) -> CGSize {
        let cardPad: CGFloat = content.cardBackground != nil ? CGFloat(content.cardPadding * 2) : 0
        let w = max(1, boxSize.width - CGFloat(content.insetLeft + content.insetRight) - cardPad)
        let h = max(1, boxSize.height - CGFloat(content.insetTop + content.insetBottom) - cardPad)
        return CGSize(width: w, height: h)
    }

    /// Size of the inner text view: full content width, and the fitted text
    /// height clamped to the content area (never taller — the area clips).
    public static func innerSize(for content: TextContent, boxSize: CGSize, fittedContentHeight: Double) -> CGSize {
        let area = contentSize(for: content, boxSize: boxSize)
        return CGSize(width: area.width, height: max(1, min(area.height, CGFloat(fittedContentHeight))))
    }

    /// Offset that places an `innerSize` run inside `boxSize` exactly at the
    /// inset origin, shifted down per `verticalAnchor` when there is slack.
    /// Applied on top of a `.center` outer frame alignment, so asymmetric
    /// insets land pixel-exact (not just centered).
    public static func centeredOffset(
        for content: TextContent,
        boxSize: CGSize,
        innerSize: CGSize
    ) -> CGSize {
        let l = CGFloat(content.insetLeft)
        let t = CGFloat(content.insetTop)
        let b = CGFloat(content.insetBottom)
        let cardPad: CGFloat = content.cardBackground != nil ? CGFloat(content.cardPadding) : 0
        // Content origin for a top-anchored run.
        let topX = l + cardPad
        let topY = t + cardPad
        // Extra slack below the run inside the content area.
        let areaH = max(0, boxSize.height - t - b - cardPad * 2)
        let slack = max(0, areaH - innerSize.height)
        let anchorShift: CGFloat
        switch content.verticalAnchor {
        case .top: anchorShift = 0
        case .center: anchorShift = slack / 2
        case .bottom: anchorShift = slack
        }
        let wantCenter = CGPoint(x: topX + innerSize.width / 2, y: topY + anchorShift + innerSize.height / 2)
        let boxCenter = CGPoint(x: boxSize.width / 2, y: boxSize.height / 2)
        return CGSize(width: wantCenter.x - boxCenter.x, height: wantCenter.y - boxCenter.y)
    }

    /// Vertical SwiftUI alignment matching the anchor (for the effects path).
    public static func verticalAlignment(for anchor: TextVerticalAnchor) -> VerticalAlignment {
        switch anchor {
        case .top: return .top
        case .center: return .center
        case .bottom: return .bottom
        }
    }
}
