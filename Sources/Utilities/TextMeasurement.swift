import AppKit
import Foundation

/// Single source of truth for text metrics shared by the canvas renderer,
/// the inline editor, the PPTX importer, and live-resize auto-fit.
///
/// Why this exists:
/// - The canvas used to measure with TextKit (importer), render with SwiftUI
///   `Text` (canvas) and edit with `NSTextView` (editor) — three layout engines
///   that disagree on wrapping, line height and trailing tracking. Boxes sized
///   in one engine looked wrong in the others (vs Canva/PowerPoint).
/// - `NSFontManager.font(withFamily:traits:weight:size:)` + descriptor fallback
///   on every frame during a resize drag is expensive. This cache makes live
///   resize cheap.
public enum TextMeasurement {
    // MARK: - Font cache

    private struct FontKey: Hashable {
        let family: String
        let sizeBits: UInt64
        let weight: Double
        let italic: Bool
    }

    private static var fontCache: [FontKey: NSFont] = [:]
    private static let cacheLock = NSLock()
    private static let maxCacheEntries = 128
    /// NSFontManager is documented main-thread-only, but makeNSFont runs on the
    /// background import queue too — bounce those calls onto the main queue.
    /// Safe: the importer never holds the main thread while resolving fonts,
    /// and render-path callers on main take the direct branch.
    private static func onMain<T>(_ work: () -> T) -> T {
        Thread.isMainThread ? work() : DispatchQueue.main.sync(execute: work)
    }

    /// Resolves the same NSFont the canvas editor uses, with caching so per-frame
    /// resize ticks don't hit NSFontManager / descriptor matching repeatedly.
    public static func nsFont(family: String, size: Double, weight: Double, italic: Bool) -> NSFont {
        let key = FontKey(
            family: family,
            sizeBits: size.bitPattern,
            weight: weight,
            italic: italic
        )
        cacheLock.lock()
        if let hit = fontCache[key] {
            cacheLock.unlock()
            return hit
        }
        cacheLock.unlock()

        let font = makeNSFont(family: family, size: size, weight: weight, italic: italic)

        cacheLock.lock()
        if fontCache.count >= maxCacheEntries {
            fontCache.removeAll(keepingCapacity: true)
        }
        fontCache[key] = font
        cacheLock.unlock()
        return font
    }

    private static func makeNSFont(family: String, size: Double, weight: Double, italic: Bool) -> NSFont {
        let nsWeight: NSFont.Weight
        if weight <= 300 { nsWeight = .light }
        else if weight <= 400 { nsWeight = .regular }
        else if weight <= 500 { nsWeight = .medium }
        else if weight <= 600 { nsWeight = .semibold }
        else if weight <= 700 { nsWeight = .bold }
        else if weight <= 800 { nsWeight = .heavy }
        else { nsWeight = .black }

        // NSFontManager is main-thread-only API — hop when called off-main
        // (the descriptor/systemFont paths below are already safe anywhere).
        var traits: NSFontTraitMask = []
        if weight >= 600 { traits.insert(.boldFontMask) }
        if italic { traits.insert(.italicFontMask) }

        let weightInt = Int(round((weight / 900.0) * 15.0))
        if let matched = onMain({
            NSFontManager.shared.font(withFamily: family, traits: traits, weight: weightInt, size: CGFloat(size))
        }) {
            return matched
        }

        var symbolicTraits: NSFontDescriptor.SymbolicTraits = []
        if weight >= 600 { symbolicTraits.insert(.bold) }
        if italic { symbolicTraits.insert(.italic) }

        let descriptor = NSFontDescriptor(fontAttributes: [
            .family: family,
            .traits: [
                NSFontDescriptor.TraitKey.weight: nsWeight,
                NSFontDescriptor.TraitKey.symbolic: symbolicTraits.rawValue
            ]
        ])
        if let fontWithDesc = NSFont(descriptor: descriptor, size: CGFloat(size)) {
            return fontWithDesc
        }

        var baseFont = NSFont.systemFont(ofSize: CGFloat(size), weight: nsWeight)
        if italic {
            baseFont = onMain {
                NSFontManager.shared.convert(baseFont, toHaveTrait: .italicFontMask)
            }
        }
        return baseFont
    }

    // MARK: - Paragraph / attributes

    public static func paragraphStyle(
        alignment: TextAlignmentKind,
        lineSpacing: Double
    ) -> NSParagraphStyle {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment.nsTextAlignment
        paragraph.lineSpacing = CGFloat(lineSpacing)
        return paragraph.copy() as! NSParagraphStyle
    }

    public static func attributes(for content: TextContent) -> [NSAttributedString.Key: Any] {
        let font = nsFont(
            family: content.fontFamily,
            size: content.fontSize,
            weight: content.fontWeight,
            italic: content.isItalic
        )
        var attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: content.textColor.nsColor,
            .paragraphStyle: paragraphStyle(alignment: content.alignment, lineSpacing: content.lineSpacing),
            .kern: CGFloat(content.letterSpacing)
        ]
        if content.isUnderlined {
            attrs[.underlineStyle] = NSUnderlineStyle.single.rawValue
        }
        return attrs
    }

    // MARK: - Measuring (TextKit, lineFragmentPadding = 0 — same as the editor)

    /// Height of `content.text` wrapped at `width`, using the exact TextKit stack
    /// the `NSTextView` editor lays out with. Used for Canva-style auto-height:
    /// side-handle resizes reflow and grow the box instead of clipping.
    ///
    /// `width` is the FULL box width — internal margins (PowerPoint insets,
    /// card padding) are subtracted for measuring and added back, so the
    /// returned height is the full box height and the transformer matches.
    public static func fittedHeight(for content: TextContent, width: Double) -> Double {
        let verticalChrome = content.insetTop + content.insetBottom
            + (content.cardBackground != nil ? content.cardPadding * 2 : 0)
        // Never collapse below one line so empty boxes stay grabbable.
        // Ceiled so fractional descenders can't clip the last line by a pixel.
        return ceil(max(content.fontSize * 1.15, contentHeight(for: content, boxWidth: width)) + verticalChrome)
    }

    /// Raw wrapped-text height inside the content area (no chrome added, no
    /// ceiling). Views use this to place the run per verticalAnchor.
    public static func contentHeight(for content: TextContent, boxWidth: Double) -> Double {
        let horizontalChrome = content.insetLeft + content.insetRight
            + (content.cardBackground != nil ? content.cardPadding * 2 : 0)
        return blockHeight(
            text: content.text,
            fontFamily: content.fontFamily,
            fontSizePx: content.fontSize,
            fontWeight: content.fontWeight,
            italic: content.isItalic,
            lineSpacing: content.lineSpacing,
            letterSpacing: content.letterSpacing,
            width: max(10, boxWidth - horizontalChrome),
            alignment: content.alignment
        )
    }

    public static func fittedHeight(
        text: String,
        fontFamily: String,
        fontSize: Double,
        fontWeight: Double,
        italic: Bool,
        lineSpacing: Double,
        letterSpacing: Double = 0,
        width: Double,
        alignment: TextAlignmentKind
    ) -> Double {
        let measured = blockHeight(
            text: text,
            fontFamily: fontFamily,
            fontSizePx: fontSize,
            fontWeight: fontWeight,
            italic: italic,
            lineSpacing: lineSpacing,
            letterSpacing: letterSpacing,
            width: width,
            alignment: alignment
        )
        // Never collapse below one line so empty boxes stay grabbable.
        // Ceiled so fractional descenders can't clip the last line by a pixel.
        return ceil(max(fontSize * 1.15, measured))
    }

    /// Core TextKit measurement. Keeps a single implementation so importer,
    /// renderer and resize all agree (previously three copies drifted apart).
    public static func blockHeight(
        text: String,
        fontFamily: String,
        fontSizePx: Double,
        fontWeight: Double,
        italic: Bool,
        lineSpacing: Double,
        letterSpacing: Double = 0,
        width: Double,
        alignment: TextAlignmentKind
    ) -> Double {
        let font = nsFont(family: fontFamily, size: fontSizePx, weight: fontWeight, italic: italic)
        let para = NSMutableParagraphStyle()
        para.alignment = alignment.nsTextAlignment
        para.lineSpacing = CGFloat(lineSpacing)

        let storage = NSTextStorage(string: text, attributes: [
            .font: font,
            .paragraphStyle: para,
            .kern: CGFloat(letterSpacing)
        ])
        let manager = NSLayoutManager()
        storage.addLayoutManager(manager)
        let container = NSTextContainer(size: NSSize(width: max(10, width), height: .greatestFiniteMagnitude))
        container.lineFragmentPadding = 0
        manager.addTextContainer(container)
        // REQUIRED: usedRect only covers glyphs laid out so far — without this
        // it returns a zero rect and every measurement collapses to the
        // single-line minimum (imported PPTX text boxes came out one line tall
        // with the rest clipped to "…").
        manager.ensureLayout(for: container)
        let used = manager.usedRect(for: container).height
        return max(fontSizePx * 1.15, Double(used))
    }

    public static func singleLineWidth(
        text: String,
        fontFamily: String,
        fontSize: Double,
        fontWeight: Double,
        italic: Bool,
        letterSpacing: Double
    ) -> Double {
        let font = nsFont(family: fontFamily, size: fontSize, weight: fontWeight, italic: italic)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .kern: CGFloat(letterSpacing)]
        return Double((text as NSString).size(withAttributes: attrs).width)
    }
}
