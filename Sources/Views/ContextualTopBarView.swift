import SwiftUI
import AppKit

public struct ContextualTopBarView: View {
    @ObservedObject var viewModel: CanvasDocumentViewModel
    @State private var showTopBarFontPopover: Bool = false

    private let availableFonts: [String] = [
        "Playfair Display", "Georgia", "Didot", "Bodoni 72", "Times New Roman", "Baskerville", "Charter",
        "Inter", "Helvetica Neue", "SF Pro", "Avenir Next", "Futura", "Optima", "Gill Sans",
        "Impact", "Copperplate", "SF Mono", "Menlo", "Courier New", "Snell Roundhand", "Zapfino"
    ]

    private let standardColors: [CodableColor] = [
        .inkBlack, CodableColor(hex: "#2563EB"), CodableColor(hex: "#C2410C"),
        CodableColor(hex: "#10B981"), CodableColor(hex: "#8B5CF6"), CodableColor(hex: "#EC4899"),
        CodableColor(hex: "#F59E0B"), CodableColor(hex: "#6B7280"), .white
    ]

    public init(viewModel: CanvasDocumentViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        HStack(spacing: 8) {
            if viewModel.selectedElementIds.count > 1 {
                // Multi-Selection Alignment & Distribution Suite
                multiSelectionContextualControls
            } else if let element = viewModel.primarySelectedElement {
                // Specific Element Formatting Bar
                switch element.payload {
                case .text(let text):
                    textContextualControls(text: text)

                case .shape(let shape):
                    shapeContextualControls(shape: shape)

                case .code(let codeContent):
                    codeContextualControls(codeContent: codeContent)

                case .image(let imageContent):
                    imageContextualControls(imageContent: imageContent)

                case .icon(let icon):
                    iconContextualControls(icon: icon)

                case .drawing:
                    drawingContextualControls()
                }

                Spacer()

                // Universal Quick Actions for Selected Element (With Large Click Targets)
                HStack(spacing: 4) {
                    // Opacity — click for presets
                    Menu {
                        ForEach([100, 90, 75, 50, 25, 10], id: \.self) { pct in
                            Button("\(pct)%") {
                                viewModel.saveHistoryState()
                                viewModel.updateSelectedElement { $0.opacity = Double(pct) / 100.0 }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "circle.lefthalf.filled")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            Text("\(Int((element.opacity * 100).rounded()))%")
                                .font(PlumaTheme.numeric(11))
                                .fixedSize()
                        }
                    }
                    .menuStyle(.borderlessButton)
                    .menuIndicator(.hidden)
                    .fixedSize()
                    .padding(.horizontal, 6)
                    .frame(height: 24)
                    .background(RoundedRectangle(cornerRadius: 6).fill(PlumaTheme.control))
                    .help("Transparency")

                    Divider().frame(height: 16)

                    // Layer Ordering
                    iconActionButton(icon: "square.2.layers.3d.top.filled", help: "Bring Forward (⌘])") {
                        viewModel.bringForward()
                    }

                    iconActionButton(icon: "square.2.layers.3d.bottom.filled", help: "Send Backward (⌘[)") {
                        viewModel.sendBackward()
                    }

                    Divider().frame(height: 16)

                    // Duplicate
                    iconActionButton(icon: "plus.square.on.square", help: "Duplicate (⌘D)") {
                        viewModel.duplicateSelected()
                    }

                    // Lock
                    iconActionButton(
                        icon: element.isLocked ? "lock.fill" : "lock.open",
                        color: element.isLocked ? Color(hex: "#D97706") : .secondary,
                        help: element.isLocked ? "Unlock (⌘L)" : "Lock (⌘L)"
                    ) {
                        viewModel.toggleLockSelected()
                    }

                    // Delete
                    iconActionButton(icon: "trash", color: .red, help: "Delete (⌫)") {
                        viewModel.deleteSelected()
                    }
                }
            } else {
                // Page / Sheet Canvas Defaults Bar (When nothing is selected)
                canvasDefaultsControls
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 38)
        .background(PlumaTheme.chrome)
        .overlay(alignment: .bottom) { Rectangle().fill(PlumaTheme.hairline).frame(height: 1) }
    }

    // MARK: - Text Contextual Controls

    @ViewBuilder
    private func textContextualControls(text: TextContent) -> some View {
        HStack(spacing: 8) {
            // Visual Typeface Selector Button & Popover
            Button(action: { showTopBarFontPopover = true }) {
                HStack(spacing: 4) {
                    Text(text.fontFamily)
                        .font(.custom(text.fontFamily, size: 12))
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.secondary.opacity(0.15), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .hoverHighlight()
            .frame(width: 140)
            .popover(isPresented: $showTopBarFontPopover, arrowEdge: .bottom) {
                VisualFontPickerPopover(viewModel: viewModel, selectedFont: text.fontFamily)
            }

            // Font Size Stepper
            HStack(spacing: 2) {
                Button(action: {
                    viewModel.updateSelectedElement { elem in
                        if case .text(var t) = elem.payload {
                            t.fontSize = max(8, t.fontSize - 2)
                            elem.payload = .text(t)
                        }
                    }
                }) {
                    Image(systemName: "minus")
                        .font(.system(size: 9, weight: .bold))
                        .frame(width: 22, height: 22)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            .hoverHighlight()

                Text("\(Int(text.fontSize))")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .frame(width: 28)

                Button(action: {
                    viewModel.updateSelectedElement { elem in
                        if case .text(var t) = elem.payload {
                            t.fontSize = min(200, t.fontSize + 2)
                            elem.payload = .text(t)
                        }
                    }
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 9, weight: .bold))
                        .frame(width: 22, height: 22)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            .hoverHighlight()
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(Color.secondary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 5))

            // Custom Canva Color Popover Button
            CanvaColorButton(
                color: Binding(
                    get: { text.textColor },
                    set: { newCol in
                        viewModel.updateSelectedElement { elem in
                            if case .text(var t) = elem.payload {
                                t.textColor = newCol
                                elem.payload = .text(t)
                            }
                        }
                    }
                ),
                documentColors: extractDocumentColors()
            )

            Divider().frame(height: 16)

            // Bold / Italic / Underline
            HStack(spacing: 2) {
                toggleButton(icon: "bold", isActive: text.fontWeight >= 600) {
                    viewModel.updateSelectedElement { elem in
                        if case .text(var t) = elem.payload {
                            t.fontWeight = (t.fontWeight >= 600) ? 400 : 700
                            elem.payload = .text(t)
                        }
                    }
                }

                toggleButton(icon: "italic", isActive: text.isItalic) {
                    viewModel.updateSelectedElement { elem in
                        if case .text(var t) = elem.payload {
                            t.isItalic.toggle()
                            elem.payload = .text(t)
                        }
                    }
                }

                toggleButton(icon: "underline", isActive: text.isUnderlined) {
                    viewModel.updateSelectedElement { elem in
                        if case .text(var t) = elem.payload {
                            t.isUnderlined.toggle()
                            elem.payload = .text(t)
                        }
                    }
                }
            }

            Divider().frame(height: 16)

            // Alignments
            HStack(spacing: 2) {
                toggleButton(icon: "text.alignleft", isActive: text.alignment == .left) {
                    updateTextAlign(.left)
                }
                toggleButton(icon: "text.aligncenter", isActive: text.alignment == .center) {
                    updateTextAlign(.center)
                }
                toggleButton(icon: "text.alignright", isActive: text.alignment == .right) {
                    updateTextAlign(.right)
                }
            }

            // Edit Text on Canvas button
            Button(action: {
                if let firstId = viewModel.selectedElementIds.first {
                    viewModel.editingTextElementId = firstId
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "pencil")
                    Text("Edit Text")
                }
                .font(.system(size: 10.5, weight: .medium))
                .padding(.horizontal, 8)
                .frame(height: 26)
                .background(Color(hex: "#C2410C").opacity(0.12))
                .foregroundColor(Color(hex: "#C2410C"))
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .hoverHighlight()
        }
    }

    // MARK: - Shape Contextual Controls

    @ViewBuilder
    private func shapeContextualControls(shape: ShapeContent) -> some View {
        HStack(spacing: 8) {
            // Fill Color Picker (Custom Canva Popover)
            HStack(spacing: 4) {
                Text("Fill").font(.system(size: 11)).foregroundColor(.secondary)
                CanvaColorButton(
                    color: Binding(
                        get: { shape.fill.solidColor },
                        set: { newCol in
                            viewModel.updateSelectedElement { elem in
                                if case .shape(var s) = elem.payload {
                                    s.fill.solidColor = newCol
                                    elem.payload = .shape(s)
                                }
                            }
                        }
                    ),
                    documentColors: extractDocumentColors()
                )
            }

            // Quick Color Palette Dots
            HStack(spacing: 4) {
                ForEach(standardColors.prefix(6), id: \.self) { c in
                    Button(action: {
                        viewModel.updateSelectedElement { elem in
                            if case .shape(var s) = elem.payload {
                                s.fill.solidColor = c
                                elem.payload = .shape(s)
                            }
                        }
                    }) {
                        Circle()
                            .fill(c.color)
                            .frame(width: 18, height: 18)
                            .overlay(Circle().stroke(Color.secondary.opacity(0.25), lineWidth: 0.8))
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
            .hoverHighlight()
                }
            }

            Divider().frame(height: 16)

            // Border Stroke Toggle & Width
            HStack(spacing: 4) {
                Text("Border").font(.system(size: 11)).foregroundColor(.secondary)
                Toggle("", isOn: Binding(
                    get: { shape.stroke.isEnabled },
                    set: { val in
                        viewModel.updateSelectedElement { elem in
                            if case .shape(var s) = elem.payload {
                                s.stroke.isEnabled = val
                                elem.payload = .shape(s)
                            }
                        }
                    }
                ))
                .toggleStyle(.switch)
                .controlSize(.mini)

                if shape.stroke.isEnabled {
                    CanvaColorButton(
                        color: Binding(
                            get: { shape.stroke.color },
                            set: { newCol in
                                viewModel.updateSelectedElement { elem in
                                    if case .shape(var s) = elem.payload {
                                        s.stroke.color = newCol
                                        elem.payload = .shape(s)
                                    }
                                }
                            }
                        ),
                        documentColors: extractDocumentColors(),
                        size: 20
                    )

                    Text("\(Int(shape.stroke.lineWidth))px")
                        .font(.system(size: 10, design: .monospaced))
                }
            }

            Divider().frame(height: 16)

            // Corner Radius (if rectangle)
            if shape.kind == .roundedRectangle || shape.kind == .rectangle {
                HStack(spacing: 4) {
                    Image(systemName: "square.dashed")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Slider(value: Binding(
                        get: { shape.cornerRadius },
                        set: { val in
                            viewModel.updateSelectedElement { elem in
                                if case .shape(var s) = elem.payload {
                                    s.cornerRadius = val
                                    elem.payload = .shape(s)
                                }
                            }
                        }
                    ), in: 0...60, step: 1)
                    .frame(width: 60)
                }
            }
        }
    }

    // MARK: - Code Contextual Controls

    @ViewBuilder
    private func codeContextualControls(codeContent: CodeContent) -> some View {
        HStack(spacing: 6) {
            // Language Picker Menu
            Menu {
                ForEach(CodeLanguage.allCases) { lang in
                    Button(lang.rawValue) {
                        viewModel.updateSelectedElement { elem in
                            if case .code(var c) = elem.payload {
                                c.language = lang
                                c.windowTitle = "snippet.\(lang.fileExtension)"
                                elem.payload = .code(c)
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "curlybraces")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "#C2410C"))
                    Text(codeContent.language.rawValue)
                        .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                .frame(height: 26)
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .menuStyle(.borderlessButton)

            // Theme Picker Menu
            Menu {
                ForEach(CodeTheme.allCases) { th in
                    Button(th.rawValue) {
                        viewModel.updateSelectedElement { elem in
                            if case .code(var c) = elem.payload {
                                c.theme = th
                                elem.payload = .code(c)
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Circle()
                        .fill(codeContent.theme.backgroundColor.color)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(Color.secondary.opacity(0.3), lineWidth: 0.8))
                    Text(codeContent.theme.rawValue)
                        .font(.system(size: 11, weight: .medium))
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                .frame(height: 26)
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .menuStyle(.borderlessButton)

            // Font Size Stepper
            HStack(spacing: 3) {
                Button(action: {
                    viewModel.updateSelectedElement { elem in
                        if case .code(var c) = elem.payload {
                            c.fontSize = max(8, c.fontSize - 1)
                            elem.payload = .code(c)
                            elem.height = CanvasDocumentViewModel.calculateCodeBlockHeight(for: c)
                        }
                    }
                }) {
                    Image(systemName: "minus")
                        .font(.system(size: 8, weight: .bold))
                        .frame(width: 20, height: 22)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            .hoverHighlight()

                Text("\(Int(codeContent.fontSize))pt")
                    .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                    .frame(width: 30)

                Button(action: {
                    viewModel.updateSelectedElement { elem in
                        if case .code(var c) = elem.payload {
                            c.fontSize = min(36, c.fontSize + 1)
                            elem.payload = .code(c)
                            elem.height = CanvasDocumentViewModel.calculateCodeBlockHeight(for: c)
                        }
                    }
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 8, weight: .bold))
                        .frame(width: 20, height: 22)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            .hoverHighlight()
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(Color.secondary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 5))

            Divider().frame(height: 16)

            // Toggles: Traffic Lights & Line Numbers
            toggleButton(icon: "macwindow.badge.plus", isActive: codeContent.showWindowHeader) {
                viewModel.updateSelectedElement { elem in
                    if case .code(var c) = elem.payload {
                        c.showWindowHeader.toggle()
                        elem.payload = .code(c)
                        elem.height = CanvasDocumentViewModel.calculateCodeBlockHeight(for: c)
                    }
                }
            }
            .help("Toggle Window Header Bar")

            toggleButton(icon: "list.number", isActive: codeContent.showLineNumbers) {
                viewModel.updateSelectedElement { elem in
                    if case .code(var c) = elem.payload {
                        c.showLineNumbers.toggle()
                        elem.payload = .code(c)
                    }
                }
            }
            .help("Toggle Line Numbers")

            Divider().frame(height: 16)

            // Direct Edit Code Button
            Button(action: {
                if let firstId = viewModel.selectedElementIds.first {
                    viewModel.editingCodeElementId = firstId
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "pencil.line")
                    Text("Edit Code")
                }
                .font(.system(size: 11, weight: .semibold))
                .padding(.horizontal, 8)
                .frame(height: 26)
                .background(Color(hex: "#C2410C").opacity(0.15))
                .foregroundColor(Color(hex: "#C2410C"))
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .hoverHighlight()
            .help("Edit code directly inside the canvas block")

            // Copy Code Button
            Button(action: {
                let pb = NSPasteboard.general
                pb.clearContents()
                pb.setString(codeContent.code, forType: .string)
                viewModel.showTemporaryToast("✨ Code Copied to Clipboard!")
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "doc.on.doc")
                    Text("Copy")
                }
                .font(.system(size: 10.5, weight: .medium))
                .padding(.horizontal, 7)
                .frame(height: 26)
                .background(Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .hoverHighlight()
            .help("Copy code to clipboard")

            // Paste Code Button
            Button(action: {
                if let str = NSPasteboard.general.string(forType: .string) {
                    viewModel.saveHistoryState()
                    viewModel.updateSelectedElement { elem in
                        if case .code(var c) = elem.payload {
                            c.code = str
                            elem.payload = .code(c)
                            elem.height = CanvasDocumentViewModel.calculateCodeBlockHeight(for: c)
                        }
                    }
                    viewModel.showTemporaryToast("📋 Pasted Code from Clipboard!")
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.doc")
                    Text("Paste")
                }
                .font(.system(size: 10.5, weight: .medium))
                .padding(.horizontal, 7)
                .frame(height: 26)
                .background(Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .hoverHighlight()
            .help("Paste clipboard code into this snippet")
        }
    }

    // MARK: - Multi-Selection Contextual Controls

    @ViewBuilder
    private var multiSelectionContextualControls: some View {
        HStack(spacing: 8) {
            Text("\(viewModel.selectedElementIds.count) Items")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(hex: "#C2410C"))

            Divider().frame(height: 16)

            // Alignment buttons
            HStack(spacing: 3) {
                iconActionButton(icon: "align.horizontal.left", help: "Align Left") {
                    viewModel.alignSelected(.left)
                }
                iconActionButton(icon: "align.horizontal.center", help: "Align Center Horizontal") {
                    viewModel.alignSelected(.centerHorizontal)
                }
                iconActionButton(icon: "align.horizontal.right", help: "Align Right") {
                    viewModel.alignSelected(.right)
                }

                Divider().frame(height: 14)

                iconActionButton(icon: "align.vertical.top", help: "Align Top") {
                    viewModel.alignSelected(.top)
                }
                iconActionButton(icon: "align.vertical.center", help: "Align Center Vertical") {
                    viewModel.alignSelected(.centerVertical)
                }
                iconActionButton(icon: "align.vertical.bottom", help: "Align Bottom") {
                    viewModel.alignSelected(.bottom)
                }
            }

            Divider().frame(height: 16)

            // Equal Distribution (if 3+ elements)
            if viewModel.selectedElementIds.count >= 3 {
                HStack(spacing: 3) {
                    iconActionButton(icon: "distribute.horizontal.center", help: "Distribute Horizontally (Equal Spacing)") {
                        viewModel.alignSelected(.distributeHorizontally)
                    }
                    iconActionButton(icon: "distribute.vertical.center", help: "Distribute Vertically (Equal Spacing)") {
                        viewModel.alignSelected(.distributeVertically)
                    }
                }
                Divider().frame(height: 16)
            }

            // Group / Ungroup
            Button(action: { viewModel.groupSelectedElements() }) {
                HStack(spacing: 4) {
                    Image(systemName: "square.dashed.inset.filled")
                    Text("Group (⌘G)").font(.system(size: 11, weight: .semibold))
                }
                .padding(.horizontal, 8)
                .frame(height: 24)
                .background(Color.secondary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .buttonStyle(.plain)
            .hoverHighlight()

            Button(action: { viewModel.ungroupSelectedElements() }) {
                HStack(spacing: 4) {
                    Image(systemName: "square.dashed")
                    Text("Ungroup (⇧⌘G)").font(.system(size: 11))
                }
                .padding(.horizontal, 6)
                .frame(height: 24)
                .background(Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .buttonStyle(.plain)
            .hoverHighlight()

            Spacer()

            // Universal delete / duplicate
            iconActionButton(icon: "plus.square.on.square", help: "Duplicate (⌘D)") {
                viewModel.duplicateSelected()
            }
            iconActionButton(icon: "trash", color: .red, help: "Delete (⌫)") {
                viewModel.deleteSelected()
            }
        }
    }

    // MARK: - Image Contextual Controls

    @ViewBuilder
    private func imageContextualControls(imageContent: ImageContent) -> some View {
        HStack(spacing: 8) {
            // 1-Click Offline Magic Background Removal
            Button(action: {
                viewModel.removeBackgroundFromSelectedImage()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "wand.and.stars")
                        .foregroundColor(Color(hex: "#C2410C"))
                    Text("Remove BG")
                        .font(.system(size: 11, weight: .bold))
                }
                .padding(.horizontal, 8)
                .frame(height: 24)
                .background(Color(hex: "#C2410C").opacity(0.12))
                .foregroundColor(Color(hex: "#C2410C"))
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .buttonStyle(.plain)
            .hoverHighlight()
            .help("1-Click Offline Apple Vision Background Remover")

            Divider().frame(height: 16)

            // Shape Frame Masking Menu
            Menu {
                Button("None (Rectangle)") {
                    viewModel.updateSelectedElement { elem in
                        if case .image(var img) = elem.payload {
                            img.frameKind = nil
                            elem.payload = .image(img)
                        }
                    }
                }
                Divider()
                Group {
                    Button("Circle Frame") { updateFrame(.circle) }
                    Button("Arch Doorway") { updateFrame(.arch) }
                    Button("Heart") { updateFrame(.heart) }
                    Button("Star Badge") { updateFrame(.star) }
                    Button("Postage Stamp") { updateFrame(.postageStamp) }
                    Button("Wax Seal") { updateFrame(.waxSeal) }
                    Button("Shield") { updateFrame(.shield) }
                    Button("Price Tag") { updateFrame(.tag) }
                    Button("Petal Flower") { updateFrame(.flower) }
                    Button("Cloud") { updateFrame(.cloud) }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "square.on.circle")
                    Text(imageContent.frameKind?.rawValue ?? "Frame Mask")
                        .font(.system(size: 11))
                }
                .padding(.horizontal, 6)
                .frame(height: 24)
                .background(Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .menuStyle(.borderlessButton)
            .frame(width: 120)

            Divider().frame(height: 16)

            // Quick Filter Presets
            HStack(spacing: 3) {
                Button("Normal") {
                    viewModel.updateSelectedElement { elem in
                        if case .image(var img) = elem.payload {
                            img.filter = .default
                            elem.payload = .image(img)
                        }
                    }
                }
                .font(.system(size: 10))
                .padding(.horizontal, 6)
                .frame(height: 24)
                .background(Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .contentShape(Rectangle())

                Button("B&W") {
                    viewModel.updateSelectedElement { elem in
                        if case .image(var img) = elem.payload {
                            img.filter.grayscale = 1.0
                            img.filter.contrast = 1.3
                            elem.payload = .image(img)
                        }
                    }
                }
                .font(.system(size: 10))
                .padding(.horizontal, 6)
                .frame(height: 24)
                .background(Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .contentShape(Rectangle())

                Button("Sepia") {
                    viewModel.updateSelectedElement { elem in
                        if case .image(var img) = elem.payload {
                            img.filter.sepia = 0.8
                            elem.payload = .image(img)
                        }
                    }
                }
                .font(.system(size: 10))
                .padding(.horizontal, 6)
                .frame(height: 24)
                .background(Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .hoverHighlight()

            Divider().frame(height: 16)

            HStack(spacing: 4) {
                Text("Corner").font(.system(size: 11)).foregroundColor(.secondary)
                Slider(value: Binding(
                    get: { imageContent.cornerRadius },
                    set: { val in
                        viewModel.updateSelectedElement { elem in
                            if case .image(var img) = elem.payload {
                                img.cornerRadius = val
                                elem.payload = .image(img)
                            }
                        }
                    }
                ), in: 0...60, step: 1)
                .frame(width: 55)
            }
        }
    }

    private func updateFrame(_ frame: ShapeKind) {
        viewModel.updateSelectedElement { elem in
            if case .image(var img) = elem.payload {
                img.frameKind = frame
                elem.payload = .image(img)
            }
        }
    }

    // MARK: - Icon Contextual Controls

    @ViewBuilder
    private func iconContextualControls(icon: IconContent) -> some View {
        HStack(spacing: 8) {
            // Mode Toggle: Monochrome vs Multicolor Palette
            Button(action: {
                viewModel.updateSelectedElement { elem in
                    if case .icon(var ic) = elem.payload {
                        ic.isMulticolor.toggle()
                        elem.payload = .icon(ic)
                    }
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: icon.isMulticolor ? "paintpalette.fill" : "circle.fill")
                    Text(icon.isMulticolor ? "Multicolor" : "Monochrome")
                }
                .font(.system(size: 10.5, weight: .semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(icon.isMulticolor ? Color(hex: "#C2410C").opacity(0.15) : Color.secondary.opacity(0.08))
                .foregroundColor(icon.isMulticolor ? Color(hex: "#C2410C") : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            .buttonStyle(.plain)
            .hoverHighlight()
            .help("Toggle Single Color vs. Multi-Color Palette")

            Divider().frame(height: 16)

            Text("Primary:").font(.system(size: 11)).foregroundColor(.secondary)
            CanvaColorButton(
                color: Binding(
                    get: { icon.primaryColor },
                    set: { newCol in
                        viewModel.updateSelectedElement { elem in
                            if case .icon(var ic) = elem.payload {
                                ic.primaryColor = newCol
                                elem.payload = .icon(ic)
                            }
                        }
                    }
                ),
                documentColors: extractDocumentColors()
            )

            if icon.isMulticolor {
                Text("Secondary:").font(.system(size: 11)).foregroundColor(.secondary)
                CanvaColorButton(
                    color: Binding(
                        get: { icon.secondaryColor },
                        set: { newCol in
                            viewModel.updateSelectedElement { elem in
                                if case .icon(var ic) = elem.payload {
                                    ic.secondaryColor = newCol
                                    elem.payload = .icon(ic)
                                }
                            }
                        }
                    ),
                    documentColors: extractDocumentColors()
                )

                Text("Tertiary:").font(.system(size: 11)).foregroundColor(.secondary)
                CanvaColorButton(
                    color: Binding(
                        get: { icon.tertiaryColor },
                        set: { newCol in
                            viewModel.updateSelectedElement { elem in
                                if case .icon(var ic) = elem.payload {
                                    ic.tertiaryColor = newCol
                                    elem.payload = .icon(ic)
                                }
                            }
                        }
                    ),
                    documentColors: extractDocumentColors()
                )
            }
        }
    }

    // MARK: - Drawing Contextual Controls

    @ViewBuilder
    private func drawingContextualControls() -> some View {
        HStack(spacing: 8) {
            Text("Inking Pen Active").font(.system(size: 11, weight: .bold)).foregroundColor(Color(hex: "#C2410C"))
        }
    }

    // MARK: - Canvas Defaults Controls (When nothing selected)

    private var canvasDefaultsControls: some View {
        HStack(spacing: 10) {
            Text(viewModel.currentPage.name.isEmpty ? "Page \(viewModel.activePageIndex + 1)" : viewModel.currentPage.name)
                .font(PlumaTheme.label(12, weight: .semibold))
                .lineLimit(1)

            Button(action: { viewModel.showPresetPickerModal = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "aspectratio")
                        .font(.system(size: 11))
                    Text("Resize")
                        .font(PlumaTheme.label(12))
                }
                .padding(.horizontal, 8)
                .frame(height: 24)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .hoverHighlight()
            .help("Change page size (\(Int(viewModel.currentPage.width)) × \(Int(viewModel.currentPage.height)))")

            Rectangle().fill(PlumaTheme.hairline).frame(width: 1, height: 16)

            HStack(spacing: 6) {
                CanvaColorButton(
                    color: Binding(
                        get: { viewModel.currentPage.background.solidColor },
                        set: { newCol in
                            viewModel.saveHistoryState()
                            viewModel.currentPage.background = .solid(newCol)
                        }
                    ),
                    documentColors: extractDocumentColors(),
                    size: 20
                )
                Text("Background")
                    .font(PlumaTheme.label(12))
                    .foregroundColor(.secondary)
            }
            .help("Page background color")

            Spacer()

            toggleButton(icon: "squareshape.split.2x2.dotted", isActive: viewModel.enableSnapping) {
                viewModel.enableSnapping.toggle()
            }
            .help(viewModel.enableSnapping ? "Smart guides & snapping: on" : "Smart guides & snapping: off")

            toggleButton(icon: "grid", isActive: viewModel.showGridOverlay) {
                viewModel.showGridOverlay.toggle()
            }
            .help(viewModel.showGridOverlay ? "Hide grid" : "Show grid")

            toggleButton(icon: "ruler", isActive: viewModel.showRulers) {
                withAnimation(.easeInOut(duration: 0.15)) { viewModel.showRulers.toggle() }
            }
            .help("Rulers & guides (⌘R)")
        }
    }

    // MARK: - Helpers

    private func extractDocumentColors() -> [CodableColor] {
        var colors: [CodableColor] = [viewModel.currentPage.background.solidColor]
        for el in viewModel.currentPage.elements {
            switch el.payload {
            case .text(let t): colors.append(t.textColor)
            case .shape(let s):
                colors.append(s.fill.solidColor)
                if s.stroke.isEnabled { colors.append(s.stroke.color) }
            case .icon(let i): colors.append(i.primaryColor)
            case .drawing(let d): colors.append(d.strokeColor)
            default: break
            }
        }
        return colors
    }

    private func updateTextAlign(_ align: TextAlignmentKind) {
        viewModel.updateSelectedElement { elem in
            if case .text(var t) = elem.payload {
                t.alignment = align
                elem.payload = .text(t)
            }
        }
    }

    private func iconActionButton(icon: String, color: Color = .primary, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11.5))
                .foregroundColor(color)
                .frame(width: 26, height: 26)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
            .hoverHighlight()
        .help(help)
    }

    private func toggleButton(icon: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: isActive ? .bold : .regular))
                .frame(width: 26, height: 26)
                .background(isActive ? PlumaTheme.accentSoft : Color.clear)
                .foregroundColor(isActive ? PlumaTheme.accentOnSoft : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
            .hoverHighlight()
    }
}
