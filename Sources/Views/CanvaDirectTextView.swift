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
        ZStack {
            NativeRepresentableDirectTextView(
                text: $text,
                textContent: textContent,
                size: size,
                isEditing: isEditing,
                onCommit: onCommit,
                onEscape: onEscape
            )
            .frame(width: max(20, size.width), height: max(20, size.height))

            if isEditing {
                // Subtle Canva editing bounding outline
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color(hex: "#2563EB"), style: SwiftUI.StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                    .padding(-2)
                    .allowsHitTesting(false)
            }
        }
        .frame(width: max(20, size.width), height: max(20, size.height))
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
        context.coordinator.applyAttributes(to: textView, content: textContent, string: text, containerSize: size)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: NativeRepresentableDirectTextView

        init(_ parent: NativeRepresentableDirectTextView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
            applyAttributes(to: textView, content: parent.textContent, string: textView.string, containerSize: parent.size)
        }

        func applyAttributes(to textView: NSTextView, content: TextContent, string: String, containerSize: CGSize) {
            let nsFont = createNSFont(family: content.fontFamily, size: content.fontSize, weight: content.fontWeight, italic: content.isItalic)
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

            textView.typingAttributes = attrs
            textView.font = nsFont
            textView.textColor = nsColor
            textView.alignment = content.alignment.nsTextAlignment
            textView.insertionPointColor = nsColor

            // Pin text strictly to the top of the text box container
            textView.textContainerInset = NSSize(width: 0, height: 0)
        }

        private func createNSFont(family: String, size: Double, weight: Double, italic: Bool) -> NSFont {
            let nsWeight: NSFont.Weight
            if weight <= 300 { nsWeight = .light }
            else if weight <= 400 { nsWeight = .regular }
            else if weight <= 500 { nsWeight = .medium }
            else if weight <= 600 { nsWeight = .semibold }
            else if weight <= 700 { nsWeight = .bold }
            else if weight <= 800 { nsWeight = .heavy }
            else { nsWeight = .black }

            let fontManager = NSFontManager.shared
            var traits: NSFontTraitMask = []
            if weight >= 600 { traits.insert(.boldFontMask) }
            if italic { traits.insert(.italicFontMask) }

            let weightInt = Int(round((weight / 900.0) * 15.0))
            if let matched = fontManager.font(withFamily: family, traits: traits, weight: weightInt, size: CGFloat(size)) {
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
                baseFont = fontManager.convert(baseFont, toHaveTrait: .italicFontMask)
            }
            return baseFont
        }
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
