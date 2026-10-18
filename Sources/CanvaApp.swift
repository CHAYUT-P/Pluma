import SwiftUI
import AppKit

@main
struct PlumaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var projectStorage = ProjectStorage.shared

    init() {
        // Hidden CLI harness: `Pluma --import-debug <file>` runs the document importer
        // headlessly and prints diagnostics (used during development & CI checks).
        // `Pluma --render-template <id> <out.png>` renders a built-in template preview.
        let args = CommandLine.arguments
        if let idx = args.firstIndex(of: "--import-debug"), idx + 1 < args.count {
            let renderDir = args.firstIndex(of: "--render").flatMap { r in
                r + 1 < args.count ? args[r + 1] : nil
            }
            ImportDebugHarness.run(path: args[idx + 1], renderDir: renderDir)
        }
        if let idx = args.firstIndex(of: "--render-template"), idx + 2 < args.count {
            ImportDebugHarness.renderTemplate(id: args[idx + 1], out: args[idx + 2])
        }
        // `Pluma --render-preset <name|all> <out-dir>` renders DevKit presets to
        // PNGs for visual verification without opening the UI.
        if let idx = args.firstIndex(of: "--render-preset"), idx + 2 < args.count {
            ImportDebugHarness.renderPreset(name: args[idx + 1], outDir: args[idx + 2])
        }
        // `Pluma --export-pptx <in> <out.pptx>` imports then re-exports — a
        // headless round-trip check for the importer/exporter pair.
        if let idx = args.firstIndex(of: "--export-pptx"), idx + 2 < args.count {
            ImportDebugHarness.exportPPTX(input: args[idx + 1], output: args[idx + 2])
        }
    }

    @State private var activeProject: CanvasProject? = nil
    @State private var isShowingDashboard: Bool = true
    @StateObject private var activeViewModel = CanvasDocumentViewModel()
    @State private var bridgeStarted = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                if isShowingDashboard {
                    HomeDashboardView(activeProject: $activeProject, isShowingDashboard: $isShowingDashboard)
                        .transition(.opacity)
                } else {
                    MainCanvasView(viewModel: activeViewModel, onReturnHome: {
                        if activeViewModel.hasOpenedDocument {
                            projectStorage.saveProject(activeViewModel.project)
                        }
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isShowingDashboard = true
                        }
                    })
                    .transition(.opacity)
                }
            }
            .navigationTitle(isShowingDashboard ? "Pluma Studio" : (activeViewModel.project.name.isEmpty ? "Untitled Design" : activeViewModel.project.name))
            .onAppear {
                // Start the localhost AI bridge (MCP talks to this) once.
                if !bridgeStarted {
                    bridgeStarted = true
                    PlumaBridgeServer.shared.start(viewModel: activeViewModel)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
                // Flush the in-memory document synchronously — the debounced
                // autosave writer would race process exit and lose the last
                // <800ms of edits. Guarded: the view model starts holding a
                // virgin "Untitled Project" — saving it when no document was
                // ever opened wrote a phantom card to Projects/ on every quit.
                if activeViewModel.hasOpenedDocument {
                    projectStorage.saveProjectNow(activeViewModel.project)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .openEditor)) { _ in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isShowingDashboard = false
                }
            }
            .onChange(of: activeProject) { oldVal, newVal in
                if let project = newVal {
                    activeViewModel.adoptProject(project)
                }
            }
            .onChange(of: projectStorage.trashedProjects) { _, trashed in
                // The dashboard can trash the project currently held by the
                // view model — drop the document so save-on-quit / Home can't
                // resurrect it into Projects/ (writes are also gated in
                // ProjectStorage.trashedIds as a second layer).
                if trashed.contains(where: { $0.id == activeViewModel.project.id }) {
                    activeViewModel.closeDocument()
                }
            }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .defaultSize(width: 1560, height: 980)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Home / Projects") {
                    // Same save-on-exit as the on-canvas "Home" button — this
                    // shortcut used to bypass it and drop unsaved page edits.
                    // Guarded like willTerminate: firing it before any document
                    // was opened would persist the virgin "Untitled Project".
                    if activeViewModel.hasOpenedDocument {
                        projectStorage.saveProject(activeViewModel.project)
                    }
                    isShowingDashboard = true
                }
                .keyboardShortcut("h", modifiers: [.command, .shift])

                Button("New Canvas") {
                    let newProj = CanvasProject(name: "Untitled Canvas", pages: [CanvasPage()])
                    projectStorage.saveProject(newProj)
                    activeProject = newProj
                    isShowingDashboard = false
                }
                .keyboardShortcut("n", modifiers: .command)
            }

            CommandGroup(replacing: .undoRedo) {
                Button("Undo") {
                    if !TextEditingRouter.forward("undo:") && !isShowingDashboard { activeViewModel.undo() }
                }
                .keyboardShortcut("z", modifiers: .command)

                Button("Redo") {
                    if !TextEditingRouter.forward("redo:") && !isShowingDashboard { activeViewModel.redo() }
                }
                .keyboardShortcut("z", modifiers: [.command, .shift])
            }

            // Edit commands route to the focused text field/view first — these
            // menu items used to win over the field editor, so ⌘C/⌘V/⌘A while
            // renaming a design or typing in the inspector copied canvas
            // elements instead of text.
            CommandGroup(replacing: .pasteboard) {
                Button("Cut") {
                    if !TextEditingRouter.forward("cut:") && !isShowingDashboard {
                        activeViewModel.copySelected()
                        activeViewModel.deleteSelected()
                    }
                }
                .keyboardShortcut("x", modifiers: .command)

                Button("Copy") {
                    if !TextEditingRouter.forward("copy:") && !isShowingDashboard { activeViewModel.copySelected() }
                }
                .keyboardShortcut("c", modifiers: .command)

                Button("Paste") {
                    if !TextEditingRouter.forward("paste:") && !isShowingDashboard { activeViewModel.paste() }
                }
                .keyboardShortcut("v", modifiers: .command)

                Button("Duplicate") {
                    activeViewModel.duplicateSelected()
                }
                .keyboardShortcut("d", modifiers: .command)
                .disabled(isShowingDashboard)

                // No bare ⌫ key equivalent here: the canvas key monitor already
                // handles Delete, and a menu-level ⌫ can eat Backspace in fields.
                Button("Delete") {
                    if !TextEditingRouter.forward("delete:") && !isShowingDashboard { activeViewModel.deleteSelected() }
                }

                Button("Select All") {
                    if !TextEditingRouter.forward("selectAll:") && !isShowingDashboard { activeViewModel.selectAll() }
                }
                .keyboardShortcut("a", modifiers: .command)

                Divider()

                Group {
                    Button("Copy as Image") {
                        activeViewModel.copyPageImageToClipboard()
                    }
                    .keyboardShortcut("c", modifiers: [.command, .shift])

                    Button("Copy as SVG for Figma") {
                        activeViewModel.copySVGForFigma()
                    }
                    .keyboardShortcut("c", modifiers: [.command, .option])
                }
                .disabled(isShowingDashboard)
            }

            CommandMenu("View") {
                Group {
                    Button("Zoom In") { activeViewModel.zoomIn() }
                        .keyboardShortcut("=", modifiers: .command)
                    Button("Zoom Out") { activeViewModel.zoomOut() }
                        .keyboardShortcut("-", modifiers: .command)
                    Button("Actual Size") { activeViewModel.zoomTo100() }
                        .keyboardShortcut("0", modifiers: .command)
                    Button("Fit Page") { activeViewModel.zoomToFit(viewportSize: activeViewModel.lastViewportSize) }
                    Divider()
                    Button("Toggle Left Panel") { activeViewModel.isLeftSidebarVisible.toggle() }
                        .keyboardShortcut("1", modifiers: .command)
                    Button("Toggle Inspector") { activeViewModel.isRightInspectorVisible.toggle() }
                        .keyboardShortcut("2", modifiers: .command)
                    Button("Toggle Rulers") { activeViewModel.showRulers.toggle() }
                        .keyboardShortcut("r", modifiers: .command)
                    Divider()
                    Button("Present") { activeViewModel.isPresentingFullscreen = true }
                        .keyboardShortcut("p", modifiers: [.command, .option])
                    Button("Command Palette…") { activeViewModel.showCommandPalette.toggle() }
                        .keyboardShortcut("k", modifiers: .command)
                }
                .disabled(isShowingDashboard)
            }

            CommandMenu("Arrange") {
                Group {
                    Button("Bring to Front") { activeViewModel.bringToFront() }
                        .keyboardShortcut("]", modifiers: [.command, .option])
                    Button("Bring Forward") { activeViewModel.bringForward() }
                        .keyboardShortcut("]", modifiers: .command)
                    Button("Send Backward") { activeViewModel.sendBackward() }
                        .keyboardShortcut("[", modifiers: .command)
                    Button("Send to Back") { activeViewModel.sendToBack() }
                        .keyboardShortcut("[", modifiers: [.command, .option])
                    Divider()
                    Button("Group") { activeViewModel.groupSelectedElements() }
                        .keyboardShortcut("g", modifiers: .command)
                    Button("Ungroup") { activeViewModel.ungroupSelectedElements() }
                        .keyboardShortcut("g", modifiers: [.command, .shift])
                    Button("Lock / Unlock") { activeViewModel.toggleLockSelected() }
                        .keyboardShortcut("l", modifiers: .command)
                }
                .disabled(isShowingDashboard)
            }

            CommandMenu("Export") {
                Button("Export Design...") {
                    NotificationCenter.default.post(name: .showExportModal, object: nil)
                }
                .keyboardShortcut("e", modifiers: .command)
            }
        }
    }
}

/// Sends standard edit actions to the focused text field/view when there is one.
enum TextEditingRouter {
    /// Returns true when a text responder had focus and received the action.
    @discardableResult
    static func forward(_ action: String) -> Bool {
        guard let responder = NSApp.keyWindow?.firstResponder as? NSText else { return false }
        // Undo/redo fall through to the canvas history once the field's own
        // undo stack is exhausted.
        if action == "undo:" && responder.undoManager?.canUndo != true { return false }
        if action == "redo:" && responder.undoManager?.canRedo != true { return false }
        return NSApp.sendAction(Selector(action), to: nil, from: nil)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
        // Dev/test hook: force an appearance to check light & dark rendering
        // without changing the system setting (PLUMA_APPEARANCE=dark|light).
        switch ProcessInfo.processInfo.environment["PLUMA_APPEARANCE"] {
        case "dark": NSApp.appearance = NSAppearance(named: .darkAqua)
        case "light": NSApp.appearance = NSAppearance(named: .aqua)
        default: break
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

extension Notification.Name {
    static let showExportModal = Notification.Name("showExportModal")
    static let openEditor = Notification.Name("openEditor")
}

// MARK: - Headless Import Diagnostics (development harness)
enum ImportDebugHarness {
    static func renderTemplate(id: String, out: String) -> Never {
        guard let tpl = TemplateCatalog.templates.first(where: { $0.id == id })
            ?? ResumeTemplates.allResumeTemplates().first(where: { $0.id == id })
            ?? WhiteboardTemplates.allWhiteboardTemplates().first(where: { $0.id == id }) else {
            print("TEMPLATE NOT FOUND: \(id)")
            exit(2)
        }
        let pageIndex = CommandLine.arguments.dropFirst().last.flatMap { Int($0) } ?? 0
        let page = tpl.pages.indices.contains(pageIndex) ? tpl.pages[pageIndex] : (tpl.pages.first ?? tpl.page)
        guard let img = ExportEngine.renderImage(page: page, scale: min(1.0, 900.0 / max(1, page.width))),
              let tiff = img.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else {
            print("RENDER FAILED")
            exit(3)
        }
        try? png.write(to: URL(fileURLWithPath: out))
        print("rendered \(tpl.title) page \(pageIndex + 1)/\(tpl.pages.count) → \(out)")
        exit(0)
    }

    @MainActor
    static func renderPreset(name: String, outDir: String) -> Never {
        let presets: [(String, () -> [CanvasElement])] = [
            ("terminal", DevKitPresets.terminalWindow),
            ("browser", DevKitPresets.browserWindow),
            ("database", DevKitPresets.databaseCylinder),
            ("server", DevKitPresets.serverUnit),
            ("badge", { DevKitPresets.statusBadge() }),
            ("apichip", { DevKitPresets.apiChip() }),
            ("keycap", { DevKitPresets.keyCap() }),
            ("sticky", DevKitPresets.todoSticky),
            ("requestflow", DevKitPresets.requestFlowDiagram),
            ("cicd", DevKitPresets.cicdPipeline),
            ("kanban", DevKitPresets.kanbanBoard),
            ("gitflow", DevKitPresets.gitFlow),
        ]
        let selected = name == "all" ? presets : presets.filter { $0.0 == name }
        guard !selected.isEmpty else {
            print("PRESET NOT FOUND: \(name) — available: \(presets.map { $0.0 }.joined(separator: ", "))")
            exit(2)
        }
        let dir = URL(fileURLWithPath: outDir)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        for (presetName, build) in selected {
            let els = build()
            var maxX: Double = 0, maxY: Double = 0
            for el in els { maxX = max(maxX, el.x + el.width); maxY = max(maxY, el.y + el.height) }
            var page = CanvasPage(name: presetName, width: maxX + 80, height: maxY + 80, background: .solid(.white))
            page.elements = els.map { var e = $0; e.x += 40; e.y += 40; return e }
            guard let img = ExportEngine.renderImage(page: page, scale: 1.0),
                  let tiff = img.tiffRepresentation,
                  let rep = NSBitmapImageRep(data: tiff),
                  let png = rep.representation(using: .png, properties: [:]) else {
                print("RENDER FAILED: \(presetName)")
                continue
            }
            let out = dir.appendingPathComponent("\(presetName).png")
            try? png.write(to: out)
            print("rendered \(presetName) (\(els.count) els) → \(out.lastPathComponent)")
        }
        exit(0)
    }

    static func run(path: String, renderDir: String? = nil) -> Never {
        let url = URL(fileURLWithPath: path)
        print("== Import debug: \(url.lastPathComponent)")
        let t0 = CFAbsoluteTimeGetCurrent()
        guard let project = CanvaDocumentImporter.importDocument(from: url) else {
            print("RESULT: FAILED — importer returned nil")
            exit(2)
        }
        let elapsed = CFAbsoluteTimeGetCurrent() - t0
        print("RESULT: ok in \(String(format: "%.2f", elapsed))s — \(project.pages.count) pages, name=\(project.name)")
        for (i, page) in project.pages.enumerated() {
            var images = 0, texts = 0, shapes = 0, drawings = 0, others = 0
            for el in page.elements {
                switch el.payload {
                case .image: images += 1
                case .text: texts += 1
                case .shape: shapes += 1
                case .drawing: drawings += 1
                default: others += 1
                }
            }
            // Bounds sanity: elements outside the page rect indicate layout bugs.
            let outOfBounds = page.elements.filter { el in
                el.x < -page.width * 0.05 || el.y < -page.height * 0.05 ||
                el.x + el.width > page.width * 1.05 || el.y + el.height > page.height * 1.05
            }.count
            print("  page \(i+1) '\(page.name)' \(Int(page.width))x\(Int(page.height)): \(page.elements.count) els (img:\(images) txt:\(texts) shp:\(shapes) drw:\(drawings) oth:\(others)) outOfBounds:\(outOfBounds)")
        }
        if let renderDir = renderDir {
            let dir = URL(fileURLWithPath: renderDir)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let maxPages = min(project.pages.count, 6)
            for i in 0..<maxPages {
                if let img = ExportEngine.renderImage(page: project.pages[i], scale: 0.5),
                   let tiff = img.tiffRepresentation,
                   let rep = NSBitmapImageRep(data: tiff),
                   let png = rep.representation(using: .png, properties: [:]) {
                    try? png.write(to: dir.appendingPathComponent("page_\(i + 1).png"))
                }
            }
            print("RENDERED \(maxPages) pages → \(renderDir)")
        }
        exit(0)
    }

    /// Imports `input` (pptx/pdf/etc.), exports it back to .pptx via ExportEngine,
    /// writes it to `output`, then re-imports the result and reports element
    /// counts — a round-trip sanity check for the importer/exporter pair.
    static func exportPPTX(input: String, output: String) -> Never {
        let inURL = URL(fileURLWithPath: input)
        print("== Export-pptx round-trip: \(inURL.lastPathComponent)")
        guard let project = CanvaDocumentImporter.importDocument(from: inURL) else {
            print("IMPORT FAILED: \(inURL.lastPathComponent)")
            exit(2)
        }
        let inCount = project.pages.reduce(0) { $0 + $1.elements.count }
        print("import1: \(project.pages.count) pages, \(inCount) elements")

        guard let data = ExportEngine.exportPPTX(project: project) else {
            print("EXPORT FAILED: exportPPTX returned nil")
            exit(2)
        }
        let outURL = URL(fileURLWithPath: output)
        do {
            try data.write(to: outURL)
        } catch {
            print("EXPORT FAILED: cannot write \(outURL.path): \(error)")
            exit(2)
        }
        print("exported \(data.count) bytes → \(outURL.path)")

        guard let re = CanvaDocumentImporter.importDocument(from: outURL) else {
            print("REIMPORT FAILED: exported file could not be re-imported")
            exit(2)
        }
        let outCount = re.pages.reduce(0) { $0 + $1.elements.count }
        print("import2: \(re.pages.count) pages, \(outCount) elements")
        exit(0)
    }
}
