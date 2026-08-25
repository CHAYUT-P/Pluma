import Foundation
import SwiftUI
import AppKit

public struct SavedProjectSummary: Identifiable, Equatable {
    public var id: UUID
    public var name: String
    public var modifiedAt: Date
    public var width: Double
    public var height: Double
    public var pageCount: Int
    public var fileURL: URL

    public init(id: UUID, name: String, modifiedAt: Date, width: Double, height: Double, pageCount: Int, fileURL: URL) {
        self.id = id
        self.name = name
        self.modifiedAt = modifiedAt
        self.width = width
        self.height = height
        self.pageCount = pageCount
        self.fileURL = fileURL
    }

    public var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: modifiedAt, relativeTo: Date())
    }

    public var dimensionsString: String {
        "\(Int(width)) × \(Int(height)) px"
    }
}

@MainActor
public final class ProjectStorage: ObservableObject {
    public static let shared = ProjectStorage()

    @Published public var savedProjects: [SavedProjectSummary] = []

    private var autosaveTask: Task<Void, Never>? = nil

    private var storageDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("CanvaNative/Projects", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    public init() {
        reloadProjects()
        if savedProjects.isEmpty {
            createInitialSampleProjects()
        }
    }

    public func reloadProjects() {
        guard let files = try? FileManager.default.contentsOfDirectory(at: storageDirectory, includingPropertiesForKeys: [.contentModificationDateKey]) else {
            return
        }

        var summaries: [SavedProjectSummary] = []

        for file in files where file.pathExtension == "canv" {
            guard let data = try? Data(contentsOf: file),
                  let project = try? CanvasProject.decode(from: data) else {
                continue
            }

            let firstPage = project.pages.first ?? CanvasPage(background: .solid(.white))
            summaries.append(SavedProjectSummary(
                id: project.id,
                name: project.name,
                modifiedAt: project.modifiedAt,
                width: firstPage.width,
                height: firstPage.height,
                pageCount: project.pages.count,
                fileURL: file
            ))
        }

        self.savedProjects = summaries.sorted { $0.modifiedAt > $1.modifiedAt }
    }

    // High-performance debounced background autosave (Zero lag on mouse drag / resize)
    public func saveProjectDebounced(_ project: CanvasProject) {
        autosaveTask?.cancel()
        autosaveTask = Task.detached(priority: .utility) { [weak self] in
            try? await Task.sleep(nanoseconds: 800_000_000) // 800ms debounce
            guard let self = self else { return }
            await self.saveProjectAsync(project)
        }
    }

    public func saveProject(_ project: CanvasProject) {
        saveProjectAsync(project)
    }

    private func saveProjectAsync(_ project: CanvasProject) {
        let dir = storageDirectory
        Task.detached(priority: .utility) {
            let file = dir.appendingPathComponent("\(project.id.uuidString).canv")
            if let data = try? project.encodeToData() {
                try? data.write(to: file, options: .atomic)
            }
        }
    }

    public func loadProject(id: UUID) -> CanvasProject? {
        let file = storageDirectory.appendingPathComponent("\(id.uuidString).canv")
        guard let data = try? Data(contentsOf: file) else { return nil }
        return try? CanvasProject.decode(from: data)
    }

    public func deleteProject(id: UUID) {
        let file = storageDirectory.appendingPathComponent("\(id.uuidString).canv")
        try? FileManager.default.removeItem(at: file)
        reloadProjects()
    }

    public func deleteProjects(ids: Set<UUID>) {
        for id in ids {
            let file = storageDirectory.appendingPathComponent("\(id.uuidString).canv")
            try? FileManager.default.removeItem(at: file)
        }
        reloadProjects()
    }

    public func duplicateProject(id: UUID) -> CanvasProject? {
        guard var project = loadProject(id: id) else { return nil }
        project.id = UUID()
        project.name = "\(project.name) Copy"
        project.modifiedAt = Date()
        saveProject(project)
        reloadProjects()
        return project
    }

    private func createInitialSampleProjects() {
        // 1. Clean Solid White Starter Canvas
        var blankPage = CanvasPage(name: "Blank Canvas", width: 1080, height: 1080, background: .solid(.white))
        blankPage.elements.append(CanvasElement(
            name: "Heading",
            payload: .text(TextContent(text: "Design Beautifully", fontFamily: "Playfair Display", fontSize: 46, fontWeight: 700, alignment: .center)),
            x: 240, y: 380, width: 600, height: 70
        ))
        blankPage.elements.append(CanvasElement(
            name: "Subtitle",
            payload: .text(TextContent(text: "Native macOS canvas • 120 FPS ProMotion • 40MB RAM", fontFamily: "Georgia", fontSize: 18, fontWeight: 400, alignment: .center, textColor: CodableColor(hex: "#6B7280"))),
            x: 240, y: 460, width: 600, height: 40
        ))
        let proj1 = CanvasProject(name: "Clean White Canvas", pages: [blankPage])
        saveProject(proj1)

        // 2. Code Snippet Card
        var codePage = CanvasPage(name: "Code Card", width: 1200, height: 675, background: .solid(.white))
        codePage.elements.append(CanvasElement(
            name: "Code Block",
            payload: .code(CodeContent()),
            x: 250, y: 135, width: 700, height: 400,
            shadow: ShadowEffect.elevated
        ))
        let proj2 = CanvasProject(name: "Code Snippet Card", pages: [codePage])
        saveProject(proj2)

        reloadProjects()
    }
}
