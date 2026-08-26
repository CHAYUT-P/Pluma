import Foundation
import SwiftUI
import AppKit
import UniformTypeIdentifiers

public enum CanvasTool: Equatable {
    case select
    case hand
    case text
    case shape(ShapeKind)
    case icon(String)
    case draw
}

public enum ResizeHandlePosition: String, CaseIterable {
    case topLeft, top, topRight
    case left, right
    case bottomLeft, bottom, bottomRight
}

@MainActor
public final class CanvasDocumentViewModel: ObservableObject {
    @Published public var project: CanvasProject
    @Published public var activePageIndex: Int = 0
    @Published public var selectedElementIds: Set<UUID> = []
    @Published public var activeTool: CanvasTool = .select

    // Inline Editing
    @Published public var editingTextElementId: UUID? = nil
    @Published public var editingCodeElementId: UUID? = nil

    // Collapsible Sidebars
    @Published public var isLeftSidebarVisible: Bool = true
    @Published public var isRightInspectorVisible: Bool = false

    // Viewport
    @Published public var zoomScale: Double = 0.65
    @Published public var panOffset: CGPoint = .zero
    @Published public var lastViewportSize: CGSize = .zero
    @Published public var pageLayoutMode: PageLayoutMode = .continuousVertical
    @Published public var isPresentingFullscreen: Bool = false
    @Published public var showExportModal: Bool = false
    @Published public var showPresetPickerModal: Bool = false
    @Published public var showToast: Bool = false
    @Published public var toastMessage: String = ""

    // Snapping Guides
    @Published public var activeGuides: [SnappingGuide] = []
    @Published public var enableSnapping: Bool = true
    @Published public var showGridOverlay: Bool = false // Clean white workspace by default

    // Left Drawer Tab Selection
    @Published public var activeSidebarTab: SidebarTab = .pages

    // Active Drawing
    @Published public var currentDrawingPoints: [DrawingPoint] = []
    @Published public var drawingColor: CodableColor = .inkBlack
    @Published public var drawingLineWidth: Double = 3.0
    @Published public var showCommandPalette: Bool = false
    @Published public var showRulers: Bool = false

    // Clipboard
    private var clipboardElements: [CanvasElement] = []

    // History
    public let historyManager = HistoryManager()
    public let performanceMonitor = PerformanceMonitor()

    public init(project: CanvasProject = CanvasProject()) {
        self.project = project
        if self.project.pages.isEmpty {
            self.project.pages = [CanvasPage(background: .solid(.white))]
        }
        if self.project.pages[0].elements.isEmpty {
            // Apply clean white starter sheet with headline & shape
            self.project.pages[0].background = .solid(.white)
        }

        let firstPage = self.project.pages[0]
        _ = firstPage
        syncLayoutMode()
        if pageLayoutMode == .infiniteWhiteboard { zoomScale = 0.5 }
    }

    /// Recomputes layout mode from the current first page.
    /// Called after template/preset swaps so an A4 template applied onto a
    /// presentation project actually becomes a continuous document (and vice versa).
    public func syncLayoutMode() {
        let firstPage = project.pages.first ?? CanvasPage(background: .solid(.white))
        if (firstPage.width >= 2400 && firstPage.height >= 1800) || project.name.contains("Whiteboard") || project.name.contains("Mindmap") || project.name.contains("Flowchart") || project.name.contains("Sticky") {
            pageLayoutMode = .infiniteWhiteboard
        } else if firstPage.width == 1240 && firstPage.height == 1754 {
            pageLayoutMode = .continuousVertical
        } else {
            pageLayoutMode = .singleSlide
        }
    }

    public var currentPage: CanvasPage {
        get {
            guard activePageIndex < project.pages.count else {
                return project.pages.first ?? CanvasPage(background: .solid(.white))
            }
            return project.pages[activePageIndex]
        }
        set {
            guard activePageIndex < project.pages.count else { return }
            project.pages[activePageIndex] = newValue
            project.modifiedAt = Date()
            ProjectStorage.shared.saveProjectDebounced(project)
        }
    }

    public var selectedElements: [CanvasElement] {
        currentPage.elements.filter { selectedElementIds.contains($0.id) }
    }

    public var primarySelectedElement: CanvasElement? {
        guard let firstId = selectedElementIds.first else { return nil }
        return currentPage.elements.first(where: { $0.id == firstId })
    }

    // MARK: - History Recording

    public func saveHistoryState() {
        historyManager.pushState(project)
    }

    public func undo() {
        if let prev = historyManager.undo(currentProject: project) {
            project = prev
            selectedElementIds.removeAll()
            editingTextElementId = nil
            showTemporaryToast("↩ Undo")
        }
    }

    public func redo() {
        if let next = historyManager.redo(currentProject: project) {
            project = next
            selectedElementIds.removeAll()
            editingTextElementId = nil
            showTemporaryToast("↪ Redo")
        }
    }

    // MARK: - Selection

    public func selectElement(_ element: CanvasElement, multiSelect: Bool = false) {
        if editingTextElementId != nil && editingTextElementId != element.id {
            editingTextElementId = nil
        }
        var targetIds: Set<UUID> = [element.id]
        if let gid = element.groupId {
            let groupMembers = currentPage.elements.filter { $0.groupId == gid }.map { $0.id }
            targetIds = Set(groupMembers)
        }

        if multiSelect {
            if targetIds.isSubset(of: selectedElementIds) {
                selectedElementIds.subtract(targetIds)
            } else {
                selectedElementIds.formUnion(targetIds)
            }
        } else {
            selectedElementIds = targetIds
        }
    }

    public func groupSelectedElements() {
        guard selectedElementIds.count > 1 else { return }
        saveHistoryState()
        let newGroupId = UUID()
        for id in selectedElementIds {
            if let idx = currentPage.elements.firstIndex(where: { $0.id == id }) {
                currentPage.elements[idx].groupId = newGroupId
            }
        }
        showTemporaryToast("Grouped (\(selectedElementIds.count) elements)")
    }

    public func ungroupSelectedElements() {
        guard !selectedElementIds.isEmpty else { return }
        saveHistoryState()
        for id in selectedElementIds {
            if let idx = currentPage.elements.firstIndex(where: { $0.id == id }) {
                currentPage.elements[idx].groupId = nil
            }
        }
        showTemporaryToast("Ungrouped elements")
    }

    public func removeBackgroundFromSelectedImage() {
        guard let first = selectedElements.first,
              case .image(var imgContent) = first.payload,
              let nsImage = ImageUtils.nsImage(from: imgContent.imageBase64) else { return }

        Task { @MainActor in
            self.showTemporaryToast("✨ Removing background...")
            if let result = await VisionBackgroundRemover.shared.removeBackground(from: nsImage),
               let base64 = ImageUtils.base64String(from: result) {
                self.saveHistoryState()
                imgContent.imageBase64 = base64
                self.updateElement(id: first.id) { elem in
                    elem.payload = .image(imgContent)
                }
                self.showTemporaryToast("✨ Background Removed!")
            } else {
                self.showTemporaryToast("Could not remove background")
            }
        }
    }

    public func selectAll() {
        selectedElementIds = Set(currentPage.elements.map { $0.id })
    }

    public func deselectAll() {
        selectedElementIds.removeAll()
        editingTextElementId = nil
        editingCodeElementId = nil
    }

    // MARK: - Element Creation

    public func addShape(_ kind: ShapeKind, fill: FillStyle = .solid(.terracotta)) {
        saveHistoryState()

        let initialW: Double
        let initialH: Double

        switch kind {
        case .washiTape:
            initialW = 220
            initialH = 38
        case .postageStamp:
            initialW = 160
            initialH = 200
        case .waxSeal:
            initialW = 120
            initialH = 120
        case .tornPaper:
            initialW = 320
            initialH = 240
        case .oxfordBorder:
            initialW = currentPage.width - 120
            initialH = 4
        case .line:
            initialW = 300
            initialH = 3
        default:
            initialW = 180
            initialH = 180
        }

        let element = CanvasElement(
            name: kind.rawValue,
            payload: .shape(ShapeContent(kind: kind, cornerRadius: 12, fill: fill)),
            x: insertionOrigin(elementWidth: initialW, elementHeight: initialH).x,
            y: insertionOrigin(elementWidth: initialW, elementHeight: initialH).y,
            width: initialW,
            height: initialH,
            zIndex: (currentPage.elements.map { $0.zIndex }.max() ?? 0) + 1
        )
        currentPage.elements.append(element)
        selectedElementIds = [element.id]
        activeTool = .select
        showTemporaryToast("Added \(kind.rawValue)")
    }

    public func addText(
        text: String = "Type your text here",
        fontSize: Double = 38,
        fontWeight: Double = 700,
        fontFamily: String = "Playfair Display",
        color: CodableColor = .inkBlack
    ) {
        saveHistoryState()
        let textOrigin = insertionOrigin(elementWidth: 440, elementHeight: 90)
        let element = CanvasElement(
            name: "Heading Text",
            payload: .text(TextContent(
                text: text,
                fontFamily: fontFamily,
                fontSize: fontSize,
                fontWeight: fontWeight,
                alignment: .center,
                textColor: color
            )),
            x: textOrigin.x,
            y: textOrigin.y,
            width: 440,
            height: 90,
            zIndex: (currentPage.elements.map { $0.zIndex }.max() ?? 0) + 1
        )
        currentPage.elements.append(element)
        selectedElementIds = [element.id]
        activeTool = .select
        showTemporaryToast("Added Text")
    }

    public func addStickyNote(
        color: CodableColor = CodableColor(hex: "#FEF08A"),
        textColor: CodableColor = CodableColor(hex: "#854D0E"),
        borderColor: CodableColor = CodableColor(hex: "#FDE047"),
        at position: CGPoint? = nil
    ) {
        saveHistoryState()
        let stickyOrigin = position ?? insertionOrigin(elementWidth: 220, elementHeight: 200)
        let element = CanvasElement(
            name: "Sticky Note",
            payload: .text(TextContent(
                text: "Add note here...",
                fontFamily: "Indie Flower",
                fontSize: 16,
                fontWeight: 700,
                alignment: .left,
                textColor: textColor,
                lineSpacing: 4,
                cardBackground: color,
                cardBorderColor: borderColor,
                cardBorderWidth: 1,
                cardCornerRadius: 10,
                cardPadding: 16
            )),
            x: stickyOrigin.x,
            y: stickyOrigin.y,
            width: 220,
            height: 200,
            shadow: ShadowEffect.subtle,
            zIndex: (currentPage.elements.map { $0.zIndex }.max() ?? 0) + 1
        )
        currentPage.elements.append(element)
        selectedElementIds = [element.id]
        editingTextElementId = element.id
        activeTool = .select
        showTemporaryToast("Added Sticky Note — type right away")
    }

    public static func calculateCodeBlockHeight(for codeContent: CodeContent) -> Double {
        let lines = codeContent.code.components(separatedBy: .newlines).count
        let effectiveLines = max(10, lines)
        let headerH: Double = codeContent.showWindowHeader ? 38.0 : 0.0
        let paddingH: Double = codeContent.padding * 2.0
        let lineH: Double = codeContent.fontSize * 1.55
        return headerH + paddingH + Double(effectiveLines) * lineH
    }

    public func addCodeBlock(
        code: String = """
        import SwiftUI

        // Ultra-fast Native Graphics ⚡
        struct PerformanceStats {
            let memory = "40 MB"
            let framerate = 120
        }
        """,
        language: CodeLanguage = .swift,
        theme: CodeTheme = .vsCodeDark
    ) {
        saveHistoryState()
        let content = CodeContent(
            code: code,
            language: language,
            theme: theme,
            showLineNumbers: true,
            showWindowHeader: true,
            windowTitle: "snippet.\(language.fileExtension)"
        )
        let w: Double = 540
        let h: Double = CanvasDocumentViewModel.calculateCodeBlockHeight(for: content)
        let codeOrigin = insertionOrigin(elementWidth: w, elementHeight: h)

        let element = CanvasElement(
            name: "Code (\(language.rawValue))",
            payload: .code(content),
            x: codeOrigin.x,
            y: codeOrigin.y,
            width: w,
            height: h,
            shadow: ShadowEffect.elevated,
            zIndex: (currentPage.elements.map { $0.zIndex }.max() ?? 0) + 1
        )
        currentPage.elements.append(element)
        selectedElementIds = [element.id]
        activeTool = .select
        showTemporaryToast("Added Code Block")
    }

    public func addIcon(_ symbolName: String, color: CodableColor = .inkBlack) {
        saveHistoryState()
        let iconOrigin = insertionOrigin(elementWidth: 80, elementHeight: 80)
        let element = CanvasElement(
            name: symbolName,
            payload: .icon(IconContent(symbolName: symbolName, primaryColor: color)),
            x: iconOrigin.x,
            y: iconOrigin.y,
            width: 80,
            height: 80,
            zIndex: (currentPage.elements.map { $0.zIndex }.max() ?? 0) + 1
        )
        currentPage.elements.append(element)
        selectedElementIds = [element.id]
        activeTool = .select
        showTemporaryToast("Added Icon")
    }

    public func addMulticolorIcon(_ symbolName: String, primary: CodableColor, secondary: CodableColor, tertiary: CodableColor = .agedBrass) {
        saveHistoryState()
        let iconOrigin = insertionOrigin(elementWidth: 80, elementHeight: 80)
        let element = CanvasElement(
            name: symbolName,
            payload: .icon(IconContent(
                symbolName: symbolName,
                primaryColor: primary,
                secondaryColor: secondary,
                tertiaryColor: tertiary,
                isMulticolor: true
            )),
            x: iconOrigin.x,
            y: iconOrigin.y,
            width: 80,
            height: 80,
            zIndex: (currentPage.elements.map { $0.zIndex }.max() ?? 0) + 1
        )
        currentPage.elements.append(element)
        selectedElementIds = [element.id]
        activeTool = .select
        showTemporaryToast("Added Multicolor Icon")
    }

    public func addImage(from nsImage: NSImage) {
        saveHistoryState()
        guard let base64 = ImageUtils.base64String(from: nsImage) else { return }

        var w = nsImage.size.width
        var h = nsImage.size.height
        let maxDim: CGFloat = 600
        if w > maxDim || h > maxDim {
            let ratio = min(maxDim / w, maxDim / h)
            w *= ratio
            h *= ratio
        }

        let imageOrigin = insertionOrigin(elementWidth: Double(w), elementHeight: Double(h))
        let element = CanvasElement(
            name: "Imported Image",
            payload: .image(ImageContent(
                imageBase64: base64,
                contentMode: .fill,
                cornerRadius: 6,
                originalWidth: Double(nsImage.size.width),
                originalHeight: Double(nsImage.size.height)
            )),
            x: imageOrigin.x,
            y: imageOrigin.y,
            width: Double(w),
            height: Double(h),
            zIndex: (currentPage.elements.map { $0.zIndex }.max() ?? 0) + 1
        )
        currentPage.elements.append(element)
        selectedElementIds = [element.id]
        activeTool = .select
        showTemporaryToast("Imported Image")
    }

    public func addQRCode(url: String, darkColor: CodableColor = .inkBlack, lightColor: CodableColor = .white) {
        guard let nsImage = QRCodeGenerator.generate(from: url, darkColor: darkColor, lightColor: lightColor, size: 512) else { return }
        saveHistoryState()
        guard let base64 = ImageUtils.base64String(from: nsImage) else { return }
        let qrOrigin = insertionOrigin(elementWidth: 240, elementHeight: 240)
        let element = CanvasElement(
            name: "QR Code (\(url))",
            payload: .image(ImageContent(
                imageBase64: base64,
                contentMode: .fit,
                cornerRadius: 8,
                originalWidth: 512,
                originalHeight: 512
            )),
            x: qrOrigin.x,
            y: qrOrigin.y,
            width: 240,
            height: 240,
            zIndex: (currentPage.elements.map { $0.zIndex }.max() ?? 0) + 1
        )
        currentPage.elements.append(element)
        selectedElementIds = [element.id]
        activeTool = .select
        showTemporaryToast("Added QR Code")
    }

    public func applyTextureBackground(preset: TexturePreset) {
        guard let base64 = preset.imageBase64 else { return }
        saveHistoryState()
        currentPage.isTransparent = false

        // Remove any prior background texture layer if it exists
        currentPage.elements.removeAll { $0.name.starts(with: "Background Texture:") }

        let minZ = (currentPage.elements.map { $0.zIndex }.min() ?? 1) - 1
        let element = CanvasElement(
            name: "Background Texture: \(preset.name)",
            payload: .image(ImageContent(
                imageBase64: base64,
                contentMode: .fill,
                cornerRadius: 0
            )),
            x: 0,
            y: 0,
            width: currentPage.width,
            height: currentPage.height,
            opacity: 1.0,
            isLocked: true,
            zIndex: minZ
        )
        currentPage.elements.insert(element, at: 0)
        showTemporaryToast("Applied \(preset.name) Background")
    }

    public func addTextureOverlay(preset: TexturePreset) {
        guard let base64 = preset.imageBase64 else { return }
        saveHistoryState()
        let maxZ = (currentPage.elements.map { $0.zIndex }.max() ?? 0) + 1
        let element = CanvasElement(
            name: "Texture Overlay: \(preset.name)",
            payload: .image(ImageContent(
                imageBase64: base64,
                contentMode: .fill,
                cornerRadius: 0
            )),
            x: 0,
            y: 0,
            width: currentPage.width,
            height: currentPage.height,
            opacity: preset.isOverlay ? 0.45 : 0.85,
            zIndex: maxZ
        )
        currentPage.elements.append(element)
        selectedElementIds = [element.id]
        activeTool = .select
        showTemporaryToast("✨ Added \(preset.name) Texture Layer")
    }

    public func finishDrawing() {
        guard currentDrawingPoints.count > 1 else {
            currentDrawingPoints.removeAll()
            return
        }
        saveHistoryState()

        let minX = currentDrawingPoints.map { $0.x }.min() ?? 0
        let maxX = currentDrawingPoints.map { $0.x }.max() ?? 0
        let minY = currentDrawingPoints.map { $0.y }.min() ?? 0
        let maxY = currentDrawingPoints.map { $0.y }.max() ?? 0

        let width = max(10, maxX - minX)
        let height = max(10, maxY - minY)

        let normalizedPoints = currentDrawingPoints.map {
            DrawingPoint(x: $0.x - minX, y: $0.y - minY)
        }

        let element = CanvasElement(
            name: "Pen Stroke",
            payload: .drawing(DrawingContent(
                points: normalizedPoints,
                strokeColor: drawingColor,
                lineWidth: drawingLineWidth
            )),
            x: minX,
            y: minY,
            width: width,
            height: height,
            zIndex: (currentPage.elements.map { $0.zIndex }.max() ?? 0) + 1
        )

        currentPage.elements.append(element)
        currentDrawingPoints.removeAll()
        selectedElementIds = [element.id]
        activeTool = .select
    }

    // MARK: - Element Updates

    public func updateSelectedElement(_ modify: (inout CanvasElement) -> Void) {
        guard !selectedElementIds.isEmpty else { return }
        for id in selectedElementIds {
            if let index = currentPage.elements.firstIndex(where: { $0.id == id }) {
                guard !currentPage.elements[index].isLocked else { continue }
                modify(&currentPage.elements[index])
            }
        }
    }

    public func updateElement(id: UUID, _ modify: (inout CanvasElement) -> Void) {
        guard let index = currentPage.elements.firstIndex(where: { $0.id == id }) else { return }
        modify(&currentPage.elements[index])
    }

    // MARK: - Drag & Snapping (1:1 Mouse Cursor Accurate)

    public func dragSelectedElements(by delta: CGSize, startPositions: [UUID: CGPoint], applySnapping: Bool = true) {
        guard !selectedElementIds.isEmpty else { return }

        let deltaCanvasX = delta.width
        let deltaCanvasY = delta.height

        guard let firstId = selectedElementIds.first,
              let firstStart = startPositions[firstId],
              let firstElem = currentPage.elements.first(where: { $0.id == firstId }) else { return }

        var proposedX = firstStart.x + deltaCanvasX
        var proposedY = firstStart.y + deltaCanvasY

        if applySnapping && enableSnapping {
            let otherRects = currentPage.elements
                .filter { !selectedElementIds.contains($0.id) }
                .map { $0.frame }

            let snapRes = SnappingEngine.snap(
                rect: CGRect(x: proposedX, y: proposedY, width: firstElem.width, height: firstElem.height),
                against: otherRects,
                canvasSize: CGSize(width: currentPage.width, height: currentPage.height),
                rulerGuides: currentPage.guides ?? []
            )
            proposedX = snapRes.snappedOrigin.x
            proposedY = snapRes.snappedOrigin.y
            activeGuides = snapRes.activeGuides
        } else {
            activeGuides = []
        }

        let finalDeltaX = proposedX - firstStart.x
        let finalDeltaY = proposedY - firstStart.y

        for id in selectedElementIds {
            if let startPos = startPositions[id],
               let index = currentPage.elements.firstIndex(where: { $0.id == id }) {
                guard !currentPage.elements[index].isLocked else { continue }
                currentPage.elements[index].x = startPos.x + finalDeltaX
                currentPage.elements[index].y = startPos.y + finalDeltaY
            }
        }
    }

    public func endDrag() {
        activeGuides.removeAll()
        // Anchored connectors follow their endpoints after any confirmed move.
        syncConnectors(touching: selectedElementIds)
    }

    // MARK: - Resizing & Handles (Rotation-Aware Canva/Figma Transform Engine)

    public var activeResizeInitialFrame: CGRect? = nil
    public var activeResizeElementId: UUID? = nil
    public var activeResizeInitialRotation: Double = 0

    public func beginResize(id: UUID, handle: ResizeHandlePosition) {
        guard let index = currentPage.elements.firstIndex(where: { $0.id == id }),
              !currentPage.elements[index].isLocked else { return }
        saveHistoryState()
        activeResizeElementId = id
        activeResizeInitialFrame = currentPage.elements[index].frame
        activeResizeInitialRotation = currentPage.elements[index].rotation
    }

    public func updateResize(
        id: UUID,
        handle: ResizeHandlePosition,
        translation: CGSize,
        lockAspectRatio: Bool = false
    ) {
        guard let initialFrame = activeResizeInitialFrame,
              let index = currentPage.elements.firstIndex(where: { $0.id == id }),
              !currentPage.elements[index].isLocked else { return }

        // --- Step 1: Project the screen-space drag delta into the element's LOCAL space ---
        // (rotationEffect rotates clockwise in y-down coords: p_local = R(-θ) · p_screen)
        let theta = activeResizeInitialRotation * .pi / 180.0
        let cosT = cos(theta)
        let sinT = sin(theta)
        let localDX = translation.width * cosT + translation.height * sinT
        let localDY = -translation.width * sinT + translation.height * cosT

        // --- Step 2: Classic axis-aligned resize math in LOCAL space ---
        var x = initialFrame.origin.x
        var y = initialFrame.origin.y
        var w = initialFrame.size.width
        var h = initialFrame.size.height
        let aspect = max(0.01, initialFrame.width / max(0.01, initialFrame.height))
        let minW: Double = 24.0
        let minH: Double = 20.0

        switch handle {
        case .topLeft:
            var dw = -localDX
            var dh = -localDY
            if lockAspectRatio {
                let d = max(dw, dh)
                dw = d
                dh = d / aspect
            }
            w = max(minW, initialFrame.width + dw)
            h = max(minH, initialFrame.height + dh)
            x = initialFrame.maxX - w
            y = initialFrame.maxY - h

        case .top:
            h = max(minH, initialFrame.height - localDY)
            y = initialFrame.maxY - h
            x = initialFrame.origin.x
            w = initialFrame.width

        case .topRight:
            var dw = localDX
            var dh = -localDY
            if lockAspectRatio {
                let d = max(dw, dh)
                dw = d
                dh = d / aspect
            }
            w = max(minW, initialFrame.width + dw)
            h = max(minH, initialFrame.height + dh)
            x = initialFrame.origin.x
            y = initialFrame.maxY - h

        case .left:
            w = max(minW, initialFrame.width - localDX)
            x = initialFrame.maxX - w
            y = initialFrame.origin.y
            h = initialFrame.height

        case .right:
            w = max(minW, initialFrame.width + localDX)
            x = initialFrame.origin.x
            y = initialFrame.origin.y
            h = initialFrame.height

        case .bottomLeft:
            var dw = -localDX
            var dh = localDY
            if lockAspectRatio {
                let d = max(dw, dh)
                dw = d
                dh = d / aspect
            }
            w = max(minW, initialFrame.width + dw)
            h = max(minH, initialFrame.height + dh)
            x = initialFrame.maxX - w
            y = initialFrame.origin.y

        case .bottom:
            h = max(minH, initialFrame.height + localDY)
            x = initialFrame.origin.x
            y = initialFrame.origin.y
            w = initialFrame.width

        case .bottomRight:
            var dw = localDX
            var dh = localDY
            if lockAspectRatio {
                let d = max(dw, dh)
                dw = d
                dh = d / aspect
            }
            w = max(minW, initialFrame.width + dw)
            h = max(minH, initialFrame.height + dh)
            x = initialFrame.origin.x
            y = initialFrame.origin.y
        }

        // --- Step 3: Pin the OPPOSITE anchor point in WORLD space so the element
        // doesn't swim while resizing a rotated frame (Figma-style behavior) ---
        let tentativeFrame = CGRect(x: x, y: y, width: w, height: h)

        let anchorLocal0 = anchorPoint(for: handle, in: initialFrame)
        let anchorLocal1 = anchorPoint(for: handle, in: tentativeFrame)

        let center0 = CGPoint(x: initialFrame.midX, y: initialFrame.midY)
        let center1 = CGPoint(x: tentativeFrame.midX, y: tentativeFrame.midY)

        func worldOffset(fromCenter c: CGPoint, local a: CGPoint) -> CGVector {
            let dx = a.x - c.x
            let dy = a.y - c.y
            return CGVector(dx: dx * cosT - dy * sinT, dy: dx * sinT + dy * cosT)
        }

        let world0 = worldOffset(fromCenter: center0, local: anchorLocal0)
        let world1 = worldOffset(fromCenter: center1, local: anchorLocal1)

        let shiftX = (center0.x + world0.dx) - (center1.x + world1.dx)
        let shiftY = (center0.y + world0.dy) - (center1.y + world1.dy)

        var elem = currentPage.elements[index]
        elem.x = tentativeFrame.origin.x + shiftX
        elem.y = tentativeFrame.origin.y + shiftY
        elem.width = tentativeFrame.width
        elem.height = tentativeFrame.height
        currentPage.elements[index] = elem
    }

    /// The stationary anchor (opposite corner / edge midpoint) for a resize handle.
    private func anchorPoint(for handle: ResizeHandlePosition, in frame: CGRect) -> CGPoint {
        switch handle {
        case .topLeft:     return CGPoint(x: frame.maxX, y: frame.maxY)
        case .top:         return CGPoint(x: frame.midX, y: frame.maxY)
        case .topRight:    return CGPoint(x: frame.minX, y: frame.maxY)
        case .left:        return CGPoint(x: frame.maxX, y: frame.midY)
        case .right:       return CGPoint(x: frame.minX, y: frame.midY)
        case .bottomLeft:  return CGPoint(x: frame.maxX, y: frame.minY)
        case .bottom:      return CGPoint(x: frame.midX, y: frame.minY)
        case .bottomRight: return CGPoint(x: frame.minX, y: frame.minY)
        }
    }

    public func endResize() {
        if let id = activeResizeElementId {
            syncConnectors(touching: [id])
        }
        activeResizeInitialFrame = nil
        activeResizeElementId = nil
    }

    // MARK: - Rotation Engine (Canva/Figma Polar Angular Tracking)

    public var activeRotationInitialDegrees: Double = 0
    public var activeRotationStartAngle: Double = 0
    public var isRotatingElement: Bool = false
    var activeRotationElementId: UUID? = nil

    public func beginRotation(id: UUID, startLocation: CGPoint) {
        guard let index = currentPage.elements.firstIndex(where: { $0.id == id }),
              !currentPage.elements[index].isLocked else { return }
        saveHistoryState()
        isRotatingElement = true
        activeRotationElementId = id
        let elem = currentPage.elements[index]
        activeRotationInitialDegrees = elem.rotation
        let center = elem.center
        activeRotationStartAngle = atan2(Double(startLocation.y - center.y), Double(startLocation.x - center.x))
    }

    public func updateRotation(id: UUID, currentLocation: CGPoint) {
        guard let index = currentPage.elements.firstIndex(where: { $0.id == id }),
              !currentPage.elements[index].isLocked else { return }
        let elem = currentPage.elements[index]
        let center = elem.center
        let currentAngle = atan2(Double(currentLocation.y - center.y), Double(currentLocation.x - center.x))
        let deltaRad = currentAngle - activeRotationStartAngle
        var degrees = activeRotationInitialDegrees + (deltaRad * 180.0 / .pi)
        degrees = degrees.truncatingRemainder(dividingBy: 360.0)
        if degrees < 0 { degrees += 360.0 }

        let snapAngles: [Double] = [0, 45, 90, 135, 180, 225, 270, 315, 360]
        for snap in snapAngles {
            if abs(degrees - snap) < 4.0 {
                degrees = (snap == 360.0) ? 0 : snap
                break
            }
        }
        currentPage.elements[index].rotation = degrees
    }

    public func endRotation() {
        isRotatingElement = false
        activeRotationStartAngle = 0
        if let id = activeRotationElementId {
            syncConnectors(touching: [id])
            activeRotationElementId = nil
        }
    }

    // MARK: - Layer Reordering

    public func bringToFront() {
        guard !selectedElementIds.isEmpty else { return }
        saveHistoryState()
        let maxZ = (currentPage.elements.map { $0.zIndex }.max() ?? 0) + 1
        for id in selectedElementIds {
            if let index = currentPage.elements.firstIndex(where: { $0.id == id }) {
                currentPage.elements[index].zIndex = maxZ
            }
        }
        reindexZIndices()
    }

    public func sendToBack() {
        guard !selectedElementIds.isEmpty else { return }
        saveHistoryState()
        let minZ = (currentPage.elements.map { $0.zIndex }.min() ?? 0) - 1
        for id in selectedElementIds {
            if let index = currentPage.elements.firstIndex(where: { $0.id == id }) {
                currentPage.elements[index].zIndex = minZ
            }
        }
        reindexZIndices()
    }

    public func bringForward() {
        guard let firstId = selectedElementIds.first,
              let index = currentPage.elements.firstIndex(where: { $0.id == firstId }) else { return }
        saveHistoryState()
        currentPage.elements[index].zIndex += 2
        reindexZIndices()
    }

    public func sendBackward() {
        guard let firstId = selectedElementIds.first,
              let index = currentPage.elements.firstIndex(where: { $0.id == firstId }) else { return }
        saveHistoryState()
        currentPage.elements[index].zIndex -= 2
        reindexZIndices()
    }

    private func reindexZIndices() {
        currentPage.elements.sort { $0.zIndex < $1.zIndex }
        for i in 0..<currentPage.elements.count {
            currentPage.elements[i].zIndex = i
        }
    }

    // MARK: - Alignments

    public func alignSelected(_ alignment: AlignmentType) {
        guard !selectedElementIds.isEmpty else { return }
        saveHistoryState()

        switch alignment {
        case .left:
            if selectedElementIds.count == 1 {
                updateSelectedElement { $0.x = 0 }
            } else {
                let minX = selectedElements.map { $0.x }.min() ?? 0
                for id in selectedElementIds { updateElement(id: id) { $0.x = minX } }
            }
        case .centerHorizontal:
            if selectedElementIds.count == 1 {
                updateSelectedElement { $0.x = (currentPage.width - $0.width) / 2.0 }
            } else {
                let minX = selectedElements.map { $0.x }.min() ?? 0
                let maxX = selectedElements.map { $0.x + $0.width }.max() ?? 0
                let midX = (minX + maxX) / 2.0
                for id in selectedElementIds { updateElement(id: id) { $0.x = midX - $0.width / 2.0 } }
            }
        case .right:
            if selectedElementIds.count == 1 {
                updateSelectedElement { $0.x = currentPage.width - $0.width }
            } else {
                let maxX = selectedElements.map { $0.x + $0.width }.max() ?? 0
                for id in selectedElementIds { updateElement(id: id) { $0.x = maxX - $0.width } }
            }
        case .top:
            if selectedElementIds.count == 1 {
                updateSelectedElement { $0.y = 0 }
            } else {
                let minY = selectedElements.map { $0.y }.min() ?? 0
                for id in selectedElementIds { updateElement(id: id) { $0.y = minY } }
            }
        case .centerVertical:
            if selectedElementIds.count == 1 {
                updateSelectedElement { $0.y = (currentPage.height - $0.height) / 2.0 }
            } else {
                let minY = selectedElements.map { $0.y }.min() ?? 0
                let maxY = selectedElements.map { $0.y + $0.height }.max() ?? 0
                let midY = (minY + maxY) / 2.0
                for id in selectedElementIds { updateElement(id: id) { $0.y = midY - $0.height / 2.0 } }
            }
        case .bottom:
            if selectedElementIds.count == 1 {
                updateSelectedElement { $0.y = currentPage.height - $0.height }
            } else {
                let maxY = selectedElements.map { $0.y + $0.height }.max() ?? 0
                for id in selectedElementIds { updateElement(id: id) { $0.y = maxY - $0.height } }
            }
        case .distributeHorizontally:
            guard selectedElementIds.count >= 3 else { return }
            let sorted = selectedElements.sorted(by: { $0.x < $1.x })
            guard let first = sorted.first, let last = sorted.last else { return }
            let minX = first.x
            let maxX = last.x + last.width
            let totalElementWidths = sorted.reduce(0.0) { $0 + $1.width }
            let totalAvailableSpace = maxX - minX - totalElementWidths
            let gap = max(0, totalAvailableSpace / Double(sorted.count - 1))

            var currentX = minX
            for elem in sorted {
                updateElement(id: elem.id) { $0.x = currentX }
                currentX += elem.width + gap
            }
            showTemporaryToast("Distributed Horizontally")

        case .distributeVertically:
            guard selectedElementIds.count >= 3 else { return }
            let sorted = selectedElements.sorted(by: { $0.y < $1.y })
            guard let first = sorted.first, let last = sorted.last else { return }
            let minY = first.y
            let maxY = last.y + last.height
            let totalElementHeights = sorted.reduce(0.0) { $0 + $1.height }
            let totalAvailableSpace = maxY - minY - totalElementHeights
            let gap = max(0, totalAvailableSpace / Double(sorted.count - 1))

            var currentY = minY
            for elem in sorted {
                updateElement(id: elem.id) { $0.y = currentY }
                currentY += elem.height + gap
            }
            showTemporaryToast("Distributed Vertically")
        }
    }

    // MARK: - Clipboard & Duplication

    public func duplicateSelected() {
        guard !selectedElementIds.isEmpty else { return }
        saveHistoryState()

        var newSelectedIds: Set<UUID> = []
        var idRemap: [UUID: UUID] = [:]
        for id in selectedElementIds {
            if let elem = currentPage.elements.first(where: { $0.id == id }) {
                var copy = elem
                let newID = UUID()
                idRemap[id] = newID
                copy.id = newID
                copy.name = "\(elem.name) Copy"
                copy.x += 20
                copy.y += 20
                copy.zIndex = (currentPage.elements.map { $0.zIndex }.max() ?? 0) + 1
                currentPage.elements.append(copy)
                newSelectedIds.insert(newID)
            }
        }
        // Remap anchored connectors whose endpoints were duplicated together;
        // connectors with missing endpoints become static arrows.
        for id in newSelectedIds {
            if let idx = currentPage.elements.firstIndex(where: { $0.id == id }),
               let conn = currentPage.elements[idx].connector {
                if let newFrom = idRemap[conn.fromID], let newTo = idRemap[conn.toID] {
                    currentPage.elements[idx].connector = ConnectorInfo(fromID: newFrom, toID: newTo)
                } else {
                    currentPage.elements[idx].connector = nil
                }
            }
        }
        selectedElementIds = newSelectedIds
        showTemporaryToast("Duplicated")
    }

    public func copySelected() {
        clipboardElements = selectedElements
        if let primary = primarySelectedElement {
            let pb = NSPasteboard.general
            pb.clearContents()
            switch primary.payload {
            case .text(let t):
                pb.setString(t.text, forType: .string)
            case .code(let c):
                pb.setString(c.code, forType: .string)
            default:
                break
            }
        }
        showTemporaryToast("Copied (⌘C)")
    }

    public func paste() {
        if !clipboardElements.isEmpty {
            saveHistoryState()
            var newSelectedIds: Set<UUID> = []
            for elem in clipboardElements {
                var copy = elem
                copy.id = UUID()
                copy.x += 30
                copy.y += 30
                copy.zIndex = (currentPage.elements.map { $0.zIndex }.max() ?? 0) + 1
                currentPage.elements.append(copy)
                newSelectedIds.insert(copy.id)
            }
            selectedElementIds = newSelectedIds
            showTemporaryToast("Pasted (⌘V)")
            return
        }

        pasteFromSystemPasteboard()
    }

    public func pasteFromSystemPasteboard() {
        let pb = NSPasteboard.general

        if let image = NSImage(pasteboard: pb) {
            addImage(from: image)
            return
        }

        if let text = pb.string(forType: .string), !text.isEmpty {
            let isCode = text.contains("{") || text.contains("func ") || text.contains("import ") || text.contains("def ") || text.contains("const ")
            if isCode {
                addCodeBlock(code: text)
            } else {
                addText(text: text, fontSize: 28, fontWeight: 500, fontFamily: "Georgia")
            }
        }
    }

    public func deleteSelected() {
        guard !selectedElementIds.isEmpty else { return }
        saveHistoryState()
        let deletedIds = selectedElementIds
        currentPage.elements.removeAll { selectedElementIds.contains($0.id) && !$0.isLocked }
        // Anchored connectors pointing at deleted elements are removed too.
        currentPage.elements.removeAll { el in
            guard let conn = el.connector else { return false }
            return deletedIds.contains(conn.fromID) || deletedIds.contains(conn.toID)
        }
        selectedElementIds.removeAll()
        editingTextElementId = nil
        showTemporaryToast("Deleted")
    }

    public func toggleLockSelected() {
        guard let firstId = selectedElementIds.first,
              let index = currentPage.elements.firstIndex(where: { $0.id == firstId }) else { return }
        saveHistoryState()
        currentPage.elements[index].isLocked.toggle()
        showTemporaryToast(currentPage.elements[index].isLocked ? "🔒 Locked" : "🔓 Unlocked")
    }

    public func flipSelected(horizontal: Bool) {
        guard !selectedElementIds.isEmpty else { return }
        saveHistoryState()
        for id in selectedElementIds {
            if let idx = currentPage.elements.firstIndex(where: { $0.id == id }) {
                if horizontal {
                    currentPage.elements[idx].flipH = !(currentPage.elements[idx].isFlippedH)
                } else {
                    currentPage.elements[idx].flipV = !(currentPage.elements[idx].isFlippedV)
                }
            }
        }
        showTemporaryToast(horizontal ? "↔️ Flipped Horizontally" : "↕️ Flipped Vertically")
    }

    // MARK: - Arrow-Key Nudging

    private var lastNudgeTime: Date = .distantPast

    /// Moves the selection by the given canvas delta. History coalesces rapid keypresses
    /// (holding an arrow key = one undo step), and re-syncs any anchored connectors.
    public func nudgeSelected(dx: Double, dy: Double) {
        guard !selectedElementIds.isEmpty else { return }
        let now = Date()
        if now.timeIntervalSince(lastNudgeTime) > 0.6 {
            saveHistoryState()
        }
        lastNudgeTime = now
        for id in selectedElementIds {
            if let idx = currentPage.elements.firstIndex(where: { $0.id == id }) {
                currentPage.elements[idx].x += dx
                currentPage.elements[idx].y += dy
            }
        }
        syncConnectors(touching: selectedElementIds)
    }

    // MARK: - Anchored Connectors (Whiteboard Arrows Glued to Elements)

    /// Chain-connects the current selection in canvas order (element 1 → 2 → 3 …).
    public func connectSelectedElements() {
        let ordered = currentPage.elements.filter { selectedElementIds.contains($0.id) && $0.connector == nil }
        guard ordered.count >= 2 else {
            showTemporaryToast("Select 2+ elements to connect (or press L)")
            return
        }
        saveHistoryState()
        var linked = 0
        for i in 1..<ordered.count {
            if makeConnector(from: ordered[i - 1].id, to: ordered[i].id) != nil {
                linked += 1
            }
        }
        if linked > 0 {
            showTemporaryToast("🔗 Connected \(linked) pair\(linked > 1 ? "s" : "") — arrows follow the elements")
        }
    }

    @discardableResult
    public func makeConnector(from: UUID, to: UUID) -> CanvasElement? {
        guard from != to,
              let fromEl = currentPage.elements.first(where: { $0.id == from }),
              let toEl = currentPage.elements.first(where: { $0.id == to }) else { return nil }

        var el = CanvasElement(
            name: "Connector",
            payload: .shape(ShapeContent(
                kind: .arrow,
                cornerRadius: 0,
                fill: .solid(CodableColor(hex: "#52525B")),
                stroke: StrokeStyle(isEnabled: false)
            )),
            x: 0, y: 0, width: 100, height: 10,
            zIndex: (currentPage.elements.map { $0.zIndex }.max() ?? 0) + 1,
            connector: ConnectorInfo(fromID: from, toID: to)
        )
        applyConnectorGeometry(&el, from: fromEl.frame, to: toEl.frame)
        currentPage.elements.append(el)
        return el
    }

    /// Recomputes every anchored connector that references one of the moved element IDs.
    public func syncConnectors(touching movedIds: Set<UUID>) {
        guard !movedIds.isEmpty else { return }
        for index in currentPage.elements.indices {
            guard let conn = currentPage.elements[index].connector else { continue }
            guard movedIds.contains(conn.fromID) || movedIds.contains(conn.toID) || movedIds.contains(currentPage.elements[index].id) else { continue }
            guard let fromEl = currentPage.elements.first(where: { $0.id == conn.fromID }),
                  let toEl = currentPage.elements.first(where: { $0.id == conn.toID }) else { continue }
            applyConnectorGeometry(&currentPage.elements[index], from: fromEl.frame, to: toEl.frame)
        }
    }

    /// Positions a horizontal arrow shape along the boundary-to-boundary segment
    /// between the two connected elements (auto edge anchoring, Miro-style).
    private func applyConnectorGeometry(_ el: inout CanvasElement, from: CGRect, to: CGRect) {
        let start = boundaryPoint(of: from, toward: CGPoint(x: to.midX, y: to.midY))
        let end = boundaryPoint(of: to, toward: CGPoint(x: from.midX, y: from.midY))
        let dx = end.x - start.x
        let dy = end.y - start.y
        let length = max(12, hypot(dx, dy))
        var angle = atan2(dy, dx) * 180.0 / .pi
        // The arrow shape points along +x; keep the flip semantics for backwards arrows.
        if angle < 0 { angle += 360 }
        el.x = (start.x + end.x) / 2.0 - length / 2.0
        el.y = (start.y + end.y) / 2.0 - 5.0
        el.width = length
        el.height = 10
        el.rotation = angle
    }

    /// Intersection of the center→target ray with the rectangle boundary.
    private func boundaryPoint(of rect: CGRect, toward target: CGPoint) -> CGPoint {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let dx = target.x - c.x
        let dy = target.y - c.y
        guard dx != 0 || dy != 0 else { return CGPoint(x: rect.maxX, y: rect.midY) }
        let halfW = rect.width / 2.0
        let halfH = rect.height / 2.0
        let tx = dx != 0 ? halfW / abs(dx) : Double.infinity
        let ty = dy != 0 ? halfH / abs(dy) : Double.infinity
        let t = min(tx, ty)
        return CGPoint(x: c.x + dx * t, y: c.y + dy * t)
    }

    // MARK: - Ruler Guides

    public var activeGuidesForPage: [CanvasGuide] {
        currentPage.guides ?? []
    }

    public func addGuide(at position: Double, isVertical: Bool) {
        saveHistoryState()
        var guides = currentPage.guides ?? []
        guides.append(CanvasGuide(position: position, isVertical: isVertical))
        currentPage.guides = guides
    }

    public func moveGuide(id: UUID, to position: Double) {
        var guides = currentPage.guides ?? []
        guard let idx = guides.firstIndex(where: { $0.id == id }) else { return }
        guides[idx].position = position
        currentPage.guides = guides
    }

    public func removeGuide(id: UUID) {
        saveHistoryState()
        currentPage.guides = (currentPage.guides ?? []).filter { $0.id != id }
    }

    public func clearGuides() {
        saveHistoryState()
        currentPage.guides = []
    }

    // MARK: - Page & Preset Management

    public func applyPreset(_ preset: CanvasPreset) {
        saveHistoryState()
        currentPage.width = preset.width
        currentPage.height = preset.height
        syncLayoutMode()
        panOffset = .zero
        showTemporaryToast("Resized to \(preset.name)")
    }

    public func applyTemplate(_ template: CanvasTemplate) {
        saveHistoryState()
        project.name = template.title
        if !template.pages.isEmpty {
            project.pages = template.pages
            activePageIndex = 0
        } else {
            var page = template.page
            page.id = currentPage.id
            currentPage = page
        }
        syncLayoutMode()
        selectedElementIds.removeAll()
        editingTextElementId = nil
        panOffset = .zero
        showTemporaryToast("Loaded: \(template.title) (\(project.pages.count) Pages)")
    }

    public func addPage() {
        saveHistoryState()
        let newPage = CanvasPage(
            name: "Page \(project.pages.count + 1)",
            width: currentPage.width,
            height: currentPage.height,
            background: .solid(.white)
        )
        project.pages.append(newPage)
        activePageIndex = project.pages.count - 1
        selectedElementIds.removeAll()
        editingTextElementId = nil
        showTemporaryToast("Added Page \(project.pages.count)")
    }

    public func duplicatePage(at index: Int) {
        guard index >= 0 && index < project.pages.count else { return }
        saveHistoryState()
        var newPage = project.pages[index]
        newPage.id = UUID()
        newPage.name = "\(newPage.name) Copy"
        newPage.elements = newPage.elements.map { el in
            var copy = el
            copy.id = UUID()
            return copy
        }
        project.pages.insert(newPage, at: index + 1)
        activePageIndex = index + 1
        selectedElementIds.removeAll()
        showTemporaryToast("Duplicated Page \(index + 1)")
    }

    public func duplicateCurrentPage() {
        duplicatePage(at: activePageIndex)
    }

    public func deletePage(at index: Int) {
        guard project.pages.count > 1 else {
            showTemporaryToast("Cannot delete the only page")
            return
        }
        guard index >= 0 && index < project.pages.count else { return }
        saveHistoryState()
        project.pages.remove(at: index)
        activePageIndex = min(activePageIndex, project.pages.count - 1)
        selectedElementIds.removeAll()
        editingTextElementId = nil
        showTemporaryToast("Deleted Page \(index + 1)")
    }

    public func deleteCurrentPage() {
        deletePage(at: activePageIndex)
    }

    public func movePageUp(at index: Int) {
        movePage(from: index, to: index - 1)
    }

    public func movePageDown(at index: Int) {
        movePage(from: index, to: index + 1)
    }

    /// Moves a page to a new index (drag-to-reorder in the grid uses this).
    public func movePage(from source: Int, to destination: Int) {
        guard source != destination,
              source >= 0, source < project.pages.count,
              destination >= 0, destination < project.pages.count else { return }
        let page = project.pages.remove(at: source)
        project.pages.insert(page, at: destination)
        if activePageIndex == source {
            activePageIndex = destination
        }
        project.modifiedAt = Date()
        ProjectStorage.shared.saveProjectDebounced(project)
        showTemporaryToast("Page moved")
    }

    /// Renames a page AND persists the change (the old direct-binding path silently
    /// skipped autosave).
    public func renamePage(at index: Int, to newName: String) {
        guard index < project.pages.count else { return }
        project.pages[index].name = newName
        project.modifiedAt = Date()
        ProjectStorage.shared.saveProjectDebounced(project)
    }

    public func scrollToPage(index: Int) {
        guard index >= 0 && index < project.pages.count else { return }
        activePageIndex = index
        selectedElementIds.removeAll()
        editingTextElementId = nil
        editingCodeElementId = nil

        if pageLayoutMode == .continuousVertical {
            let pageGap: Double = 56.0
            let targetOffsetY = -Double(index) * (currentPage.height + pageGap) * zoomScale
            withAnimation(.easeInOut(duration: 0.25)) {
                panOffset.y = targetOffsetY
            }
        }
    }

    public func goToNextPage() {
        if activePageIndex < project.pages.count - 1 {
            scrollToPage(index: activePageIndex + 1)
            showTemporaryToast("Page \(activePageIndex + 1) of \(project.pages.count)")
        }
    }

    public func goToPreviousPage() {
        if activePageIndex > 0 {
            scrollToPage(index: activePageIndex - 1)
            showTemporaryToast("Page \(activePageIndex + 1) of \(project.pages.count)")
        }
    }

    // MARK: - True Infinite Canvas Math (Screen ⇄ Canvas Transforms)

    /// Layout model: the page plane (size W×H) is scaled about its own center by
    /// `zoomScale`, then centered at (viewportCenter + panOffset). Therefore:
    ///   screen = V + pan + z·(canvasPoint − pageCenter)
    ///   canvasPoint = pageCenter + (screen − V − pan) / z

    public func screenToCanvasPoint(_ s: CGPoint, viewportSize: CGSize) -> CGPoint {
        let z = max(0.0001, zoomScale)
        let vx = viewportSize.width / 2.0 + panOffset.x
        let vy = viewportSize.height / 2.0 + panOffset.y
        return CGPoint(
            x: currentPage.width / 2.0 + (s.x - vx) / z,
            y: currentPage.height / 2.0 + (s.y - vy) / z
        )
    }

    public func canvasToScreenPoint(_ q: CGPoint, viewportSize: CGSize) -> CGPoint {
        let z = zoomScale
        let vx = viewportSize.width / 2.0 + panOffset.x
        let vy = viewportSize.height / 2.0 + panOffset.y
        return CGPoint(
            x: vx + (q.x - currentPage.width / 2.0) * z,
            y: vy + (q.y - currentPage.height / 2.0) * z
        )
    }

    public func visibleCanvasRect(viewportSize: CGSize) -> CGRect {
        // Before the viewport is measured, treat everything as visible (no culling).
        guard viewportSize.width > 1 && viewportSize.height > 1 else {
            return CGRect(x: -.infinity, y: -.infinity, width: .infinity, height: .infinity)
        }
        let a = screenToCanvasPoint(.zero, viewportSize: viewportSize)
        let b = screenToCanvasPoint(CGPoint(x: viewportSize.width, y: viewportSize.height), viewportSize: viewportSize)
        return CGRect(
            x: min(a.x, b.x),
            y: min(a.y, b.y),
            width: abs(b.x - a.x),
            height: abs(b.y - a.y)
        )
    }

    /// The canvas point currently under the middle of the viewport.
    public var viewportCenterCanvasPoint: CGPoint {
        screenToCanvasPoint(
            CGPoint(x: lastViewportSize.width / 2.0, y: lastViewportSize.height / 2.0),
            viewportSize: lastViewportSize
        )
    }

    /// Origin for a new element so it appears centered where the user is LOOKING,
    /// not pinned to the abstract page rect. Falls back to page center outside
    /// infinite-whiteboard mode.
    public func insertionOrigin(elementWidth: Double, elementHeight: Double) -> CGPoint {
        if pageLayoutMode == .infiniteWhiteboard && lastViewportSize.width > 1 {
            let c = viewportCenterCanvasPoint
            return CGPoint(x: c.x - elementWidth / 2.0, y: c.y - elementHeight / 2.0)
        }
        return CGPoint(
            x: (currentPage.width - elementWidth) / 2.0,
            y: (currentPage.height - elementHeight) / 2.0
        )
    }

    /// Zoom keeping the canvas point under `screenPoint` glued to the cursor
    /// (Figma-style focal zoom instead of always zooming to the viewport center).
    public func applyFocalZoom(factor: Double, screenPoint: CGPoint, viewportSize: CGSize) {
        if pageLayoutMode != .infiniteWhiteboard {
            zoomScale = max(0.15, min(3.5, zoomScale * factor))
            clampPanOffset(for: viewportSize)
            return
        }
        let oldZ = zoomScale
        let newZ = max(0.05, min(8.0, oldZ * factor))
        guard abs(newZ - oldZ) > 1e-9 else { return }

        let vx = viewportSize.width / 2.0
        let vy = viewportSize.height / 2.0
        let pcx = currentPage.width / 2.0
        let pcy = currentPage.height / 2.0

        // Canvas point under the cursor BEFORE the zoom…
        let qx = pcx + (screenPoint.x - vx - panOffset.x) / oldZ
        let qy = pcy + (screenPoint.y - vy - panOffset.y) / oldZ
        // …must stay under the cursor AFTER the zoom.
        panOffset = CGPoint(
            x: screenPoint.x - vx - (qx - pcx) * newZ,
            y: screenPoint.y - vy - (qy - pcy) * newZ
        )
        zoomScale = newZ
    }

    public func updateViewportSize(_ size: CGSize) {
        lastViewportSize = size
        // Keep pan clamped when viewport resizes (e.g. window resize)
        clampPanOffset(for: size)
    }

    // MARK: - Pan Discipline (Canva-style locked pages)

    /// Vertical space reserved for the bottom filmstrip rail (set by CanvasViewportView).
    /// Fit & clamping math keeps the page floating ABOVE the rail instead of under it.
    public var bottomInset: CGFloat = 0

    /// Viewport minus the bottom rail reserve — the area the page actually lives in.
    private func effectiveViewportSize(_ size: CGSize) -> CGSize {
        CGSize(width: size.width, height: max(60, size.height - bottomInset))
    }

    /// Zoom of the last programmatic fit — while zoomScale equals this, the user hasn't
    /// zoomed manually, so window resizes re-fit (launch-small-then-grow self-heals).
    public var lastFitZoom: Double? = nil

    /// Fit scale for the current page (same math as zoomToFit without applying it).
    public func fitScale(for viewportSize: CGSize) -> Double {
        guard viewportSize.width > 50 && viewportSize.height > 50 else { return zoomScale }
        if pageLayoutMode == .infiniteWhiteboard { return zoomScale } // infinite board is free
        let eff = effectiveViewportSize(viewportSize)
        let availableW = max(50, eff.width - 80)
        let availableH = max(50, eff.height - 110)
        let wRatio = availableW / currentPage.width
        let hRatio = availableH / currentPage.height
        return max(0.15, min(1.5, min(wRatio, hRatio)))
    }

    /// Whether hand/scroll panning may move the page right now.
    /// Presentations are LOCKED at fit zoom — zoom in first to pan.
    /// Documents allow vertical scroll (that IS page navigation) but lock horizontal.
    public func canPan(viewportSize: CGSize) -> Bool {
        switch pageLayoutMode {
        case .infiniteWhiteboard:
            return true
        case .continuousVertical:
            return true
        case .singleSlide:
            return zoomScale > fitScale(for: viewportSize) + 0.02
        }
    }

    /// Canva-style pan rules — pure function so gestures can pre-clamp BEFORE rendering
    /// (locked axes never move a pixel, so there is no snap-back / rubber-band jank):
    /// • singleSlide: hard-locked to center at/below fit zoom; when zoomed in, panning is
    ///   bounded to the paper plus a 60px peek — never fully off the slide.
    /// • continuousVertical: horizontal locked to center unless zoomed in past fit AND the
    ///   page is wider than the viewport; vertical is the document flow, bounded to a
    ///   60px peek past the document's start/end (no endless blank scrolling).
    private func clampedPan(_ target: CGPoint, viewportSize: CGSize) -> CGPoint {
        if pageLayoutMode == .infiniteWhiteboard { return target }
        let margin: CGFloat = 60 // "a little bit" of workspace allowed past the paper edge
        let scaledW = currentPage.width * zoomScale
        let scaledH = currentPage.height * zoomScale
        let fit = fitScale(for: viewportSize)

        switch pageLayoutMode {
        case .singleSlide:
            if zoomScale <= fit + 0.02 {
                return .zero // fixed place: slide centered above the filmstrip, immovable
            }
            return CGPoint(
                x: axisPanBound(target.x, scaled: scaledW, viewport: viewportSize.width, margin: margin),
                y: axisPanBound(target.y, scaled: scaledH, viewport: effectiveViewportSize(viewportSize).height, margin: margin)
            )

        case .continuousVertical:
            // Horizontal: locked unless zoomed in enough that the paper overflows the viewport
            let x: CGFloat
            if zoomScale <= fit + 0.02 || scaledW + 2 * margin <= viewportSize.width {
                x = 0
            } else {
                let bound = (scaledW - viewportSize.width) / 2.0 + margin
                x = min(bound, max(-bound, target.x))
            }
            // Vertical: document flow — bounded to a small peek past the doc's start/end
            let stackH = totalStackHeight * zoomScale
            let topPad: CGFloat = 40
            let y: CGFloat
            if topPad + stackH <= viewportSize.height - margin {
                y = 0 // whole document fits → top-anchored, no vertical pan needed
            } else {
                let minY = viewportSize.height - topPad - stackH - margin
                let maxY = margin - topPad
                y = min(maxY, max(minY, target.y))
            }
            return CGPoint(x: x, y: y)

        case .infiniteWhiteboard:
            return target
        }
    }

    /// One-axis bound: page may pan until only `margin` of workspace shows past its edge.
    /// If the scaled page fits inside the viewport (with peek room), the axis is locked to 0.
    private func axisPanBound(_ value: CGFloat, scaled: CGFloat, viewport: CGFloat, margin: CGFloat) -> CGFloat {
        if scaled + 2 * margin <= viewport { return 0 }
        let bound = (scaled - viewport) / 2.0 + margin
        return min(bound, max(-bound, value))
    }

    /// Rendered height of the continuous page stack in canvas units (matches the view's layout).
    private var totalStackHeight: CGFloat {
        let n = CGFloat(max(1, project.pages.count))
        let gap: CGFloat = 56.0
        return n * CGFloat(currentPage.height) + (n - 1) * gap + 140.0
    }

    /// Re-clamps the current pan offset (viewport resize, zoom change, page switch…).
    public func clampPanOffset(for viewportSize: CGSize) {
        guard viewportSize.width > 1 && viewportSize.height > 1 else { return }
        let clamped = clampedPan(panOffset, viewportSize: viewportSize)
        if clamped != panOffset { panOffset = clamped }
    }

    /// Applies a pan DELTA with pre-clamping — used by scroll & hand-drag so locked axes
    /// never move (fixes the "moves sideways then snaps back" laggy feel).
    public func applyPan(delta: CGSize, viewportSize: CGSize) {
        guard viewportSize.width > 1 && viewportSize.height > 1 else { return }
        let target = CGPoint(x: panOffset.x + delta.width, y: panOffset.y + delta.height)
        let clamped = clampedPan(target, viewportSize: viewportSize)
        if clamped != panOffset { panOffset = clamped }
    }

    /// Sets an absolute pan position (drag gestures using start-offset + translation).
    public func setPan(to point: CGPoint, viewportSize: CGSize) {
        guard viewportSize.width > 1 && viewportSize.height > 1 else { return }
        let clamped = clampedPan(point, viewportSize: viewportSize)
        if clamped != panOffset { panOffset = clamped }
    }

    // MARK: - Zoom Controls

    public func zoomIn() {
        let upper = pageLayoutMode == .infiniteWhiteboard ? 8.0 : 4.0
        zoomScale = min(upper, zoomScale + 0.1)
        clampPanOffset(for: lastViewportSize)
    }

    public func zoomOut() {
        let lower = pageLayoutMode == .infiniteWhiteboard ? 0.05 : 0.1
        zoomScale = max(lower, zoomScale - 0.1)
        clampPanOffset(for: lastViewportSize)
    }

    public func zoomToFit(viewportSize: CGSize) {
        guard viewportSize.width > 50 && viewportSize.height > 50 else { return }

        if pageLayoutMode == .infiniteWhiteboard {
            // Use ROTATED bounds so tilted elements fit properly
            let allBounds = currentPage.elements.filter { $0.isVisible }.map { $0.rotatedCanvasBounds }
            if !allBounds.isEmpty {
                let minX = allBounds.map { $0.minX }.min() ?? 0
                let maxX = allBounds.map { $0.maxX }.max() ?? 1000
                let minY = allBounds.map { $0.minY }.min() ?? 0
                let maxY = allBounds.map { $0.maxY }.max() ?? 1000
                let boundW = max(400, maxX - minX + 240)
                let boundH = max(400, maxY - minY + 240)
                let centerElemX = (minX + maxX) / 2.0
                let centerElemY = (minY + maxY) / 2.0
                let fit = min(viewportSize.width / boundW, viewportSize.height / boundH)
                zoomScale = max(0.15, min(1.2, fit))
                panOffset = CGPoint(x: -centerElemX * zoomScale, y: -centerElemY * zoomScale)
            } else {
                zoomScale = 0.8
                panOffset = .zero
            }
            return
        }

        let eff = effectiveViewportSize(viewportSize)
        let availableW = max(50, eff.width - 80)
        let availableH = max(50, eff.height - 110)

        let wRatio = availableW / currentPage.width
        let hRatio = availableH / currentPage.height
        let fit = min(wRatio, hRatio)
        zoomScale = max(0.15, min(1.5, fit))
        lastFitZoom = zoomScale
        panOffset = .zero
    }

    public func zoomTo100() {
        zoomScale = 1.0
        panOffset = .zero
        clampPanOffset(for: lastViewportSize)
    }

    /// Zooms so the current selection fills the viewport (Figma-style ⌘F / "F" key).
    /// With no selection, fits the whole page.
    public func zoomToSelection(viewportSize: CGSize) {
        guard viewportSize.width > 50 && viewportSize.height > 50 else { return }
        var bounds = CGRect.null
        if selectedElements.isEmpty {
            bounds = CGRect(x: 0, y: 0, width: currentPage.width, height: currentPage.height)
        } else {
            for el in selectedElements {
                bounds = bounds.union(el.rotatedCanvasBounds)
            }
        }
        guard bounds.width > 1, bounds.height > 1 else { return }
        let paddedW = bounds.width + 220
        let paddedH = bounds.height + 220
        let fit = min(viewportSize.width / paddedW, viewportSize.height / paddedH)
        let upper = pageLayoutMode == .infiniteWhiteboard ? 8.0 : 4.0
        zoomScale = max(0.1, min(upper, fit))
        panOffset = CGPoint(x: -bounds.midX * zoomScale, y: -bounds.midY * zoomScale)
        clampPanOffset(for: viewportSize)
    }

    // MARK: - Quick Export & Share

    public func copyPageImageToClipboard() {
        if ExportEngine.copyImageToClipboard(page: currentPage, scale: 2.0) {
            showTemporaryToast("✨ HD Image Copied to Clipboard!")
        } else {
            showTemporaryToast("❌ Failed to copy image")
        }
    }

    /// Copies only the primary selected element as a transparent PNG (⌘⇧C variant).
    public func copySelectedElementAsImage() {
        guard let el = primarySelectedElement else {
            showTemporaryToast("Select an element first")
            return
        }
        var page = CanvasPage(
            name: "element",
            width: el.width + 60,
            height: el.height + 60,
            background: .solid(.white),
            isTransparent: true
        )
        var copy = el
        copy.x = 30
        copy.y = 30
        page.elements = [copy]
        if let img = ExportEngine.renderImage(page: page, scale: 2.0) {
            let pb = NSPasteboard.general
            pb.clearContents()
            pb.writeObjects([img])
            showTemporaryToast("🧩 Element copied as image")
        } else {
            showTemporaryToast("❌ Failed to render element")
        }
    }

    public func copySVGForFigma() {
        if ExportEngine.copySVGToClipboard(page: currentPage) {
            showTemporaryToast("✨ Vector SVG Copied! Press ⌘V in Figma to paste layers.")
        } else {
            showTemporaryToast("❌ Failed to copy vector SVG")
        }
    }

    private var toastTask: Task<Void, Never>? = nil

    @MainActor
    public func showTemporaryToast(_ message: String) {
        toastMessage = message
        showToast = true
        toastTask?.cancel()
        toastTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if !Task.isCancelled {
                self.showToast = false
            }
        }
    }
}

public enum PageLayoutMode: String, Codable, CaseIterable, Identifiable {
    case continuousVertical = "Continuous Document"
    case singleSlide = "Single Slide"
    case infiniteWhiteboard = "Infinite Whiteboard"

    public var id: String { rawValue }
}

public enum AlignmentType {
    case left, centerHorizontal, right
    case top, centerVertical, bottom
    case distributeHorizontally, distributeVertically
}

public enum SidebarTab: String, CaseIterable, Identifiable {
    case pages = "Pages"
    case templates = "Templates"
    case code = "Code"
    case elements = "Shapes"
    case text = "Text"
    case media = "Media"
    case icons = "Icons"
    case brandKit = "Brand"
    case backgrounds = "Background"
    case draw = "Pen"
    case layers = "Layers"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .pages: return "doc.on.doc.fill"
        case .templates: return "newspaper.fill"
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .elements: return "square.on.circle"
        case .text: return "textformat"
        case .media: return "photo.on.rectangle.angled"
        case .icons: return "sparkles"
        case .brandKit: return "briefcase.fill"
        case .backgrounds: return "paintpalette.fill"
        case .draw: return "pencil.tip"
        case .layers: return "square.3.layers.3d.down.right.fill"
        }
    }
}
