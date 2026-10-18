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
    @Published public var project: CanvasProject {
        didSet { hasOpenedDocument = true }
    }
    /// True once a real document is loaded or the virgin project is mutated —
    /// gates save-on-quit / save-on-Home so a dashboard-only session can't
    /// write a phantom "Untitled Project" to Projects/ on every launch+quit.
    public private(set) var hasOpenedDocument = false
    @Published public var activePageIndex: Int = 0 {
        didSet {
            if activePageIndex != oldValue {
                // Text/code edit sessions can't outlive their page.
                editingTextElementId = nil
                editingCodeElementId = nil
                // A page switch mid-gesture orphans the gesture's
                // commitLiveTransform — reset the flag or thumbnails/effects
                // stay degraded forever.
                if isLiveTransforming {
                    isLiveTransforming = false
                    persistProject()
                }
                // Selection is per-page: ids from the previous page would make
                // drag/group/align act on the wrong (or no) elements.
                let alive = Set(currentPage.elements.map(\.id))
                let kept = selectedElementIds.filter { alive.contains($0) }
                if kept != selectedElementIds { selectedElementIds = kept }
            }
        }
    }
    @Published public var selectedElementIds: Set<UUID> = [] {
        didSet {
            if let id = textEditSnapshotId, !selectedElementIds.contains(id) { textEditSnapshotId = nil }
            if let id = codeEditSnapshotId, !selectedElementIds.contains(id) { codeEditSnapshotId = nil }
        }
    }
    @Published public var activeTool: CanvasTool = .select

    // Inline Editing
    @Published public var editingTextElementId: UUID? = nil {
        didSet {
            if editingTextElementId != oldValue { textEditSnapshotId = nil }
        }
    }
    @Published public var editingCodeElementId: UUID? = nil {
        didSet {
            if editingCodeElementId != oldValue { codeEditSnapshotId = nil }
        }
    }

    /// Element whose current edit session already pushed an undo state (so a
    /// typing run is ONE undo step instead of per-keystroke or none at all).
    private var textEditSnapshotId: UUID? = nil
    private var codeEditSnapshotId: UUID? = nil

    // Collapsible Sidebars
    @Published public var isLeftSidebarVisible: Bool = true
    @Published public var isRightInspectorVisible: Bool = true

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
    @Published public var toastIsError: Bool = false

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

    /// Virgin-session init — project is the placeholder "Untitled Project" and
    /// must NOT count as an opened document (see hasOpenedDocument).
    public init() {
        self.project = CanvasProject()
        commonInit()
        // commonInit mutates project (starter page/background) — those writes
        // fire project's didSet; they are setup, not an opened document.
        hasOpenedDocument = false
    }

    /// Constructing a view model around an existing project means that project
    /// is the opened document — mark it so save-on-quit/Home persists it.
    public init(project: CanvasProject) {
        self.project = project
        commonInit()
        hasOpenedDocument = true
    }

    /// The open document was trashed from the dashboard — drop it entirely and
    /// return to the closed state. Without this, save-on-quit / Home navigation
    /// would resurrect the file back into Projects/ (trashed ids are also
    /// write-gated in ProjectStorage as a second layer).
    public func closeDocument() {
        if isLiveTransforming { isLiveTransforming = false }
        project = CanvasProject()   // didSet fires; flag is reset below
        commonInit()
        activePageIndex = 0
        selectedElementIds.removeAll()
        historyManager.clear()
        hasOpenedDocument = false
    }

    private func commonInit() {
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
            // Page + timestamp in ONE assignment: the canvas re-renders on every
            // `project` publish, and writing them separately published twice.
            var updated = project
            updated.pages[activePageIndex] = newValue
            updated.modifiedAt = Date()
            project = updated
            ProjectStorage.shared.saveProjectDebounced(project)
        }
    }

    public var selectedElements: [CanvasElement] {
        currentPage.elements.filter { selectedElementIds.contains($0.id) }
    }

    // MARK: - Render Cache

    private var zOrderCache: [UUID: (source: [CanvasElement], sorted: [CanvasElement])] = [:]

    /// A page's elements in paint order (ascending zIndex), memoized per page.
    /// Every drag tick republishes `project`, and Document mode renders every
    /// page — re-sorting all of them per frame was pure waste. Untouched pages
    /// keep the same array buffer, so the `==` check is O(1) for them (Array
    /// equality short-circuits on buffer identity); only the edited page re-sorts.
    public func zOrderedElements(of page: CanvasPage) -> [CanvasElement] {
        if let hit = zOrderCache[page.id], hit.source == page.elements {
            return hit.sorted
        }
        let sorted = page.elements.sorted { $0.zIndex < $1.zIndex }
        if zOrderCache.count > project.pages.count + 8 {
            let live = Set(project.pages.map(\.id))
            zOrderCache = zOrderCache.filter { live.contains($0.key) }
        }
        zOrderCache[page.id] = (page.elements, sorted)
        return sorted
    }

    /// Deterministic "representative" of the selection (topmost element) —
    /// `Set.first` changed between renders, so the inspector flickered between
    /// members of a multi-selection.
    public var primarySelectedElement: CanvasElement? {
        guard !selectedElementIds.isEmpty else { return nil }
        if selectedElementIds.count == 1, let id = selectedElementIds.first {
            return currentPage.elements.first(where: { $0.id == id })
        }
        return currentPage.elements
            .filter { selectedElementIds.contains($0.id) }
            .max(by: { $0.zIndex < $1.zIndex })
    }

    // MARK: - History Recording

    public func saveHistoryState() {
        historyManager.pushState(project)
        lastHistoryPush = Date()
    }

    private var lastHistoryPush: Date = .distantPast
    private var lastCoalescedEdit: Date = .distantPast
    private var lastCoalescedSelection: Set<UUID> = []

    /// One undo step per burst of inspector edits: a slider drag or a run of
    /// keystrokes in a field becomes a single step instead of none (the old
    /// behaviour — ⌘Z then wiped the previous action too) or one per tick.
    /// Skipped when the caller already pushed a snapshot for this edit.
    public func recordCoalescedEdit() {
        let now = Date()
        let continuing = now.timeIntervalSince(lastCoalescedEdit) < 0.8 && lastCoalescedSelection == selectedElementIds
        let callerJustPushed = now.timeIntervalSince(lastHistoryPush) < 0.05
        if !continuing && !callerJustPushed {
            saveHistoryState()
        }
        lastCoalescedEdit = now
        lastCoalescedSelection = selectedElementIds
    }

    /// Persist a project-level mutation (page add/remove/reorder, rename,
    /// template swap). Anything writing `project` outside the `currentPage`
    /// setter MUST call this — a plain `project.pages` write never reaches disk.
    private func persistProject() {
        project.modifiedAt = Date()
        ProjectStorage.shared.saveProjectDebounced(project)
    }

    public func undo() {
        if let prev = historyManager.undo(currentProject: project) {
            project = prev
            retainSurvivingSelection()
            editingTextElementId = nil
            editingCodeElementId = nil
            textEditSnapshotId = nil
            codeEditSnapshotId = nil
            // project has no autosave didSet — undo must persist like an edit.
            persistProject()
        }
    }

    /// Keeps whatever is still on the page selected across undo/redo (Figma/Canva
    /// behaviour) instead of dropping the selection every time.
    private func retainSurvivingSelection() {
        // ⌘Z mid-gesture tears down the selection overlay before its onEnded
        // fires — clear gesture state so the next resize starts fresh (and
        // records its own undo step) instead of reusing a stale frame.
        activeResizeInitialFrame = nil
        if isLiveTransforming { isLiveTransforming = false }
        if !project.pages.indices.contains(activePageIndex) {
            activePageIndex = max(0, project.pages.count - 1)
        }
        let alive = Set(currentPage.elements.map(\.id))
        selectedElementIds = selectedElementIds.filter { alive.contains($0) }
    }

    public func redo() {
        if let next = historyManager.redo(currentProject: project) {
            project = next
            retainSurvivingSelection()
            editingTextElementId = nil
            editingCodeElementId = nil
            textEditSnapshotId = nil
            codeEditSnapshotId = nil
            persistProject()
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
        // Mutate a local copy and write the page once — each write through the
        // `currentPage` setter republishes the whole project and kicks autosave.
        var page = currentPage
        for idx in page.elements.indices where selectedElementIds.contains(page.elements[idx].id) {
            page.elements[idx].groupId = newGroupId
        }
        currentPage = page
        showTemporaryToast("Grouped (\(selectedElementIds.count) elements)")
    }

    public func ungroupSelectedElements() {
        guard !selectedElementIds.isEmpty else { return }
        saveHistoryState()
        var page = currentPage
        for idx in page.elements.indices where selectedElementIds.contains(page.elements[idx].id) {
            page.elements[idx].groupId = nil
        }
        currentPage = page
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
        selectedElementIds = Set(currentPage.elements.filter { $0.isVisible }.map { $0.id })
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

        // Open-path kinds (hairlines) can't be filled — draw them via stroke
        // in the fill color so an inserted Line isn't invisible.
        let lineStroke = StrokeStyle(
            isEnabled: kind == .line,
            color: fill.solidColor,
            lineWidth: max(2, initialH)
        )
        let element = CanvasElement(
            name: kind.rawValue,
            payload: .shape(ShapeContent(kind: kind, cornerRadius: 12, fill: fill, stroke: lineStroke)),
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
        let content = TextContent(
            text: text,
            fontFamily: fontFamily,
            fontSize: fontSize,
            fontWeight: fontWeight,
            alignment: .center,
            textColor: color
        )
        // Start tight to the content (Canva-style) instead of a hardcoded box.
        let fittedH = Self.fittedHeightForText(content, width: 440)
        let element = CanvasElement(
            name: "Heading Text",
            payload: .text(content),
            x: textOrigin.x,
            y: textOrigin.y,
            width: 440,
            height: fittedH,
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

    /// Inserts a bundle of elements (a DevKit preset / composite component):
    /// the bundle is translated so its bounding box lands at the insertion
    /// origin, all members share a groupId, stacking continues after the
    /// current top, and the whole bundle is selected.
    public func insertElements(_ bundle: [CanvasElement], name: String) {
        guard !bundle.isEmpty else { return }
        saveHistoryState()

        var minX = Double.greatestFiniteMagnitude
        var minY = Double.greatestFiniteMagnitude
        var maxX = -Double.greatestFiniteMagnitude
        var maxY = -Double.greatestFiniteMagnitude
        for el in bundle {
            minX = min(minX, el.x); minY = min(minY, el.y)
            maxX = max(maxX, el.x + el.width); maxY = max(maxY, el.y + el.height)
        }
        let origin = insertionOrigin(elementWidth: maxX - minX, elementHeight: maxY - minY)
        var z = (currentPage.elements.map { $0.zIndex }.max() ?? 0) + 1
        let gid = bundle.count > 1 ? UUID() : nil
        var ids: [UUID] = []
        for el in bundle {
            var e = el
            e.x += Double(origin.x) - minX
            e.y += Double(origin.y) - minY
            e.groupId = gid
            e.zIndex = z
            z += 1
            currentPage.elements.append(e)
            ids.append(e.id)
        }
        selectedElementIds = Set(ids)
        activeTool = .select
        showTemporaryToast("Added \(name)")
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
        var page = currentPage
        var changed = false
        for index in page.elements.indices where selectedElementIds.contains(page.elements[index].id) {
            guard !page.elements[index].isLocked else { continue }
            let before = page.elements[index]
            modify(&page.elements[index])
            if page.elements[index] != before { changed = true }
        }
        guard changed else { return }
        recordCoalescedEdit()
        // One write through the setter (one publish + one autosave) instead of
        // one per selected element.
        currentPage = page
    }

    public func updateElement(id: UUID, _ modify: (inout CanvasElement) -> Void) {
        guard let index = currentPage.elements.firstIndex(where: { $0.id == id }) else { return }
        modify(&currentPage.elements[index])
    }

    // MARK: - Text Auto-Fit (Canva / PowerPoint parity)

    /// Tight height for a text payload at the given box width (internal margins
    /// honored — see TextMeasurement).
    public static func fittedHeightForText(_ t: TextContent, width: Double) -> Double {
        TextMeasurement.fittedHeight(for: t, width: width)
    }

    /// Sets text content and grows the box to fit (Canva auto-height). Never
    /// shrinks below one line so the box stays selectable.
    public func updateTextAndFitHeight(id: UUID, newText: String) {
        guard let index = currentPage.elements.firstIndex(where: { $0.id == id }) else { return }
        var el = currentPage.elements[index]
        guard case .text(var t) = el.payload else { return }
        // Snapshot the pre-edit state once per editing session so Cmd+Z undoes
        // the whole typing run rather than one keystroke (or nothing, as before).
        if t.text != newText && textEditSnapshotId != id {
            saveHistoryState()
            textEditSnapshotId = id
        }
        t.text = newText
        el.payload = .text(t)
        el.height = Self.fittedHeightForText(t, width: el.width)
        currentPage.elements[index] = el
    }

    /// Sets code content and refits the block height. One undo state per edit
    /// session — same contract as `updateTextAndFitHeight`.
    public func updateCodeAndFitHeight(id: UUID, newCode: String) {
        guard let index = currentPage.elements.firstIndex(where: { $0.id == id }) else { return }
        var el = currentPage.elements[index]
        guard case .code(var c) = el.payload else { return }
        if c.code != newCode && codeEditSnapshotId != id {
            saveHistoryState()
            codeEditSnapshotId = id
        }
        c.code = newCode
        el.payload = .code(c)
        el.height = Self.calculateCodeBlockHeight(for: c)
        currentPage.elements[index] = el
    }

    /// Reflows selected text boxes after a width/metric change (inspector edits).
    /// Boxes stay tight to their content like Canva (no stale empty space, no
    /// clipping). Manual top/bottom stretches are re-tightened on the next
    /// content or metric edit — same tradeoff Canva makes for auto-height boxes.
    public func refitSelectedTextHeights() {
        for id in selectedElementIds {
            guard let index = currentPage.elements.firstIndex(where: { $0.id == id }) else { continue }
            var el = currentPage.elements[index]
            guard case .text(let t) = el.payload else { continue }
            let fitted = Self.fittedHeightForText(t, width: el.width)
            if abs(fitted - el.height) > 0.5 {
                el.height = fitted
                currentPage.elements[index] = el
            }
        }
    }

    // MARK: - Drag & Snapping (1:1 Mouse Cursor Accurate)

    public func dragSelectedElements(by delta: CGSize, startPositions: [UUID: CGPoint], applySnapping: Bool = true) {
        guard !selectedElementIds.isEmpty else { return }

        let deltaCanvasX = delta.width
        let deltaCanvasY = delta.height

        // Snap the whole selection's box (at its start positions), not an
        // arbitrary member — Set.first made multi-drags snap unpredictably.
        var startBox = CGRect.null
        for el in currentPage.elements where selectedElementIds.contains(el.id) {
            guard let start = startPositions[el.id] else { continue }
            startBox = startBox.union(CGRect(x: start.x, y: start.y, width: el.width, height: el.height))
        }
        guard !startBox.isNull else { return }

        var finalDeltaX = deltaCanvasX
        var finalDeltaY = deltaCanvasY

        if applySnapping && enableSnapping {
            let otherRects = currentPage.elements
                .filter { $0.isVisible && !selectedElementIds.contains($0.id) }
                .map { $0.frame }

            let snapRes = SnappingEngine.snap(
                rect: startBox.offsetBy(dx: deltaCanvasX, dy: deltaCanvasY),
                against: otherRects,
                canvasSize: CGSize(width: currentPage.width, height: currentPage.height),
                rulerGuides: currentPage.guides ?? [],
                // Constant ~6 screen points of "pull" at any zoom level.
                threshold: SnappingEngine.snapThreshold / max(0.05, zoomScale)
            )
            finalDeltaX = snapRes.snappedOrigin.x - startBox.minX
            finalDeltaY = snapRes.snappedOrigin.y - startBox.minY
            activeGuides = snapRes.activeGuides
        } else {
            activeGuides = []
        }

        batchLiveWrites {
            for id in selectedElementIds {
                if let startPos = startPositions[id],
                   let index = currentPage.elements.firstIndex(where: { $0.id == id }) {
                    guard !currentPage.elements[index].isLocked else { continue }
                    let nx = startPos.x + finalDeltaX
                    let ny = startPos.y + finalDeltaY
                    writeElementLive(index: index) {
                        $0.x = nx
                        $0.y = ny
                    }
                }
            }
        }
        if !isLiveTransforming {
            isLiveTransforming = true
        }
    }

    public func endDrag() {
        activeGuides.removeAll()
        // Anchored connectors follow their endpoints after any confirmed move.
        syncConnectors(touching: selectedElementIds)
        commitLiveTransform()
    }

    // MARK: - Resizing & Handles (Rotation-Aware Canva/Figma Transform Engine)

    /// True while a resize / drag / rotate gesture is actively streaming ticks.
    /// Views use this to skip expensive per-frame work (sync thumbnail renders,
    /// multi-pass text shadows) until the gesture commits. Toggled twice per
    /// gesture, so its own publishes are cheap — the 60Hz ticks in between must
    /// NOT trigger autosave / modifiedAt churn (see writeElementLive).
    @Published public var isLiveTransforming: Bool = false

    public var activeResizeInitialFrame: CGRect? = nil
    public var activeResizeElementId: UUID? = nil
    public var activeResizeInitialRotation: Double = 0
    // Initial text metrics for Canva-style corner-drag font scaling.
    public var activeResizeInitialFontSize: Double = 0
    public var activeResizeInitialLineSpacing: Double = 0
    public var activeResizeInitialLetterSpacing: Double = 0
    public var activeResizeIsText: Bool = false

    /// Writes one element straight into the page WITHOUT touching
    /// `modifiedAt` or kicking the autosave debounce. Use for every
    /// per-tick update during a live gesture; call `commitLiveTransform()`
    /// once on gesture end. (Going through the `currentPage` setter on every
    /// tick was a major source of resize lag.)
    @MainActor
    private func writeElementLive(index: Int, _ modify: (inout CanvasElement) -> Void) {
        if liveBatchElements != nil {
            modify(&liveBatchElements![index])
            return
        }
        guard activePageIndex < project.pages.count else { return }
        modify(&project.pages[activePageIndex].elements[index])
    }

    /// Buffer for `batchLiveWrites` — nil outside a batch.
    private var liveBatchElements: [CanvasElement]? = nil

    /// Runs `body` with every `writeElementLive` buffered on a local copy of the
    /// page's elements, then publishes once. A multi-selection drag used to
    /// republish `project` (and re-render every page) once per member per tick.
    @MainActor
    private func batchLiveWrites(_ body: () -> Void) {
        guard activePageIndex < project.pages.count, liveBatchElements == nil else {
            body()
            return
        }
        liveBatchElements = project.pages[activePageIndex].elements
        body()
        if let batched = liveBatchElements {
            liveBatchElements = nil
            if batched != project.pages[activePageIndex].elements {
                project.pages[activePageIndex].elements = batched
            }
        }
    }

    /// Persists a finished gesture: timestamp + debounced autosave + flag reset.
    @MainActor
    private func commitLiveTransform() {
        persistProject()
        if isLiveTransforming {
            isLiveTransforming = false
        }
    }

    public func beginResize(id: UUID, handle: ResizeHandlePosition) {
        guard let index = currentPage.elements.firstIndex(where: { $0.id == id }),
              !currentPage.elements[index].isLocked else { return }
        saveHistoryState()
        activeResizeElementId = id
        activeResizeInitialFrame = currentPage.elements[index].frame
        activeResizeInitialRotation = currentPage.elements[index].rotation
        if case .text(let t) = currentPage.elements[index].payload {
            activeResizeIsText = true
            activeResizeInitialFontSize = t.fontSize
            activeResizeInitialLineSpacing = t.lineSpacing
            activeResizeInitialLetterSpacing = t.letterSpacing
        } else {
            activeResizeIsText = false
            activeResizeInitialFontSize = 0
            activeResizeInitialLineSpacing = 0
            activeResizeInitialLetterSpacing = 0
        }
        isLiveTransforming = true
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

        // --- Step 4: Canva/PowerPoint text behavior + cheap live write ---
        // NOTE: `translation` must already be in canvas units (callers divide
        // the screen-space gesture translation by zoomScale — see
        // SelectionOverlayView). Do NOT divide here or zoomed resizes double-scale.
        let isCorner: Bool = {
            switch handle {
            case .topLeft, .topRight, .bottomLeft, .bottomRight: return true
            case .top, .left, .right, .bottom: return false
            }
        }()
        let isSideWidth: Bool = (handle == .left || handle == .right)
        let isHeightOnly: Bool = (handle == .top || handle == .bottom)

        writeElementLive(index: index) { elem in
            elem.x = tentativeFrame.origin.x + shiftX
            elem.y = tentativeFrame.origin.y + shiftY
            elem.width = tentativeFrame.width
            elem.height = tentativeFrame.height

            // Text boxes behave like Canva / PowerPoint:
            // • side handles reflow the paragraph and auto-fit height (font kept)
            // • top/bottom never clip — height is at least the fitted height
            // • corner handles scale the font (Canva) then auto-fit height
            if case .text(var t) = elem.payload, activeResizeIsText, activeResizeInitialFontSize > 0 {
                if isCorner {
                    let scale = max(0.15, elem.width / max(1, initialFrame.width))
                    let newFont = min(400, max(6, activeResizeInitialFontSize * scale))
                    let fontRatio = newFont / max(1, activeResizeInitialFontSize)
                    t.fontSize = newFont
                    t.lineSpacing = activeResizeInitialLineSpacing * fontRatio
                    t.letterSpacing = activeResizeInitialLetterSpacing * fontRatio
                    elem.payload = .text(t)
                    elem.height = TextMeasurement.fittedHeight(for: t, width: elem.width)
                } else if isSideWidth {
                    elem.height = TextMeasurement.fittedHeight(for: t, width: elem.width)
                } else if isHeightOnly {
                    let fitted = TextMeasurement.fittedHeight(for: t, width: elem.width)
                    elem.height = max(elem.height, fitted)
                }
            }
        }
        if !isLiveTransforming {
            isLiveTransforming = true
        }
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
        activeResizeIsText = false
        commitLiveTransform()
    }

    // MARK: - Multi-Selection / Group Transform (Figma-style collective box)

    /// Axis-aligned union of every selected element's rotated bounds — the
    /// collective bounding box the multi-select overlay draws and transforms.
    public var selectionBounds: CGRect {
        selectedElements.reduce(CGRect.null) { $0.union($1.rotatedCanvasBounds) }
    }

    /// Marquee hit-testing may land inside only SOME members of a group; expand
    /// the hit set so the whole group is always selected/ transformed together.
    public func expandSelectionForGroups(_ ids: Set<UUID>) -> Set<UUID> {
        var result = ids
        let hitGroupIds = Set(currentPage.elements.filter { ids.contains($0.id) }.compactMap { $0.groupId })
        guard !hitGroupIds.isEmpty else { return result }
        for el in currentPage.elements where el.groupId.map({ hitGroupIds.contains($0) }) == true {
            result.insert(el.id)
        }
        return result
    }

    public var groupResizeInitialBounds: CGRect? = nil
    public var groupResizeInitialFrames: [UUID: CGRect] = [:]
    public var groupResizeInitialText: [UUID: (fontSize: Double, lineSpacing: Double, letterSpacing: Double)] = [:]

    public func beginGroupResize() {
        let members = selectedElements.filter { !$0.isLocked }
        guard !members.isEmpty else { return }
        saveHistoryState()
        groupResizeInitialFrames = [:]
        groupResizeInitialText = [:]
        var union = CGRect.null
        for el in members {
            groupResizeInitialFrames[el.id] = el.frame
            if case .text(let t) = el.payload {
                groupResizeInitialText[el.id] = (t.fontSize, t.lineSpacing, t.letterSpacing)
            }
            union = union.union(el.rotatedCanvasBounds)
        }
        groupResizeInitialBounds = union
        isLiveTransforming = true
    }

    /// Scales every selected element linearly about the stationary anchor — the
    /// collective box is axis-aligned so the translation needs no rotation
    /// projection (theta = 0).
    public func updateGroupResize(
        handle: ResizeHandlePosition,
        translation: CGSize,
        lockAspectRatio: Bool = false
    ) {
        guard let initialBounds = groupResizeInitialBounds else { return }

        let localDX = translation.width
        let localDY = translation.height
        var w = initialBounds.width
        var h = initialBounds.height
        let aspect = max(0.01, initialBounds.width / max(0.01, initialBounds.height))
        let minW: Double = 24.0
        let minH: Double = 20.0

        switch handle {
        case .topLeft:
            var dw = -localDX
            var dh = -localDY
            if lockAspectRatio { let d = max(dw, dh); dw = d; dh = d / aspect }
            w = max(minW, initialBounds.width + dw)
            h = max(minH, initialBounds.height + dh)
        case .top:
            h = max(minH, initialBounds.height - localDY)
        case .topRight:
            var dw = localDX
            var dh = -localDY
            if lockAspectRatio { let d = max(dw, dh); dw = d; dh = d / aspect }
            w = max(minW, initialBounds.width + dw)
            h = max(minH, initialBounds.height + dh)
        case .left:
            w = max(minW, initialBounds.width - localDX)
        case .right:
            w = max(minW, initialBounds.width + localDX)
        case .bottomLeft:
            var dw = -localDX
            var dh = localDY
            if lockAspectRatio { let d = max(dw, dh); dw = d; dh = d / aspect }
            w = max(minW, initialBounds.width + dw)
            h = max(minH, initialBounds.height + dh)
        case .bottom:
            h = max(minH, initialBounds.height + localDY)
        case .bottomRight:
            var dw = localDX
            var dh = localDY
            if lockAspectRatio { let d = max(dw, dh); dw = d; dh = d / aspect }
            w = max(minW, initialBounds.width + dw)
            h = max(minH, initialBounds.height + dh)
        }

        let scaleX = w / max(1, initialBounds.width)
        let scaleY = h / max(1, initialBounds.height)
        let anchor = anchorPoint(for: handle, in: initialBounds)
        let isCorner: Bool = {
            switch handle {
            case .topLeft, .topRight, .bottomLeft, .bottomRight: return true
            case .top, .left, .right, .bottom: return false
            }
        }()
        // Corner drags scale type along with the box (tightest axis wins so the
        // text never outgrows its frame); edge drags keep the font and reflow.
        let fontScale = isCorner ? min(scaleX, scaleY) : 1.0

        batchLiveWrites {
            for el in selectedElements {
                guard let startFrame = groupResizeInitialFrames[el.id],
                      let index = currentPage.elements.firstIndex(where: { $0.id == el.id }),
                      !currentPage.elements[index].isLocked else { continue }
                writeElementLive(index: index) { elem in
                    elem.x = anchor.x + (startFrame.origin.x - anchor.x) * scaleX
                    elem.y = anchor.y + (startFrame.origin.y - anchor.y) * scaleY
                    elem.width = max(1, startFrame.width * scaleX)
                    elem.height = max(1, startFrame.height * scaleY)

                    if case .text(var t) = elem.payload,
                       let initial = groupResizeInitialText[el.id], initial.fontSize > 0 {
                        if fontScale != 1.0 {
                            let newFont = min(400, max(6, initial.fontSize * fontScale))
                            let fontRatio = newFont / initial.fontSize
                            t.fontSize = newFont
                            t.lineSpacing = initial.lineSpacing * fontRatio
                            t.letterSpacing = initial.letterSpacing * fontRatio
                            elem.payload = .text(t)
                        }
                        // Never clip: grow the box if the reflowed text needs more.
                        let fitted = TextMeasurement.fittedHeight(for: t, width: elem.width)
                        elem.height = max(elem.height, fitted)
                    }
                }
            }
        }
        if !isLiveTransforming {
            isLiveTransforming = true
        }
    }

    public func endGroupResize() {
        syncConnectors(touching: selectedElementIds)
        groupResizeInitialBounds = nil
        groupResizeInitialFrames = [:]
        groupResizeInitialText = [:]
        commitLiveTransform()
    }

    // MARK: - Group Rotation (members orbit the collective center)

    public var isRotatingGroup: Bool = false
    public var groupRotationCenter: CGPoint = .zero
    public var groupRotationStartAngle: Double = 0
    public var groupRotationAppliedDelta: Double = 0
    public var groupRotationInitial: [UUID: (center: CGPoint, rotation: Double)] = [:]

    public func beginGroupRotation(startLocation: CGPoint) {
        let members = selectedElements.filter { !$0.isLocked }
        guard !members.isEmpty else { return }
        saveHistoryState()
        isRotatingGroup = true
        isLiveTransforming = true
        groupRotationInitial = [:]
        var union = CGRect.null
        for el in members {
            groupRotationInitial[el.id] = (el.center, el.rotation)
            union = union.union(el.rotatedCanvasBounds)
        }
        groupRotationCenter = CGPoint(x: union.midX, y: union.midY)
        groupRotationStartAngle = atan2(
            Double(startLocation.y - union.midY),
            Double(startLocation.x - union.midX)
        )
        groupRotationAppliedDelta = 0
    }

    public func updateGroupRotation(currentLocation: CGPoint) {
        guard isRotatingGroup else { return }
        let currentAngle = atan2(
            Double(currentLocation.y - groupRotationCenter.y),
            Double(currentLocation.x - groupRotationCenter.x)
        )
        var deltaDeg = (currentAngle - groupRotationStartAngle) * 180.0 / .pi
        // Snap the delta to 15° increments like the single-element rotator.
        let snapAngles: [Double] = stride(from: -180.0, through: 180.0, by: 15.0).map { $0 }
        for snap in snapAngles where abs(deltaDeg - snap) < 4.0 {
            deltaDeg = snap
            break
        }
        groupRotationAppliedDelta = deltaDeg
        let deltaRad = deltaDeg * .pi / 180.0
        let c = cos(deltaRad)
        let s = sin(deltaRad)

        batchLiveWrites {
            for el in selectedElements {
                guard let initial = groupRotationInitial[el.id],
                      let index = currentPage.elements.firstIndex(where: { $0.id == el.id }),
                      !currentPage.elements[index].isLocked else { continue }
                let dx = Double(initial.center.x - groupRotationCenter.x)
                let dy = Double(initial.center.y - groupRotationCenter.y)
                let newCenterX = groupRotationCenter.x + dx * c - dy * s
                let newCenterY = groupRotationCenter.y + dx * s + dy * c
                var newRotation = (initial.rotation + deltaDeg).truncatingRemainder(dividingBy: 360.0)
                if newRotation < 0 { newRotation += 360.0 }
                writeElementLive(index: index) { elem in
                    elem.x = newCenterX - elem.width / 2.0
                    elem.y = newCenterY - elem.height / 2.0
                    elem.rotation = newRotation
                }
            }
        }
    }

    public func endGroupRotation() {
        isRotatingGroup = false
        groupRotationInitial = [:]
        groupRotationAppliedDelta = 0
        syncConnectors(touching: selectedElementIds)
        commitLiveTransform()
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
        isLiveTransforming = true
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
        let finalDegrees = degrees
        writeElementLive(index: index) { $0.rotation = finalDegrees }
    }

    public func endRotation() {
        isRotatingElement = false
        activeRotationStartAngle = 0
        if let id = activeRotationElementId {
            syncConnectors(touching: [id])
            activeRotationElementId = nil
        }
        commitLiveTransform()
    }

    // MARK: - Layer Reordering

    public func bringToFront() {
        reorderSelection { ordered, sel in
            ordered.filter { !sel.contains($0.id) } + ordered.filter { sel.contains($0.id) }
        }
    }

    public func sendToBack() {
        reorderSelection { ordered, sel in
            ordered.filter { sel.contains($0.id) } + ordered.filter { !sel.contains($0.id) }
        }
    }

    /// Moves each selected element one slot up past the next unselected
    /// element. Walking top→down keeps a multi-selection's internal order (the
    /// old "+2 then sort" interleaved selected runs with their neighbours).
    public func bringForward() {
        reorderSelection { ordered, sel in
            var arr = ordered
            var i = arr.count - 2
            while i >= 0 {
                if sel.contains(arr[i].id) && !sel.contains(arr[i + 1].id) {
                    arr.swapAt(i, i + 1)
                }
                i -= 1
            }
            return arr
        }
    }

    public func sendBackward() {
        reorderSelection { ordered, sel in
            var arr = ordered
            var i = 1
            while i < arr.count {
                if sel.contains(arr[i].id) && !sel.contains(arr[i - 1].id) {
                    arr.swapAt(i, i - 1)
                }
                i += 1
            }
            return arr
        }
    }

    /// Applies a z-order permutation on a local copy and writes the page once.
    private func reorderSelection(_ transform: ([CanvasElement], Set<UUID>) -> [CanvasElement]) {
        guard !selectedElementIds.isEmpty else { return }
        var page = currentPage
        let ordered = page.elements.enumerated()
            .sorted { ($0.element.zIndex, $0.offset) < ($1.element.zIndex, $1.offset) }
            .map(\.element)
        let result = transform(ordered, selectedElementIds)
        guard result.map(\.id) != ordered.map(\.id) else { return }
        saveHistoryState()
        page.elements = result
        for i in page.elements.indices { page.elements[i].zIndex = i }
        currentPage = page
    }

    private func reindexZIndices() {
        currentPage.elements.sort { $0.zIndex < $1.zIndex }
        for i in 0..<currentPage.elements.count {
            currentPage.elements[i].zIndex = i
        }
    }

    // MARK: - Alignments

    /// Alignment works on "units": each group moves as one rigid block and each
    /// ungrouped element on its own. Locked elements never move. A single unit
    /// aligns to the page; several align to their collective bounds.
    public func alignSelected(_ alignment: AlignmentType) {
        let movable = selectedElements.filter { !$0.isLocked }
        guard !movable.isEmpty else { return }

        struct Unit { var ids: [UUID]; var rect: CGRect }
        var units: [Unit] = []
        var groupIndex: [UUID: Int] = [:]
        for el in movable {
            let r = CGRect(x: el.x, y: el.y, width: el.width, height: el.height)
            if let gid = el.groupId, let i = groupIndex[gid] {
                units[i].ids.append(el.id)
                units[i].rect = units[i].rect.union(r)
            } else {
                if let gid = el.groupId { groupIndex[gid] = units.count }
                units.append(Unit(ids: [el.id], rect: r))
            }
        }

        let isDistribute = alignment == .distributeHorizontally || alignment == .distributeVertically
        if isDistribute && units.count < 3 { return }

        let target: CGRect = units.count == 1
            ? CGRect(x: 0, y: 0, width: currentPage.width, height: currentPage.height)
            : units.dropFirst().reduce(units[0].rect) { $0.union($1.rect) }

        var deltas: [(ids: [UUID], dx: Double, dy: Double)] = []
        switch alignment {
        case .left:             deltas = units.map { ($0.ids, target.minX - $0.rect.minX, 0) }
        case .centerHorizontal: deltas = units.map { ($0.ids, target.midX - $0.rect.midX, 0) }
        case .right:            deltas = units.map { ($0.ids, target.maxX - $0.rect.maxX, 0) }
        case .top:              deltas = units.map { ($0.ids, 0, target.minY - $0.rect.minY) }
        case .centerVertical:   deltas = units.map { ($0.ids, 0, target.midY - $0.rect.midY) }
        case .bottom:           deltas = units.map { ($0.ids, 0, target.maxY - $0.rect.maxY) }
        case .distributeHorizontally:
            let sorted = units.sorted { $0.rect.minX < $1.rect.minX }
            let total = sorted.reduce(0.0) { $0 + $1.rect.width }
            let gap = max(0, (target.width - total) / Double(sorted.count - 1))
            var cursor = target.minX
            for u in sorted {
                deltas.append((u.ids, cursor - u.rect.minX, 0))
                cursor += u.rect.width + gap
            }
        case .distributeVertically:
            let sorted = units.sorted { $0.rect.minY < $1.rect.minY }
            let total = sorted.reduce(0.0) { $0 + $1.rect.height }
            let gap = max(0, (target.height - total) / Double(sorted.count - 1))
            var cursor = target.minY
            for u in sorted {
                deltas.append((u.ids, 0, cursor - u.rect.minY))
                cursor += u.rect.height + gap
            }
        }

        guard deltas.contains(where: { abs($0.dx) > 0.01 || abs($0.dy) > 0.01 }) else { return }
        saveHistoryState()
        var page = currentPage
        for d in deltas {
            for id in d.ids {
                if let i = page.elements.firstIndex(where: { $0.id == id }) {
                    page.elements[i].x += d.dx
                    page.elements[i].y += d.dy
                }
            }
        }
        currentPage = page
        syncConnectors(touching: Set(movable.map(\.id)))
        if isDistribute {
            showTemporaryToast(alignment == .distributeHorizontally ? "Distributed horizontally" : "Distributed vertically")
        }
    }

    // MARK: - Clipboard & Duplication

    public func duplicateSelected() {
        guard !selectedElementIds.isEmpty else { return }
        saveHistoryState()

        // Group integrity: duplicating EVERY member of a group must mint a fresh
        // groupId for the copies — otherwise the copies share the source group
        // and selecting a duplicate also selects the originals. Partial
        // duplication keeps the old groupId (copies join the existing group).
        var groupRemap: [UUID: UUID] = [:]
        let membersByGroup = Dictionary(grouping: currentPage.elements.filter { $0.groupId != nil }, by: { $0.groupId! })
        for (gid, members) in membersByGroup where members.allSatisfy({ selectedElementIds.contains($0.id) }) {
            groupRemap[gid] = UUID()
        }

        var newSelectedIds: Set<UUID> = []
        var idRemap: [UUID: UUID] = [:]
        // Page z-order, not Set order — iterating the Set stacked a preset's
        // background on top of its content at random.
        let sources = selectedElements.sorted { $0.zIndex < $1.zIndex }
        var nextZ = (currentPage.elements.map { $0.zIndex }.max() ?? 0) + 1
        var page = currentPage
        for elem in sources {
            var copy = elem
            let newID = UUID()
            idRemap[elem.id] = newID
            copy.id = newID
            copy.name = "\(elem.name) Copy"
            copy.x += 20
            copy.y += 20
            copy.zIndex = nextZ
            nextZ += 1
            copy.isLocked = false
            copy.groupId = elem.groupId.map { groupRemap[$0] ?? $0 }
            page.elements.append(copy)
            newSelectedIds.insert(newID)
        }
        currentPage = page
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

    /// System pasteboard generation at our last copy — if another app copied
    /// since, ⌘V pastes that instead of our stale internal clipboard.
    private var clipboardChangeCount: Int = -1
    private var pasteGeneration: Int = 0

    public func copySelected() {
        guard !selectedElementIds.isEmpty else { return }
        clipboardElements = selectedElements.sorted { $0.zIndex < $1.zIndex }
        pasteGeneration = 0
        let pb = NSPasteboard.general
        pb.clearContents()
        if clipboardElements.count == 1, let primary = clipboardElements.first {
            switch primary.payload {
            case .text(let t):
                pb.setString(t.text, forType: .string)
            case .code(let c):
                pb.setString(c.code, forType: .string)
            default:
                break
            }
        }
        clipboardChangeCount = pb.changeCount
        showTemporaryToast(clipboardElements.count == 1 ? "Copied" : "Copied \(clipboardElements.count) elements")
    }

    public func paste() {
        if !clipboardElements.isEmpty && NSPasteboard.general.changeCount == clipboardChangeCount {
            saveHistoryState()
            // Each successive paste steps further so copies don't pile up.
            pasteGeneration += 1
            let offset = 30.0 * Double(pasteGeneration)
            // Fresh groupIds per paste — pasted elements must form their own
            // group, not silently join the group they were copied from.
            var groupRemap: [UUID: UUID] = [:]
            for elem in clipboardElements {
                if let gid = elem.groupId, groupRemap[gid] == nil {
                    groupRemap[gid] = UUID()
                }
            }
            var newSelectedIds: Set<UUID> = []
            var idRemap: [UUID: UUID] = [:]
            for elem in clipboardElements {
                var copy = elem
                let newID = UUID()
                idRemap[elem.id] = newID
                copy.id = newID
                copy.x += offset
                copy.y += offset
                copy.zIndex = (currentPage.elements.map { $0.zIndex }.max() ?? 0) + 1
                copy.groupId = elem.groupId.map { groupRemap[$0] ?? $0 }
                currentPage.elements.append(copy)
                newSelectedIds.insert(copy.id)
            }
            // Anchored connectors must point at the pasted copies, not the
            // originals — otherwise the pasted connector snaps back to the
            // source elements on the next syncConnectors. Same rule as
            // duplicateSelected: missing endpoints → static arrow.
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
        guard selectedElements.contains(where: { !$0.isLocked }) else {
            showTemporaryToast("Locked elements can't be deleted — unlock first (⌘L)")
            return
        }
        saveHistoryState()
        let deletedIds = selectedElementIds
        currentPage.elements.removeAll { selectedElementIds.contains($0.id) && !$0.isLocked }
        // Anchored connectors are removed only when their endpoint was
        // ACTUALLY deleted — locked survivors keep their connectors.
        let survivingIds = Set(currentPage.elements.map { $0.id })
        let removedIds = deletedIds.subtracting(survivingIds)
        currentPage.elements.removeAll { el in
            guard let conn = el.connector else { return false }
            return removedIds.contains(conn.fromID) || removedIds.contains(conn.toID)
        }
        selectedElementIds.removeAll()
        editingTextElementId = nil
        editingCodeElementId = nil
        showTemporaryToast("Deleted")
    }

    public func toggleLockSelected() {
        guard let firstId = selectedElementIds.first,
              let firstIndex = currentPage.elements.firstIndex(where: { $0.id == firstId }) else { return }
        saveHistoryState()
        // Apply one state to the WHOLE selection — the old code only toggled the
        // first element, silently leaving the rest unlocked.
        let newState = !currentPage.elements[firstIndex].isLocked
        var page = currentPage
        for idx in page.elements.indices where selectedElementIds.contains(page.elements[idx].id) {
            page.elements[idx].isLocked = newState
        }
        currentPage = page
        // Locked elements are click-through on the canvas, so say where to undo it.
        showTemporaryToast(newState ? "Locked — unlock from Layers or with ⌘L" : "Unlocked")
    }

    public func flipSelected(horizontal: Bool) {
        guard !selectedElementIds.isEmpty else { return }
        saveHistoryState()
        var page = currentPage
        for idx in page.elements.indices
        where selectedElementIds.contains(page.elements[idx].id) && !page.elements[idx].isLocked {
            if horizontal {
                page.elements[idx].flipH = !(page.elements[idx].isFlippedH)
            } else {
                page.elements[idx].flipV = !(page.elements[idx].isFlippedV)
            }
        }
        currentPage = page
        showTemporaryToast(horizontal ? "Flipped horizontally" : "Flipped vertically")
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
        var page = currentPage
        for idx in page.elements.indices
        where selectedElementIds.contains(page.elements[idx].id) && !page.elements[idx].isLocked {
            page.elements[idx].x += dx
            page.elements[idx].y += dy
        }
        currentPage = page
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
        var page = currentPage
        var changed = false
        for index in page.elements.indices {
            guard let conn = page.elements[index].connector else { continue }
            guard movedIds.contains(conn.fromID) || movedIds.contains(conn.toID) || movedIds.contains(page.elements[index].id) else { continue }
            guard let fromEl = page.elements.first(where: { $0.id == conn.fromID }),
                  let toEl = page.elements.first(where: { $0.id == conn.toID }) else { continue }
            applyConnectorGeometry(&page.elements[index], from: fromEl.frame, to: toEl.frame)
            changed = true
        }
        // One write (publish + autosave) instead of one per connector — and none
        // when no connector touches the moved elements.
        if changed { currentPage = page }
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

    /// Resizes the current page from typed values (inspector W/H). Clamped to a
    /// sane minimum and recorded as one undo step per field edit.
    public func setCurrentPageSize(width: Double? = nil, height: Double? = nil) {
        let w = max(16, min(20000, width ?? currentPage.width))
        let h = max(16, min(20000, height ?? currentPage.height))
        guard w != currentPage.width || h != currentPage.height else { return }
        saveHistoryState()
        currentPage.width = w
        currentPage.height = h
    }

    /// Canonical "load a whole project" path (dashboard open, document import).
    /// Resets page-scoped state AND the view: layout mode + pan/zoom must
    /// follow the new project — importing a 16:9 deck while in
    /// .infiniteWhiteboard otherwise keeps the board's gestures, a hidden
    /// filmstrip, and a stale pan offset. Same convention as applyTemplate.
    public func adoptProject(_ newProject: CanvasProject) {
        if isLiveTransforming { isLiveTransforming = false }
        project = newProject
        activePageIndex = 0
        selectedElementIds.removeAll()
        editingTextElementId = nil
        editingCodeElementId = nil
        syncLayoutMode()
        panOffset = .zero
        zoomScale = pageLayoutMode == .infiniteWhiteboard ? 0.5 : 0.65
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
        editingCodeElementId = nil
        panOffset = .zero
        persistProject()
        showTemporaryToast("Applied \(template.title) — ⌘Z to undo")
    }

    /// Appends a template's pages after the current page instead of replacing
    /// the design (sidebar "Add as new pages").
    public func appendTemplatePages(_ template: CanvasTemplate) {
        let source = template.pages.isEmpty ? [template.page] : template.pages
        guard !source.isEmpty else { return }
        saveHistoryState()
        let fresh = source.map { page -> CanvasPage in
            var p = page
            p.id = UUID()
            return p
        }
        let insertAt = min(activePageIndex + 1, project.pages.count)
        project.pages.insert(contentsOf: fresh, at: insertAt)
        activePageIndex = insertAt
        persistProject()
        showTemporaryToast("Added \(fresh.count) page\(fresh.count == 1 ? "" : "s") from \(template.title)")
    }

    /// True when the open design has anything worth protecting from a replace.
    public var hasDesignContent: Bool {
        project.pages.contains { !$0.elements.isEmpty }
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
        editingCodeElementId = nil
        persistProject()
        showTemporaryToast("Added Page \(project.pages.count)")
    }

    public func duplicatePage(at index: Int) {
        guard index >= 0 && index < project.pages.count else { return }
        saveHistoryState()
        var newPage = project.pages[index]
        newPage.id = UUID()
        newPage.name = "\(newPage.name) Copy"
        // Fresh ids for elements AND groups, then point connectors at the copies —
        // otherwise arrows on the duplicate keep following the original page.
        var idRemap: [UUID: UUID] = [:]
        var groupRemap: [UUID: UUID] = [:]
        for el in newPage.elements {
            idRemap[el.id] = UUID()
            if let gid = el.groupId, groupRemap[gid] == nil { groupRemap[gid] = UUID() }
        }
        newPage.elements = newPage.elements.map { el in
            var copy = el
            copy.id = idRemap[el.id] ?? UUID()
            copy.groupId = el.groupId.flatMap { groupRemap[$0] }
            if let conn = el.connector {
                if let f = idRemap[conn.fromID], let t = idRemap[conn.toID] {
                    copy.connector = ConnectorInfo(fromID: f, toID: t)
                } else {
                    copy.connector = nil
                }
            }
            return copy
        }
        project.pages.insert(newPage, at: index + 1)
        activePageIndex = index + 1
        selectedElementIds.removeAll()
        persistProject()
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
        // Keep the same page active when an earlier page is removed.
        if index < activePageIndex { activePageIndex -= 1 }
        activePageIndex = min(activePageIndex, project.pages.count - 1)
        selectedElementIds.removeAll()
        editingTextElementId = nil
        persistProject()
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
        saveHistoryState()
        let activeId = currentPage.id
        let page = project.pages.remove(at: source)
        project.pages.insert(page, at: destination)
        // Follow the active page wherever it ended up (it can shift even when
        // it wasn't the page being moved).
        if let idx = project.pages.firstIndex(where: { $0.id == activeId }) {
            activePageIndex = idx
        }
        persistProject()
        showTemporaryToast("Page moved")
    }

    /// Renames a page AND persists the change (the old direct-binding path silently
    /// skipped autosave).
    public func renamePage(at index: Int, to newName: String) {
        guard index < project.pages.count else { return }
        project.pages[index].name = newName
        persistProject()
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

    /// Single-element insert used by sidebar presets: centered where the user is
    /// looking, stacked on top of existing content, one undo step, selected.
    public func placeNewElement(_ element: CanvasElement) {
        saveHistoryState()
        var el = element
        let origin = insertionOrigin(elementWidth: el.width, elementHeight: el.height)
        el.x = origin.x
        el.y = origin.y
        el.zIndex = (currentPage.elements.map(\.zIndex).max() ?? -1) + 1
        currentPage.elements.append(el)
        selectedElementIds = [el.id]
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

    /// Zoom presets used by the step buttons and the zoom menu. Stepping walks
    /// this ladder (multiplicative) instead of ±10 points — a fixed +0.1 step was
    /// a 66% jump at 15% zoom but a 2.5% nudge at 400%.
    public static let zoomLadder: [Double] = [0.1, 0.15, 0.25, 0.33, 0.5, 0.67, 0.75, 1.0, 1.25, 1.5, 2.0, 3.0, 4.0, 6.0, 8.0]

    private var zoomBounds: ClosedRange<Double> {
        pageLayoutMode == .infiniteWhiteboard ? 0.05...8.0 : 0.1...4.0
    }

    public func zoomIn() {
        let next = Self.zoomLadder.first(where: { $0 > zoomScale + 0.001 }) ?? zoomBounds.upperBound
        setZoom(next)
    }

    public func zoomOut() {
        let prev = Self.zoomLadder.last(where: { $0 < zoomScale - 0.001 }) ?? zoomBounds.lowerBound
        setZoom(prev)
    }

    /// Sets an explicit zoom level (clamped to the layout mode's range).
    public func setZoom(_ scale: Double) {
        zoomScale = min(zoomBounds.upperBound, max(zoomBounds.lowerBound, scale))
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
                // Center the bbox at the viewport middle: the page plane is
                // scaled about its own center, so pan = z·(pageCenter − c).
                // The old "-c·z" ignored the scale origin and landed half a
                // page-width off.
                panOffset = CGPoint(
                    x: (currentPage.width / 2.0 - centerElemX) * zoomScale,
                    y: (currentPage.height / 2.0 - centerElemY) * zoomScale
                )
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
        // pan = z·(pageCenter − selectionCenter) — same center-anchored
        // convention as zoomToFit; "-mid·z" is off by z·pageCenter.
        panOffset = CGPoint(
            x: (currentPage.width / 2.0 - bounds.midX) * zoomScale,
            y: (currentPage.height / 2.0 - bounds.midY) * zoomScale
        )
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
        // Callers historically prefixed messages with an emoji; the toast now
        // carries its own status icon, so strip the decoration and use it only
        // to pick the style.
        let trimmed = message.trimmingCharacters(in: .whitespaces)
        toastIsError = trimmed.hasPrefix("❌") || trimmed.hasPrefix("⚠️")
        toastMessage = Self.stripLeadingEmoji(trimmed)
        showToast = true
        toastTask?.cancel()
        toastTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if !Task.isCancelled {
                self.showToast = false
            }
        }
    }

    private static func stripLeadingEmoji(_ text: String) -> String {
        var scalars = Substring(text)
        while let first = scalars.unicodeScalars.first,
              first.properties.isEmojiPresentation || first.properties.isEmoji && first.value > 0x238C
                || first.value == 0xFE0F || first.value == 0x200D || first == " " {
            scalars = scalars.dropFirst()
        }
        return String(scalars)
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
    // Rail order = declaration order: content-creation tabs first (Canva's
    // Design → Elements → Text → Uploads flow), document structure next,
    // developer tooling last. Pen settings live in the toolbar Pen popover.
    case templates = "Templates"
    case elements = "Shapes"
    case text = "Text"
    case media = "Media"
    case icons = "Icons"
    case brandKit = "Brand"
    case backgrounds = "Background"
    case pages = "Pages"
    case layers = "Layers"
    case code = "Code"

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
        case .layers: return "square.3.layers.3d"
        }
    }
}
