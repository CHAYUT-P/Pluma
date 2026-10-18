import Foundation

@MainActor
public final class HistoryManager {
    private var undoStack: [CanvasProject] = []
    private var redoStack: [CanvasProject] = []
    private let maxDepth: Int
    /// Memory ceiling for the undo stack — image-heavy decks can otherwise balloon RAM
    /// across a long editing session. Oldest states are evicted first.
    private let maxBytes: Int
    private var estimatedBytes: [Int] = [] // parallel to undoStack
    private var redoBytes: [Int] = []

    public init(maxDepth: Int = 50, maxBytes: Int = 192 * 1024 * 1024) {
        self.maxDepth = maxDepth
        self.maxBytes = maxBytes
    }

    public var canUndo: Bool {
        !undoStack.isEmpty
    }

    public var canRedo: Bool {
        !redoStack.isEmpty
    }

    public func pushState(_ project: CanvasProject) {
        undoStack.append(project)
        estimatedBytes.append(Self.estimateBytes(of: project))
        trimExcess()
        redoStack.removeAll()
        redoBytes.removeAll()
    }

    public func undo(currentProject: CanvasProject) -> CanvasProject? {
        guard let previous = undoStack.popLast() else { return nil }
        _ = estimatedBytes.popLast()
        redoStack.append(currentProject)
        redoBytes.append(Self.estimateBytes(of: currentProject))
        trimExcess()
        return previous
    }

    public func redo(currentProject: CanvasProject) -> CanvasProject? {
        guard let next = redoStack.popLast() else { return nil }
        _ = redoBytes.popLast()
        undoStack.append(currentProject)
        estimatedBytes.append(Self.estimateBytes(of: currentProject))
        trimExcess()
        return next
    }

    public func clear() {
        undoStack.removeAll()
        redoStack.removeAll()
        estimatedBytes.removeAll()
        redoBytes.removeAll()
    }

    /// Evicts oldest undo states while over the depth or byte budget.
    /// Always keeps the most recent state so a single undo always works.
    private func trimExcess() {
        var total = estimatedBytes.reduce(0, +)
        while undoStack.count > maxDepth || (total > maxBytes && undoStack.count > 2) {
            undoStack.removeFirst()
            let removed = estimatedBytes.isEmpty ? 0 : estimatedBytes.removeFirst()
            total -= removed
        }
        var redoTotal = redoBytes.reduce(0, +)
        while redoStack.count > maxDepth || (redoTotal > maxBytes && redoStack.count > 2) {
            redoStack.removeFirst()
            let removed = redoBytes.isEmpty ? 0 : redoBytes.removeFirst()
            redoTotal -= removed
        }
    }

    /// Cheap estimate: element count + image payload lengths (the only heavyweight data).
    static func estimateBytes(of project: CanvasProject) -> Int {
        var bytes = 512
        for page in project.pages {
            bytes += 256
            for el in page.elements {
                bytes += 128
                switch el.payload {
                case .image(let img):
                    bytes += img.imageBase64.utf8.count
                case .text(let t):
                    bytes += t.text.utf8.count + 64
                case .code(let c):
                    bytes += c.code.utf8.count + 64
                case .drawing(let d):
                    bytes += d.points.count * 32
                default:
                    bytes += 64
                }
            }
        }
        return bytes
    }
}
