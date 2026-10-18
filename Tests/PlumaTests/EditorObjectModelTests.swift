import XCTest
@testable import Pluma

/// Behavioural tests for the editor's object system (selection, z-order,
/// clipboard, alignment, pages, undo). Storage is redirected to a temp folder
/// so autosaves never touch the user's real projects.
@MainActor
final class EditorObjectModelTests: XCTestCase {

    private var storeRoot: URL!
    private var vm: CanvasDocumentViewModel!

    override func setUp() async throws {
        storeRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("PlumaEditorTests-\(UUID().uuidString)")
        setenv("PLUMA_STORAGE_ROOT", storeRoot.path, 1)
        vm = CanvasDocumentViewModel()
    }

    override func tearDown() async throws {
        vm = nil
        try? FileManager.default.removeItem(at: storeRoot)
    }

    // MARK: - Helpers

    private func rect(_ name: String, x: Double = 0, y: Double = 0, w: Double = 100, h: Double = 100,
                      z: Int, group: UUID? = nil, locked: Bool = false) -> CanvasElement {
        CanvasElement(name: name, payload: .shape(ShapeContent()), x: x, y: y, width: w, height: h,
                      isLocked: locked, zIndex: z, groupId: group)
    }

    private func load(_ elements: [CanvasElement], pages extra: Int = 0) {
        var first = CanvasPage(name: "Page 1", width: 1000, height: 800, background: .solid(.white))
        first.elements = elements
        var pages = [first]
        for i in 0..<extra {
            pages.append(CanvasPage(name: "Page \(i + 2)", width: 1000, height: 800, background: .solid(.white)))
        }
        vm.adoptProject(CanvasProject(name: "Test", pages: pages))
    }

    private var stackOrder: [String] {
        vm.currentPage.elements.sorted { $0.zIndex < $1.zIndex }.map(\.name)
    }

    private func ids(_ names: String...) -> Set<UUID> {
        Set(vm.currentPage.elements.filter { names.contains($0.name) }.map(\.id))
    }

    private func element(_ name: String) -> CanvasElement {
        vm.currentPage.elements.first { $0.name == name }!
    }

    // MARK: - Z-order

    func testBringForwardMovesMultiSelectionAsBlock() {
        load([rect("A", z: 0), rect("B", z: 1), rect("C", z: 2), rect("D", z: 3)])
        vm.selectedElementIds = ids("A", "B")
        vm.bringForward()
        XCTAssertEqual(stackOrder, ["C", "A", "B", "D"])
    }

    func testSendBackwardMovesMultiSelectionAsBlock() {
        load([rect("A", z: 0), rect("B", z: 1), rect("C", z: 2), rect("D", z: 3)])
        vm.selectedElementIds = ids("C", "D")
        vm.sendBackward()
        XCTAssertEqual(stackOrder, ["A", "C", "D", "B"])
    }

    func testBringToFrontKeepsRelativeOrder() {
        load([rect("A", z: 0), rect("B", z: 1), rect("C", z: 2), rect("D", z: 3)])
        vm.selectedElementIds = ids("A", "C")
        vm.bringToFront()
        XCTAssertEqual(stackOrder, ["B", "D", "A", "C"])
    }

    func testReorderAtTopIsNoOpWithoutUndoStep() {
        load([rect("A", z: 0), rect("B", z: 1)])
        vm.selectedElementIds = ids("B")
        vm.bringForward()
        XCTAssertFalse(vm.historyManager.canUndo)
    }

    // MARK: - Duplicate & clipboard

    func testDuplicatePreservesStackingOrder() {
        load([rect("Back", z: 0), rect("Front", z: 1)])
        vm.selectedElementIds = ids("Back", "Front")
        vm.duplicateSelected()
        let copies = vm.currentPage.elements.filter { vm.selectedElementIds.contains($0.id) }
            .sorted { $0.zIndex < $1.zIndex }.map(\.name)
        XCTAssertEqual(copies, ["Back Copy", "Front Copy"])
    }

    func testRepeatedPasteStepsOffset() {
        load([rect("A", x: 100, y: 100, z: 0)])
        vm.selectedElementIds = ids("A")
        vm.copySelected()
        vm.paste()
        let first = vm.primarySelectedElement!
        vm.paste()
        let second = vm.primarySelectedElement!
        XCTAssertEqual(first.x, 130)
        XCTAssertEqual(second.x, 160)
    }

    // MARK: - Locks

    func testDeleteAllLockedRecordsNoUndo() {
        load([rect("L", z: 0, locked: true)])
        vm.selectedElementIds = ids("L")
        vm.deleteSelected()
        XCTAssertEqual(vm.currentPage.elements.count, 1)
        XCTAssertFalse(vm.historyManager.canUndo)
    }

    func testFlipSkipsLockedElements() {
        load([rect("L", z: 0, locked: true)])
        vm.selectedElementIds = ids("L")
        vm.flipSelected(horizontal: true)
        XCTAssertFalse(element("L").isFlippedH)
    }

    func testSelectAllIgnoresHidden() {
        var hidden = rect("H", z: 1)
        hidden.isVisible = false
        load([rect("A", z: 0), hidden])
        vm.selectAll()
        XCTAssertEqual(vm.selectedElementIds, ids("A"))
    }

    // MARK: - Alignment

    func testAlignKeepsGroupsRigid() {
        let g = UUID()
        load([
            rect("G1", x: 100, y: 0, w: 50, z: 0, group: g),
            rect("G2", x: 200, y: 0, w: 50, z: 1, group: g),
            rect("S", x: 500, y: 300, w: 50, z: 2),
        ])
        vm.selectedElementIds = ids("G1", "G2", "S")
        vm.alignSelected(.left)
        // Group keeps its internal 100pt spacing; S joins the left edge.
        XCTAssertEqual(element("G1").x, 100)
        XCTAssertEqual(element("G2").x, 200)
        XCTAssertEqual(element("S").x, 100)
    }

    func testAlignLeavesLockedElementsInPlace() {
        load([rect("A", x: 10, z: 0), rect("B", x: 300, z: 1, locked: true), rect("C", x: 600, z: 2)])
        vm.selectedElementIds = ids("A", "B", "C")
        vm.alignSelected(.right)
        XCTAssertEqual(element("B").x, 300)
        XCTAssertEqual(element("A").x, 600)
    }

    // MARK: - Inspector undo coalescing

    func testInspectorEditsAreUndoable() {
        load([rect("A", x: 0, z: 0)])
        vm.selectedElementIds = ids("A")
        // A burst of slider ticks → one undo step.
        for i in 1...10 { vm.updateSelectedElement { $0.x = Double(i) } }
        XCTAssertEqual(element("A").x, 10)
        vm.undo()
        XCTAssertEqual(element("A").x, 0)
        XCTAssertFalse(vm.historyManager.canUndo)
    }

    func testUndoKeepsSurvivingSelection() {
        load([rect("A", z: 0)])
        vm.selectedElementIds = ids("A")
        vm.updateSelectedElement { $0.x = 50 }
        vm.undo()
        XCTAssertEqual(vm.selectedElementIds, ids("A"))
    }

    // MARK: - Pages

    func testUndoAddPageClampsActiveIndex() {
        load([rect("A", z: 0)], pages: 1)
        vm.activePageIndex = 1
        vm.addPage()
        XCTAssertEqual(vm.activePageIndex, 2)
        vm.undo()
        XCTAssertEqual(vm.project.pages.count, 2)
        XCTAssertLessThan(vm.activePageIndex, vm.project.pages.count)
    }

    func testMovePageFollowsActivePage() {
        load([], pages: 2)
        vm.activePageIndex = 1
        let activeId = vm.currentPage.id
        vm.movePage(from: 0, to: 2)
        XCTAssertEqual(vm.currentPage.id, activeId)
        XCTAssertTrue(vm.historyManager.canUndo)
    }

    func testDuplicatePageRemapsConnectors() {
        let a = rect("A", z: 0), b = rect("B", x: 300, z: 1)
        var arrow = rect("Arrow", z: 2)
        arrow.connector = ConnectorInfo(fromID: a.id, toID: b.id)
        load([a, b, arrow])
        vm.duplicatePage(at: 0)
        let copy = vm.project.pages[1]
        let copyIds = Set(copy.elements.map(\.id))
        let conn = copy.elements.first { $0.name == "Arrow" }!.connector!
        XCTAssertTrue(copyIds.contains(conn.fromID))
        XCTAssertTrue(copyIds.contains(conn.toID))
    }

    func testSwitchingPagesDropsForeignSelection() {
        load([rect("A", z: 0)], pages: 1)
        vm.selectedElementIds = ids("A")
        vm.activePageIndex = 1
        XCTAssertTrue(vm.selectedElementIds.isEmpty)
    }

    // MARK: - Snapping

    func testDragSnapsSelectionBoxEdgeToNeighbour() {
        load([rect("A", x: 0, y: 300, w: 100, z: 0), rect("B", x: 200, y: 300, w: 100, z: 1)])
        vm.setZoom(1.0)
        vm.selectedElementIds = ids("A")
        // A's right edge lands at 197 — within 6pt of B's left edge (200).
        vm.dragSelectedElements(by: CGSize(width: 97, height: 0), startPositions: [element("A").id: CGPoint(x: 0, y: 300)])
        vm.endDrag()
        XCTAssertEqual(element("A").x, 100, accuracy: 0.001)
    }

    func testSnapThresholdScalesWithZoom() {
        load([rect("A", x: 0, y: 300, w: 100, z: 0), rect("B", x: 200, y: 300, w: 100, z: 1)])
        vm.setZoom(4.0) // 6 screen pt = 1.5 canvas units → a 3-unit gap must NOT snap
        vm.selectedElementIds = ids("A")
        vm.dragSelectedElements(by: CGSize(width: 97, height: 0), startPositions: [element("A").id: CGPoint(x: 0, y: 300)])
        vm.endDrag()
        XCTAssertEqual(element("A").x, 97, accuracy: 0.001)
    }

    // MARK: - Zoom

    func testZoomStepsFollowLadder() {
        load([])
        vm.setZoom(0.5)
        vm.zoomIn()
        XCTAssertEqual(vm.zoomScale, 0.67, accuracy: 0.001)
        vm.zoomOut()
        XCTAssertEqual(vm.zoomScale, 0.5, accuracy: 0.001)
    }
}
