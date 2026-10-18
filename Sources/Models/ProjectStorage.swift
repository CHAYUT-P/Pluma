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
    /// First page, kept from the metadata decode so cards can render real
    /// thumbnails without re-reading the file from disk.
    public var firstPage: CanvasPage

    public init(id: UUID, name: String, modifiedAt: Date, width: Double, height: Double, pageCount: Int, fileURL: URL, firstPage: CanvasPage) {
        self.id = id
        self.name = name
        self.modifiedAt = modifiedAt
        self.width = width
        self.height = height
        self.pageCount = pageCount
        self.fileURL = fileURL
        self.firstPage = firstPage
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
    @Published public var trashedProjects: [SavedProjectSummary] = []

    private var autosaveTask: Task<Void, Never>? = nil
    /// Project a pending debounced save would write — lets trashing cancel it
    /// instead of resurrecting the file back into Projects/.
    private var pendingAutosaveId: UUID? = nil
    /// Tombstone set — ids currently in Trash (or permanently deleted this
    /// session). ALL write paths refuse these ids: a trashed project must not
    /// resurrect into Projects/ via a late autosave, an explicit save, or the
    /// willTerminate flush. Cleared only by restoreProject().
    private var trashedIds: Set<UUID> = []

    /// Application Support can theoretically fail to resolve (corrupt
    /// environment, non-standard homedir) — fall back to the conventional
    /// path instead of crashing every save/load.
    private static var appSupportDirectory: URL {
        // Dev/test isolation: point the whole store at a scratch folder so
        // automated runs never touch the user's real projects.
        if let override = ProcessInfo.processInfo.environment["PLUMA_STORAGE_ROOT"], !override.isEmpty {
            return URL(fileURLWithPath: override, isDirectory: true)
        }
        if let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            return dir
        }
        return FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support", isDirectory: true)
    }

    private var storageDirectory: URL {
        let dir = Self.appSupportDirectory.appendingPathComponent("CanvaNative/Projects", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private var trashDirectory: URL {
        let dir = Self.appSupportDirectory.appendingPathComponent("CanvaNative/Trash", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    public init() {
        reloadProjects()
        reloadTrash()
        if savedProjects.isEmpty {
            createInitialSampleProjects()
        }
    }

    private func loadSummaries(from directory: URL) -> [SavedProjectSummary] {
        guard let files = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.contentModificationDateKey]) else {
            return []
        }

        var summaries: [SavedProjectSummary] = []

        for file in files where file.pathExtension == "canv" {
            guard let data = try? Data(contentsOf: file) else {
                NSLog("ProjectStorage: unreadable project file %@", file.lastPathComponent)
                continue
            }
            do {
                let project = try CanvasProject.decode(from: data)
                let firstPage = project.pages.first ?? CanvasPage(background: .solid(.white))
                summaries.append(SavedProjectSummary(
                    id: project.id,
                    name: project.name,
                    modifiedAt: project.modifiedAt,
                    width: firstPage.width,
                    height: firstPage.height,
                    pageCount: project.pages.count,
                    fileURL: file,
                    firstPage: firstPage
                ))
            } catch {
                // Log instead of silently dropping — a project that fails to
                // decode must be diagnosable, not invisible.
                NSLog("ProjectStorage: skipping %@ — decode failed: %@", file.lastPathComponent, "\(error)")
                continue
            }
        }

        return summaries.sorted { $0.modifiedAt > $1.modifiedAt }
    }

    public func reloadProjects() {
        self.savedProjects = loadSummaries(from: storageDirectory)
    }

    public func reloadTrash() {
        let loaded = loadSummaries(from: trashDirectory)
        self.trashedProjects = loaded
        // Rebuild the tombstone from what's actually on disk, keeping any ids
        // permanently deleted this session — their writes must stay refused
        // even though no file remains to list.
        trashedIds.formUnion(loaded.map(\.id))
    }

    /// Serializes all `.canv` writes and coalesces pending snapshots per
    /// project — the OLD fire-and-forget detached tasks let a stale debounced
    /// snapshot land AFTER a newer explicit save and win.
    private actor FileWriter {
        private var pending: [UUID: CanvasProject] = [:]
        private var cancelled: Set<UUID> = []
        /// Trashed ids — actor-side tombstone. enqueue() runs on a detached
        /// task scheduled BEFORE the trash may still land after cancel(); only
        /// an actor-side check closes that race. Cleared by unblock().
        private var blocked: Set<UUID> = []
        private var running = false

        func enqueue(_ project: CanvasProject, in dir: URL) async {
            guard !blocked.contains(project.id) else { return }
            // A fresh save for a previously-cancelled id re-arms it.
            cancelled.remove(project.id)
            pending[project.id] = project
            guard !running else { return }
            running = true
            while let (id, snapshot) = pending.first {
                pending[id] = nil
                let file = dir.appendingPathComponent("\(id.uuidString).canv")
                if cancelled.remove(id) != nil { continue }
                if let data = try? snapshot.encodeToData() {
                    try? data.write(to: file, options: .atomic)
                    // Cancel raced the in-flight write — don't let the file
                    // resurrect back into Projects/ after the move to Trash.
                    if cancelled.remove(id) != nil {
                        try? FileManager.default.removeItem(at: file)
                    }
                }
            }
            running = false
        }

        /// Drops a queued-but-unwritten snapshot AND marks in-flight writes for
        /// post-write deletion (e.g. its project was trashed).
        func cancel(_ id: UUID) {
            pending[id] = nil
            cancelled.insert(id)
        }

        /// cancel + a persistent block — nothing for this id writes again
        /// until unblock() (restore). One actor message, so a racing enqueue
        /// can never slip between the two steps.
        func block(_ id: UUID) {
            pending[id] = nil
            cancelled.insert(id)
            blocked.insert(id)
        }

        func unblock(_ id: UUID) {
            blocked.remove(id)
        }
    }
    private let fileWriter = FileWriter()

    // High-performance debounced background autosave (Zero lag on mouse drag / resize)
    public func saveProjectDebounced(_ project: CanvasProject) {
        guard !trashedIds.contains(project.id) else { return }
        autosaveTask?.cancel()
        pendingAutosaveId = project.id
        autosaveTask = Task.detached(priority: .utility) { [weak self] in
            try? await Task.sleep(nanoseconds: 800_000_000) // 800ms debounce
            guard !Task.isCancelled, let self = self else { return }
            await self.fileWriter.enqueue(project, in: self.storageDirectory)
        }
    }

    public func saveProject(_ project: CanvasProject) {
        guard !trashedIds.contains(project.id) else { return }
        // An explicit save supersedes any pending debounced snapshot.
        autosaveTask?.cancel()
        pendingAutosaveId = project.id
        let dir = storageDirectory
        Task.detached(priority: .utility) { [fileWriter] in
            await fileWriter.enqueue(project, in: dir)
        }
    }

    /// Synchronous write for app termination — the async writer would race
    /// process exit, so this goes straight to disk on the calling thread.
    public func saveProjectNow(_ project: CanvasProject) {
        guard !trashedIds.contains(project.id) else { return }
        autosaveTask?.cancel()
        pendingAutosaveId = nil
        writeProjectNow(project)
    }

    /// Blocking write for callers that immediately re-read the directory
    /// (duplicate, initial samples) — going through the async writer would
    /// race the reload and make the new file invisible until next reload.
    private func writeProjectNow(_ project: CanvasProject) {
        guard !trashedIds.contains(project.id) else { return }
        let file = storageDirectory.appendingPathComponent("\(project.id.uuidString).canv")
        if let data = try? project.encodeToData() {
            try? data.write(to: file, options: .atomic)
        }
    }

    public func loadProject(id: UUID) -> CanvasProject? {
        let file = storageDirectory.appendingPathComponent("\(id.uuidString).canv")
        guard let data = try? Data(contentsOf: file) else { return nil }
        do {
            return try CanvasProject.decode(from: data)
        } catch {
            NSLog("ProjectStorage: %@.canv failed to decode: %@", id.uuidString, "\(error)")
            return nil
        }
    }

    /// Cancels the main-side pending debounce for `id`.
    private func cancelAutosave(for id: UUID) {
        if pendingAutosaveId == id {
            autosaveTask?.cancel()
            pendingAutosaveId = nil
        }
    }

    /// Tombstones `id` on every layer that could still write it: the pending
    /// debounce task, the FileWriter's queue/in-flight write, and the actor's
    /// `blocked` set (a detached save scheduled just before trashing must not
    /// re-arm past cancel()).
    private func discardPendingSave(for id: UUID) {
        cancelAutosave(for: id)
        Task { await fileWriter.block(id) }
    }

    /// If a detached write landed in Projects/ between our block dispatch and
    /// the move, it sits at `src` now — remove it so nothing resurrects.
    private func sweepResurrectedFile(at src: URL) {
        if FileManager.default.fileExists(atPath: src.path) {
            try? FileManager.default.removeItem(at: src)
        }
    }

    /// Moves a project to Trash (recoverable until "Delete Forever").
    public func deleteProject(id: UUID) {
        discardPendingSave(for: id)
        trashedIds.insert(id)   // block any later writes before the move lands
        let src = storageDirectory.appendingPathComponent("\(id.uuidString).canv")
        let dst = trashDirectory.appendingPathComponent("\(id.uuidString).canv")
        try? FileManager.default.moveItem(at: src, to: dst)
        sweepResurrectedFile(at: src)
        reloadProjects()
        reloadTrash()
    }

    public func deleteProjects(ids: Set<UUID>) {
        for id in ids {
            discardPendingSave(for: id)
            trashedIds.insert(id)
            let src = storageDirectory.appendingPathComponent("\(id.uuidString).canv")
            let dst = trashDirectory.appendingPathComponent("\(id.uuidString).canv")
            try? FileManager.default.moveItem(at: src, to: dst)
            sweepResurrectedFile(at: src)
        }
        reloadProjects()
        reloadTrash()
    }

    /// Restores a trashed project back into the library — the only path that
    /// clears an id's write block.
    public func restoreProject(id: UUID) {
        // Cancel a stale debounce, but do NOT dispatch block() — the unblock
        // below must not race a later-arriving block and stay blocked forever.
        cancelAutosave(for: id)
        let src = trashDirectory.appendingPathComponent("\(id.uuidString).canv")
        let dst = storageDirectory.appendingPathComponent("\(id.uuidString).canv")
        do {
            try FileManager.default.moveItem(at: src, to: dst)
            // Ungate only after the move — if it failed, the project is still
            // in Trash and writes must stay blocked.
            trashedIds.remove(id)
            Task { await fileWriter.unblock(id) }
        } catch {
            NSLog("ProjectStorage: restore of %@ failed: %@", id.uuidString, "\(error)")
        }
        reloadProjects()
        reloadTrash()
    }

    /// Permanently deletes a trashed project file — not recoverable.
    public func deletePermanently(id: UUID) {
        let file = trashDirectory.appendingPathComponent("\(id.uuidString).canv")
        try? FileManager.default.removeItem(at: file)
        reloadTrash()
    }

    public func emptyTrash() {
        guard let files = try? FileManager.default.contentsOfDirectory(at: trashDirectory, includingPropertiesForKeys: nil) else { return }
        for file in files where file.pathExtension == "canv" {
            try? FileManager.default.removeItem(at: file)
        }
        reloadTrash()
    }

    public func duplicateProject(id: UUID) -> CanvasProject? {
        guard var project = loadProject(id: id) else { return nil }
        project.id = UUID()
        project.name = "\(project.name) Copy"
        project.modifiedAt = Date()
        writeProjectNow(project)
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
        writeProjectNow(proj1)

        // 2. Code Snippet Card
        var codePage = CanvasPage(name: "Code Card", width: 1200, height: 675, background: .solid(.white))
        codePage.elements.append(CanvasElement(
            name: "Code Block",
            payload: .code(CodeContent()),
            x: 250, y: 135, width: 700, height: 400,
            shadow: ShadowEffect.elevated
        ))
        let proj2 = CanvasProject(name: "Code Snippet Card", pages: [codePage])
        writeProjectNow(proj2)

        reloadProjects()
    }
}
