import SwiftUI
import AppKit

public struct MainCanvasView: View {
    @ObservedObject var viewModel: CanvasDocumentViewModel
    var onReturnHome: (() -> Void)?

    public init(viewModel: CanvasDocumentViewModel, onReturnHome: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onReturnHome = onReturnHome
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Main Top Title & Tool Bar
            CanvasToolbarView(viewModel: viewModel, onReturnHome: onReturnHome)

            // Contextual Top Property Formatting Bar (Canva-style Top Bar for Quick Edits)
            ContextualTopBarView(viewModel: viewModel)

            // Main Editor Body: Left Sidebar + Centered Artboard Viewport + Right Inspector
            // Panels stay in the hierarchy and collapse via width — the old
            // `if` + `.move` transition could leave the view rendered but its
            // hit-test region displaced (dead clicks/hover) after mixed
            // animated/unanimated toggles (⌘1 animates; toolbar buttons don't).
            HStack(spacing: 0) {
                LeftSidebarView(viewModel: viewModel)
                    .frame(width: viewModel.isLeftSidebarVisible ? nil : 0, alignment: .leading)
                    .clipped()
                    .allowsHitTesting(viewModel.isLeftSidebarVisible)

                // Center Artboard Canvas Viewport
                CanvasViewportView(viewModel: viewModel)

                InspectorView(viewModel: viewModel)
                    .frame(width: viewModel.isRightInspectorVisible ? nil : 0, alignment: .trailing)
                    .clipped()
                    .allowsHitTesting(viewModel.isRightInspectorVisible)
            }
            .animation(.easeInOut(duration: 0.2), value: viewModel.isLeftSidebarVisible)
            .animation(.easeInOut(duration: 0.2), value: viewModel.isRightInspectorVisible)
        }
        .frame(minWidth: 950, minHeight: 650)
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $viewModel.showExportModal) {
            ExportModalView(viewModel: viewModel)
        }
        .onReceive(NotificationCenter.default.publisher(for: .showExportModal)) { _ in
            viewModel.showExportModal = true
        }
        .sheet(isPresented: $viewModel.showPresetPickerModal) {
            PresetPickerModal(viewModel: viewModel)
        }
        .overlay {
            if viewModel.isPresentingFullscreen {
                PresentationModeView(viewModel: viewModel)
                    .transition(.opacity)
            }
        }
        .overlay {
            if viewModel.showCommandPalette {
                CommandPaletteView(viewModel: viewModel) {
                    withAnimation(.easeInOut(duration: 0.12)) {
                        viewModel.showCommandPalette = false
                    }
                }
                .zIndex(100)
            }
        }
        .overlay {
            ImportProgressOverlay()
                .zIndex(200)
        }
        .allowsHitTesting(true)
        .background(
            KeyboardShortcutHandler(viewModel: viewModel)
        )
    }
}

// Invisible Key Handler View for macOS global keyboard shortcuts using Local Monitor
struct KeyboardShortcutHandler: NSViewRepresentable {
    let viewModel: CanvasDocumentViewModel

    func makeNSView(context: Context) -> KeyCaptureView {
        let view = KeyCaptureView()
        view.viewModel = viewModel
        return view
    }

    func updateNSView(_ nsView: KeyCaptureView, context: Context) {
        nsView.viewModel = viewModel
    }

    class KeyCaptureView: NSView {
        weak var viewModel: CanvasDocumentViewModel?
        private var monitor: Any?

        /// Invisible event-monitor view sized to the whole window. It must never
        /// enter the hit-test chain — if compositing ever lifts it above the
        /// SwiftUI content it would silently eat every click and hover.
        override func hitTest(_ point: NSPoint) -> NSView? { nil }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if monitor == nil && window != nil {
                monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                    guard let self = self, let viewModel = self.viewModel else { return event }

                    // Popovers (color picker hex field, font search) and sheets
                    // (export, resize) are separate windows: their keystrokes
                    // must never reach the canvas shortcuts below.
                    guard event.window == nil || event.window === self.window else { return event }

                    // Presentation mode owns the keyboard (Esc / arrows).
                    if viewModel.isPresentingFullscreen { return event }

                    // CRITICAL: If the user is actively typing in a text element or text field
                    if viewModel.editingTextElementId != nil || viewModel.editingCodeElementId != nil {
                        if event.keyCode == 53 { // Escape cancels editing
                            viewModel.editingTextElementId = nil
                            viewModel.editingCodeElementId = nil
                            return nil
                        }
                        return event
                    }

                    if let responder = (event.window ?? NSApp.keyWindow)?.firstResponder,
                       responder is NSTextView || responder is NSTextField || responder is NSText {
                        return event
                    }

                    let flags = event.modifierFlags
                    let isCmd = flags.contains(.command)
                    let isShift = flags.contains(.shift)
                    let isOption = flags.contains(.option)

                    if isCmd {
                        switch event.charactersIgnoringModifiers?.lowercased() {
                        case "1":
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.isLeftSidebarVisible.toggle()
                            }
                            return nil
                        case "2":
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.isRightInspectorVisible.toggle()
                            }
                            return nil
                        case "z":
                            if isShift { viewModel.redo() } else { viewModel.undo() }
                            return nil
                        case "y":
                            viewModel.redo()
                            return nil
                        case "c":
                            if isOption { viewModel.copySVGForFigma() }
                            else if isShift { viewModel.copyPageImageToClipboard() }
                            else { viewModel.copySelected() }
                            return nil
                        case "l":
                            // ⌘L — lock/unlock (advertised in the selection bar)
                            if !viewModel.selectedElementIds.isEmpty { viewModel.toggleLockSelected() }
                            return nil
                        case "v":
                            viewModel.paste()
                            return nil
                        case "d":
                            viewModel.duplicateSelected()
                            return nil
                        case "a":
                            viewModel.selectAll()
                            return nil
                        case "e":
                            viewModel.showExportModal = true
                            return nil
                        case "0":
                            viewModel.zoomTo100()
                            return nil
                        case "+", "=":
                            viewModel.zoomIn()
                            return nil
                        case "-":
                            viewModel.zoomOut()
                            return nil
                        case "]":
                            if isOption { viewModel.bringToFront() } else { viewModel.bringForward() }
                            return nil
                        case "[":
                            if isOption { viewModel.sendToBack() } else { viewModel.sendBackward() }
                            return nil
                        case "g":
                            if isShift { viewModel.ungroupSelectedElements() } else { viewModel.groupSelectedElements() }
                            return nil
                        case "k":
                            withAnimation(.easeInOut(duration: 0.15)) {
                                viewModel.showCommandPalette.toggle()
                            }
                            return nil
                        case "r":
                            withAnimation(.easeInOut(duration: 0.15)) {
                                viewModel.showRulers.toggle()
                            }
                            return nil
                        default:
                            break
                        }
                    } else {
                        // Non-Cmd shortcuts (Only when not editing text!)
                        switch event.keyCode {
                        case 51, 117: // Delete / Backspace
                            if !viewModel.selectedElementIds.isEmpty {
                                viewModel.deleteSelected()
                                return nil
                            }
                        case 53: // Escape
                            viewModel.deselectAll()
                            return nil
                        default:
                            break
                        }

                        switch event.charactersIgnoringModifiers?.lowercased() {
                        case "v":
                            viewModel.activeTool = .select
                            return nil
                        case "h":
                            viewModel.activeTool = .hand
                            return nil
                        case "t":
                            viewModel.addText()
                            return nil
                        case "c":
                            viewModel.addCodeBlock()
                            return nil
                        case "r":
                            viewModel.addShape(.roundedRectangle)
                            return nil
                        case "o":
                            viewModel.addShape(.circle)
                            return nil
                        case "p":
                            viewModel.activeTool = (viewModel.activeTool == .draw) ? .select : .draw
                            return nil
                        case "l":
                            // Link selected elements with an anchored connector (chain order)
                            viewModel.connectSelectedElements()
                            return nil
                        case "f":
                            // F = zoom to selection (or fit page when nothing is selected)
                            viewModel.zoomToSelection(viewportSize: viewModel.lastViewportSize)
                            return nil
                        default:
                            break
                        }

                        // Arrow keys: nudge selection (1px, Shift = 10px)
                        if !viewModel.selectedElementIds.isEmpty {
                            let step: Double = isShift ? 10.0 : 1.0
                            switch event.keyCode {
                            case 123: viewModel.nudgeSelected(dx: -step, dy: 0); return nil
                            case 124: viewModel.nudgeSelected(dx: step, dy: 0); return nil
                            case 125: viewModel.nudgeSelected(dx: 0, dy: step); return nil
                            case 126: viewModel.nudgeSelected(dx: 0, dy: -step); return nil
                            default: break
                            }
                        }
                    }

                    return event
                }
            } else if window == nil, let m = monitor {
                NSEvent.removeMonitor(m)
                monitor = nil
            }
        }

        deinit {
            if let m = monitor {
                NSEvent.removeMonitor(m)
            }
        }
    }
}
