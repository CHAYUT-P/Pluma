import SwiftUI
import AppKit

public struct CanvasViewportView: View {
    @ObservedObject var viewModel: CanvasDocumentViewModel

    @State private var dragStartPositions: [UUID: CGPoint] = [:]
    @State private var isDraggingElements: Bool = false

    // Pan Gesture
    @State private var isPanningCanvas: Bool = false
    @State private var panStartOffset: CGPoint = .zero
    @State private var isSpacebarPressed: Bool = false

    // Pinch-to-zoom Gesture
    @State private var initialZoomScale: Double = 0.65

    // Marquee selection
    @State private var marqueeStart: CGPoint? = nil
    @State private var marqueeCurrent: CGPoint? = nil

    // Canva-style page overview grid (thumbnails)
    @State private var showPageGridOverlay: Bool = false
    // Tracks bottom-rail visibility so fit/zoom re-runs when it appears/disappears
    @State private var filmstripWasVisible: Bool = false
    // Ensures the first real fit happens against a settled (non-transition) viewport
    @State private var didInitialFit: Bool = false

    /// Refits only while the user hasn't manually zoomed since the last programmatic fit.
    private func refitIfUntouched(_ size: CGSize) {
        if viewModel.lastFitZoom == nil || viewModel.zoomScale == viewModel.lastFitZoom! {
            viewModel.zoomToFit(viewportSize: size)
        }
    }

    public init(viewModel: CanvasDocumentViewModel) {
        self.viewModel = viewModel
    }

    private var isHandOrPanMode: Bool {
        viewModel.activeTool == .hand || isSpacebarPressed
    }

    private var pageGap: CGFloat { 56.0 }

    private var totalContinuousStackHeight: CGFloat {
        let pagesCount = max(1, CGFloat(viewModel.project.pages.count))
        let totalPageHeights = pagesCount * CGFloat(viewModel.currentPage.height)
        let totalGaps = (pagesCount - 1) * pageGap
        return totalPageHeights + totalGaps + 140.0
    }

    public var body: some View {
        GeometryReader { geometry in
            // Canva-style bottom rail reserve: presentation & document pages float in the
            // space ABOVE the filmstrip so page and page-switcher never overlap.
            // Always on outside whiteboard mode: it is also where zoom lives (Canva-style).
            let filmstripVisible = viewModel.pageLayoutMode != .infiniteWhiteboard
            let bottomReserved: CGFloat = filmstripVisible ? 108 : 0
            ZStack {
                // 1. Dynamic Workspace Backdrop (visual only)
                Group {
                    if viewModel.pageLayoutMode == .infiniteWhiteboard {
                        // Figma-style infinite dot matrix
                        InfiniteDotGridBackdrop(zoomScale: viewModel.zoomScale, panOffset: viewModel.panOffset)
                    } else {
                        // Studio drafting backdrop
                        StudioDraftingWorkspaceBackdrop(showGrid: viewModel.showGridOverlay)
                            .onTapGesture {
                                viewModel.editingTextElementId = nil
                                viewModel.editingCodeElementId = nil
                                viewModel.deselectAll()
                            }
                    }
                }
                .ignoresSafeArea()

                // 2. Native AppKit Trackpad & Scroll Gesture Interceptor (Smooth 2-finger pan, mouse wheel scroll, & pinch-to-zoom)
                CanvasTrackpadGestureHostViewRepresentable(
                    viewModel: viewModel,
                    isSpacebarPressed: $isSpacebarPressed
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // 2b. Infinite-board interaction layer — geometry-aligned (no safe-area
                // skew). Sits ABOVE the NSView gesture host (so it reliably receives
                // events) and BELOW the artboards (so elements & the page surface keep
                // priority). Catches marquee/draw/deselect anywhere on the boundless board.
                if viewModel.pageLayoutMode == .infiniteWhiteboard {
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(infiniteSurfaceGesture(viewportSize: geometry.size))
                        // Double-click empty board space → sticky note right there (Miro-style)
                        .gesture(
                            SpatialTapGesture(count: 2)
                                .onEnded { value in
                                    guard viewModel.activeTool == .select,
                                          viewModel.editingTextElementId == nil,
                                          viewModel.editingCodeElementId == nil else { return }
                                    let canvasPoint = viewModel.screenToCanvasPoint(
                                        value.location,
                                        viewportSize: geometry.size
                                    )
                                    viewModel.addStickyNote(
                                        at: CGPoint(x: canvasPoint.x - 110, y: canvasPoint.y - 100)
                                    )
                                }
                        )
                }

                // 3. Artboards Canvas Workspace Container (Infinite Whiteboard, Top-Anchored Continuous Document, or Centered Single Slide)
                Group {
                    if viewModel.pageLayoutMode == .infiniteWhiteboard {
                        infiniteWhiteboardCanvasView
                            .frame(width: viewModel.currentPage.width, height: viewModel.currentPage.height)
                            .scaleEffect(viewModel.zoomScale)
                            .position(
                                x: geometry.size.width / 2.0 + viewModel.panOffset.x,
                                y: geometry.size.height / 2.0 + viewModel.panOffset.y
                            )
                    } else if viewModel.pageLayoutMode == .continuousVertical {
                        continuousDocumentStackView
                            .frame(width: viewModel.currentPage.width, height: totalContinuousStackHeight, alignment: .top)
                            .scaleEffect(viewModel.zoomScale)
                            .position(
                                x: geometry.size.width / 2.0 + viewModel.panOffset.x,
                                y: (totalContinuousStackHeight * viewModel.zoomScale) / 2.0 + 40.0 + viewModel.panOffset.y
                            )
                    } else {
                        singleSlideArtboardView
                            .frame(width: viewModel.currentPage.width, height: viewModel.currentPage.height + 40)
                            .scaleEffect(viewModel.zoomScale)
                            .position(
                                x: geometry.size.width / 2.0 + viewModel.panOffset.x,
                                y: (geometry.size.height - bottomReserved) / 2.0 + viewModel.panOffset.y
                            )
                    }
                }
                .gesture(
                    // Pan Gesture when in Hand mode or holding Spacebar (clamped for presentation)
                    DragGesture(minimumDistance: 1)
                        .onChanged { value in
                            if (isHandOrPanMode || NSEvent.modifierFlags.contains(.control) || NSEvent.modifierFlags.contains(.option)) && viewModel.canPan(viewportSize: geometry.size) {
                                if !isPanningCanvas {
                                    isPanningCanvas = true
                                    panStartOffset = viewModel.panOffset
                                    NSCursor.closedHand.set()
                                }
                                // Pre-clamped set: locked axes never move (no snap-back)
                                viewModel.setPan(
                                    to: CGPoint(
                                        x: panStartOffset.x + value.translation.width,
                                        y: panStartOffset.y + value.translation.height
                                    ),
                                    viewportSize: geometry.size
                                )
                            }
                        }
                        .onEnded { _ in
                            isPanningCanvas = false
                            if isHandOrPanMode {
                                NSCursor.openHand.set()
                            }
                            viewModel.clampPanOffset(for: geometry.size)
                        }
                )

                // 3b. Screen-space overlays for the infinite board: marquee rectangle
                // and live pen-stroke preview render above everything and are NOT
                // clipped to the logical page rect.
                if viewModel.pageLayoutMode == .infiniteWhiteboard {
                    infiniteScreenOverlays(viewportSize: geometry.size)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                // 4. Page Navigation Dock — whiteboard only (documents use the bottom rail)
                if viewModel.pageLayoutMode == .infiniteWhiteboard && viewModel.project.pages.count > 1 {
                    VStack {
                        Spacer()
                        HStack {
                            floatingPageNavigationDock
                                .padding(.leading, 18)
                                .padding(.bottom, 16)
                            Spacer()
                        }
                    }
                }

                // 4a. Whiteboard Quick-Add Palette (left edge, board mode only)
                if viewModel.pageLayoutMode == .infiniteWhiteboard {
                    VStack {
                        Spacer()
                        HStack {
                            whiteboardQuickPalette
                                .padding(.leading, 18)
                                .padding(.bottom, 16)
                            Spacer()
                        }
                    }
                    .transition(.move(edge: .leading).combined(with: .opacity))
                }

                // 4b. Page Overview Grid (Canva-style thumbnails)
                if showPageGridOverlay {
                    Color.black.opacity(0.18)
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                        .onTapGesture { withAnimation(.easeInOut(duration: 0.18)) { showPageGridOverlay = false } }
                        .overlay(
                            PageGridOverlayView(viewModel: viewModel) {
                                withAnimation(.easeInOut(duration: 0.18)) { showPageGridOverlay = false }
                            }
                        )
                        .transition(.opacity)
                        .zIndex(50)
                }

                // 4c. Unified Bottom Rail — filmstrip + zoom in one bar (documents & presentations)
                if filmstripVisible {
                    VStack {
                        Spacer()
                        bottomBarView
                            .padding(.horizontal, 24)
                            .padding(.bottom, 14)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // 5. Floating Zoom Dock — whiteboard only (documents use the bottom rail)
                if viewModel.pageLayoutMode == .infiniteWhiteboard {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            floatingZoomSliderDock(viewportSize: geometry.size)
                                .padding(.trailing, 16)
                                .padding(.bottom, 16)
                        }
                    }
                }

                // 5b. Rulers & Draggable Guides (toggle: ⌘R / ⌘K palette)
                if viewModel.showRulers {
                    rulersOverlay(viewportSize: geometry.size)
                        .allowsHitTesting(true)
                }

                // 6. Toast Notification
                if viewModel.showToast {
                    VStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Image(systemName: viewModel.toastIsError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                                .foregroundColor(viewModel.toastIsError ? PlumaTheme.danger : PlumaTheme.success)
                            Text(viewModel.toastMessage)
                                .font(PlumaTheme.label(12.5, weight: .medium))
                                .lineLimit(2)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                        .padding(.bottom, filmstripVisible ? bottomReserved + 12 : 65)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .allowsHitTesting(false)
                    .animation(.spring(response: 0.3), value: viewModel.showToast)
                }
            }
            .clipped()
            // `.clipped()` only clips drawing, not hit testing: zoomed-in artboards
            // overflowing the viewport stayed clickable outside it and swallowed
            // every click on the sidebar, toolbar and inspector. The content shape
            // limits hit testing to the viewport's own rect.
            .contentShape(Rectangle())
            .onAppear {
                initialZoomScale = viewModel.zoomScale
                viewModel.bottomInset = bottomReserved
                filmstripWasVisible = filmstripVisible
                viewModel.updateViewportSize(geometry.size)
                if geometry.size.width > 100 {
                    didInitialFit = true
                    viewModel.zoomToFit(viewportSize: geometry.size)
                }
            }
            .onChange(of: geometry.size) { oldSize, newSize in
                viewModel.bottomInset = bottomReserved
                viewModel.updateViewportSize(newSize)
                if !didInitialFit && newSize.width > 100 {
                    // First settled layout (dashboard→editor transition can report tiny frames)
                    didInitialFit = true
                    viewModel.zoomToFit(viewportSize: newSize)
                } else if viewModel.zoomScale == 0.65 {
                    viewModel.zoomToFit(viewportSize: newSize)
                } else if let fitZoom = viewModel.lastFitZoom, viewModel.zoomScale == fitZoom {
                    // User hasn't zoomed since the last fit → keep the page fitted on resize
                    viewModel.zoomToFit(viewportSize: newSize)
                }
            }
            .onChange(of: viewModel.project.pages.count) { _, newCount in
                // Bottom rail appeared/disappeared → refit so the page clears it
                let visible = viewModel.pageLayoutMode != .infiniteWhiteboard
                if visible != filmstripWasVisible {
                    filmstripWasVisible = visible
                    viewModel.bottomInset = visible ? 108 : 0
                    viewModel.zoomToFit(viewportSize: geometry.size)
                }
            }
            .onChange(of: viewModel.pageLayoutMode) { _, newMode in
                // Template/preset swaps can flip the layout (A4 ↔ presentation ↔ board):
                // re-reserve the rail and refit for the new geometry.
                let visible = newMode != .infiniteWhiteboard
                filmstripWasVisible = visible
                viewModel.bottomInset = visible ? 108 : 0
                viewModel.zoomToFit(viewportSize: geometry.size)
            }
            .onChange(of: viewModel.currentPage.width) { _, _ in refitIfUntouched(geometry.size) }
            .onChange(of: viewModel.currentPage.height) { _, _ in refitIfUntouched(geometry.size) }
            .onChange(of: viewModel.zoomScale) { _, _ in
                viewModel.clampPanOffset(for: geometry.size)
            }
            .onChange(of: viewModel.activePageIndex) { _, _ in
                // Reset pan slightly when switching pages so filmstrip stays synced
                viewModel.clampPanOffset(for: geometry.size)
            }
        }
    }

    // MARK: - True Infinite Surface Gesture (works anywhere on the board)

    private func infiniteSurfaceGesture(viewportSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                guard !isHandOrPanMode,
                      viewModel.activeTool == .select || viewModel.activeTool == .draw else { return }
                if viewModel.editingTextElementId != nil || viewModel.editingCodeElementId != nil { return }

                let startCanvas = viewModel.screenToCanvasPoint(value.startLocation, viewportSize: viewportSize)
                let currentCanvas = viewModel.screenToCanvasPoint(value.location, viewportSize: viewportSize)

                if viewModel.activeTool == .draw {
                    if viewModel.currentDrawingPoints.isEmpty {
                        viewModel.currentDrawingPoints.append(DrawingPoint(startCanvas))
                    }
                    viewModel.currentDrawingPoints.append(DrawingPoint(currentCanvas))
                } else {
                    // Marquee select across the boundless board
                    if marqueeStart == nil {
                        marqueeStart = startCanvas
                        marqueeCurrent = startCanvas
                        if !NSEvent.modifierFlags.contains(.shift) {
                            viewModel.selectedElementIds.removeAll()
                        }
                    }
                    marqueeCurrent = currentCanvas

                    let rect = CGRect(
                        x: min(startCanvas.x, currentCanvas.x),
                        y: min(startCanvas.y, currentCanvas.y),
                        width: abs(currentCanvas.x - startCanvas.x),
                        height: abs(currentCanvas.y - startCanvas.y)
                    )
                    let intersecting = viewModel.currentPage.elements.filter {
                        $0.isVisible && !$0.isLocked && $0.rotatedCanvasBounds.intersects(rect)
                    }
                    let hitIds = Set(intersecting.map { $0.id })
                    if NSEvent.modifierFlags.contains(.shift) {
                        viewModel.selectedElementIds.formUnion(viewModel.expandSelectionForGroups(hitIds))
                    } else {
                        viewModel.selectedElementIds = viewModel.expandSelectionForGroups(hitIds)
                    }
                }
            }
            .onEnded { value in
                guard !isHandOrPanMode else { return }
                if viewModel.activeTool == .draw {
                    viewModel.finishDrawing()
                } else if marqueeStart != nil && hypot(value.translation.width, value.translation.height) < 3 {
                    // A click on empty space → drop selection & inline editors
                    if !NSEvent.modifierFlags.contains(.shift) {
                        viewModel.editingTextElementId = nil
                        viewModel.editingCodeElementId = nil
                        viewModel.deselectAll()
                    }
                }
                marqueeStart = nil
                marqueeCurrent = nil
            }
    }

    // MARK: - Screen-Space Overlays for the Infinite Board (marquee + live stroke preview)

    @ViewBuilder
    private func infiniteScreenOverlays(viewportSize: CGSize) -> some View {
        ZStack {
            if let start = marqueeStart, let current = marqueeCurrent {
                let a = viewModel.canvasToScreenPoint(start, viewportSize: viewportSize)
                let b = viewModel.canvasToScreenPoint(current, viewportSize: viewportSize)
                let rect = CGRect(
                    x: min(a.x, b.x),
                    y: min(a.y, b.y),
                    width: abs(b.x - a.x),
                    height: abs(b.y - a.y)
                )
                Rectangle()
                    .stroke(Color(hex: "#7C3AED"), style: SwiftUI.StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                    .background(Color(hex: "#7C3AED").opacity(0.08))
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
            }

            if viewModel.activeTool == .draw && viewModel.currentDrawingPoints.count > 1 {
                DrawStrokeShape(points: viewModel.currentDrawingPoints.map {
                    viewModel.canvasToScreenPoint($0.cgPoint, viewportSize: viewportSize)
                })
                .stroke(
                    viewModel.drawingColor.color,
                    style: SwiftUI.StrokeStyle(
                        lineWidth: CGFloat(viewModel.drawingLineWidth) * CGFloat(viewModel.zoomScale),
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Infinite Whiteboard Canvas View (Truly Boundless, Figma & Miro Style)

    @ViewBuilder
    private var infiniteWhiteboardCanvasView: some View {
        let page = viewModel.currentPage
        let pageIndex = viewModel.activePageIndex

        ZStack {
            // Elements Layer — viewport culling keeps huge boards silky smooth:
            // elements outside the visible region (plus margin) are skipped entirely.
            let cullRect = viewModel.visibleCanvasRect(viewportSize: viewModel.lastViewportSize)
                .insetBy(dx: -600, dy: -600)
            ForEach(viewModel.zOrderedElements(of: page)) { element in
                if element.isVisible && element.rotatedCanvasBounds.intersects(cullRect) {
                    EquatableElementRenderer(
                        viewModel: viewModel,
                        element: element,
                        isEditingText: (viewModel.editingTextElementId == element.id),
                        isEditingCode: (viewModel.editingCodeElementId == element.id),
                        isLiveTransforming: viewModel.isLiveTransforming
                    )
                    .equatable()
                    .position(x: element.x + element.width / 2.0, y: element.y + element.height / 2.0)
                    .contextMenu {
                        elementContextMenu(for: element)
                    }
                    // Instant select + delayed double-tap edit: use simultaneousGesture for single so transformer appears with zero delay
                    .gesture(
                        TapGesture(count: 2).onEnded {
                            if case .text = element.payload {
                                viewModel.editingTextElementId = element.id
                                viewModel.editingCodeElementId = nil
                            } else if case .code = element.payload {
                                viewModel.editingCodeElementId = element.id
                                viewModel.editingTextElementId = nil
                            }
                        }
                    )
                    .simultaneousGesture(
                        TapGesture(count: 1).onEnded {
                            if viewModel.editingTextElementId != element.id {
                                viewModel.editingTextElementId = nil
                            }
                            if viewModel.editingCodeElementId != element.id {
                                viewModel.editingCodeElementId = nil
                            }
                            if viewModel.activeTool == .select {
                                let isShiftPressed = NSEvent.modifierFlags.contains(.shift)
                                viewModel.selectElement(element, multiSelect: isShiftPressed)
                            }
                        }
                    )
                    .gesture(
                        DragGesture(minimumDistance: 3, coordinateSpace: .global)
                            .onChanged { value in
                                guard viewModel.activeTool == .select && !isHandOrPanMode else { return }
                                if viewModel.editingTextElementId != nil || viewModel.editingCodeElementId != nil { return }

                                if !viewModel.selectedElementIds.contains(element.id) {
                                    viewModel.selectElement(element)
                                }
                                if !isDraggingElements {
                                    isDraggingElements = true
                                    dragStartPositions = [:]
                                    for id in viewModel.selectedElementIds {
                                        if let el = viewModel.currentPage.elements.first(where: { $0.id == id }) {
                                            dragStartPositions[id] = CGPoint(x: el.x, y: el.y)
                                        }
                                    }
                                    viewModel.saveHistoryState()
                                }
                                let scaledDelta = CGSize(
                                    width: value.translation.width / CGFloat(viewModel.zoomScale),
                                    height: value.translation.height / CGFloat(viewModel.zoomScale)
                                )
                                viewModel.dragSelectedElements(
                                    by: scaledDelta,
                                    startPositions: dragStartPositions,
                                    applySnapping: !NSEvent.modifierFlags.contains(.command)
                                )
                            }
                            .onEnded { _ in
                                isDraggingElements = false
                                dragStartPositions = [:]
                                viewModel.endDrag()
                            }
                    )
                    // Locked = click-through (Figma model): a locked full-page background
                    // must not swallow clicks, marquees and drags. Unlock via Layers or ⌘L.
                    .allowsHitTesting(!element.isLocked)
                }
            }

            // Selection Overlays (canvas space) — SelectionOverlayView self-positions
            // & self-rotates; NO extra .rotationEffect/.position here or the transformer
            // detaches from the object.
            if viewModel.activeTool == .select && !isHandOrPanMode && viewModel.editingTextElementId == nil && viewModel.editingCodeElementId == nil {
                if viewModel.selectedElements.count > 1 {
                    // Multi-select / group: light member outlines + ONE collective
                    // transform box so composite objects (browser windows, device
                    // frames) scale & rotate as a single unit.
                    ForEach(viewModel.selectedElements) { member in
                        Rectangle()
                            .stroke(Color(hex: "#C2410C").opacity(0.55), lineWidth: 1 / max(0.5, viewModel.zoomScale))
                            .frame(width: member.width, height: member.height)
                            .rotationEffect(.degrees(member.rotation))
                            .position(x: member.x + member.width / 2, y: member.y + member.height / 2)
                            .allowsHitTesting(false)
                    }
                    GroupSelectionOverlayView(
                        viewModel: viewModel,
                        coordinateSpaceName: "canvasSpace_\(pageIndex)"
                    )
                } else {
                    ForEach(viewModel.selectedElements) { selectedElement in
                        SelectionOverlayView(
                            viewModel: viewModel,
                            element: selectedElement,
                            coordinateSpaceName: "canvasSpace_\(pageIndex)"
                        )
                    }
                }
            }

            // Marquee selection & live stroke preview are rendered in SCREEN space at
            // the viewport root (see infiniteScreenOverlays) so they work anywhere on
            // the boundless board — no page-rect clipping.
        }
        .frame(width: page.width, height: page.height)
        .coordinateSpace(name: "canvasSpace_\(pageIndex)")
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 4, coordinateSpace: .named("canvasSpace_\(pageIndex)"))
                .onChanged { value in
                    guard !isHandOrPanMode else { return }

                    if viewModel.activeTool == .draw {
                        viewModel.currentDrawingPoints.append(DrawingPoint(value.location))
                    } else if viewModel.activeTool == .select && (marqueeStart != nil || viewModel.selectedElementIds.isEmpty || NSEvent.modifierFlags.contains(.shift)) {
                        if marqueeStart == nil {
                            marqueeStart = value.startLocation
                            let isShiftPressed = NSEvent.modifierFlags.contains(.shift)
                            if !isShiftPressed {
                                viewModel.selectedElementIds.removeAll()
                            }
                        }
                        marqueeCurrent = value.location

                        let rect = CGRect(
                            x: min(value.startLocation.x, value.location.x),
                            y: min(value.startLocation.y, value.location.y),
                            width: abs(value.location.x - value.startLocation.x),
                            height: abs(value.location.y - value.startLocation.y)
                        )
                        let intersecting = viewModel.currentPage.elements.filter { $0.isVisible && !$0.isLocked && $0.rotatedCanvasBounds.intersects(rect) }
                        let hitIds = Set(intersecting.map { $0.id })
                        let isShiftPressed = NSEvent.modifierFlags.contains(.shift)
                        if isShiftPressed {
                            viewModel.selectedElementIds.formUnion(viewModel.expandSelectionForGroups(hitIds))
                        } else {
                            viewModel.selectedElementIds = viewModel.expandSelectionForGroups(hitIds)
                        }
                    }
                }
                .onEnded { _ in
                    if viewModel.activeTool == .draw {
                        viewModel.finishDrawing()
                    }
                    marqueeStart = nil
                    marqueeCurrent = nil
                }
        )
    }

    // MARK: - Continuous Vertical Document Stack View (A4, Resumes, Multi-Page Flow)

    private var continuousDocumentStackView: some View {
        VStack(spacing: pageGap) {
            ForEach(Array(viewModel.project.pages.enumerated()), id: \.element.id) { index, page in
                VStack(spacing: 10) {
                    // Page Header Bar with Quick Action Pills
                    zoomInvariantPageHeader(index: index, page: page)

                    // Page Sheet Surface & Elements
                    pageArtboardSurfaceView(pageIndex: index, page: page)
                }
            }

            // Bottom Add Page Action Card
            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    viewModel.addPage()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14))
                    Text("Add Next Page")
                        .font(.system(size: 13, weight: .bold, design: .serif))
                }
                .foregroundColor(Color(hex: "#C2410C"))
                .frame(width: viewModel.currentPage.width, height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color(hex: "#C2410C").opacity(0.4), style: SwiftUI.StrokeStyle(lineWidth: 2, dash: [8, 6]))
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#C2410C").opacity(0.04)))
                )
            }
            .buttonStyle(.plain)
            .padding(.top, 12)
            .padding(.bottom, 60)
        }
    }

    // MARK: - Single Slide Artboard View

    private var singleSlideArtboardView: some View {
        let page = viewModel.currentPage
        let index = viewModel.activePageIndex

        return VStack(spacing: 10) {
            zoomInvariantPageHeader(index: index, page: page)

            pageArtboardSurfaceView(pageIndex: index, page: page)
        }
    }

    // MARK: - Page Header Action Bar

    /// The header lives inside the zoomed artboard stack, so at fit zoom (~50%)
    /// its labels used to render at ~5pt. Lay it out at screen size and undo the
    /// stack's zoom, keeping text and hit targets at a constant on-screen size.
    /// The layout slot stays the original page-unit height; when zoomed out the
    /// header simply grows upward into the margin above the page.
    private func zoomInvariantPageHeader(index: Int, page: CanvasPage) -> some View {
        let z = max(0.05, viewModel.zoomScale)
        return pageHeaderActionBar(index: index, page: page)
            .frame(width: page.width * z, height: 26)
            .scaleEffect(1 / z, anchor: .bottomLeading)
            .frame(width: page.width, height: 22, alignment: .bottomLeading)
    }

    private func pageHeaderActionBar(index: Int, page: CanvasPage) -> some View {
        let isCurrent = viewModel.activePageIndex == index

        return HStack {
            HStack(spacing: 8) {
                Text("Page \(index + 1)")
                    .font(PlumaTheme.label(11, weight: .semibold))
                    .foregroundColor(isCurrent ? PlumaTheme.accentOnSoft : .secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(isCurrent ? PlumaTheme.accentSoft : PlumaTheme.control)
                    .clipShape(Capsule())

                // Default names ("Page 3") would just repeat the badge.
                if !page.name.isEmpty && page.name != "Page \(index + 1)" {
                    Text(page.name)
                        .font(PlumaTheme.label(12, weight: isCurrent ? .semibold : .regular))
                        .foregroundColor(isCurrent ? .primary : .secondary)
                }

                Text("\(Int(page.width)) × \(Int(page.height))")
                    .font(PlumaTheme.numeric(10.5, weight: .regular))
                    .foregroundColor(.secondary)
            }
            .lineLimit(1)
            .contentShape(Rectangle())
            .onTapGesture { viewModel.activePageIndex = index }

            Spacer()

            HStack(spacing: 4) {
                if index > 0 {
                    Button(action: { viewModel.movePageUp(at: index) }) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                            .frame(width: 22, height: 22)
                    }
                    .buttonStyle(CircleHoverButtonStyle(side: 22))
                    .help("Move Page Up")
                }

                if index < viewModel.project.pages.count - 1 {
                    Button(action: { viewModel.movePageDown(at: index) }) {
                        Image(systemName: "arrow.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                            .frame(width: 22, height: 22)
                    }
                    .buttonStyle(CircleHoverButtonStyle(side: 22))
                    .help("Move Page Down")
                }

                Button(action: { viewModel.duplicatePage(at: index) }) {
                    Image(systemName: "plus.square.on.square")
                        .font(.system(size: 10.5))
                        .foregroundColor(.secondary)
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(CircleHoverButtonStyle(side: 22))
                .help("Duplicate Page")

                if viewModel.project.pages.count > 1 {
                    Button(action: { viewModel.deletePage(at: index) }) {
                        Image(systemName: "trash")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .frame(width: 22, height: 22)
                    }
                    .buttonStyle(CircleHoverButtonStyle(side: 22))
                    .help("Delete Page")
                }
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Page Artboard Surface & Elements Render Tree

    private func pageArtboardSurfaceView(pageIndex: Int, page: CanvasPage) -> some View {
        let isCurrentPage = (viewModel.activePageIndex == pageIndex)

        return ZStack {
            // Paper Sheet Background
            pageBackgroundSheet(page: page)
                .frame(width: page.width, height: page.height)
                .shadow(color: Color.black.opacity(isCurrentPage ? 0.16 : 0.08), radius: isCurrentPage ? 28 : 12, x: 0, y: isCurrentPage ? 12 : 4)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                .overlay(
                    Rectangle()
                        .stroke(isCurrentPage ? Color(hex: "#C2410C").opacity(0.5) : Color.secondary.opacity(0.18), lineWidth: isCurrentPage ? 1.5 : 1)
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.activePageIndex = pageIndex
                    viewModel.editingTextElementId = nil
                    viewModel.editingCodeElementId = nil
                    viewModel.deselectAll()
                }

            // Elements Layer
            ZStack {
                ForEach(viewModel.zOrderedElements(of: page)) { element in
                    if element.isVisible {
                        EquatableElementRenderer(
                            viewModel: viewModel,
                            element: element,
                            isEditingText: isCurrentPage && (viewModel.editingTextElementId == element.id),
                            isEditingCode: isCurrentPage && (viewModel.editingCodeElementId == element.id),
                            isLiveTransforming: viewModel.isLiveTransforming
                        )
                        .equatable()
                        .position(x: element.x + element.width / 2.0, y: element.y + element.height / 2.0)
                        .contextMenu {
                            elementContextMenu(for: element)
                        }
                        // Instant select + delayed double-tap edit (no 300ms transformer delay)
                        .gesture(
                            TapGesture(count: 2).onEnded {
                                viewModel.activePageIndex = pageIndex
                                if case .text = element.payload {
                                    viewModel.editingTextElementId = element.id
                                    viewModel.editingCodeElementId = nil
                                } else if case .code = element.payload {
                                    viewModel.editingCodeElementId = element.id
                                    viewModel.editingTextElementId = nil
                                }
                            }
                        )
                        .simultaneousGesture(
                            TapGesture(count: 1).onEnded {
                                viewModel.activePageIndex = pageIndex
                                if viewModel.editingTextElementId != element.id {
                                    viewModel.editingTextElementId = nil
                                }
                                if viewModel.editingCodeElementId != element.id {
                                    viewModel.editingCodeElementId = nil
                                }
                                if viewModel.activeTool == .select {
                                    let isShiftPressed = NSEvent.modifierFlags.contains(.shift)
                                    viewModel.selectElement(element, multiSelect: isShiftPressed)
                                }
                            }
                        )
                        .gesture(
                            DragGesture(minimumDistance: 3, coordinateSpace: .global)
                                .onChanged { value in
                                    guard viewModel.activeTool == .select && !isHandOrPanMode else { return }
                                    if viewModel.editingTextElementId != nil || viewModel.editingCodeElementId != nil { return }

                                    viewModel.activePageIndex = pageIndex
                                    if !viewModel.selectedElementIds.contains(element.id) {
                                        viewModel.selectElement(element)
                                    }
                                    if !isDraggingElements {
                                        isDraggingElements = true
                                        dragStartPositions = [:]
                                        for id in viewModel.selectedElementIds {
                                            if let el = viewModel.currentPage.elements.first(where: { $0.id == id }) {
                                                dragStartPositions[id] = CGPoint(x: el.x, y: el.y)
                                            }
                                        }
                                        viewModel.saveHistoryState()
                                    }
                                    let scaledDelta = CGSize(
                                        width: value.translation.width / CGFloat(viewModel.zoomScale),
                                        height: value.translation.height / CGFloat(viewModel.zoomScale)
                                    )
                                    viewModel.dragSelectedElements(
                                        by: scaledDelta,
                                        startPositions: dragStartPositions,
                                        applySnapping: !NSEvent.modifierFlags.contains(.command)
                                    )
                                }
                                .onEnded { _ in
                                    isDraggingElements = false
                                    dragStartPositions = [:]
                                    viewModel.endDrag()
                                }
                        )
                        // Locked = click-through (Figma model): a locked full-page background
                        // must not swallow clicks, marquees and drags. Unlock via Layers or ⌘L.
                        .allowsHitTesting(!element.isLocked)
                    }
                }
            }
            .frame(width: page.width, height: page.height)
            .clipped()

            // Drawing Stroke Overlay
            if isCurrentPage && viewModel.activeTool == .draw && !viewModel.currentDrawingPoints.isEmpty {
                Canvas { context, _ in
                    var path = Path()
                    path.move(to: viewModel.currentDrawingPoints[0].cgPoint)
                    for pt in viewModel.currentDrawingPoints.dropFirst() {
                        path.addLine(to: pt.cgPoint)
                    }
                    context.stroke(
                        path,
                        with: .color(viewModel.drawingColor.color),
                        style: SwiftUI.StrokeStyle(lineWidth: CGFloat(viewModel.drawingLineWidth), lineCap: .round, lineJoin: .round)
                    )
                }
                .frame(width: page.width, height: page.height)
                .allowsHitTesting(false)
            }

            // Smart Alignment Guides
            if isCurrentPage {
                SmartGuidesOverlayView(guides: viewModel.activeGuides, pageSize: CGSize(width: page.width, height: page.height))
            }

            // Selection Overlays — see note above: NO extra transform here.
            if isCurrentPage && viewModel.activeTool == .select && !isHandOrPanMode && viewModel.editingTextElementId == nil && viewModel.editingCodeElementId == nil {
                if viewModel.selectedElements.count > 1 {
                    ForEach(viewModel.selectedElements) { member in
                        Rectangle()
                            .stroke(Color(hex: "#C2410C").opacity(0.55), lineWidth: 1 / max(0.5, viewModel.zoomScale))
                            .frame(width: member.width, height: member.height)
                            .rotationEffect(.degrees(member.rotation))
                            .position(x: member.x + member.width / 2, y: member.y + member.height / 2)
                            .allowsHitTesting(false)
                    }
                    GroupSelectionOverlayView(
                        viewModel: viewModel,
                        coordinateSpaceName: "canvasSpace_\(pageIndex)"
                    )
                } else {
                    ForEach(viewModel.selectedElements) { selectedElement in
                        SelectionOverlayView(
                            viewModel: viewModel,
                            element: selectedElement,
                            coordinateSpaceName: "canvasSpace_\(pageIndex)"
                        )
                    }
                }
            }

            // Ruler Guides (draggable alignment lines, current page only)
            pageGuidesOverlay(pageIndex: pageIndex, page: page)

            // Marquee Selection Box
            if isCurrentPage, let start = marqueeStart, let current = marqueeCurrent {
                let rect = CGRect(
                    x: min(start.x, current.x),
                    y: min(start.y, current.y),
                    width: abs(current.x - start.x),
                    height: abs(current.y - start.y)
                )
                Rectangle()
                    .stroke(Color(hex: "#C2410C"), style: SwiftUI.StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                    .background(Color(hex: "#C2410C").opacity(0.08))
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
                    .allowsHitTesting(false)
            }
        }
        .frame(width: page.width, height: page.height)
        .coordinateSpace(name: "canvasSpace_\(pageIndex)")
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 4, coordinateSpace: .named("canvasSpace_\(pageIndex)"))
                .onChanged { value in
                    guard !isHandOrPanMode else { return }
                    viewModel.activePageIndex = pageIndex

                    if viewModel.activeTool == .draw {
                        viewModel.currentDrawingPoints.append(DrawingPoint(value.location))
                    } else if viewModel.activeTool == .select && (marqueeStart != nil || viewModel.selectedElementIds.isEmpty || NSEvent.modifierFlags.contains(.shift)) {
                        if marqueeStart == nil {
                            marqueeStart = value.startLocation
                            let isShiftPressed = NSEvent.modifierFlags.contains(.shift)
                            if !isShiftPressed {
                                viewModel.selectedElementIds.removeAll()
                            }
                        }
                        marqueeCurrent = value.location

                        let rect = CGRect(
                            x: min(value.startLocation.x, value.location.x),
                            y: min(value.startLocation.y, value.location.y),
                            width: abs(value.location.x - value.startLocation.x),
                            height: abs(value.location.y - value.startLocation.y)
                        )
                        let intersecting = viewModel.currentPage.elements.filter { $0.isVisible && !$0.isLocked && $0.rotatedCanvasBounds.intersects(rect) }
                        let hitIds = Set(intersecting.map { $0.id })
                        let isShiftPressed = NSEvent.modifierFlags.contains(.shift)
                        if isShiftPressed {
                            viewModel.selectedElementIds.formUnion(viewModel.expandSelectionForGroups(hitIds))
                        } else {
                            viewModel.selectedElementIds = viewModel.expandSelectionForGroups(hitIds)
                        }
                    }
                }
                .onEnded { _ in
                    if viewModel.activeTool == .draw {
                        viewModel.finishDrawing()
                    }
                    marqueeStart = nil
                    marqueeCurrent = nil
                }
        )
    }

    // MARK: - Floating Modern Page Navigation Dock (Bottom Left)

    private var floatingPageNavigationDock: some View {
        HStack(spacing: 8) {
            // Previous Page Button
            Button(action: { viewModel.goToPreviousPage() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(viewModel.activePageIndex > 0 ? .primary : .secondary.opacity(0.3))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(CircleHoverButtonStyle(side: 28))
            .disabled(viewModel.activePageIndex == 0)
            .help("Previous Page")

            // Page Counter Pill
            Text("Page \(viewModel.activePageIndex + 1) of \(viewModel.project.pages.count)")
                .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                .foregroundColor(.primary)
                .padding(.horizontal, 6)

            // Next Page Button
            Button(action: { viewModel.goToNextPage() }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(viewModel.activePageIndex < viewModel.project.pages.count - 1 ? .primary : .secondary.opacity(0.3))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(CircleHoverButtonStyle(side: 28))
            .disabled(viewModel.activePageIndex >= viewModel.project.pages.count - 1)
            .help("Next Page")

            Divider().frame(height: 16)

            // Grid Overview Button (Canva-style page thumbnails)
            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { showPageGridOverlay.toggle() } }) {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 11, weight: .semibold))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(CircleHoverButtonStyle(side: 28, isSelected: showPageGridOverlay))
            .help("Page Overview Grid")

            // Add Page Quick Button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    viewModel.addPage()
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .bold))
                    Text("Page")
                        .font(.system(size: 11, weight: .bold))
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .foregroundColor(Color(hex: "#C2410C"))
            }
            .buttonStyle(HoverPillButtonStyle(cornerRadius: 7, tint: Color(hex: "#C2410C")))
            .help("Add New Page")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 4)
    }

    // MARK: - Floating Zoom Slider Dock (Bottom Right)

    private func floatingZoomSliderDock(viewportSize: CGSize) -> some View {
        HStack(spacing: 8) {
            Button(action: { viewModel.zoomOut() }) {
                Image(systemName: "minus")
                    .font(.system(size: 11, weight: .bold))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(CircleHoverButtonStyle(side: 24))
            .help("Zoom Out")

            Slider(
                value: Binding(
                    get: { viewModel.zoomScale },
                    set: { viewModel.zoomScale = $0 }
                ),
                in: 0.15...3.0
            )
            .frame(width: 80)
            .controlSize(.mini)

            Button(action: { viewModel.zoomIn() }) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .bold))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(CircleHoverButtonStyle(side: 24))
            .help("Zoom In")

            Text("\(Int(viewModel.zoomScale * 100))%")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .frame(width: 36)

            Divider().frame(height: 14)

            Button(action: { withAnimation(.easeInOut(duration: 0.15)) { viewModel.showRulers.toggle() } }) {
                Image(systemName: "ruler")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(viewModel.showRulers ? Color(hex: "#C2410C") : .primary)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(CircleHoverButtonStyle(side: 24, isSelected: viewModel.showRulers))
            .help("Rulers & Guides (⌘R)")

            Button(action: { viewModel.zoomToFit(viewportSize: viewportSize) }) {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 10))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(CircleHoverButtonStyle(side: 24))
            .help("Fit to Screen")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 4)
    }

    // MARK: - Unified Bottom Rail (Canva-style): page filmstrip + zoom optics in one bar

    private var bottomBarView: some View {
        HStack(spacing: 14) {
            // Filmstrip — the page switcher
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(viewModel.project.pages.enumerated()), id: \.element.id) { idx, page in
                            filmstripThumbnail(page: page, index: idx, isActive: viewModel.activePageIndex == idx)
                                .id(idx)
                        }

                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) { viewModel.addPage() }
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                                .frame(width: 54, height: 54)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .strokeBorder(Color.secondary.opacity(0.35), style: SwiftUI.StrokeStyle(lineWidth: 1, dash: [4, 3]))
                                )
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .hoverHighlight(cornerRadius: 6)
                        .help("Add Page")
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 6)
                }
                .onChange(of: viewModel.activePageIndex) { _, newIdx in
                    withAnimation(.easeInOut(duration: 0.22)) {
                        proxy.scrollTo(newIdx, anchor: .center)
                    }
                }
            }

            Divider()
                .frame(height: 40)

            // Zoom optics
            HStack(spacing: 6) {
                Button(action: { viewModel.zoomOut() }) {
                    Image(systemName: "minus")
                        .font(.system(size: 10, weight: .bold))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(CircleHoverButtonStyle(side: 24))
                .help("Zoom Out (⌘−)")

                Slider(
                    value: Binding(
                        get: { min(3.0, max(0.15, viewModel.zoomScale)) },
                        set: { viewModel.setZoom($0) }
                    ),
                    in: 0.15...3.0
                )
                .frame(width: 84)
                .controlSize(.mini)
                .tint(PlumaTheme.accent)

                Button(action: { viewModel.zoomIn() }) {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .bold))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(CircleHoverButtonStyle(side: 24))
                .help("Zoom In (⌘+)")

                Menu {
                    Button("Fit Page") { viewModel.zoomToFit(viewportSize: viewModel.lastViewportSize) }
                    Button("Zoom to Selection  F") { viewModel.zoomToSelection(viewportSize: viewModel.lastViewportSize) }
                    Button("Actual Size  ⌘0") { viewModel.zoomTo100() }
                    Divider()
                    ForEach([0.25, 0.5, 0.75, 1.0, 1.5, 2.0, 3.0], id: \.self) { level in
                        Button("\(Int(level * 100))%") { viewModel.setZoom(level) }
                    }
                } label: {
                    Text("\(Int((viewModel.zoomScale * 100).rounded()))%")
                        .font(PlumaTheme.numeric(11, weight: .semibold))
                        .lineLimit(1)
                        .fixedSize()
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
                .frame(width: 42)
                .help("Zoom presets")

                Button(action: { viewModel.zoomToFit(viewportSize: viewModel.lastViewportSize) }) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 10))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(CircleHoverButtonStyle(side: 24))
                .help("Fit Page")

                Button(action: { withAnimation(.easeInOut(duration: 0.15)) { viewModel.showRulers.toggle() } }) {
                    Image(systemName: "ruler")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(viewModel.showRulers ? .white : .primary)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(CircleHoverButtonStyle(side: 24, isSelected: viewModel.showRulers))
                .help("Rulers & Guides (⌘R)")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 4)
    }

    private func filmstripThumbnail(page: CanvasPage, index: Int, isActive: Bool) -> some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                // During a live resize/drag/rotate the page fingerprint changes
                // every tick — a synchronous render here would re-rasterize the
                // whole page on the main thread per frame (the text-box lag).
                // Show the cached frame instead; it refreshes on commit.
                if viewModel.isLiveTransforming {
                    if let thumb = PageThumbnailService.shared.thumbnailIfCached(for: page, targetWidth: 128) {
                        Image(nsImage: thumb)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 96, height: 54)
                    } else {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.08))
                            .frame(width: 96, height: 54)
                    }
                } else if let thumb = PageThumbnailService.shared.thumbnail(for: page, targetWidth: 128) {
                    Image(nsImage: thumb)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 96, height: 54)
                } else {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.08))
                        .frame(width: 96, height: 54)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isActive ? PlumaTheme.accent : PlumaTheme.hairline, lineWidth: isActive ? 2 : 1)
            )
            .shadow(color: isActive ? Color(hex: "#C2410C").opacity(0.25) : .clear, radius: 4, x: 0, y: 2)

            Text("\(index + 1)")
                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 17, height: 17)
                .background(isActive ? Color(hex: "#C2410C") : Color.black.opacity(0.55))
                .clipShape(Circle())
                .padding(4)
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.activePageIndex = index
                viewModel.selectedElementIds.removeAll()
            }
        }
        .help("Go to Page \(index + 1)")
    }

    // MARK: - Whiteboard Quick-Add Palette

    private var whiteboardQuickPalette: some View {
        HStack(spacing: 4) {
            paletteButton(icon: "cursorarrow.rays", label: "Select (V)", isActive: viewModel.activeTool == .select) {
                viewModel.activeTool = .select
            }
            paletteButton(icon: "pencil.tip", label: "Pen (P)", isActive: viewModel.activeTool == .draw) {
                viewModel.activeTool = (viewModel.activeTool == .draw) ? .select : .draw
            }
            Divider().frame(height: 20)
            paletteButton(icon: "note.text", label: "Sticky Note (or double-click the board)", isActive: false) {
                viewModel.addStickyNote()
            }
            paletteButton(icon: "textformat", label: "Text (T)", isActive: false) {
                viewModel.addText()
            }
            paletteButton(icon: "square.on.circle", label: "Shape", isActive: false) {
                viewModel.addShape(.roundedRectangle)
            }
            paletteButton(icon: "arrow.right", label: "Arrow", isActive: false) {
                viewModel.addShape(.arrow)
            }
            paletteButton(icon: "star", label: "Star", isActive: false) {
                viewModel.addShape(.star)
            }
            Divider().frame(height: 20)
            paletteButton(icon: "arrow.triangle.turn.up.right.diamond", label: "Connect Selected (L) — arrows follow elements", isActive: false, isDisabled: viewModel.selectedElementIds.count < 2) {
                viewModel.connectSelectedElements()
            }
            paletteButton(icon: "arrow.uturn.backward", label: "Undo (⌘Z)", isActive: false) {
                viewModel.undo()
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 4)
    }

    private func paletteButton(icon: String, label: String, isActive: Bool, isDisabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isDisabled ? .secondary.opacity(0.5) : (isActive ? .white : .primary))
                .frame(width: 30, height: 30)
        }
        .buttonStyle(HoverIconButtonStyle(side: 30, cornerRadius: 8, isSelected: isActive))
        .disabled(isDisabled)
        .help(label)
    }

    // MARK: - Rulers & Draggable Guides

    private let rulerThickness: CGFloat = 20

    /// Screen-space rulers along the top and left edges showing canvas coordinates,
    /// with drag-to-create guides. Guides themselves render in `pageGuidesOverlay`.
    private func rulersOverlay(viewportSize: CGSize) -> some View {
        ZStack(alignment: .topLeading) {
            rulerStrip(viewportSize: viewportSize, isVertical: false)
            rulerStrip(viewportSize: viewportSize, isVertical: true)

            // Corner square
            Rectangle()
                .fill(Color(nsColor: .windowBackgroundColor).opacity(0.92))
                .frame(width: rulerThickness, height: rulerThickness)
                .overlay(Rectangle().stroke(Color.secondary.opacity(0.25), lineWidth: 0.5))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func rulerStrip(viewportSize: CGSize, isVertical: Bool) -> some View {
        let length = isVertical ? viewportSize.height : viewportSize.width
        let origin = viewModel.canvasToScreenPoint(.zero, viewportSize: viewportSize)
        let pageLen = isVertical ? viewModel.currentPage.height : viewModel.currentPage.width
        let z = viewModel.zoomScale

        return Group {
            if isVertical {
                RulerTicksCanvas(length: length, thickness: rulerThickness, originOffset: origin.y, pageLength: pageLen, zoom: z, isVertical: true, viewportSize: viewportSize, viewModel: viewModel)
                    .frame(width: rulerThickness, height: length)
            } else {
                RulerTicksCanvas(length: length, thickness: rulerThickness, originOffset: origin.x, pageLength: pageLen, zoom: z, isVertical: false, viewportSize: viewportSize, viewModel: viewModel)
                    .frame(width: length, height: rulerThickness)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.92))
        .overlay(
            Rectangle()
                .stroke(Color.secondary.opacity(0.25), lineWidth: 0.5)
        )
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged { value in
                    if guideDraftID == nil {
                        // Create a guide at the grab point
                        let canvasPoint = viewModel.screenToCanvasPoint(value.location, viewportSize: viewportSize)
                        let pos = isVertical ? canvasPoint.x : canvasPoint.y
                        viewModel.addGuide(at: pos, isVertical: isVertical)
                        if let last = viewModel.activeGuidesForPage.last {
                            guideDraftID = last.id
                        }
                    } else if let id = guideDraftID {
                        let canvasPoint = viewModel.screenToCanvasPoint(value.location, viewportSize: viewportSize)
                        viewModel.moveGuide(id: id, to: isVertical ? canvasPoint.x : canvasPoint.y)
                    }
                }
                .onEnded { _ in
                    guideDraftID = nil
                }
        )
        .onHover { hovering in
            NSCursor.crosshair.set()
            _ = hovering
        }
    }

    @State private var guideDraftID: UUID? = nil

    // MARK: - Page Guides Overlay (canvas-space lines with drag handles)

    @ViewBuilder
    private func pageGuidesOverlay(pageIndex: Int, page: CanvasPage) -> some View {
        let guides = page.guides ?? []
        if viewModel.showRulers && !guides.isEmpty && viewModel.activePageIndex == pageIndex {
            ZStack {
                ForEach(guides) { guide in
                    guideLine(guide: guide, page: page)
                }
            }
            .allowsHitTesting(true)
        }
    }

    private func guideLine(guide: CanvasGuide, page: CanvasPage) -> some View {
        let isVertical = guide.isVertical
        return Group {
            if isVertical {
                Rectangle()
                    .fill(Color(hex: "#EC4899"))
                    .frame(width: 1.5)
                    .position(x: guide.position, y: page.height / 2.0)
            } else {
                Rectangle()
                    .fill(Color(hex: "#EC4899"))
                    .frame(height: 1.5)
                    .position(x: page.width / 2.0, y: guide.position)
            }
        }
        .overlay(
            // Wide invisible grab handle
            Rectangle()
                .fill(Color.clear)
                .frame(width: isVertical ? 10 : nil, height: isVertical ? nil : 10)
                .contentShape(Rectangle())
        )
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .named("canvasSpace_\(viewModel.activePageIndex)"))
                .onChanged { value in
                    viewModel.moveGuide(id: guide.id, to: isVertical ? value.location.x : value.location.y)
                }
                .onEnded { value in
                    // Drag off the page (or double-click region) removes the guide
                    let pos = isVertical ? value.location.x : value.location.y
                    let limit = isVertical ? page.width : page.height
                    if pos < -20 || pos > limit + 20 {
                        viewModel.removeGuide(id: guide.id)
                    }
                }
        )
        .onTapGesture(count: 2) {
            viewModel.removeGuide(id: guide.id)
        }
    }

    // MARK: - Paper Sheet Background

    @ViewBuilder
    private func pageBackgroundSheet(page: CanvasPage) -> some View {
        if page.isTransparent {
            TransparencyCheckerboard()
        } else {
            switch page.background.type {
            case .solid, .newsprint:
                Rectangle().fill(page.background.solidColor.color)
            case .kraft:
                Rectangle().fill(page.background.solidColor.color)
                    .overlay(KraftFiberTextureView())
            case .vintageParchment:
                Rectangle().fill(page.background.solidColor.color)
                    .overlay(ParchmentTextureView())
            case .graphPaper:
                Rectangle().fill(page.background.solidColor.color)
                    .overlay(DraftingGridPatternView())
            case .linearGradient:
                let angleRad = page.background.gradientAngle * .pi / 180.0
                let startPoint = UnitPoint(x: 0.5 - 0.5 * cos(angleRad), y: 0.5 - 0.5 * sin(angleRad))
                let endPoint = UnitPoint(x: 0.5 + 0.5 * cos(angleRad), y: 0.5 + 0.5 * sin(angleRad))
                let gradient = Gradient(stops: page.background.gradientStops.map {
                    Gradient.Stop(color: $0.color.color, location: CGFloat($0.location))
                })
                Rectangle().fill(LinearGradient(gradient: gradient, startPoint: startPoint, endPoint: endPoint))
            case .radialGradient:
                let gradient = Gradient(stops: page.background.gradientStops.map {
                    Gradient.Stop(color: $0.color.color, location: CGFloat($0.location))
                })
                Rectangle().fill(RadialGradient(gradient: gradient, center: .center, startRadius: 0, endRadius: max(page.width, page.height) / 1.5))
            case .glass:
                Rectangle().fill(page.background.solidColor.color)
            case .pattern:
                Rectangle().fill(page.background.solidColor.color)
                    .overlay(PatternFillView(fill: page.background))
            }
        }
    }

    // MARK: - Element Context Menu

    /// Right-click doesn't run the tap gesture, so the clicked element's page may
    /// not be active (continuous mode) and it may not be selected. Activate its
    /// page and select it — but keep an existing multi-selection that already
    /// contains it, so "Delete" on one of several selected items deletes them all.
    private func prepareContextTarget(_ element: CanvasElement) {
        if let pageIdx = viewModel.project.pages.firstIndex(where: { $0.elements.contains(where: { $0.id == element.id }) }),
           pageIdx != viewModel.activePageIndex {
            viewModel.activePageIndex = pageIdx
        }
        if !viewModel.selectedElementIds.contains(element.id) {
            viewModel.selectElement(element)
        }
    }

    @ViewBuilder
    private func elementContextMenu(for element: CanvasElement) -> some View {
        if case .text = element.payload {
            Button("Edit Text") {
                prepareContextTarget(element)
                viewModel.editingTextElementId = element.id
            }
            .disabled(element.isLocked)
            Divider()
        } else if case .code = element.payload {
            Button("Edit Code") {
                prepareContextTarget(element)
                viewModel.editingCodeElementId = element.id
            }
            .disabled(element.isLocked)
            Divider()
        }

        Button("Copy (⌘C)") {
            prepareContextTarget(element)
            viewModel.copySelected()
        }
        Button("Duplicate (⌘D)") {
            prepareContextTarget(element)
            viewModel.duplicateSelected()
        }
        Divider()
        Button("Bring to Front (⌘])") {
            prepareContextTarget(element)
            viewModel.bringToFront()
        }
        Button("Send to Back (⌘[)") {
            prepareContextTarget(element)
            viewModel.sendToBack()
        }
        Divider()
        if viewModel.selectedElementIds.count >= 2 {
            Button("Group (⌘G)") {
                viewModel.groupSelectedElements()
            }
            Button("Connect Selected (L)") {
                viewModel.connectSelectedElements()
            }
            Divider()
        }
        if element.groupId != nil {
            Button("Ungroup (⇧⌘G)") {
                prepareContextTarget(element)
                viewModel.ungroupSelectedElements()
            }
            Divider()
        }
        Button("Flip Horizontal") {
            prepareContextTarget(element)
            viewModel.flipSelected(horizontal: true)
        }
        Button("Flip Vertical") {
            prepareContextTarget(element)
            viewModel.flipSelected(horizontal: false)
        }
        Button(element.isLocked ? "Unlock (⌘L)" : "Lock (⌘L)") {
            prepareContextTarget(element)
            viewModel.toggleLockSelected()
        }
        Button("Copy as Image") {
            prepareContextTarget(element)
            viewModel.copySelectedElementAsImage()
        }
        Divider()
        Button("Delete (⌫)") {
            prepareContextTarget(element)
            viewModel.deleteSelected()
        }
    }
}

// MARK: - Ruler Tick Renderer (screen-space Canvas with canvas-coordinate labels)

struct RulerTicksCanvas: View {
    let length: CGFloat
    let thickness: CGFloat
    let originOffset: CGFloat   // screen position of canvas coordinate 0 along this axis
    let pageLength: Double
    let zoom: Double
    let isVertical: Bool
    let viewportSize: CGSize
    @ObservedObject var viewModel: CanvasDocumentViewModel

    var body: some View {
        Canvas { context, _ in
            // Choose a step whose on-screen spacing stays readable
            let candidates: [Double] = [1, 2, 5, 10, 20, 50, 100, 200, 500, 1000, 2000, 5000, 10000]
            let step = candidates.first { Double($0) * zoom >= 56 } ?? 10000
            let minorStep = step / 5.0

            let cMin = Double((0 - originOffset) / max(0.0001, zoom)) - step
            let cMax = Double((length - originOffset) / max(0.0001, zoom)) + step

            func screenPos(_ canvas: Double) -> CGFloat {
                originOffset + CGFloat(canvas * zoom)
            }

            // Highlight the page region
            let pageStart = screenPos(0)
            let pageEnd = screenPos(pageLength)
            let pageRect: CGRect = isVertical
                ? CGRect(x: 0, y: pageStart, width: thickness, height: pageEnd - pageStart)
                : CGRect(x: pageStart, y: 0, width: pageEnd - pageStart, height: thickness)
            context.fill(Path(pageRect), with: .color(Color(hex: "#C2410C").opacity(0.10)))

            let minorColor = Color.secondary.opacity(0.35)
            let majorColor = Color.secondary.opacity(0.7)

            var c = (cMin / minorStep).rounded(.down) * minorStep
            while c <= cMax {
                let s = screenPos(c)
                let isMajor = abs(c.truncatingRemainder(dividingBy: step)) < 0.0001 || abs(abs(c.truncatingRemainder(dividingBy: step)) - step) < 0.0001
                let tickLen: CGFloat = isMajor ? 9 : 4
                var tickRect: CGRect
                if isVertical {
                    tickRect = CGRect(x: thickness - tickLen, y: s - 0.5, width: tickLen, height: 1)
                } else {
                    tickRect = CGRect(x: s - 0.5, y: thickness - tickLen, width: 1, height: tickLen)
                }
                context.fill(Path(tickRect), with: .color(isMajor ? majorColor : minorColor))

                if isMajor {
                    let label = Text("\(Int(c))")
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundColor(Color.secondary.opacity(0.85))
                    if isVertical {
                        context.draw(context.resolve(label), at: CGPoint(x: 6, y: s + 8))
                    } else {
                        context.draw(context.resolve(label), at: CGPoint(x: s + 9, y: 7))
                    }
                }
                c += minorStep
            }
        }
        .gesture(
            // Guide creation is attached here too (whole strip is draggable)
            DragGesture(minimumDistance: 0)
                .onChanged { _ in }
        )
    }
}

// MARK: - Freehand Stroke Shape (Screen Space Preview)

public struct DrawStrokeShape: Shape {
    public var points: [CGPoint]

    public init(points: [CGPoint]) {
        self.points = points
    }

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        for pt in points.dropFirst() {
            path.addLine(to: pt)
        }
        return path
    }
}

// MARK: - Infinite Dot Grid Matrix (Figma / Miro Style)

public struct InfiniteDotGridBackdrop: View {
    let zoomScale: Double
    let panOffset: CGPoint

    public init(zoomScale: Double, panOffset: CGPoint) {
        self.zoomScale = zoomScale
        self.panOffset = panOffset
    }

    public var body: some View {
        Canvas { context, size in
            let baseStep: CGFloat = 28.0 * CGFloat(zoomScale)
            let step = baseStep < 14 ? baseStep * 2 : baseStep

            let startX = (CGFloat(panOffset.x) + size.width / 2.0).truncatingRemainder(dividingBy: step)
            let startY = (CGFloat(panOffset.y) + size.height / 2.0).truncatingRemainder(dividingBy: step)

            let dotRadius: CGFloat = min(1.6, max(0.8, 1.2 * CGFloat(zoomScale)))
            let dotColor = Color.primary.opacity(0.18)

            for x in stride(from: startX - step, through: size.width + step, by: step) {
                for y in stride(from: startY - step, through: size.height + step, by: step) {
                    let dotRect = CGRect(x: x - dotRadius, y: y - dotRadius, width: dotRadius * 2, height: dotRadius * 2)
                    context.fill(Path(ellipseIn: dotRect), with: .color(dotColor))
                }
            }
        }
        .background(PlumaTheme.workspace)
    }
}

// MARK: - Transparency Checkerboard & Workspace Backdrop Components

public struct TransparencyCheckerboard: View {
    public init() {}
    public var body: some View {
        Canvas { context, size in
            let tileSize: CGFloat = 8
            let cols = Int(ceil(size.width / tileSize))
            let rows = Int(ceil(size.height / tileSize))
            for r in 0..<rows {
                for c in 0..<cols {
                    if (r + c) % 2 == 0 {
                        let rect = CGRect(x: CGFloat(c) * tileSize, y: CGFloat(r) * tileSize, width: tileSize, height: tileSize)
                        context.fill(Path(rect), with: .color(Color(white: 0.85)))
                    } else {
                        let rect = CGRect(x: CGFloat(c) * tileSize, y: CGFloat(r) * tileSize, width: tileSize, height: tileSize)
                        context.fill(Path(rect), with: .color(Color(white: 0.95)))
                    }
                }
            }
        }
    }
}

public struct StudioDraftingWorkspaceBackdrop: View {
    let showGrid: Bool
    public init(showGrid: Bool = false) {
        self.showGrid = showGrid
    }
    public var body: some View {
        ZStack {
            PlumaTheme.workspace
            if showGrid {
                Canvas { context, size in
                    let step: CGFloat = 20
                    var path = Path()
                    for x in stride(from: 0, through: size.width, by: step) {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                    }
                    for y in stride(from: 0, through: size.height, by: step) {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                    }
                    context.stroke(path, with: .color(Color.secondary.opacity(0.1)), lineWidth: 0.5)
                }
            }
        }
    }
}

// MARK: - Native Trackpad & Scroll Gesture Interceptor (Two-finger pan, pinch-to-zoom, Spacebar drag)

public struct CanvasTrackpadGestureHostViewRepresentable: NSViewRepresentable {
    @ObservedObject var viewModel: CanvasDocumentViewModel
    @Binding var isSpacebarPressed: Bool

    public func makeNSView(context: Context) -> TrackpadGestureHostView {
        let view = TrackpadGestureHostView()
        view.viewModel = viewModel
        view.onSpacebarChanged = { pressed in
            DispatchQueue.main.async {
                self.isSpacebarPressed = pressed
            }
        }
        return view
    }

    public func updateNSView(_ nsView: TrackpadGestureHostView, context: Context) {
        nsView.viewModel = viewModel
        nsView.onSpacebarChanged = { pressed in
            DispatchQueue.main.async {
                self.isSpacebarPressed = pressed
            }
        }
    }
}

public final class TrackpadGestureHostView: NSView {
    public var viewModel: CanvasDocumentViewModel?
    public var onSpacebarChanged: ((Bool) -> Void)?

    private var localEventMonitor: Any?
    private var resignObserver: NSObjectProtocol?

    public override var acceptsFirstResponder: Bool { true }

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupGlobalMonitors()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGlobalMonitors()
    }

    deinit {
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let observer = resignObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    public override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let observer = resignObserver {
            NotificationCenter.default.removeObserver(observer)
            resignObserver = nil
        }
        guard let window = window else { return }
        // The spacebar key-up only arrives while this window is key — if the
        // user releases Space after focus leaves (clicks another app, opens a
        // sheet), `isSpacebarPressed` would stick ON forever: pan mode + hand
        // cursor stuck and every element gesture early-returns. Reset on resign.
        resignObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            self?.onSpacebarChanged?(false)
            NSCursor.arrow.set()
        }
    }

    private func setupGlobalMonitors() {
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.scrollWheel, .magnify, .keyDown, .keyUp]) { [weak self] event in
            guard let self = self, let vm = self.viewModel else { return event }

            if event.type == .keyDown && event.keyCode == 49 && !event.isARepeat { // Spacebar pressed
                // Typing a space in any text field (inspector, rename, popover)
                // must not flip the canvas into pan mode.
                let typingInField = (event.window ?? NSApp.keyWindow)?.firstResponder is NSText
                if vm.editingTextElementId == nil && vm.editingCodeElementId == nil && !typingInField
                    && (event.window == nil || event.window === self.window) {
                    self.onSpacebarChanged?(true)
                    NSCursor.openHand.set()
                }
            } else if event.type == .keyUp && event.keyCode == 49 { // Spacebar released
                self.onSpacebarChanged?(false)
                NSCursor.arrow.set()
            } else if event.type == .scrollWheel {
                // Check if scroll event is happening inside our window
                if let window = self.window, window.isKeyWindow {
                    let mouseLoc = window.mouseLocationOutsideOfEventStream
                    let localPoint = self.convert(mouseLoc, from: nil)

                    // ONLY handle scroll if the mouse cursor is physically over the canvas viewport
                    // This prevents scrolling in the Left Sidebar from moving the canvas artboard!
                    if self.bounds.contains(localPoint) {
                        if event.modifierFlags.contains(.command) {
                            // Zoom anchored under the CURSOR (Figma-style focal zoom):
                            // the canvas point beneath the pointer stays glued to it.
                            let zoomFactor = 1.0 - (event.deltaY * 0.02)
                            let cursorPoint = self.swiftUICursorPosition()
                            vm.applyFocalZoom(
                                factor: Double(zoomFactor),
                                screenPoint: cursorPoint,
                                viewportSize: CGSize(width: self.bounds.width, height: self.bounds.height)
                            )
                        } else if vm.canPan(viewportSize: CGSize(width: self.bounds.width, height: self.bounds.height)) {
                            // Smooth pan, pre-clamped per axis synchronously — locked axes
                            // (e.g. horizontal on a fit-zoomed document) never move at all,
                            // so there is no move-then-snap-back jank.
                            let dx = event.scrollingDeltaX
                            let dy = event.scrollingDeltaY
                            let hasPrecise = event.hasPreciseScrollingDeltas
                            let multiplier: CGFloat = hasPrecise ? 1.0 : 8.0

                            vm.applyPan(
                                delta: CGSize(width: dx * multiplier, height: dy * multiplier),
                                viewportSize: CGSize(width: self.bounds.width, height: self.bounds.height)
                            )
                        }
                    }
                }
            } else if event.type == .magnify {
                // Pinch-to-zoom also anchors under the cursor
                let factor = 1.0 + event.magnification
                let cursorPoint = self.swiftUICursorPosition()
                vm.applyFocalZoom(
                    factor: Double(factor),
                    screenPoint: cursorPoint,
                    viewportSize: CGSize(width: self.bounds.width, height: self.bounds.height)
                )
            }
            return event
        }
    }

    /// Current mouse position converted into SwiftUI's top-left-origin coordinate space.
    private func swiftUICursorPosition() -> CGPoint {
        guard let window = window else { return CGPoint(x: bounds.midX, y: bounds.midY) }
        let mouseLoc = window.mouseLocationOutsideOfEventStream
        let local = convert(mouseLoc, from: nil)
        // AppKit is bottom-left origin; SwiftUI is top-left origin.
        return CGPoint(x: local.x, y: bounds.height - local.y)
    }
}

// MARK: - Equatable element renderer

/// Wraps `ElementRendererView` so SwiftUI can skip re-rendering elements whose
/// content didn't change. Every drag tick republishes `project`, which used to
/// re-evaluate every element on every page (Document mode especially). The
/// callbacks only capture the view model and the element id, so they are
/// deliberately left out of `==`. Position is applied by the parent via
/// `.position`, so a pure move doesn't re-render the content either.
private struct EquatableElementRenderer: View, Equatable {
    let viewModel: CanvasDocumentViewModel
    let element: CanvasElement
    let isEditingText: Bool
    let isEditingCode: Bool
    let isLiveTransforming: Bool

    static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.isEditingText == rhs.isEditingText,
              lhs.isEditingCode == rhs.isEditingCode,
              lhs.isLiveTransforming == rhs.isLiveTransforming else { return false }
        if lhs.element == rhs.element { return true }
        var unmoved = rhs.element
        unmoved.x = lhs.element.x
        unmoved.y = lhs.element.y
        return lhs.element == unmoved
    }

    var body: some View {
        let id = element.id
        let viewModel = viewModel
        ElementRendererView(
            element: element,
            isEditingText: isEditingText,
            isEditingCode: isEditingCode,
            isLiveTransforming: isLiveTransforming,
            onUpdateText: { newText in
                viewModel.updateTextAndFitHeight(id: id, newText: newText)
            },
            onCommitText: {
                viewModel.editingTextElementId = nil
            },
            onUpdateCode: { newCode in
                viewModel.updateCodeAndFitHeight(id: id, newCode: newCode)
            },
            onUpdateLanguage: { newLang in
                viewModel.saveHistoryState()
                viewModel.updateElement(id: id) { elem in
                    if case .code(var c) = elem.payload {
                        c.language = newLang
                        c.windowTitle = "snippet.\(newLang.fileExtension)"
                        elem.payload = .code(c)
                    }
                }
            },
            onUpdateTheme: { newTheme in
                viewModel.saveHistoryState()
                viewModel.updateElement(id: id) { elem in
                    if case .code(var c) = elem.payload {
                        c.theme = newTheme
                        elem.payload = .code(c)
                    }
                }
            }
        )
    }
}
