import SwiftUI
import AppKit

public struct CanvaDirectTextView: View {
    @Binding var text: String
    let textContent: TextContent
    let size: CGSize
    let isEditing: Bool
    var onCommit: () -> Void
    var onEscape: () -> Void

    public init(
        text: Binding<String>,
        textContent: TextContent,
        size: CGSize,
        isEditing: Bool,
        onCommit: @escaping () -> Void = {},
        onEscape: @escaping () -> Void = {}
    ) {
        self._text = text
        self.textContent = textContent
        self.size = size
        self.isEditing = isEditing
        self.onCommit = onCommit
        self.onEscape = onEscape
    }

    public var body: some View {
        // The NSTextView renders the inset content area; SwiftUI places that
        // run inside the full box per verticalAnchor (PowerPoint anchor parity).
        // Zero insets + top anchor collapses to the old exact behavior.
        let boxW = max(20, size.width)
        let boxH = max(20, size.height)
        let boxSize = CGSize(width: boxW, height: boxH)
        let contentH = TextMeasurement.contentHeight(for: textContent, boxWidth: boxW)
        let inner = TextBoxLayout.innerSize(for: textContent, boxSize: boxSize, fittedContentHeight: contentH)
        let offset = TextBoxLayout.centeredOffset(for: textContent, boxSize: boxSize, innerSize: inner)
        ZStack {
            if isEditing {
                NativeRepresentableDirectTextView(
                    text: $text,
                    textContent: textContent,
                    size: CGSize(width: inner.width, height: inner.height),
                    isEditing: true,
                    onCommit: onCommit,
                    onEscape: onEscape
                )
                .frame(width: inner.width, height: inner.height)
                .offset(offset)
            } else {
                // Display-only: a single NSView drawing the identical TextKit
                // layout — not a full NSScrollView/NSTextView pair per element.
                // Table imports emit one text element per cell, so a 200-cell
                // deck would otherwise instantiate 200+ AppKit text views.
                NativeStaticTextView(
                    text: text,
                    textContent: textContent,
                    size: CGSize(width: inner.width, height: inner.height)
                )
                .frame(width: inner.width, height: inner.height)
                .offset(offset)
            }

            if isEditing {
                // Subtle Canva editing bounding outline
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color(hex: "#2563EB"), style: SwiftUI.StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                    .padding(-2)
                    .allowsHitTesting(false)
            }
        }
        .frame(width: boxW, height: boxH, alignment: .center)
    }
}

// MARK: - AppKit Native NSTextView (Unified View & Edit Engine)

struct NativeRepresentableDirectTextView: NSViewRepresentable {
    @Binding var text: String
    let textContent: TextContent
    let size: CGSize
    let isEditing: Bool
    var onCommit: () -> Void
    var onEscape: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true

        let textView = CanvaUnifiedNSTextView()
        textView.drawsBackground = false
        textView.backgroundColor = .clear
        textView.isRichText = false
        textView.allowsUndo = true
        textView.isSelectable = isEditing
        textView.isEditable = isEditing
        textView.isFieldEditor = false
        textView.onEscape = onEscape
        textView.delegate = context.coordinator

        // Zero out container insets for exact pixel rendering
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = true
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width]

        context.coordinator.applyAttributes(to: textView, content: textContent, string: text, containerSize: size)

        scrollView.documentView = textView

        if isEditing {
            DispatchQueue.main.async {
                textView.window?.makeFirstResponder(textView)
            }
        }

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? CanvaUnifiedNSTextView else { return }

        if textView.isEditable != isEditing {
            textView.isEditable = isEditing
            textView.isSelectable = isEditing
            if isEditing {
                DispatchQueue.main.async {
                    textView.window?.makeFirstResponder(textView)
                }
            } else {
                if textView.window?.firstResponder == textView {
                    textView.window?.makeFirstResponder(nil)
                }
            }
        }

        if textView.string != text {
            textView.string = text
        }

        context.coordinator.parent = self
        // Skip the NSFontManager/descriptor round-trip when nothing meaningful
        // changed (size-only ticks during a resize still need a layout pass, but
        // identical content+metrics must not rebuild fonts every frame).
        if !context.coordinator.isApplied(content: textContent, string: text, containerSize: size) {
            context.coordinator.applyAttributes(to: textView, content: textContent, string: text, containerSize: size)
        } else {
            // Frame still changed during a resize — keep the container tracking it.
            textView.frame.size = NSSize(width: max(20, size.width), height: max(20, size.height))
        }
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: NativeRepresentableDirectTextView
        private var lastFingerprint: Int = 0

        init(_ parent: NativeRepresentableDirectTextView) {
            self.parent = parent
        }

        /// Cheap fingerprint of everything applyAttributes depends on.
        func isApplied(content: TextContent, string: String, containerSize: CGSize) -> Bool {
            fingerprint(content: content, string: string, containerSize: containerSize) == lastFingerprint
        }

        private func fingerprint(content: TextContent, string: String, containerSize: CGSize) -> Int {
            var hasher = Hasher()
            hasher.combine(string)
            hasher.combine(content.fontFamily)
            hasher.combine(content.fontSize)
            hasher.combine(content.fontWeight)
            hasher.combine(content.isItalic)
            hasher.combine(content.isUnderlined)
            hasher.combine(content.alignment)
            hasher.combine(content.textColor)
            hasher.combine(content.letterSpacing)
            hasher.combine(content.lineSpacing)
            hasher.combine(content.effectKind)
            hasher.combine(content.effectColor)
            hasher.combine(content.effectWidth)
            hasher.combine(content.outlineColor)
            hasher.combine(content.outlineWidth)
            hasher.combine(content.insetLeft)
            hasher.combine(content.insetRight)
            hasher.combine(content.insetTop)
            hasher.combine(content.insetBottom)
            hasher.combine(content.verticalAnchor)
            hasher.combine(Int(containerSize.width * 4))
            hasher.combine(Int(containerSize.height * 4))
            return hasher.finalize()
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
            applyAttributes(to: textView, content: parent.textContent, string: textView.string, containerSize: parent.size)
        }

        func applyAttributes(to textView: NSTextView, content: TextContent, string: String, containerSize: CGSize) {
            let attrs = TextKitAttributes.forContent(content)
            textView.typingAttributes = attrs
            textView.font = attrs[.font] as? NSFont
            textView.textColor = attrs[.foregroundColor] as? NSColor
            textView.alignment = content.alignment.nsTextAlignment
            textView.insertionPointColor = attrs[.foregroundColor] as? NSColor

            // Pin text strictly to the top of the text box container
            textView.textContainerInset = NSSize(width: 0, height: 0)

            // Remember what we applied so updateNSView can skip redundant work.
            lastFingerprint = fingerprint(content: content, string: string, containerSize: containerSize)
        }
    }
}

/// Shared attributed-string builder used by BOTH the editing NSTextView and
/// the display-only static view — keeps the two TextKit stacks pixel-identical
/// so they can never drift (font, paragraph style, kern, underline, effects).
enum TextKitAttributes {
    static func forContent(_ content: TextContent) -> [NSAttributedString.Key: Any] {
        let nsFont = TextMeasurement.nsFont(family: content.fontFamily, size: content.fontSize, weight: content.fontWeight, italic: content.isItalic)
        let nsColor = content.textColor.nsColor

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = content.alignment.nsTextAlignment
        paragraph.lineSpacing = CGFloat(content.lineSpacing)

        var attrs: [NSAttributedString.Key: Any] = [
            .font: nsFont,
            .foregroundColor: nsColor,
            .paragraphStyle: paragraph,
            .kern: CGFloat(content.letterSpacing)
        ]

        if content.isUnderlined {
            attrs[.underlineStyle] = NSUnderlineStyle.single.rawValue
        }

        // Text Effects
        switch content.effectKind {
        case .none:
            break
        case .outline:
            attrs[.strokeColor] = content.outlineColor.nsColor
            attrs[.strokeWidth] = NSNumber(value: content.outlineWidth * 2.0)
        case .shadow, .neon:
            let shadow = NSShadow()
            shadow.shadowColor = content.effectColor.nsColor
            shadow.shadowBlurRadius = CGFloat(content.effectWidth)
            shadow.shadowOffset = NSSize(width: 0, height: -2)
            attrs[.shadow] = shadow
        case .letterpressDeboss:
            let shadow = NSShadow()
            shadow.shadowColor = NSColor.black.withAlphaComponent(0.3)
            shadow.shadowBlurRadius = 1
            shadow.shadowOffset = NSSize(width: 0, height: -1)
            attrs[.shadow] = shadow
        case .stampDistressed, .backgroundPill:
            break
        }
        return attrs
    }
}

// MARK: - Display-only lightweight text view

/// SwiftUI wrapper for `CanvaStaticTextView` — same inner-box metrics as the
/// editing path (container width tracks the view, zero padding/inset) so a
/// non-editing element renders the identical TextKit layout without
/// NSScrollView/NSTextView cost. Pass-through hit testing lets canvas
/// gestures work exactly like the NSTextView non-editing path.
struct NativeStaticTextView: NSViewRepresentable {
    let text: String
    let textContent: TextContent
    let size: CGSize

    func makeNSView(context: Context) -> CanvaStaticTextView {
        let view = CanvaStaticTextView()
        view.apply(content: textContent, string: text, containerSize: size)
        return view
    }

    func updateNSView(_ nsView: CanvaStaticTextView, context: Context) {
        nsView.apply(content: textContent, string: text, containerSize: size)
    }
}

final class CanvaStaticTextView: NSView {
    private let storage = NSTextStorage()
    private let layoutManager = NSLayoutManager()
    private let textContainer = NSTextContainer()
    private var lastFingerprint: Int = 0

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        textContainer.lineFragmentPadding = 0
        layoutManager.addTextContainer(textContainer)
        storage.addLayoutManager(layoutManager)
        wantsLayer = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    /// NSTextView lays out top-down in a flipped coordinate system — match it
    /// or glyph origins land bottom-up.
    override var isFlipped: Bool { true }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    func apply(content: TextContent, string: String, containerSize: CGSize) {
        // Same skip-if-unchanged fingerprint as the editing Coordinator —
        // resize ticks reframe the view without rebuilding the attributed
        // string or the TextKit layout.
        var hasher = Hasher()
        hasher.combine(string)
        hasher.combine(content.fontFamily)
        hasher.combine(content.fontSize)
        hasher.combine(content.fontWeight)
        hasher.combine(content.isItalic)
        hasher.combine(content.isUnderlined)
        hasher.combine(content.alignment)
        hasher.combine(content.textColor)
        hasher.combine(content.letterSpacing)
        hasher.combine(content.lineSpacing)
        hasher.combine(content.effectKind)
        hasher.combine(content.effectColor)
        hasher.combine(content.effectWidth)
        hasher.combine(content.outlineColor)
        hasher.combine(content.outlineWidth)
        hasher.combine(Int(containerSize.width * 4))
        hasher.combine(Int(containerSize.height * 4))
        let fp = hasher.finalize()
        guard fp != lastFingerprint else { return }
        lastFingerprint = fp

        storage.setAttributedString(NSAttributedString(string: string, attributes: TextKitAttributes.forContent(content)))
        // Container width drives wrapping; the view frame itself is owned by
        // SwiftUI's .frame() on the representable — don't set it here or the
        // two layout systems fight.
        textContainer.size = NSSize(width: max(1, containerSize.width), height: .greatestFiniteMagnitude)
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        let range = layoutManager.glyphRange(for: textContainer)
        guard range.length > 0 else { return }
        let ctx = NSGraphicsContext.current?.cgContext
        ctx?.saveGState()
        // Match the old NSScrollView behavior: text overflowing the element's
        // frame is clipped to the box, not drawn over neighboring elements.
        ctx?.clip(to: bounds)
        layoutManager.drawBackground(forGlyphRange: range, at: .zero)
        layoutManager.drawGlyphs(forGlyphRange: range, at: .zero)
        ctx?.restoreGState()
    }
}

// MARK: - Custom Unified NSTextView

class CanvaUnifiedNSTextView: NSTextView {
    var onEscape: (() -> Void)?

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape key
            onEscape?()
            window?.makeFirstResponder(nil)
            return
        }
        super.keyDown(with: event)
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        if !isEditable {
            return nil // Allow click & drag gestures to pass through cleanly when not editing
        }
        return super.hitTest(point)
    }
}
