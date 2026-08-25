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
                        projectStorage.saveProject(activeViewModel.project)
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
            .onChange(of: activeProject) { oldVal, newVal in
                if let project = newVal {
                    activeViewModel.project = project
                    activeViewModel.activePageIndex = 0
                    activeViewModel.selectedElementIds.removeAll()
                }
            }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Home / Projects") {
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
                    activeViewModel.undo()
                }
                .keyboardShortcut("z", modifiers: .command)

                Button("Redo") {
                    activeViewModel.redo()
                }
                .keyboardShortcut("z", modifiers: [.command, .shift])
            }

            CommandGroup(replacing: .pasteboard) {
                Button("Cut") {
                    activeViewModel.copySelected()
                    activeViewModel.deleteSelected()
                }
                .keyboardShortcut("x", modifiers: .command)

                Button("Copy") {
                    activeViewModel.copySelected()
                }
                .keyboardShortcut("c", modifiers: .command)

                Button("Paste") {
                    activeViewModel.paste()
                }
                .keyboardShortcut("v", modifiers: .command)

                Button("Duplicate") {
                    activeViewModel.duplicateSelected()
                }
                .keyboardShortcut("d", modifiers: .command)

                Button("Delete") {
                    activeViewModel.deleteSelected()
                }
                .keyboardShortcut(.delete, modifiers: [])

                Button("Select All") {
                    activeViewModel.selectAll()
                }
                .keyboardShortcut("a", modifiers: .command)

                Divider()

                Button("Copy as Image") {
                    activeViewModel.copyPageImageToClipboard()
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
            }

            CommandMenu("Arrange") {
                Button("Bring to Front") {
                    NotificationCenter.default.post(name: .bringToFront, object: nil)
                }
                .keyboardShortcut("]", modifiers: [.command, .option])

                Button("Bring Forward") {
                    NotificationCenter.default.post(name: .bringForward, object: nil)
                }
                .keyboardShortcut("]", modifiers: .command)

                Button("Send Backward") {
                    NotificationCenter.default.post(name: .sendBackward, object: nil)
                }
                .keyboardShortcut("[", modifiers: .command)

                Button("Send to Back") {
                    NotificationCenter.default.post(name: .sendToBack, object: nil)
                }
                .keyboardShortcut("[", modifiers: [.command, .option])
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

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

extension Notification.Name {
    static let duplicateElement = Notification.Name("duplicateElement")
    static let copyImageToClipboard = Notification.Name("copyImageToClipboard")
    static let bringToFront = Notification.Name("bringToFront")
    static let bringForward = Notification.Name("bringForward")
    static let sendBackward = Notification.Name("sendBackward")
    static let sendToBack = Notification.Name("sendToBack")
    static let showExportModal = Notification.Name("showExportModal")
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
        let page = tpl.pages.first ?? tpl.page
        guard let img = ExportEngine.renderImage(page: page, scale: min(1.0, 900.0 / max(1, page.width))),
              let tiff = img.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else {
            print("RENDER FAILED")
            exit(3)
        }
        try? png.write(to: URL(fileURLWithPath: out))
        print("rendered \(tpl.title) → \(out)")
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
}
