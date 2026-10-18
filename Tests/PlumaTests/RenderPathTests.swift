import XCTest
import Combine
@testable import Pluma

/// The canvas re-renders on every `project` publish, so batch edits must
/// publish once, and the per-page paint order must track edits.
@MainActor
final class RenderPathTests: XCTestCase {

    private var storeRoot: URL!
    private var vm: CanvasDocumentViewModel!
    private var bag: Set<AnyCancellable> = []

    override func setUp() async throws {
        storeRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("PlumaRenderTests-\(UUID().uuidString)")
        setenv("PLUMA_STORAGE_ROOT", storeRoot.path, 1)
        vm = CanvasDocumentViewModel()
    }

    override func tearDown() async throws {
        bag.removeAll()
        vm = nil
        try? FileManager.default.removeItem(at: storeRoot)
    }

    private func rect(_ name: String, x: Double = 0, z: Int) -> CanvasElement {
        CanvasElement(name: name, payload: .shape(ShapeContent()), x: x, y: 0, width: 100, height: 100, zIndex: z)
    }

    private func load(_ elements: [CanvasElement], extraPages: Int = 0) {
        var first = CanvasPage(name: "Page 1", width: 1000, height: 800, background: .solid(.white))
        first.elements = elements
        var pages = [first]
        for i in 0..<extraPages {
            var page = CanvasPage(name: "Page \(i + 2)", width: 1000, height: 800, background: .solid(.white))
            page.elements = [rect("P\(i + 2)-B", z: 1), rect("P\(i + 2)-A", z: 0)]
            pages.append(page)
        }
        vm.adoptProject(CanvasProject(name: "Test", pages: pages))
    }

    private func ids(_ names: String...) -> Set<UUID> {
        Set(vm.currentPage.elements.filter { names.contains($0.name) }.map(\.id))
    }

    private func countProjectPublishes(during work: () -> Void) -> Int {
        var count = 0
        vm.$project.dropFirst().sink { _ in count += 1 }.store(in: &bag)
        work()
        bag.removeAll()
        return count
    }

    func testZOrderedElementsSortsAndTracksEdits() {
        load([rect("C", z: 2), rect("A", z: 0), rect("B", z: 1)], extraPages: 1)
        XCTAssertEqual(vm.zOrderedElements(of: vm.currentPage).map(\.name), ["A", "B", "C"])
        XCTAssertEqual(vm.zOrderedElements(of: vm.project.pages[1]).map(\.name), ["P2-A", "P2-B"])

        vm.selectedElementIds = ids("A")
        vm.bringToFront()
        XCTAssertEqual(vm.zOrderedElements(of: vm.currentPage).map(\.name), ["B", "C", "A"])

        // Content edits (not just order) must come through too.
        vm.updateSelectedElement { $0.opacity = 0.5 }
        XCTAssertEqual(vm.zOrderedElements(of: vm.currentPage).last?.opacity, 0.5)
        XCTAssertEqual(vm.zOrderedElements(of: vm.project.pages[1]).map(\.name), ["P2-A", "P2-B"])
    }

    func testGroupAndUngroupPublishOnce() {
        load([rect("A", z: 0), rect("B", z: 1), rect("C", z: 2)])
        vm.selectedElementIds = ids("A", "B", "C")

        XCTAssertEqual(countProjectPublishes { vm.groupSelectedElements() }, 1)
        XCTAssertEqual(Set(vm.currentPage.elements.compactMap(\.groupId)).count, 1)

        XCTAssertEqual(countProjectPublishes { vm.ungroupSelectedElements() }, 1)
        XCTAssertTrue(vm.currentPage.elements.allSatisfy { $0.groupId == nil })
    }

    func testMultiSelectionDragPublishesOncePerTick() {
        load([rect("A", x: 0, z: 0), rect("B", x: 300, z: 1), rect("C", x: 600, z: 2)])
        vm.enableSnapping = false
        vm.selectedElementIds = ids("A", "B", "C")
        let starts = Dictionary(uniqueKeysWithValues: vm.currentPage.elements.map { ($0.id, CGPoint(x: $0.x, y: $0.y)) })

        let publishes = countProjectPublishes {
            vm.dragSelectedElements(by: CGSize(width: 10, height: 5), startPositions: starts)
        }
        XCTAssertEqual(publishes, 1)
        XCTAssertEqual(vm.currentPage.elements.map(\.x).sorted(), [10, 310, 610])
        vm.endDrag()
    }
}
