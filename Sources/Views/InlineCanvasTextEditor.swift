import SwiftUI
import AppKit

public struct InlineCanvasTextEditor: View {
    @Binding var text: String
    let textContent: TextContent
    let size: CGSize
    var onCommit: () -> Void
    var onEscape: () -> Void

    public init(
        text: Binding<String>,
        textContent: TextContent,
        size: CGSize,
        onCommit: @escaping () -> Void,
        onEscape: @escaping () -> Void
    ) {
        self._text = text
        self.textContent = textContent
        self.size = size
        self.onCommit = onCommit
        self.onEscape = onEscape
    }

    public var body: some View {
        ZStack {
            // Canva-Style WYSIWYG In-Place Text Editor (100% Transparent, 0px Jump)
            NativeRepresentableTextView(
                text: $text,
                textContent: textContent,
                size: size,
                onCommit: onCommit,
                onEscape: onEscape
            )
            .frame(width: max(40, size.width), height: max(24, size.height))
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color(hex: "#2563EB"), style: SwiftUI.StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                    .padding(-3)
            )
        }
        .frame(width: max(40, size.width), height: max(24, size.height))
    }
}

// MARK: - AppKit Native NSTextView Wrapper for 1:1 Pixel-Accurate Typography

struct NativeRepresentableTextView: NSViewRepresentable {
    @Binding var text: String
    let textContent: TextContent
    let size: CGSize
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

        let textView = CanvasNSTextView()
        textView.drawsBackground = false
        textView.backgroundColor = .clear
        textView.isRichText = false
        textView.allowsUndo = true
        textView.isSelectable = true
        textView.isEditable = true
        textView.isFieldEditor = false
        textView.onEscape = onEscape
        textView.delegate = context.coordinator

        // Zero out container padding for exact match with SwiftUI Text
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = true
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width]

        context.coordinator.applyAttributes(to: textView, content: textContent, string: text, containerSize: size)

        scrollView.documentView = textView

        // Auto-focus immediately on double-click
        DispatchQueue.main.async {
            textView.window?.makeFirstResponder(textView)
            textView.selectAll(nil)
        }

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? CanvasNSTextView else { return }
        if textView.string != text {
            textView.string = text
        }
        context.coordinator.applyAttributes(to: textView, content: textContent, string: text, containerSize: size)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: NativeRepresentableTextView

        init(_ parent: NativeRepresentableTextView) {
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

            textView.typingAttributes = attrs
            textView.font = nsFont
            textView.textColor = nsColor
            textView.alignment = content.alignment.nsTextAlignment
            textView.insertionPointColor = nsColor

            // Exact Vertical Centering match with SwiftUI Text view
            let textToMeasure = string.isEmpty ? " " : string
            let stringBounds = (textToMeasure as NSString).boundingRect(
                with: NSSize(width: max(40, containerSize.width), height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: attrs
            )
            let textH = stringBounds.height
            let topInset = max(0, (containerSize.height - textH) / 2.0)
            textView.textContainerInset = NSSize(width: 0, height: topInset)
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

// Custom NSTextView with Escape handling
class CanvasNSTextView: NSTextView {
    var onEscape: (() -> Void)?

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape key
            onEscape?()
            window?.makeFirstResponder(nil)
            return
        }
        super.keyDown(with: event)
    }
}
