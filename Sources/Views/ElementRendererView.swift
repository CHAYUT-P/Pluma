import SwiftUI
import AppKit

public struct ElementRendererView: View {
    public let element: CanvasElement
    public var isEditingText: Bool = false
    public var isEditingCode: Bool = false
    public var onUpdateText: ((String) -> Void)? = nil
    public var onCommitText: (() -> Void)? = nil
    public var onUpdateCode: ((String) -> Void)? = nil
    public var onUpdateLanguage: ((CodeLanguage) -> Void)? = nil
    public var onUpdateTheme: ((CodeTheme) -> Void)? = nil

    public init(
        element: CanvasElement,
        isEditingText: Bool = false,
        isEditingCode: Bool = false,
        onUpdateText: ((String) -> Void)? = nil,
        onCommitText: (() -> Void)? = nil,
        onUpdateCode: ((String) -> Void)? = nil,
        onUpdateLanguage: ((CodeLanguage) -> Void)? = nil,
        onUpdateTheme: ((CodeTheme) -> Void)? = nil
    ) {
        self.element = element
        self.isEditingText = isEditingText
        self.isEditingCode = isEditingCode
        self.onUpdateText = onUpdateText
        self.onCommitText = onCommitText
        self.onUpdateCode = onUpdateCode
        self.onUpdateLanguage = onUpdateLanguage
        self.onUpdateTheme = onUpdateTheme
    }

    public var body: some View {
        Group {
            switch element.payload {
            case .shape(let shape):
                ShapeRendererView(shape: shape, size: CGSize(width: element.width, height: element.height))

            case .text(let text):
                if text.isCurved && !isEditingText {
                    CurvedTextRendererView(textContent: text, size: CGSize(width: element.width, height: element.height))
                } else if isEditingText {
                    CanvaDirectTextView(
                        text: Binding(
                            get: { text.text },
                            set: { newText in onUpdateText?(newText) }
                        ),
                        textContent: text,
                        size: CGSize(width: element.width, height: element.height),
                        isEditing: true,
                        onCommit: { onCommitText?() },
                        onEscape: { onCommitText?() }
                    )
                } else {
                    TextRendererView(text: text, size: CGSize(width: element.width, height: element.height))
                }

            case .image(let imageContent):
                ImageRendererView(imageContent: imageContent, size: CGSize(width: element.width, height: element.height))

            case .icon(let icon):
                IconRendererView(icon: icon, size: CGSize(width: element.width, height: element.height))

            case .drawing(let drawing):
                DrawingRendererView(drawing: drawing, size: CGSize(width: element.width, height: element.height))

            case .code(let codeContent):
                CodeBlockRendererView(
                    codeContent: codeContent,
                    size: CGSize(width: element.width, height: element.height),
                    isEditing: isEditingCode,
                    onUpdateCode: onUpdateCode,
                    onUpdateLanguage: onUpdateLanguage,
                    onUpdateTheme: onUpdateTheme
                )
            }
        }
        .frame(width: max(1, element.width), height: max(1, element.height))
        .if(element.backdropBlur > 0) { view in
            view.background(.ultraThinMaterial)
        }
        .opacity(element.opacity)
        .scaleEffect(x: element.isFlippedH ? -1 : 1, y: element.isFlippedV ? -1 : 1)
        .rotationEffect(.degrees(element.rotation))
        .if(element.shadow.isEnabled) { view in
            view.shadow(
                color: element.shadow.color.color,
                radius: CGFloat(element.shadow.radius),
                x: CGFloat(element.shadow.x),
                y: CGFloat(element.shadow.y)
            )
        }
    }
}

// MARK: - Shape Renderer

struct ShapeRendererView: View {
    let shape: ShapeContent
    let size: CGSize

    var body: some View {
        let rect = CGRect(origin: .zero, size: size)
        let shapePath = CustomShapePath.path(
            for: shape.kind,
            in: rect,
            cornerRadius: shape.cornerRadius,
            starPoints: shape.starPoints,
            polygonSides: shape.polygonSides
        )

        ZStack {
            // Fill
            switch shape.fill.type {
            case .solid:
                shapePath.fill(shape.fill.solidColor.color)

            case .newsprint:
                shapePath.fill(shape.fill.solidColor.color)
                    .overlay(PaperGrainTextureView())
                    .clipShape(shapePath)

            case .kraft:
                shapePath.fill(shape.fill.solidColor.color)
                    .overlay(KraftFiberTextureView())
                    .clipShape(shapePath)

            case .vintageParchment:
                shapePath.fill(shape.fill.solidColor.color)
                    .overlay(ParchmentTextureView())
                    .clipShape(shapePath)

            case .graphPaper:
                shapePath.fill(shape.fill.solidColor.color)
                    .overlay(DraftingGridPatternView())
                    .clipShape(shapePath)

            case .linearGradient:
                let angleRad = shape.fill.gradientAngle * .pi / 180.0
                let startPoint = UnitPoint(x: 0.5 - 0.5 * cos(angleRad), y: 0.5 - 0.5 * sin(angleRad))
                let endPoint = UnitPoint(x: 0.5 + 0.5 * cos(angleRad), y: 0.5 + 0.5 * sin(angleRad))
                let gradient = Gradient(stops: shape.fill.gradientStops.map {
                    Gradient.Stop(color: $0.color.color, location: CGFloat($0.location))
                })
                shapePath.fill(LinearGradient(gradient: gradient, startPoint: startPoint, endPoint: endPoint))

            case .radialGradient:
                let gradient = Gradient(stops: shape.fill.gradientStops.map {
                    Gradient.Stop(color: $0.color.color, location: CGFloat($0.location))
                })
                shapePath.fill(RadialGradient(gradient: gradient, center: .center, startRadius: 0, endRadius: max(size.width, size.height) / 1.5))

            case .glass:
                shapePath.fill(.ultraThinMaterial)

            case .pattern:
                shapePath.fill(shape.fill.solidColor.color)
            }

            // Stroke
            if shape.stroke.isEnabled && shape.stroke.lineWidth > 0 {
                if shape.kind == .oxfordBorder {
                    Rectangle()
                        .stroke(shape.stroke.color.color, lineWidth: CGFloat(shape.stroke.lineWidth))
                        .padding(CGFloat(shape.stroke.lineWidth) + 2)
                        .overlay(
                            Rectangle()
                                .stroke(shape.stroke.color.color, lineWidth: CGFloat(shape.stroke.lineWidth) / 2.5)
                        )
                } else {
                    shapePath.stroke(
                        shape.stroke.color.color,
                        style: SwiftUI.StrokeStyle(
                            lineWidth: CGFloat(shape.stroke.lineWidth),
                            dash: shape.stroke.dashPattern.lineDash
                        )
                    )
                }
            }
        }
    }
}

struct TextRendererView: View {
    let text: TextContent
    let size: CGSize

    var body: some View {
        if text.isCurved && !text.text.isEmpty {
            CurvedTextView(text: text, size: size)
        } else {
            let textWeight = fontWeight(from: text.fontWeight)
            let isBold = text.fontWeight >= 600
            let font = Font.custom(text.fontFamily, size: CGFloat(text.fontSize))
            let innerW = max(1, size.width - (text.cardBackground != nil ? CGFloat(text.cardPadding * 2) : 0))
            let innerH = max(1, size.height - (text.cardBackground != nil ? CGFloat(text.cardPadding * 2) : 0))

            let baseText = Text(text.text)
                .font(font)
                .fontWeight(textWeight)
                .bold(isBold)
                .italic(text.isItalic)
                .underline(text.isUnderlined)
                .tracking(CGFloat(text.letterSpacing))
                .lineSpacing(CGFloat(text.lineSpacing))
                .multilineTextAlignment(text.alignment.textAlignment)
                .foregroundColor(text.textColor.color)
                .frame(width: innerW, height: innerH, alignment: textAlignmentAlignment(text.alignment))

            ZStack {
                if let bg = text.cardBackground {
                    RoundedRectangle(cornerRadius: CGFloat(text.cardCornerRadius))
                        .fill(bg.color)
                        .if(text.cardBorderColor != nil && text.cardBorderWidth > 0) { v in
                            v.overlay(
                                RoundedRectangle(cornerRadius: CGFloat(text.cardCornerRadius))
                                    .stroke(text.cardBorderColor!.color, lineWidth: CGFloat(text.cardBorderWidth))
                            )
                        }
                }
                styledText(baseText)
            }
            .frame(width: size.width, height: size.height)
        }
    }

    @ViewBuilder
    private func styledText(_ view: some View) -> some View {
        switch text.effectKind {
        case .none:
            view
        case .outline:
            // Multi-shadow outline simulation for crisp hollow/outlined typography
            view
                .shadow(color: text.outlineColor.color, radius: 0.5, x: -CGFloat(text.outlineWidth), y: 0)
                .shadow(color: text.outlineColor.color, radius: 0.5, x: CGFloat(text.outlineWidth), y: 0)
                .shadow(color: text.outlineColor.color, radius: 0.5, x: 0, y: -CGFloat(text.outlineWidth))
                .shadow(color: text.outlineColor.color, radius: 0.5, x: 0, y: CGFloat(text.outlineWidth))
        case .neon:
            view
                .shadow(color: text.effectColor.color, radius: 3, x: 0, y: 0)
                .shadow(color: text.effectColor.color, radius: CGFloat(text.effectWidth * 4), x: 0, y: 0)
                .shadow(color: text.effectColor.color.opacity(0.6), radius: CGFloat(text.effectWidth * 8), x: 0, y: 0)
        case .shadow:
            view.shadow(color: text.effectColor.color, radius: CGFloat(text.effectWidth), x: 2, y: CGFloat(text.effectWidth * 1.5))
        case .backgroundPill:
            view.background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(text.effectColor.color.opacity(0.35))
                    .padding(-6)
            )
        case .letterpressDeboss:
            view
                .shadow(color: Color.white.opacity(0.8), radius: 0.5, x: 0, y: 1)
                .shadow(color: Color.black.opacity(0.25), radius: 0.5, x: 0, y: -0.5)
        case .stampDistressed:
            view
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(text.textColor.color, lineWidth: 2)
                        .padding(-4)
                )
        }
    }

    private func textAlignmentAlignment(_ align: TextAlignmentKind) -> Alignment {
        switch align {
        case .left: return .topLeading
        case .center: return .top
        case .right: return .topTrailing
        case .justified: return .topLeading
        }
    }

    private func fontWeight(from weight: Double) -> Font.Weight {
        if weight <= 300 { return .light }
        if weight <= 400 { return .regular }
        if weight <= 500 { return .medium }
        if weight <= 600 { return .semibold }
        if weight <= 700 { return .bold }
        if weight <= 800 { return .heavy }
        return .black
    }
}

// MARK: - Curved Arc Text View

struct CurvedTextView: View {
    let text: TextContent
    let size: CGSize

    var body: some View {
        let chars = Array(text.text)
        let count = chars.count
        let radius = min(size.width, size.height) * 0.42
        let totalAngle = Angle(degrees: text.curveAngle)
        let anglePerChar = count > 1 ? totalAngle.radians / Double(count - 1) : 0
        let startAngle = -totalAngle.radians / 2.0

        ZStack {
            ForEach(0..<count, id: \.self) { i in
                let charAngle = startAngle + Double(i) * anglePerChar
                let x = radius * sin(charAngle)
                let y = -radius * cos(charAngle) + radius

                Text(String(chars[i]))
                    .font(.custom(text.fontFamily, size: CGFloat(text.fontSize)))
                    .fontWeight(text.fontWeight >= 600 ? .bold : .regular)
                    .foregroundColor(text.textColor.color)
                    .rotationEffect(Angle(radians: charAngle))
                    .offset(x: x, y: y)
            }
        }
        .frame(width: size.width, height: size.height)
    }
}

// MARK: - Image Renderer

struct ImageRendererView: View {
    let imageContent: ImageContent
    let size: CGSize

    var body: some View {
        let rect = CGRect(origin: .zero, size: size)
        Group {
            if let nsImage = ImageUtils.displayImage(from: imageContent.imageBase64, options: imageContent.filter) {
                let img = Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: imageContent.contentMode == .fit ? .fit : .fill)
                    .frame(width: size.width, height: size.height)

                if let frame = imageContent.frameKind {
                    let shapePath = CustomShapePath.path(for: frame, in: rect, cornerRadius: imageContent.cornerRadius)
                    img
                        .clipShape(shapePath)
                        .if(imageContent.stroke.isEnabled && imageContent.stroke.lineWidth > 0) { view in
                            view.overlay(
                                shapePath.stroke(
                                    imageContent.stroke.color.color,
                                    style: SwiftUI.StrokeStyle(
                                        lineWidth: CGFloat(imageContent.stroke.lineWidth),
                                        dash: imageContent.stroke.dashPattern.lineDash
                                    )
                                )
                            )
                        }
                } else {
                    img
                        .clipShape(RoundedRectangle(cornerRadius: CGFloat(imageContent.cornerRadius)))
                        .if(imageContent.stroke.isEnabled && imageContent.stroke.lineWidth > 0) { view in
                            view.overlay(
                                RoundedRectangle(cornerRadius: CGFloat(imageContent.cornerRadius))
                                    .stroke(
                                        imageContent.stroke.color.color,
                                        style: SwiftUI.StrokeStyle(
                                            lineWidth: CGFloat(imageContent.stroke.lineWidth),
                                            dash: imageContent.stroke.dashPattern.lineDash
                                        )
                                    )
                            )
                        }
                }
            } else {
                // Placeholder Woodcut
                ZStack {
                    if let frame = imageContent.frameKind {
                        CustomShapePath.path(for: frame, in: rect, cornerRadius: imageContent.cornerRadius)
                            .fill(Color(hex: "#292524"))
                    } else {
                        RoundedRectangle(cornerRadius: CGFloat(imageContent.cornerRadius))
                            .fill(Color(hex: "#292524"))
                    }
                    VStack(spacing: 6) {
                        Image(systemName: "photo")
                            .font(.system(size: 28))
                            .foregroundColor(Color(hex: "#D97706"))
                        Text("Artwork / Frame")
                            .font(.system(size: 11, weight: .bold, design: .serif))
                            .foregroundColor(Color(hex: "#FAF7F0"))
                    }
                }
            }
        }
    }
}

// MARK: - Icon Renderer

struct IconRendererView: View {
    let icon: IconContent
    let size: CGSize

    var body: some View {
        if icon.isMulticolor {
            Image(systemName: icon.symbolName)
                .resizable()
                .scaledToFit()
                .symbolRenderingMode(.palette)
                .foregroundStyle(icon.primaryColor.color, icon.secondaryColor.color, icon.tertiaryColor.color)
                .frame(width: size.width, height: size.height)
        } else {
            Image(systemName: icon.symbolName)
                .resizable()
                .scaledToFit()
                .foregroundColor(icon.primaryColor.color)
                .frame(width: size.width, height: size.height)
        }
    }
}

// MARK: - Drawing Renderer

struct DrawingRendererView: View {
    let drawing: DrawingContent
    let size: CGSize

    var body: some View {
        Canvas { context, _ in
            guard drawing.points.count > 1 else { return }
            var path = Path()
            path.move(to: drawing.points[0].cgPoint)
            for pt in drawing.points.dropFirst() {
                path.addLine(to: pt.cgPoint)
            }
            context.stroke(
                path,
                with: .color(drawing.strokeColor.color),
                style: SwiftUI.StrokeStyle(
                    lineWidth: CGFloat(drawing.lineWidth),
                    lineCap: .round,
                    lineJoin: .round
                )
            )
        }
        .frame(width: size.width, height: size.height)
    }
}

// MARK: - Code Block Renderer (With Direct Inline Live Editing)

struct CodeBlockRendererView: View {
    let codeContent: CodeContent
    let size: CGSize
    var isEditing: Bool = false
    var onUpdateCode: ((String) -> Void)? = nil
    var onUpdateLanguage: ((CodeLanguage) -> Void)? = nil
    var onUpdateTheme: ((CodeTheme) -> Void)? = nil

    @State private var isCopiedToast: Bool = false

    var body: some View {
        let highlightedLines = CodeHighlighter.highlight(
            code: codeContent.code,
            language: codeContent.language,
            theme: codeContent.theme
        )
        let maxLineNumber = max(1, highlightedLines.count)
        let digitCount = max(2, String(maxLineNumber).count)
        let lineNumberColumnWidth = max(28.0, CGFloat(digitCount) * CGFloat(codeContent.fontSize) * 0.65 + 8.0)

        VStack(alignment: .leading, spacing: 0) {
            // Window Header (Traffic Lights, Title & Interactive Language/Theme Buttons)
            if codeContent.showWindowHeader {
                HStack(spacing: 6) {
                    Circle().fill(Color(hex: "#FF5F56")).frame(width: 10, height: 10)
                    Circle().fill(Color(hex: "#FFBD2E")).frame(width: 10, height: 10)
                    Circle().fill(Color(hex: "#27C93F")).frame(width: 10, height: 10)

                    Spacer()

                    Text(codeContent.windowTitle.isEmpty ? "snippet.\(codeContent.language.fileExtension)" : codeContent.windowTitle)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(codeContent.theme.commentColor.color)

                    Spacer()

                    // Language Switcher Menu
                    Menu {
                        ForEach(CodeLanguage.allCases) { lang in
                            Button(lang.rawValue) {
                                onUpdateLanguage?(lang)
                            }
                        }
                    } label: {
                        Text(codeContent.language.rawValue.uppercased())
                            .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Capsule())
                            .foregroundColor(codeContent.theme.keywordColor.color)
                    }
                    .menuStyle(.borderlessButton)

                    // Copy Code Button
                    Button(action: {
                        let pb = NSPasteboard.general
                        pb.clearContents()
                        pb.setString(codeContent.code, forType: .string)
                        isCopiedToast = true
                        Task {
                            try? await Task.sleep(nanoseconds: 1_500_000_000)
                            isCopiedToast = false
                        }
                    }) {
                        Image(systemName: isCopiedToast ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 9))
                            .foregroundColor(isCopiedToast ? Color(hex: "#10B981") : codeContent.theme.commentColor.color)
                            .padding(4)
                    }
                    .buttonStyle(.plain)
                    .help("Copy Code")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(codeContent.theme.backgroundColor.color.opacity(0.92))
                .overlay(
                    Rectangle().frame(height: 1).foregroundColor(Color.white.opacity(0.08)),
                    alignment: .bottom
                )
            }

            // Code Content or Direct Live Editor (Strictly Top-Left Aligned)
            if isEditing {
                TextEditor(text: Binding(
                    get: { codeContent.code },
                    set: { newCode in onUpdateCode?(newCode) }
                ))
                .font(.system(size: CGFloat(codeContent.fontSize), design: .monospaced))
                .foregroundColor(codeContent.theme.defaultTextColor.color)
                .scrollContentBackground(.hidden)
                .background(codeContent.theme.backgroundColor.color)
                .padding(CGFloat(codeContent.padding))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                ScrollView([.horizontal, .vertical], showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 3) {
                        ForEach(highlightedLines) { line in
                            HStack(alignment: .top, spacing: 12) {
                                if codeContent.showLineNumbers {
                                    Text("\(line.lineNumber)")
                                        .font(.system(size: CGFloat(codeContent.fontSize), weight: .regular, design: .monospaced))
                                        .foregroundColor(codeContent.theme.commentColor.color.opacity(0.55))
                                        .lineLimit(1)
                                        .fixedSize(horizontal: true, vertical: false)
                                        .frame(width: lineNumberColumnWidth, alignment: .trailing)
                                }

                                HStack(spacing: 0) {
                                    ForEach(line.tokens) { token in
                                        Text(token.text)
                                            .font(.system(size: CGFloat(codeContent.fontSize), weight: .medium, design: .monospaced))
                                            .foregroundColor(token.color)
                                    }
                                    Spacer(minLength: 0)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, CGFloat(codeContent.padding))
                    .padding(.top, CGFloat(codeContent.padding))
                    .padding(.bottom, CGFloat(codeContent.padding) + 16)
                    .frame(
                        minWidth: max(50, size.width),
                        minHeight: max(50, size.height - (codeContent.showWindowHeader ? 38 : 0)),
                        alignment: .topLeading
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .background(codeContent.theme.backgroundColor.color)
        .clipShape(RoundedRectangle(cornerRadius: CGFloat(codeContent.cornerRadius)))
        .overlay(
            RoundedRectangle(cornerRadius: CGFloat(codeContent.cornerRadius))
                .stroke(isEditing ? Color(hex: "#C2410C") : Color.white.opacity(0.12), lineWidth: isEditing ? 2 : 1)
        )
    }
}

// MARK: - Paper Grain & Texture Overlays

public struct PaperGrainTextureView: View {
    public var body: some View {
        Canvas { context, size in
            var x: CGFloat = 0
            var i = 0
            while x < size.width {
                var y: CGFloat = 0
                while y < size.height {
                    if (i % 7 == 0) {
                        context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1.5, height: 1.5)), with: .color(Color(hex: "#44403C").opacity(0.06)))
                    }
                    y += 18
                    i += 1
                }
                x += 18
            }
        }
        .allowsHitTesting(false)
    }
}

public struct KraftFiberTextureView: View {
    public var body: some View {
        Canvas { context, size in
            var x: CGFloat = 0
            var i = 0
            while x < size.width {
                var y: CGFloat = 0
                while y < size.height {
                    if (i % 5 == 0) {
                        context.fill(Path(CGRect(x: x, y: y, width: 2, height: 1)), with: .color(Color(hex: "#78350F").opacity(0.08)))
                    }
                    y += 14
                    i += 1
                }
                x += 14
            }
        }
        .allowsHitTesting(false)
    }
}

public struct ParchmentTextureView: View {
    public var body: some View {
        RadialGradient(
            colors: [Color.clear, Color(hex: "#B45309").opacity(0.05)],
            center: .center,
            startRadius: 50,
            endRadius: 600
        )
        .allowsHitTesting(false)
    }
}

public struct DraftingGridPatternView: View {
    public var body: some View {
        Canvas { context, size in
            let step: CGFloat = 20
            var x: CGFloat = 0
            while x < size.width {
                context.stroke(Path { p in p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: size.height)) }, with: .color(Color(hex: "#2563EB").opacity(0.12)), lineWidth: 0.8)
                x += step
            }
            var y: CGFloat = 0
            while y < size.height {
                context.stroke(Path { p in p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: size.width, y: y)) }, with: .color(Color(hex: "#2563EB").opacity(0.12)), lineWidth: 0.8)
                y += step
            }
        }
        .allowsHitTesting(false)
    }
}

extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

public struct CurvedTextRendererView: View {
    let textContent: TextContent
    let size: CGSize

    private func fontWeight(for value: Double) -> Font.Weight {
        switch value {
        case ..<250: return .ultraLight
        case 250..<350: return .light
        case 350..<450: return .regular
        case 450..<550: return .medium
        case 550..<650: return .semibold
        case 650..<750: return .bold
        case 750..<850: return .heavy
        default: return .black
        }
    }

    public var body: some View {
        Canvas { context, canvasSize in
            let chars = Array(textContent.text)
            guard !chars.isEmpty else { return }

            let center = CGPoint(x: canvasSize.width / 2.0, y: canvasSize.height / 2.0)
            let radius = min(canvasSize.width, canvasSize.height) * 0.42
            let totalAngle = textContent.curveAngle * .pi / 180.0
            let startAngle = -(.pi / 2.0) - (totalAngle / 2.0)
            let stepAngle = chars.count > 1 ? totalAngle / Double(chars.count - 1) : 0

            for (index, char) in chars.enumerated() {
                let charAngle = startAngle + Double(index) * stepAngle
                let x = center.x + CGFloat(cos(charAngle)) * radius
                let y = center.y + CGFloat(sin(charAngle)) * radius

                var charContext = context
                charContext.translateBy(x: x, y: y)
                charContext.rotate(by: Angle(radians: charAngle + .pi / 2.0))

                let text = Text(String(char))
                    .font(.custom(textContent.fontFamily, size: CGFloat(textContent.fontSize)).weight(fontWeight(for: textContent.fontWeight)))
                    .foregroundColor(textContent.textColor.color)
                charContext.draw(text, at: .zero, anchor: .center)
            }
        }
        .frame(width: size.width, height: size.height)
    }
}
