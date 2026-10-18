import XCTest
@testable import Pluma

/// Fixture-based tests for the PPTX importer — the most intricate subsystem.
/// Fixtures are built on the fly with /usr/bin/zip (always present — the
/// importer itself shells out to /usr/bin/unzip).
final class PPTXImporterTests: XCTestCase {

    // MARK: - Fixture plumbing

    private var tempRoot: URL!

    override func setUp() {
        super.setUp()
        tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("PlumaTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempRoot)
        super.tearDown()
    }

    /// Writes `files` (path → XML string) into a staging dir, zips it into a
    /// .pptx, and returns the archive URL. `symlinks` stages symlink entries
    /// (zip -y preserves them — unzip restores them, exercising the
    /// importer's containment checks).
    private func makePPTX(named name: String, files: [String: String],
                          symlinks: [String: URL] = [:]) throws -> URL {
        let stage = tempRoot.appendingPathComponent(name)
        for (rel, xml) in files {
            let f = stage.appendingPathComponent(rel)
            try FileManager.default.createDirectory(
                at: f.deletingLastPathComponent(), withIntermediateDirectories: true)
            try xml.write(to: f, atomically: true, encoding: .utf8)
        }
        for (rel, dest) in symlinks {
            let f = stage.appendingPathComponent(rel)
            try FileManager.default.createDirectory(
                at: f.deletingLastPathComponent(), withIntermediateDirectories: true)
            try FileManager.default.createSymbolicLink(at: f, withDestinationURL: dest)
        }
        let zip = tempRoot.appendingPathComponent("\(name).pptx")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        process.arguments = ["-qry", zip.path, "."]
        process.currentDirectoryURL = stage
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()
        XCTAssertEqual(process.terminationStatus, 0, "zip failed for \(name)")
        return zip
    }

    /// Minimal scaffold: presentation.xml + rels + the given slides.
    /// `slideIds` lists (sldId order, rId, filename) — presentation order can
    /// differ from filename order to exercise the p:sldIdLst path.
    private func scaffold(
        slides: [(xml: String, file: String)],
        order: [Int]? = nil
    ) -> [String: String] {
        var files: [String: String] = [:]
        var sldIds = ""
        var rels = ""
        let ord = order ?? Array(slides.indices)
        for (seq, slideIdx) in ord.enumerated() {
            sldIds += "<p:sldId id=\"\(256 + seq)\" r:id=\"rIdS\(slideIdx)\"/>"
            rels += "<Relationship Id=\"rIdS\(slideIdx)\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide\" Target=\"slides/\(slides[slideIdx].file)\"/>"
        }
        for s in slides {
            files["ppt/slides/\(s.file)"] = s.xml
        }
        files["ppt/presentation.xml"] = """
            <?xml version="1.0"?><p:presentation xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><p:sldSz cx="12192000" cy="6858000"/><p:sldIdLst>\(sldIds)</p:sldIdLst></p:presentation>
            """
        files["ppt/_rels/presentation.xml.rels"] = """
            <?xml version="1.0"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\(rels)</Relationships>
            """
        return files
    }

    private func slideXML(body: String) -> String {
        """
        <?xml version="1.0"?><p:sld xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><p:cSld><p:spTree>\(body)</p:spTree></p:cSld></p:sld>
        """
    }

    private func tableXML(rows: [[String]]) -> String {
        // rows: array of tc-attr lists, e.g. ["", "gridSpan=\"2\"", "hMerge=\"1\"", ""]
        let cols = rows[0].count
        let grid = (0..<cols).map { _ in "<a:gridCol w=\"1000000\"/>" }.joined()
        var trs = ""
        for row in rows {
            var tcs = ""
            for (i, attr) in row.enumerated() {
                let a = attr.isEmpty ? "" : " \(attr)"
                tcs += "<a:tc\(a)><a:txBody><a:bodyPr/><a:p><a:r><a:t>C\(i)</a:t></a:r></a:p></a:txBody><a:tcPr/></a:tc>"
            }
            trs += "<a:tr h=\"500000\">\(tcs)</a:tr>"
        }
        return """
            <p:graphicFrame><p:nvGraphicFramePr><p:cNvPr id="5" name="t"/><p:cNvGraphicFramePr/><p:nvPr/></p:nvGraphicFramePr><p:xfrm><a:off x="0" y="0"/><a:ext cx="\(cols * 1000000)" cy="\(rows.count * 500000)"/></p:xfrm><a:graphic><a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/table"><a:tbl><a:tblGrid>\(grid)</a:tblGrid>\(trs)</a:tbl></a:graphicData></a:graphic></p:graphicFrame>
            """
    }

    private func countElements(_ project: CanvasProject?, page: Int = 0) -> Int {
        project?.pages[page].elements.count ?? -1
    }

    // MARK: - The reported bug + regressions

    /// Reviewer's exact case: [A1][master gridSpan=2][hMerge][D1] — the cell
    /// after a horizontal merge must not be dropped.
    func testTableCellAfterHorizontalMergeIsKept() throws {
        let slide = slideXML(body: tableXML(rows: [
            ["", "gridSpan=\"2\"", "hMerge=\"1\"", ""],
            ["", "", "", ""],
        ]))
        let url = try makePPTX(named: "merge", files: scaffold(slides: [(slide, "slide1.xml")]))
        let project = CanvaDocumentImporter.importDocument(from: url)
        // 7 visible cells × (rect + text) = 14 — the old code produced 12.
        XCTAssertEqual(countElements(project), 14)
    }

    /// A text shape with geometry — `parseShape` drops shapes lacking xfrm.
    private func textShapeXML(_ paragraphs: String, name: String = "s") -> String {
        """
        <p:sp><p:nvSpPr><p:cNvPr id="2" name="\(name)"/><p:cNvSpPr/><p:nvPr/></p:nvSpPr><p:spPr><a:xfrm><a:off x="914400" y="914400"/><a:ext cx="5486400" cy="2743200"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></p:spPr><p:txBody><a:bodyPr/>\(paragraphs)</p:txBody></p:sp>
        """
    }

    /// Malformed startAt values crashed the import (UInt8 trap / roman loop).
    func testAutoNumStartAtCannotCrash() throws {
        let slide = slideXML(body: textShapeXML("""
            <a:p><a:pPr><a:buAutoNum type="alphaLcPeriod" startAt="1000000"/></a:pPr><a:r><a:t>a</a:t></a:r></a:p><a:p><a:pPr><a:buAutoNum type="romanUcPeriod" startAt="-9223372036854775808"/></a:pPr><a:r><a:t>b</a:t></a:r></a:p><a:p><a:pPr><a:buAutoNum type="alphaUcPeriod" startAt="200"/></a:pPr><a:r><a:t>c</a:t></a:r></a:p><a:p><a:pPr><a:buAutoNum type="alphaLcPeriod" startAt="27"/></a:pPr><a:r><a:t>d</a:t></a:r></a:p>
            """))
        let url = try makePPTX(named: "startat", files: scaffold(slides: [(slide, "slide1.xml")]))
        let project = CanvaDocumentImporter.importDocument(from: url)
        XCTAssertEqual(countElements(project), 1)
        guard case .text(let t)? = project?.pages[0].elements.first?.payload else {
            return XCTFail("expected text element")
        }
        XCTAssertTrue(t.text.contains("eqxd."), "alpha>26 should wrap base-26, got \(t.text)")
        XCTAssertTrue(t.text.contains("I."), "clamped roman")
        XCTAssertTrue(t.text.contains("aa."), "startAt=27 → aa")
    }

    /// p:sldIdLst order must win over filename order.
    func testSlideOrderFollowsSldIdLst() throws {
        let s1 = slideXML(body: textShapeXML("<a:p><a:r><a:t>FIRST_BY_LIST</a:t></a:r></a:p>", name: "a"))
        let s2 = slideXML(body: textShapeXML("<a:p><a:r><a:t>SECOND_BY_LIST</a:t></a:r></a:p>", name: "b"))
        // Files slide1/slide2 but list order reversed: slide2 first.
        let url = try makePPTX(named: "order", files: scaffold(
            slides: [(s1, "slide1.xml"), (s2, "slide2.xml")], order: [1, 0]))
        let project = CanvaDocumentImporter.importDocument(from: url)
        guard case .text(let t)? = project?.pages[0].elements.first?.payload else {
            return XCTFail("expected text on page 1")
        }
        XCTAssertEqual(t.text, "SECOND_BY_LIST")
    }

    /// mc:AlternateContent: first productive Choice wins; Fallback is preview.
    func testAlternateContentChoiceNotFallback() throws {
        let slide = slideXML(body: """
            <mc:AlternateContent xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"><mc:Choice><p:graphicFrame><p:nvGraphicFramePr><p:cNvPr id="5" name="t"/><p:cNvGraphicFramePr/><p:nvPr/></p:nvGraphicFramePr><p:xfrm><a:off x="0" y="0"/><a:ext cx="2000000" cy="500000"/></p:xfrm><a:graphic><a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/table"><a:tbl><a:tblGrid><a:gridCol w="1000000"/><a:gridCol w="1000000"/></a:tblGrid><a:tr h="500000"><a:tc><a:txBody><a:bodyPr/><a:p><a:r><a:t>T1</a:t></a:r></a:p></a:txBody><a:tcPr/></a:tc><a:tc><a:txBody><a:bodyPr/><a:p><a:r><a:t>T2</a:t></a:r></a:p></a:txBody><a:tcPr/></a:tc></a:tr></a:tbl></a:graphicData></a:graphic></p:graphicFrame></mc:Choice><mc:Fallback><p:sp><p:nvSpPr><p:cNvPr id="9" name="fb"/><p:cNvSpPr/><p:nvPr/></p:nvSpPr><p:spPr><a:xfrm><a:off x="914400" y="914400"/><a:ext cx="5486400" cy="2743200"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></p:spPr><p:txBody><a:bodyPr/><a:p><a:r><a:t>FALLBACK_SHAPE</a:t></a:r></a:p></p:txBody></p:sp></mc:Fallback></mc:AlternateContent>
            """)
        let url = try makePPTX(named: "ac", files: scaffold(slides: [(slide, "slide1.xml")]))
        let project = CanvaDocumentImporter.importDocument(from: url)
        // 2 cells × (rect + text) = 4; Fallback shape must NOT also import.
        XCTAssertEqual(countElements(project), 4)
        let texts = project?.pages[0].elements.compactMap { el -> String? in
            if case .text(let t) = el.payload { return t.text }
            return nil
        } ?? []
        XCTAssertFalse(texts.contains("FALLBACK_SHAPE"))
    }

    /// Project round-trip: encode → .canv on disk → importer decodes (ISO8601).
    func testProjectFileRoundTripsThroughImporter() throws {
        var project = CanvasProject(name: "RT")
        project.pages = [CanvasPage(name: "p1", width: 960, height: 540)]
        let data = try project.encodeToData()
        for ext in ["canv", "pluma", "json"] {
            let u = tempRoot.appendingPathComponent("rt.\(ext)")
            try data.write(to: u)
            let back = CanvaDocumentImporter.importDocument(from: u)
            XCTAssertEqual(back?.name, "RT", "\(ext) failed to decode")
            XCTAssertEqual(back?.pages.count, 1)
        }
    }

    // MARK: - Security: archive symlinks & nested transforms

    /// A symlinked media entry must not be read — it can point at any file on
    /// the user's disk. The slide references ppt/media/evil.png which is a
    /// symlink to a file OUTSIDE the archive.
    func testSymlinkedMediaIsNotRead() throws {
        // A real PNG outside the package — if the importer followed the
        // symlink it would succeed and emit an image element.
        let outside = tempRoot.appendingPathComponent("secret.png")
        try XCTUnwrap(Data(base64Encoded:
            "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="))
            .write(to: outside)
        let slide = slideXML(body: """
            <p:pic><p:nvPicPr><p:cNvPr id="6" name="p"/><p:cNvPicPr/><p:nvPr/></p:nvPicPr><p:blipFill><a:blip r:embed="rIdImg"/></p:blipFill><p:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="1000000" cy="1000000"/></a:xfrm></p:spPr></p:pic>
            """)
        var files = scaffold(slides: [(slide, "slide1.xml")])
        files["ppt/slides/_rels/slide1.xml.rels"] = """
            <?xml version="1.0"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rIdImg" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="../media/evil.png"/></Relationships>
            """
        let url = try makePPTX(named: "symlink",
                               files: files,
                               symlinks: ["ppt/media/evil.png": outside])
        let project = CanvaDocumentImporter.importDocument(from: url)
        let images = project?.pages.flatMap { $0.elements }.filter {
            if case .image = $0.payload { return true }; return false
        } ?? []
        XCTAssertEqual(images.count, 0, "symlinked media must be rejected")
    }

    /// Nested groups must apply each ancestor transform ONCE — GroupTransform
    /// already concatenates, so re-applying the whole stack double-shifts.
    func testNestedGroupTransformAppliesOnce() throws {
        let table = """
            <p:graphicFrame><p:nvGraphicFramePr><p:cNvPr id="5" name="t"/><p:cNvGraphicFramePr/><p:nvPr/></p:nvGraphicFramePr><p:xfrm><a:off x="0" y="0"/><a:ext cx="1000000" cy="500000"/></p:xfrm><a:graphic><a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/table"><a:tbl><a:tblGrid><a:gridCol w="1000000"/></a:tblGrid><a:tr h="500000"><a:tc><a:txBody><a:bodyPr/><a:p><a:r><a:t>X</a:t></a:r></a:p></a:txBody><a:tcPr/></a:tc></a:tr></a:tbl></a:graphicData></a:graphic></p:graphicFrame>
            """
        let slide = slideXML(body: """
            <p:grpSp><p:nvGrpSpPr><p:cNvPr id="10" name="g1"/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr><a:xfrm><a:off x="100000" y="0"/><a:ext cx="5000000" cy="3000000"/><a:chOff x="0" y="0"/><a:chExt cx="5000000" cy="3000000"/></a:xfrm></p:grpSpPr><p:grpSp><p:nvGrpSpPr><p:cNvPr id="11" name="g2"/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr><a:xfrm><a:off x="200000" y="0"/><a:ext cx="4000000" cy="2000000"/><a:chOff x="0" y="0"/><a:chExt cx="4000000" cy="2000000"/></a:xfrm></p:grpSpPr>\(table)</p:grpSp></p:grpSp>
            """)
        let url = try makePPTX(named: "nested", files: scaffold(slides: [(slide, "slide1.xml")]))
        let project = CanvaDocumentImporter.importDocument(from: url)
        let minX = project?.pages[0].elements.map(\.x).min() ?? -1
        // Each ancestor applies once: +100000 + +200000 = 300000 EMU = 31.496px.
        // Double-application would land at 400000 EMU ≈ 41.99px.
        XCTAssertEqual(minX, 300000.0 / 9525.0, accuracy: 0.5,
                       "nested group transforms must not double-apply")
    }

    /// zoomToSelection must center the selection at the viewport middle under
    /// the center-anchored pan convention (pan = z·(pageCenter − c)).
    @MainActor
    func testZoomToSelectionCentersSelection() {
        var project = CanvasProject(name: "Z")
        var page = CanvasPage(name: "p", width: 1000, height: 600)
        let el = CanvasElement(name: "e", payload: .shape(ShapeContent()),
                               x: 800, y: 400, width: 100, height: 50)
        page.elements = [el]
        project.pages = [page]
        let vm = CanvasDocumentViewModel(project: project)
        vm.pageLayoutMode = .infiniteWhiteboard // clampedPan is identity here
        vm.selectedElementIds = [el.id]
        let viewport = CGSize(width: 1200, height: 800)
        vm.zoomToSelection(viewportSize: viewport)
        // Element center (850,425) must land at viewport center (600,400).
        let screen = vm.canvasToScreenPoint(CGPoint(x: 850, y: 425), viewportSize: viewport)
        XCTAssertEqual(screen.x, 600, accuracy: 1.0)
        XCTAssertEqual(screen.y, 400, accuracy: 1.0)
    }
}
