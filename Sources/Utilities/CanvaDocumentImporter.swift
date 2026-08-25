import Foundation
import AppKit
import PDFKit
import UniformTypeIdentifiers

public enum CanvaDocumentImporter {

    /// Supported file extensions for importing Canva, PowerPoint, and vector documents
    public static let supportedExtensions = ["pptx", "pdf", "svg", "png", "jpg", "jpeg", "webp", "heic", "tiff", "zip", "json", "pluma"]

    /// Imports any supported Canva export, PowerPoint deck, PDF, SVG, Image, or Zip into a complete multi-page CanvasProject.
    public static func importDocument(from url: URL) -> CanvasProject? {
        let ext = url.pathExtension.lowercased()
        let projectName = url.deletingPathExtension().lastPathComponent
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .capitalized

        switch ext {
        case "pptx":
            return importFromPPTX(url: url, projectName: projectName)
        case "pdf":
            return importFromPDF(url: url, projectName: projectName)
        case "svg":
            return importFromSVG(url: url, projectName: projectName)
        case "zip":
            return importFromZIP(url: url, projectName: projectName)
        case "png", "jpg", "jpeg", "webp", "heic", "tiff":
            return importFromImage(url: url, projectName: projectName)
        case "json", "pluma":
            return importFromJSON(url: url)
        default:
            return nil
        }
    }

    // =========================================================================
    // 1. UNIVERSAL CANVA & POWERPOINT IMPORTER (.pptx) — High-Fidelity Engine
    //
    // Fidelity rules:
    //   • Exact unit conversion: 1 px = 9525 EMU (96 dpi), 1 pt = 12700 EMU.
    //     Page size AND every element use the SAME scale, and font pt → px is
    //     pt × 4/3. Nothing is "remapped" to preset canvas sizes.
    //   • Placeholder geometry inherited from slideLayout → slideMaster.
    //   • Theme colors resolved with tx1/bg1/tx2/bg2 aliases + sysClr + alpha.
    //   • True linear gradients (stops + angle), strokes, dash, shadows.
    //   • Dominant-run text formatting (longest run wins, not first run).
    //   • Text box internal insets (lIns/rIns/tIns/bIns) honored.
    //   • normAutofit fontScale applied (Canva/PowerPoint autofit).
    // =========================================================================

    // MARK: PPTX Unit Constants

    private static let emuPerPx: Double = 9525.0        // 96 dpi
    private static let emuPerPt: Double = 12700.0
    private static let ptToPx: Double = emuPerPt / emuPerPx // ≈ 1.3333

    // MARK: Parsed Theme

    private struct PPTXTheme {
        var colors: [String: CodableColor] = [:]
        var majorFont = "Helvetica Neue"
        var minorFont = "Helvetica Neue"
        /// Line widths (pt) from fmtScheme lnStyleLst — indexed by lnRef idx (1-based)
        var lineStyleWidthsPt: [Double] = [6350.0 / 12700.0, 12700.0 / 12700.0, 19050.0 / 12700.0]

        /// Resolve an OOXML scheme color token (tx1, bg1, accent3…) to a real color.
        func color(_ token: String) -> CodableColor? {
            let aliases = ["tx1": "dk1", "bg1": "lt1", "tx2": "dk2", "bg2": "lt2"]
            let key = aliases[token] ?? token
            return colors[key] ?? colors[token]
        }
    }

    /// A resolved OOXML color: RGB + opacity (from <a:alpha>).
    private struct ResolvedColor {
        var color: CodableColor
        var alpha: Double // 0...1

        init(_ color: CodableColor, _ alpha: Double = 1.0) {
            self.color = color
            self.alpha = min(1, max(0, alpha))
        }
    }

    /// Placeholder geometry + text style inherited from layout/master.
    private struct PlaceholderInfo {
        var frame: CGRect? = nil
        var fontSizePx: Double? = nil   // resolved from layout/master text styles
        var fontPxIsTitle: Bool = false
    }

    // MARK: Entry

    public static func importFromPPTX(url: URL, projectName: String) -> CanvasProject? {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-q", url.path, "-d", tempDir.path]
        do {
            try process.run()
        } catch {
            try? FileManager.default.removeItem(at: tempDir)
            return nil
        }
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            try? FileManager.default.removeItem(at: tempDir)
            return nil
        }
        defer { try? FileManager.default.removeItem(at: tempDir) }

        // ---------- A. Theme ----------
        let theme = parseTheme(tempDir: tempDir)

        // ---------- A2. Table styles (ppt/tableStyles.xml) ----------
        let tableStyles = parseTableStyles(tempDir: tempDir, theme: theme)

        // ---------- B. Exact slide size (no preset remapping!) ----------
        var slideWpx: Double = 1280
        var slideHpx: Double = 720
        if let presData = try? Data(contentsOf: tempDir.appendingPathComponent("ppt/presentation.xml")),
           let sldSz = (try? XMLDocument(data: presData))?.rootElement()?.elements(forName: "p:sldSz").first {
            let cx = Double(sldSz.attribute(forName: "cx")?.stringValue ?? "") ?? (1280 * emuPerPx)
            let cy = Double(sldSz.attribute(forName: "cy")?.stringValue ?? "") ?? (720 * emuPerPx)
            slideWpx = max(200, round(cx / emuPerPx))
            slideHpx = max(200, round(cy / emuPerPx))
        }

        // ---------- C. Slides in presentation order ----------
        let slidesDir = tempDir.appendingPathComponent("ppt/slides")
        guard let slideFiles = try? FileManager.default.contentsOfDirectory(at: slidesDir, includingPropertiesForKeys: nil) else { return nil }
        let xmlSlides = slideFiles
            .filter { $0.pathExtension == "xml" && $0.lastPathComponent.hasPrefix("slide") }
            .sorted {
                let n1 = Int($0.deletingPathExtension().lastPathComponent.dropFirst("slide".count)) ?? 0
                let n2 = Int($1.deletingPathExtension().lastPathComponent.dropFirst("slide".count)) ?? 0
                return n1 < n2
            }
        guard !xmlSlides.isEmpty else { return nil }

        var pages: [CanvasPage] = []

        for (slideIdx, slideURL) in xmlSlides.enumerated() {
            guard var slideData = try? Data(contentsOf: slideURL) else { continue }
            slideData = Self.encodeWhitespaceOnlyTextRuns(slideData)
            guard let slideDoc = try? XMLDocument(data: slideData),
                  let root = slideDoc.rootElement() else { continue }
            // Skip hidden slides (show="0")
            if root.attribute(forName: "show")?.stringValue == "0" { continue }
            guard let cSld = root.elements(forName: "p:cSld").first,
                  let spTree = cSld.elements(forName: "p:spTree").first else { continue }

            // ---- Relationships (images, layout) ----
            let relsURL = tempDir.appendingPathComponent("ppt/slides/_rels/\(slideURL.lastPathComponent).rels")
            let relMap = parseRelationships(relsURL)

            // ---- Layout & Master (for placeholder geometry + inherited bg) ----
            var layoutDoc: XMLDocument?
            var masterDoc: XMLDocument?
            var layoutRels: [String: String] = [:]
            if let layoutTarget = relMap.values.first(where: { $0.contains("slideLayout") }) {
                let layoutURL = tempDir.appendingPathComponent("ppt").appendingPathComponent(normalizeTarget(layoutTarget))
                layoutDoc = (try? Data(contentsOf: layoutURL)).flatMap { try? XMLDocument(data: Self.encodeWhitespaceOnlyTextRuns($0)) }
                layoutRels = parseRelationships(layoutURL.deletingLastPathComponent().appendingPathComponent("_rels/\(layoutURL.lastPathComponent).rels"))
                if let masterTarget = layoutRels.values.first(where: { $0.contains("slideMaster") }) {
                    let masterURL = tempDir.appendingPathComponent("ppt").appendingPathComponent(normalizeTarget(masterTarget))
                    masterDoc = (try? Data(contentsOf: masterURL)).flatMap { try? XMLDocument(data: Self.encodeWhitespaceOnlyTextRuns($0)) }
                }
            }

            // ---- Slide background: slide → layout → master → white ----
            var pageBackground = FillStyle.solid(.white)
            var bgLockedImage: CanvasElement? = nil
            let bgSources: [XMLElement?] = [
                cSld.elements(forName: "p:bg").first,
                layoutDoc?.rootElement()?.elements(forName: "p:cSld").first?.elements(forName: "p:bg").first,
                masterDoc?.rootElement()?.elements(forName: "p:cSld").first?.elements(forName: "p:bg").first
            ]
            bgLoop: for bg in bgSources.compactMap({ $0 }) {
                let bgPr = bg.elements(forName: "p:bgPr").first
                if let solid = bgPr?.elements(forName: "a:solidFill").first {
                    pageBackground = FillStyle.solid(resolveColor(solid, theme: theme).color)
                    break bgLoop
                } else if let grad = bgPr?.elements(forName: "a:gradFill").first {
                    pageBackground = parseGradientFill(grad, theme: theme) ?? pageBackground
                    break bgLoop
                } else if let blip = bgPr?.elements(forName: "a:blipFill").first {
                    if let rId = blip.elements(forName: "a:blip").first?.attribute(forName: "r:embed")?.stringValue,
                       let target = relMap[rId],
                       let imgEl = makeImageElement(
                           target: target, tempDir: tempDir,
                           x: 0, y: 0, w: slideWpx, h: slideHpx,
                           srcRect: nil, rotation: 0, opacity: 1.0, name: "Slide Background", zIndex: 0
                       ) {
                        bgLockedImage = imgEl
                    }
                    break bgLoop
                } else {
                    // bgRef: theme-indexed background fill reference — resolve its child color element
                    let hasColorChild = bg.children?.contains(where: { ["a:schemeClr", "a:srgbClr", "a:sysClr", "a:prstClr"].contains(($0 as? XMLElement)?.name ?? "") }) == true
                    if hasColorChild {
                        pageBackground = FillStyle.solid(resolveColor(bg, theme: theme).color)
                        break bgLoop
                    }
                }
            }

            var elements: [CanvasElement] = []
            if let bgImg = bgLockedImage { elements.append(bgImg) }
            var zIndex = elements.isEmpty ? 0 : 1

            // ---- Placeholder maps from layout & master (merged: layout wins, master fills gaps) ----
            let layoutPlaceholders = placeholderMap(from: layoutDoc)
            let masterPlaceholders = placeholderMap(from: masterDoc)
            var combinedPH = masterPlaceholders
            for (key, lInfo) in layoutPlaceholders {
                var info = lInfo
                if info.frame == nil, let m = masterPlaceholders[key], m.frame != nil {
                    info.frame = m.frame
                }
                if info.fontSizePx == nil, let m = masterPlaceholders[key], m.fontSizePx != nil {
                    info.fontSizePx = m.fontSizePx
                    info.fontPxIsTitle = m.fontPxIsTitle
                }
                combinedPH[key] = info
            }

            // ---- Walk shape tree ----
            func walk(_ parent: XMLElement, groupStack: [GroupTransform]) {
                for child in parent.children ?? [] {
                    guard let node = child as? XMLElement else { continue }
                    switch node.name ?? "" {
                    case "p:grpSp":
                        var next = groupStack
                        if let xfrm = node.elements(forName: "p:grpSpPr").first?.elements(forName: "a:xfrm").first,
                           let g = parseGroupTransform(xfrm, stack: groupStack) {
                            next = groupStack + [g]
                        }
                        walk(node, groupStack: next)
                    case "p:sp", "p:pic", "p:cxnSp":
                        let els = parseShape(
                            node, theme: theme, relMap: relMap, tempDir: tempDir,
                            slideW: slideWpx, slideH: slideHpx,
                            groupStack: groupStack,
                            layoutPH: combinedPH, masterPH: masterPlaceholders,
                            zIndex: &zIndex
                        )
                        elements.append(contentsOf: els)
                    case "p:graphicFrame":
                        let graphicData = node.elements(forName: "a:graphic").first?
                            .elements(forName: "a:graphicData").first
                        let tbl = graphicData?.elements(forName: "a:tbl").first
                        let diagramRelIds = graphicData?.elements(forName: "dgm:relIds").first
                        let chartRef = graphicData?.elements(forName: "c:chart").first
                        if let tbl = tbl {
                            if let tblEls = parseTable(tbl, frameNode: node, theme: theme, tableStyles: tableStyles, groupStack: groupStack, zIndex: &zIndex) {
                                elements.append(contentsOf: tblEls)
                            }
                        } else if diagramRelIds != nil {
                            // SmartArt: render node text from ppt/diagrams/data#.xml as a styled list
                            if let dgmEls = parseSmartArtFallback(node, diagramRelIds!, theme: theme, relMap: relMap, tempDir: tempDir, groupStack: groupStack, zIndex: &zIndex) {
                                elements.append(contentsOf: dgmEls)
                            }
                        } else if let chartRef = chartRef,
                                  let rId = chartRef.attribute(forName: "r:id")?.stringValue,
                                  let target = relMap[rId] {
                            // Native PowerPoint chart (bar / line / pie) → rendered vector image
                            if let chartEl = parseChart(
                                node, chartTarget: target, tempDir: tempDir,
                                theme: theme, groupStack: groupStack, zIndex: &zIndex
                            ) {
                                elements.append(chartEl)
                            }
                        }
                    default:
                        break
                    }
                }
            }
            walk(spTree, groupStack: [])

            let page = CanvasPage(
                name: "Slide \(slideIdx + 1)",
                width: slideWpx,
                height: slideHpx,
                background: pageBackground,
                elements: elements
            )
            pages.append(page)
        }

        guard !pages.isEmpty else { return nil }
        return CanvasProject(name: projectName, pages: pages)
    }

    // MARK: Group Transforms

    /// Full affine group transform: maps child-space EMU points to slide-space EMU points,
    /// including scale (ext/chExt), translation (off - chOff·scale), rotation (rot around group
    /// center), and all ancestor group transforms folded in.
    private struct GroupTransform {
        var affine: CGAffineTransform
        /// Total rotation contributed by all groups (degrees, clockwise)
        var rotationDeg: Double

        static let identity = GroupTransform(affine: .identity, rotationDeg: 0)

        /// Apply to a child-space rect → slide-space rect (axis-aligned bounding box, no rotation applied to size)
        func apply(_ r: CGRect) -> CGRect {
            let scaleX = sqrt(affine.a * affine.a + affine.b * affine.b)
            let scaleY = sqrt(affine.c * affine.c + affine.d * affine.d)
            let center = CGPoint(x: r.midX, y: r.midY).applying(affine)
            return CGRect(
                x: center.x - r.width * scaleX / 2,
                y: center.y - r.height * scaleY / 2,
                width: r.width * scaleX,
                height: r.height * scaleY
            )
        }
    }

    private static func parseGroupTransform(_ xfrm: XMLElement, stack: [GroupTransform]) -> GroupTransform? {
        let off = xfrm.elements(forName: "a:off").first
        let ext = xfrm.elements(forName: "a:ext").first
        let chOff = xfrm.elements(forName: "a:chOff").first
        let chExt = xfrm.elements(forName: "a:chExt").first
        let gx = emu(off?.attribute(forName: "x")?.stringValue)
        let gy = emu(off?.attribute(forName: "y")?.stringValue)
        let gw = emu(ext?.attribute(forName: "cx")?.stringValue)
        let gh = emu(ext?.attribute(forName: "cy")?.stringValue)
        let chx = emu(chOff?.attribute(forName: "x")?.stringValue)
        let chy = emu(chOff?.attribute(forName: "y")?.stringValue)
        let chw = emu(chExt?.attribute(forName: "cx")?.stringValue)
        let chh = emu(chExt?.attribute(forName: "cy")?.stringValue)
        guard gw > 0, gh > 0 else { return nil }

        var rotDeg: Double = 0
        if let rotStr = xfrm.attribute(forName: "rot")?.stringValue, let rot = Double(rotStr) {
            rotDeg = rot / 60000.0
        }

        // Local mapping: child point p → off + R(center) · S(ext/chExt) · (p - chOff)
        var t = CGAffineTransform(translationX: CGFloat(gx), y: CGFloat(gy))
        if rotDeg != 0 {
            let cx = CGFloat(gw / 2), cy = CGFloat(gh / 2)
            t = t.translatedBy(x: cx, y: cy)
            t = t.rotated(by: CGFloat(rotDeg * .pi / 180.0))
            t = t.translatedBy(x: -cx, y: -cy)
        }
        let sx = chw > 0 ? gw / chw : 1.0
        let sy = chh > 0 ? gh / chh : 1.0
        t = t.scaledBy(x: CGFloat(sx), y: CGFloat(sy))
        t = t.translatedBy(x: CGFloat(-chx), y: CGFloat(-chy))

        // Fold ancestor transforms: total = parentTotal · local (local applied first)
        let parent = stack.last ?? .identity
        return GroupTransform(affine: t.concatenating(parent.affine), rotationDeg: parent.rotationDeg + rotDeg)
    }

    // MARK: Shape / Picture / Connector Parsing

    private static func parseShape(
        _ node: XMLElement,
        theme: PPTXTheme,
        relMap: [String: String],
        tempDir: URL,
        slideW: Double,
        slideH: Double,
        groupStack: [GroupTransform],
        layoutPH: [String: PlaceholderInfo],
        masterPH: [String: PlaceholderInfo],
        zIndex: inout Int
    ) -> [CanvasElement] {
        let spPr = node.elements(forName: "p:spPr").first
            ?? node.elements(forName: "p:grpSpPr").first // cxnSp style fallback

        // ---- Placeholder identity ----
        let ph = node.elements(forName: "p:nvSpPr").first?.elements(forName: "p:nvPr").first?.elements(forName: "p:ph").first
            ?? node.elements(forName: "p:nvPicPr").first?.elements(forName: "p:nvPr").first?.elements(forName: "p:ph").first
            ?? node.elements(forName: "p:nvCxnSpPr").first?.elements(forName: "p:nvPr").first?.elements(forName: "p:ph").first
        let phType = ph?.attribute(forName: "type")?.stringValue
        let phIdx = ph?.attribute(forName: "idx")?.stringValue

        // ---- Geometry (EMU → px, exact) ----
        var frame: CGRect? = nil
        var rotation: Double = 0
        var flipH = false
        var flipV = false
        if let xfrm = spPr?.elements(forName: "a:xfrm").first {
            let x = emu(xfrm.elements(forName: "a:off").first?.attribute(forName: "x")?.stringValue)
            let y = emu(xfrm.elements(forName: "a:off").first?.attribute(forName: "y")?.stringValue)
            let w = emu(xfrm.elements(forName: "a:ext").first?.attribute(forName: "cx")?.stringValue)
            let h = emu(xfrm.elements(forName: "a:ext").first?.attribute(forName: "cy")?.stringValue)
            frame = CGRect(x: x, y: y, width: w, height: h)
            if let rotStr = xfrm.attribute(forName: "rot")?.stringValue, let rot = Double(rotStr) {
                rotation = rot / 60000.0
            }
            flipH = xfrm.attribute(forName: "flipH")?.stringValue == "1"
            flipV = xfrm.attribute(forName: "flipV")?.stringValue == "1"
        }

        // Placeholder without explicit geometry → inherit from layout, then master.
        // NEVER inherit for non-placeholder shapes (connectors etc. with tiny/zero extents are legit).
        if ph != nil, frame == nil || (frame?.width ?? 0) < 1 || (frame?.height ?? 0) < 1 {
            let inherited = inheritedPlaceholder(phType: phType, phIdx: phIdx, layoutPH: layoutPH, masterPH: masterPH)
            if let inh = inherited.frame {
                frame = inh
            }
        }
        guard var rect = frame else { return [] }

        // Apply the innermost group's folded affine (already includes all ancestors).
        // Group rotation is added to the element's own rotation (rotation is around center).
        if let g = groupStack.last {
            rect = g.apply(rect)
            if g.rotationDeg != 0 {
                rotation += g.rotationDeg
            }
        }

        // Exact px conversion (page and elements share this scale)
        let x = rect.minX / emuPerPx
        let y = rect.minY / emuPerPx
        let w = rect.width / emuPerPx
        let h = rect.height / emuPerPx

        // ---- Body properties (text insets & autofit) ----
        let bodyPr = node.elements(forName: "p:txBody").first?.elements(forName: "a:bodyPr").first
        let lIns = emu(bodyPr?.attribute(forName: "lIns")?.stringValue, default: 91440) / emuPerPx
        let rIns = emu(bodyPr?.attribute(forName: "rIns")?.stringValue, default: 91440) / emuPerPx
        let tIns = emu(bodyPr?.attribute(forName: "tIns")?.stringValue, default: 45720) / emuPerPx
        let bIns = emu(bodyPr?.attribute(forName: "bIns")?.stringValue, default: 45720) / emuPerPx
        var autofitScale: Double = 1.0
        if let fontScale = bodyPr?.elements(forName: "a:normAutofit").first?.attribute(forName: "fontScale")?.stringValue,
           let v = Double(fontScale), v > 0 {
            autofitScale = v / 100000.0
        }
        let anchor = bodyPr?.attribute(forName: "anchor")?.stringValue ?? "t"

        // ---- Theme style references (p:style fillRef / lnRef / fontRef) ----
        let styleRef = node.elements(forName: "p:style").first
        let fillRef = styleRef?.elements(forName: "a:fillRef").first
        let lnRef = styleRef?.elements(forName: "a:lnRef").first
        let fontRef = styleRef?.elements(forName: "a:fontRef").first

        // Stroke: explicit <a:ln> wins; otherwise fall back to theme lnRef (idx 0 = no line)
        let lnElem = spPr?.elements(forName: "a:ln").first
        let lnExplicitNone = lnElem?.elements(forName: "a:noFill").first != nil
        var stroke = parseStroke(lnElem, theme: theme)
        let lnRefIdx = lnRef?.attribute(forName: "idx")?.stringValue ?? "1"
        if stroke == nil && !lnExplicitNone && lnRefIdx != "0", let lnRef = lnRef {
            var widthPt = theme.lineStyleWidthsPt[0]
            if let idxStr = lnRef.attribute(forName: "idx")?.stringValue, let idx = Int(idxStr), idx >= 1, idx <= theme.lineStyleWidthsPt.count {
                widthPt = theme.lineStyleWidthsPt[idx - 1]
            }
            let rc = resolveColor(lnRef, theme: theme)
            stroke = StrokeStyle(isEnabled: true, color: rc.color, lineWidth: max(0.5, widthPt * ptToPx), dashPattern: .solid)
        }

        // Default text color from fontRef (e.g. white text on dark themed shapes)
        var styleTextColor: ResolvedColor? = nil
        if let fontRef = fontRef,
           fontRef.children?.contains(where: { ["a:schemeClr", "a:srgbClr", "a:sysClr", "a:prstClr"].contains(($0 as? XMLElement)?.name ?? "") }) == true {
            styleTextColor = resolveColor(fontRef, theme: theme)
        }

        // ---- Picture? ----
        let blipFill = node.elements(forName: "p:blipFill").first ?? spPr?.elements(forName: "a:blipFill").first
        if let rId = blipFill?.elements(forName: "a:blip").first?.attribute(forName: "r:embed")?.stringValue,
           let target = relMap[rId] {
            zIndex += 1
            let srcRect = blipFill?.elements(forName: "a:srcRect").first
            var opacity = 1.0
            if let blip = blipFill?.elements(forName: "a:blip").first,
               let alpha = blip.elements(forName: "a:alphaModFix").first?.attribute(forName: "amt")?.stringValue,
               let v = Double(alpha) {
                opacity = v / 100000.0
            }
            // Rounded / circular picture frames
            let prst = spPr?.elements(forName: "a:prstGeom").first?.attribute(forName: "prst")?.stringValue ?? ""
            var corner: Double = 0
            var frameKind: ShapeKind? = nil
            if prst == "ellipse" {
                frameKind = .circle
                corner = min(w, h) / 2
            } else if prst == "roundRect" {
                frameKind = .roundedRectangle
                corner = roundRectRadius(prstGeom: spPr?.elements(forName: "a:prstGeom").first, w: w, h: h)
            }

            var el = makeImageElement(
                target: target, tempDir: tempDir,
                x: x, y: y, w: w, h: h,
                srcRect: srcRect, rotation: rotation, opacity: opacity,
                name: "Image: \(target.components(separatedBy: "/").last ?? "picture")",
                zIndex: zIndex
            )
            if var content = el?.payload, case .image(var img) = content, frameKind != nil {
                img.cornerRadius = corner
                img.frameKind = frameKind
                content = .image(img)
                el?.payload = content
            }
            if let stroke = stroke {
                if var content = el?.payload, case .image(var img) = content {
                    img.stroke = stroke
                    content = .image(img)
                    el?.payload = content
                }
            }
            if let unwrapped = el {
                return [unwrapped]
            }
            // Could not decode the bitmap: emit a visible placeholder pair so the slide
            // keeps its structure (frame + explanatory label).
            return makeUnsupportedImagePlaceholder(
                name: "Image: \(target.components(separatedBy: "/").last ?? "picture")",
                x: x, y: y, w: w, h: h, rotation: rotation, zIndex: zIndex + 1,
                detail: target.components(separatedBy: ".").last?.uppercased() ?? "IMG"
            )
        }

        // ---- Shape fill / stroke / geometry ----
        let fillElem = spPr?.children?.first(where: { ["a:solidFill", "a:gradFill", "a:noFill", "a:pattFill", "a:blipFill", "a:grpFill"].contains($0.name ?? "") }) as? XMLElement
        let prstGeom = spPr?.elements(forName: "a:prstGeom").first
        let prst = prstGeom?.attribute(forName: "prst")?.stringValue ?? "rect"

        var shapeOpacity = 1.0
        var shapeFill: FillStyle? = nil
        if let fill = fillElem {
            switch fill.name ?? "" {
            case "a:solidFill":
                let rc = resolveColor(fill, theme: theme)
                shapeOpacity = rc.alpha
                shapeFill = .solid(rc.color)
            case "a:gradFill":
                shapeFill = parseGradientFill(fill, theme: theme)
            case "a:pattFill":
                shapeFill = .solid(resolveColor(fill, theme: theme).color)
            case "a:noFill":
                shapeFill = nil
            default:
                shapeFill = nil
            }
        } else if let fillRef = fillRef,
                  fillRef.attribute(forName: "idx")?.stringValue != "0", // idx 0 = explicitly no fill
                  fillRef.children?.contains(where: { ["a:schemeClr", "a:srgbClr", "a:sysClr", "a:prstClr"].contains(($0 as? XMLElement)?.name ?? "") }) == true {
            // No explicit fill → theme fillRef (idx 1 = solid; gradient style fills rendered as solid theme color)
            shapeFill = .solid(resolveColor(fillRef, theme: theme).color)
        }

        // ---- Custom geometry (freeform paths) → rasterized vector image ----
        if let custGeom = spPr?.elements(forName: "a:custGeom").first {
            if let el = rasterizeCustomGeometry(
                custGeom, fill: shapeFill, stroke: stroke,
                x: x, y: y, w: w, h: h,
                rotation: rotation, opacity: shapeOpacity, zIndex: zIndex + 1
            ) {
                zIndex += 1
                return [el]
            }
        }

        let hasVisibleStroke = stroke?.isEnabled == true
        let connectorPrsts: Set<String> = ["line", "straightConnector1", "bentConnector2", "bentConnector3", "bentConnector4", "bentConnector5", "curvedConnector2", "curvedConnector3", "curvedConnector4", "curvedConnector5"]
        let isLineLike = connectorPrsts.contains(prst)

        // Only emit a shape if it's actually visible (fill, stroke, or connector)
        var shapeResult: [CanvasElement] = []
        if (shapeFill != nil || hasVisibleStroke) && (w > 2 || isLineLike) {
            zIndex += 1
            var kind = mapShapeKind(prst: prst, w: w, h: h)
            var corner: Double = 0
            if kind == .roundedRectangle {
                corner = roundRectRadius(prstGeom: prstGeom, w: w, h: h)
            }

            // Connectors render as a straight line spanning the frame's diagonal.
            // Our .line shape is horizontal, so widen the frame to the diagonal length
            // and rotate by the diagonal angle (flips mirror the diagonal).
            var emitW = max(2, w)
            var emitH = max(2, h)
            var emitX = x
            var emitY = y
            if isLineLike {
                kind = .line
                emitW = max(4, sqrt(w * w + h * h))
                emitH = 2
                var angle = atan2(h, w) * 180.0 / .pi
                if flipH != flipV { angle = -angle }
                rotation += angle
                // Keep the segment's center so the rotated line stays in place
                emitX = x + w / 2 - emitW / 2
                emitY = y + h / 2 - emitH / 2
            } else if flipH != flipV || (flipH && flipV) {
                // Mirrored shapes: approximate by 180° rotation when both flips,
                // single flips on symmetric shapes are visually identical.
                if flipH && flipV { rotation += 180 }
            }

            var el = CanvasElement(
                name: "Shape: \(prettyShapeName(prst))",
                payload: .shape(ShapeContent(
                    kind: kind,
                    cornerRadius: corner,
                    fill: shapeFill ?? .solid(.clear),
                    stroke: stroke ?? StrokeStyle(isEnabled: false)
                )),
                x: emitX, y: emitY,
                width: emitW, height: emitH,
                rotation: rotation,
                opacity: shapeOpacity,
                zIndex: zIndex
            )
            if let shadow = parseShadow(spPr?.elements(forName: "a:effectLst").first, theme: theme) {
                el.shadow = shadow
            }
            shapeResult = [el]
        }

        // ---- Text body (shapes can carry text AND fill — emit both!) ----
        if let txBody = node.elements(forName: "p:txBody").first {
            // Inherited font size for placeholders (layout → master → defaults)
            var inheritedSizePt: Double? = nil
            let inherited = inheritedPlaceholder(phType: phType, phIdx: phIdx, layoutPH: layoutPH, masterPH: masterPH)
            if let s = inherited.fontSizePx {
                inheritedSizePt = s / ptToPx
            }

            var textEls = parseTextBody(
                txBody, theme: theme,
                x: x, y: y, w: w, h: h, rotation: rotation,
                lIns: lIns, rIns: rIns, tIns: tIns, bIns: bIns,
                autofitScale: autofitScale, anchor: anchor,
                phType: phType, inheritedSizePt: inheritedSizePt,
                majorFont: theme.majorFont, minorFont: theme.minorFont,
                styleDefaultColor: styleTextColor,
                slideW: slideW, zIndex: &zIndex
            )
            // Vertical text direction (bodyPr vert="vert" / "vert270" / "eaVert"):
            // approximate by rotating the text element and swapping its frame.
            if let vert = bodyPr?.attribute(forName: "vert")?.stringValue, vert.hasPrefix("vert") || vert == "eaVert" {
                let add: Double = vert == "vert270" ? 270 : 90
                for i in textEls.indices {
                    textEls[i].rotation += add
                    let tw = textEls[i].width
                    textEls[i].width = textEls[i].height
                    textEls[i].height = tw
                }
            }
            if !textEls.isEmpty {
                return shapeResult + textEls
            }
        }

        return shapeResult
    }

    // MARK: Text Body → Text Element

    private static func parseTextBody(
        _ txBody: XMLElement,
        theme: PPTXTheme,
        x: Double, y: Double, w: Double, h: Double, rotation: Double,
        lIns: Double, rIns: Double, tIns: Double, bIns: Double,
        autofitScale: Double,
        anchor: String,
        phType: String?,
        inheritedSizePt: Double?,
        majorFont: String, minorFont: String,
        styleDefaultColor: ResolvedColor?,
        slideW: Double,
        zIndex: inout Int
    ) -> [CanvasElement] {

        struct ParaLine {
            var text: String
            var fmt: RunFormat
            var align: TextAlignmentKind
            var spacingPt: Double? // exact line height in pt (spcPts)
        }

        var paragraphs: [ParaLine] = []
        var autoNumCounters: [Int: Int] = [:]
        func romanNumeral(_ n: Int) -> String {
            let pairs: [(Int, String)] = [(10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I")]
            var v = n, out = ""
            for (val, sym) in pairs {
                while v >= val { out += sym; v -= val }
            }
            return out
        }

        // This shape's own list style (a:lstStyle lvl1 defRPr) is another size fallback
        var ownListStylePt: Double? = nil
        if let defRPr = txBody.elements(forName: "a:lstStyle").first?.elements(forName: "a:lvl1pPr").first?.elements(forName: "a:defRPr").first,
           let sz = Double(defRPr.attribute(forName: "sz")?.stringValue ?? "") {
            ownListStylePt = sz / 100.0
        }

        for p in txBody.elements(forName: "a:p") {
            let pPr = p.elements(forName: "a:pPr").first
            var align: TextAlignmentKind = .left
            switch pPr?.attribute(forName: "algn")?.stringValue ?? "" {
            case "ctr": align = .center
            case "r": align = .right
            case "just": align = .justified
            default: break
            }

            // Bullet detection (auto-numbering counters are tracked per indent level)
            let lvl = Int(pPr?.attribute(forName: "lvl")?.stringValue ?? "0") ?? 0
            var bullet: String? = nil
            if pPr?.elements(forName: "a:buNone").first != nil {
                bullet = nil
            } else if let buCharEl = pPr?.elements(forName: "a:buChar").first {
                let rawChar = buCharEl.attribute(forName: "char")?.stringValue ?? ""
                let buFont = pPr?.elements(forName: "a:buFont").first?.attribute(forName: "typeface")?.stringValue
                bullet = mapBulletChar(rawChar, buFont)
            } else if let buAutoNum = pPr?.elements(forName: "a:buAutoNum").first {
                let type = buAutoNum.attribute(forName: "type")?.stringValue ?? "arabicPeriod"
                autoNumCounters[lvl, default: 0] += 1
                // Reset deeper-level counters when a shallower level appears
                for k in autoNumCounters.keys where k > lvl { autoNumCounters[k] = 0 }
                let n = autoNumCounters[lvl]!
                switch type {
                case "alphaLcPeriod", "alphaLcParenBoth", "alphaLcParenR":
                    bullet = String(Character(UnicodeScalar(UInt8(96 + n)))) + "."
                case "alphaUcPeriod", "alphaUcParenBoth", "alphaUcParenR":
                    bullet = String(Character(UnicodeScalar(UInt8(64 + n)))) + "."
                case "romanLcPeriod":
                    bullet = romanNumeral(n) + "."
                case "romanUcPeriod":
                    bullet = romanNumeral(n).uppercased() + "."
                default:
                    bullet = "\(n)."
                }
            }

            // Paragraph line spacing: spcPts (hundredths of a point) or spcPct
            var spacingPt: Double? = nil
            let lnSpc = pPr?.elements(forName: "a:lnSpc").first
            if let spcPts = lnSpc?.elements(forName: "a:spcPts").first?.attribute(forName: "val")?.stringValue,
               let pts = Double(spcPts) {
                spacingPt = pts / 100.0
            } else if let spcPct = lnSpc?.elements(forName: "a:spcPct").first?.attribute(forName: "val")?.stringValue,
                      let pct = Double(spcPct) {
                spacingPt = -pct / 100000.0 // negative encodes percentage for later resolution
            }

            // Paragraph-level default run properties (defRPr)
            var paraDefault = RunFormat()
            if let defRPr = pPr?.elements(forName: "a:defRPr").first {
                paraDefault = runFormat(from: defRPr, theme: theme)
            }

            var lineText = ""
            var lineFmt = RunFormat()
            var hasRun = false

            // Walk children in order so <a:br/> line breaks land in the right place
            for child in p.children ?? [] {
                guard let el = child as? XMLElement else { continue }
                switch el.name ?? "" {
                case "a:r":
                    let runText = decodeTextWhitespace(el.elements(forName: "a:t").first?.stringValue ?? "")
                    guard !runText.isEmpty else { continue }
                    var fmt = runFormat(from: el.elements(forName: "a:rPr").first, theme: theme)
                    // fall back: paragraph default → own lstStyle → inherited placeholder
                    if fmt.sizePt == nil { fmt.sizePt = paraDefault.sizePt ?? ownListStylePt ?? inheritedSizePt }
                    if fmt.font == nil { fmt.font = paraDefault.font }
                    if !fmt.bold { fmt.bold = paraDefault.bold }
                    if !fmt.italic { fmt.italic = paraDefault.italic }
                    if fmt.color == nil { fmt.color = paraDefault.color ?? styleDefaultColor }

                    lineText += runText
                    if runText.count >= lineFmt.textLen || !hasRun {
                        lineFmt = fmt
                        lineFmt.textLen = runText.count
                    }
                    hasRun = true
                case "a:br":
                    lineText += "\n"
                    // A break also resets the dominant-run length comparison baseline
                    if lineFmt.textLen > lineText.count { lineFmt.textLen = lineText.count }
                default:
                    break
                }
            }

            // Preserve intentional empty paragraphs (vertical spacing in real decks)
            if !lineText.trimmingCharacters(in: .whitespaces).isEmpty {
                let prefixed = bullet != nil ? "\(bullet!) \(lineText)" : lineText
                paragraphs.append(ParaLine(text: prefixed, fmt: lineFmt, align: align, spacingPt: spacingPt))
            } else if !paragraphs.isEmpty && hasRun == false && lineText.isEmpty {
                paragraphs.append(ParaLine(text: "", fmt: lineFmt, align: align, spacingPt: spacingPt))
            }
        }

        // Trim leading/trailing empty paragraphs (but keep interior ones)
        while let first = paragraphs.first, first.text.isEmpty { paragraphs.removeFirst() }
        while let last = paragraphs.last, last.text.isEmpty { paragraphs.removeLast() }
        guard !paragraphs.isEmpty else { return [] }

        let isTitle = phType == "title" || phType == "ctrTitle"
        let fallbackFont = isTitle ? majorFont : minorFont

        // Resolve per-paragraph formatting so mixed-format paragraphs keep their own look
        struct ResolvedPara {
            var text: String
            var fontSizePx: Double
            var fontFamily: String
            var fontWeight: Double
            var italic: Bool
            var underline: Bool
            var color: CodableColor
            var align: TextAlignmentKind
            var lineSpacing: Double
            var measuredHeight: Double = 0
        }

        func resolvedColorFor(_ fmt: RunFormat) -> CodableColor {
            var color = fmt.color?.color ?? styleDefaultColor?.color ?? theme.color("tx1") ?? .inkBlack
            if let a = fmt.color?.alpha, a < 1 {
                color = CodableColor(red: color.red, green: color.green, blue: color.blue, opacity: color.opacity * a)
            } else if let a = styleDefaultColor?.alpha, fmt.color == nil, a < 1 {
                color = CodableColor(red: color.red, green: color.green, blue: color.blue, opacity: color.opacity * a)
            }
            return color
        }

        func resolvePara(_ para: ParaLine) -> ResolvedPara {
            let fmt = para.fmt
            var fontSizePt = fmt.sizePt ?? ownListStylePt ?? inheritedSizePt ?? (isTitle ? 44.0 : 18.0)
            fontSizePt *= autofitScale
            let fontSizePx = max(8, fontSizePt * ptToPx)
            // SwiftUI lineSpacing = EXTRA space beyond natural single spacing.
            // spcPts gives the exact total line height; spcPct (encoded negative) is a multiplier.
            var lineSpacing: Double = 0
            if let sp = para.spacingPt {
                if sp >= 0 {
                    lineSpacing = max(0, (sp * ptToPx) - fontSizePx * 1.21)
                } else {
                    lineSpacing = max(0, (fontSizePx * 1.21) * (-sp - 1.0))
                }
            }
            return ResolvedPara(
                text: para.text,
                fontSizePx: fontSizePx,
                fontFamily: fmt.font ?? fallbackFont,
                fontWeight: fmt.bold ? 700 : 400,
                italic: fmt.italic,
                underline: fmt.underline,
                color: resolvedColorFor(fmt),
                align: para.align,
                lineSpacing: lineSpacing
            )
        }

        // Empty paragraphs occupy the height of the next non-empty paragraph (PowerPoint spacing)
        var resolvedParas: [ResolvedPara] = []
        for (idx, p) in paragraphs.enumerated() {
            if p.text.isEmpty {
                if let next = paragraphs.dropFirst(idx + 1).first(where: { !$0.text.isEmpty }) {
                    var r = resolvePara(ParaLine(text: "", fmt: next.fmt, align: p.align, spacingPt: p.spacingPt))
                    r.text = ""
                    resolvedParas.append(r)
                } else if let prev = resolvedParas.last {
                    resolvedParas.append(prev)
                    resolvedParas[resolvedParas.count - 1].text = ""
                    resolvedParas[resolvedParas.count - 1].align = p.align
                }
            } else {
                resolvedParas.append(resolvePara(p))
            }
        }

        // Honor text-box internal insets
        let tx = x + lIns
        let tw = max(24, w - lIns - rIns)
        let th = max(18, h - tIns - bIns)

        // Measure every paragraph with TextKit so wrapped lines are counted correctly
        // (the previous single-line estimate caused overlapping text on wrapped paragraphs).
        for i in resolvedParas.indices {
            let r = resolvedParas[i]
            let h = measureTextBlockHeight(
                text: r.text.isEmpty ? " " : r.text,
                fontFamily: r.fontFamily,
                fontSizePx: r.fontSizePx,
                fontWeight: r.fontWeight,
                italic: r.italic,
                lineSpacing: r.lineSpacing,
                width: tw,
                alignment: r.align
            )
            resolvedParas[i].measuredHeight = h
        }

        // Merge consecutive paragraphs that share identical formatting into single text
        // elements (Canva/PowerPoint text boxes behave this way; it also makes the import
        // far easier to edit). Mixed-format runs stay separate.
        struct EmittedBlock {
            var text: String = ""
            var height: Double = 0
            var para: ResolvedPara? = nil
        }
        var blocks: [EmittedBlock] = []
        func sameFormat(_ a: ResolvedPara, _ b: ResolvedPara) -> Bool {
            abs(a.fontSizePx - b.fontSizePx) < 0.5 && a.fontFamily == b.fontFamily &&
            a.fontWeight == b.fontWeight && a.italic == b.italic && a.underline == b.underline &&
            a.color == b.color && a.align == b.align && abs(a.lineSpacing - b.lineSpacing) < 0.5
        }
        for r in resolvedParas {
            if var last = blocks.last, let lp = last.para, sameFormat(lp, r) {
                last.text += (last.text.isEmpty ? "" : "\n") + r.text
                last.height += r.measuredHeight
                blocks[blocks.count - 1] = last
            } else {
                var b = EmittedBlock()
                b.text = r.text
                b.height = r.measuredHeight
                b.para = r
                blocks.append(b)
            }
        }

        let totalH = resolvedParas.reduce(0.0) { $0 + $1.measuredHeight }

        // Vertical anchoring: PowerPoint vertically centers/bottom-aligns text within the box
        var cursorY = y + tIns
        if totalH < th {
            if anchor == "ctr" { cursorY += (th - totalH) / 2 }
            else if anchor == "b" { cursorY += (th - totalH) }
        }

        var results: [CanvasElement] = []
        for b in blocks {
            guard let p = b.para, !b.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                cursorY += b.height
                continue
            }
            zIndex += 1
            results.append(CanvasElement(
                name: "Text: \(b.text.prefix(20))",
                payload: .text(TextContent(
                    text: b.text,
                    fontFamily: p.fontFamily,
                    fontSize: p.fontSizePx,
                    fontWeight: p.fontWeight,
                    isItalic: p.italic,
                    isUnderlined: p.underline,
                    alignment: p.align,
                    textColor: p.color,
                    letterSpacing: 0,
                    lineSpacing: p.lineSpacing
                )),
                x: tx, y: cursorY,
                width: tw, height: max(18, b.height),
                rotation: rotation,
                zIndex: zIndex
            ))
            cursorY += b.height
        }
        return results
    }

    /// Measures the rendered height of a (possibly multi-line, wrapping) text block using
    /// TextKit with the same font/spacing the canvas renderer uses. Returns points.
    static func measureTextBlockHeight(
        text: String,
        fontFamily: String,
        fontSizePx: Double,
        fontWeight: Double,
        italic: Bool,
        lineSpacing: Double,
        width: Double,
        alignment: TextAlignmentKind
    ) -> Double {
        let weight: NSFont.Weight
        switch fontWeight {
        case ..<250: weight = .ultraLight
        case ..<350: weight = .light
        case ..<450: weight = .regular
        case ..<550: weight = .medium
        case ..<650: weight = .semibold
        case ..<750: weight = .bold
        case ..<850: weight = .heavy
        default: weight = .black
        }
        var base: NSFont? = NSFont(name: fontFamily, size: fontSizePx)
        if base == nil {
            base = NSFont.systemFont(ofSize: fontSizePx, weight: weight)
        } else if fontWeight >= 600 || fontWeight <= 300 {
            // Custom font families usually ship a single weight; let AppKit synthesize bold.
            if fontWeight >= 600 {
                base = NSFontManager().convert(base!, toHaveTrait: .boldFontMask)
            }
        }
        var font = base!
        if italic {
            font = NSFontManager().convert(font, toHaveTrait: .italicFontMask)
        }

        let para = NSMutableParagraphStyle()
        para.lineSpacing = CGFloat(lineSpacing)
        switch alignment {
        case .center: para.alignment = .center
        case .right: para.alignment = .right
        case .justified: para.alignment = .justified
        case .left: para.alignment = .left
        }

        let storage = NSTextStorage(string: text, attributes: [
            .font: font,
            .paragraphStyle: para
        ])
        let manager = NSLayoutManager()
        storage.addLayoutManager(manager)
        let container = NSTextContainer(size: NSSize(width: max(10, width), height: .greatestFiniteMagnitude))
        container.lineFragmentPadding = 0
        manager.addTextContainer(container)
        let used = manager.usedRect(for: container).height
        return max(fontSizePx * 1.15, Double(used))
    }

    /// Maps Wingdings/Webdings/Symbol bullet glyphs (private-use codepoints that render
    /// as tofu on macOS) to visually equivalent Unicode characters.
    private static func mapBulletChar(_ raw: String, _ buFont: String?) -> String {
        guard let scalar = raw.unicodeScalars.first else { return "•" }
        let font = (buFont ?? "").lowercased()
        if font.contains("wingdings") || font.contains("webdings") {
            switch scalar.value {
            case 0xF0A7: return "▪" // small square
            case 0xF0A8: return "❑"
            case 0xF0B7: return "•" // large dot
            case 0xF0D8: return "➢"
            case 0xF0E0: return "➔"
            case 0xF0FC: return "✓"
            case 0xF0FE: return "☑"
            default: return "•"
            }
        }
        if font.contains("symbol") {
            switch scalar.value {
            case 0xF0B7: return "•"
            case 0xF0A7: return "▪"
            default: return "•"
            }
        }
        // Private-use area leftovers without a known font → safe dot
        if scalar.value >= 0xE000 && scalar.value <= 0xF8FF { return "•" }
        return raw.isEmpty ? "•" : raw
    }

    /// Formatting of a single text run (or paragraph default).
    private struct RunFormat {
        var sizePt: Double? = nil
        var font: String? = nil
        var bold = false
        var italic = false
        var underline = false
        var color: ResolvedColor? = nil
        var textLen = 0
    }

    private static func runFormat(from rPr: XMLElement?, theme: PPTXTheme) -> RunFormat {
        var f = RunFormat()
        guard let rPr = rPr else { return f }
        if let sz = Double(rPr.attribute(forName: "sz")?.stringValue ?? "") {
            f.sizePt = sz / 100.0 // hundredths of a point
        }
        if let latin = rPr.elements(forName: "a:latin").first?.attribute(forName: "typeface")?.stringValue,
           !latin.isEmpty, !latin.hasPrefix("+") {
            f.font = mapFontName(latin)
        }
        f.bold = rPr.attribute(forName: "b")?.stringValue == "1"
        f.italic = rPr.attribute(forName: "i")?.stringValue == "1"
        f.underline = rPr.attribute(forName: "u")?.stringValue == "sng"
        if let solid = rPr.elements(forName: "a:solidFill").first {
            f.color = resolveColor(solid, theme: theme)
        }
        return f
    }

    // MARK: Color Resolution (scheme aliases, sysClr, alpha)

    private static func resolveColor(_ fillElem: XMLElement, theme: PPTXTheme) -> ResolvedColor {
        // Direct color child
        for child in fillElem.children ?? [] {
            guard let colorEl = child as? XMLElement else { continue }
            let alpha = parseAlpha(colorEl)
            switch colorEl.name ?? "" {
            case "a:srgbClr":
                if let hex = colorEl.attribute(forName: "val")?.stringValue {
                    return ResolvedColor(CodableColor(hex: "#" + hex), alpha)
                }
            case "a:sysClr":
                // e.g. <a:sysClr val="windowText" lastClr="000000"/>
                if let last = colorEl.attribute(forName: "lastClr")?.stringValue {
                    return ResolvedColor(CodableColor(hex: "#" + last), alpha)
                }
                let val = colorEl.attribute(forName: "val")?.stringValue ?? ""
                if val == "window" { return ResolvedColor(.white, alpha) }
                return ResolvedColor(.black, alpha)
            case "a:schemeClr":
                let token = colorEl.attribute(forName: "val")?.stringValue ?? ""
                if let base = theme.color(token) {
                    // lumMod/lumOff/tint/shade adjustments
                    var c = base
                    if let lumMod = childModifier(colorEl, name: "a:lumMod") {
                        c = scaleColor(c, by: lumMod)
                    }
                    if let shade = childModifier(colorEl, name: "a:shade") {
                        c = scaleColor(c, by: shade)
                    }
                    if let tint = childModifier(colorEl, name: "a:tint") {
                        c = mixColor(c, with: .white, amount: 1 - tint)
                    }
                    if let lumOff = childModifier(colorEl, name: "a:lumOff") {
                        c = mixColor(c, with: .white, amount: lumOff)
                    }
                    return ResolvedColor(c, alpha)
                }
            case "a:prstClr":
                if let val = colorEl.attribute(forName: "val")?.stringValue {
                    let preset: CodableColor
                    switch val {
                    case "white": preset = .white
                    case "black": preset = .black
                    case "red": preset = CodableColor(hex: "#FF0000")
                    case "green": preset = CodableColor(hex: "#008000")
                    case "blue": preset = CodableColor(hex: "#0000FF")
                    case "yellow": preset = CodableColor(hex: "#FFFF00")
                    default: preset = .black
                    }
                    return ResolvedColor(preset, alpha)
                }
            default:
                break
            }
        }
        return ResolvedColor(theme.color("tx1") ?? .black, 1)
    }

    /// <a:alpha val="50000"/> → 0.5
    private static func parseAlpha(_ colorEl: XMLElement) -> Double {
        if let v = Double(colorEl.elements(forName: "a:alpha").first?.attribute(forName: "val")?.stringValue ?? "") {
            return v / 100000.0
        }
        return 1.0
    }

    private static func childModifier(_ colorEl: XMLElement, name: String) -> Double? {
        if let v = Double(colorEl.elements(forName: name).first?.attribute(forName: "val")?.stringValue ?? "") {
            return v / 100000.0
        }
        return nil
    }

    private static func scaleColor(_ c: CodableColor, by factor: Double) -> CodableColor {
        CodableColor(red: c.red * factor, green: c.green * factor, blue: c.blue * factor, opacity: c.opacity)
    }

    private static func mixColor(_ c: CodableColor, with other: CodableColor, amount: Double) -> CodableColor {
        let t = min(1, max(0, amount))
        return CodableColor(
            red: c.red * (1 - t) + other.red * t,
            green: c.green * (1 - t) + other.green * t,
            blue: c.blue * (1 - t) + other.blue * t,
            opacity: c.opacity
        )
    }

    // MARK: Gradient Fill

    private static func parseGradientFill(_ grad: XMLElement, theme: PPTXTheme) -> FillStyle? {
        guard let gsLst = grad.elements(forName: "a:gsLst").first else { return nil }
        var stops: [GradientStop] = []
        for gs in gsLst.elements(forName: "a:gs") {
            guard let posStr = gs.attribute(forName: "pos")?.stringValue, let pos = Double(posStr) else { continue }
            let rc = resolveColor(gs, theme: theme)
            var color = rc.color
            if rc.alpha < 1 {
                color = CodableColor(red: color.red, green: color.green, blue: color.blue, opacity: rc.alpha)
            }
            stops.append(GradientStop(color: color, location: pos / 100000.0))
        }
        guard stops.count >= 2 else { return nil }

        var angle: Double = 90
        if let lin = grad.elements(forName: "a:lin").first,
           let angStr = lin.attribute(forName: "ang")?.stringValue, let ang = Double(angStr) {
            angle = ang / 60000.0 // OOXML: 60000ths deg, clockwise from +x — same convention as ours
        }
        // Radial gradients → approximate with our radial fill
        if grad.elements(forName: "a:path").first?.attribute(forName: "path")?.stringValue == "circle" {
            return FillStyle(
                type: .radialGradient,
                solidColor: stops.first?.color ?? .white,
                gradientStops: stops
            )
        }
        return FillStyle(
            type: .linearGradient,
            solidColor: stops.first?.color ?? .white,
            gradientStops: stops,
            gradientAngle: angle
        )
    }

    // MARK: Stroke & Shadow

    private static func parseStroke(_ ln: XMLElement?, theme: PPTXTheme) -> StrokeStyle? {
        guard let ln = ln else { return nil }
        // <a:noFill/> inside <a:ln> = no stroke
        if ln.elements(forName: "a:noFill").first != nil { return nil }
        guard let solid = ln.elements(forName: "a:solidFill").first else { return nil }
        let rc = resolveColor(solid, theme: theme)
        var widthPt: Double = 0.75 // OOXML default
        if let wStr = ln.attribute(forName: "w")?.stringValue, let w = Double(wStr), w > 0 {
            widthPt = w / emuPerPt
        }
        var dash: DashPattern = .solid
        switch ln.elements(forName: "a:prstDash").first?.attribute(forName: "val")?.stringValue ?? "" {
        case "dash", "sysDash", "lgDash": dash = .dashed
        case "dot", "sysDot", "lgDashDot", "lgDashDotDot": dash = .dotted
        default: break
        }
        let strokeColor = rc.alpha < 1
            ? CodableColor(red: rc.color.red, green: rc.color.green, blue: rc.color.blue, opacity: rc.alpha)
            : rc.color
        return StrokeStyle(isEnabled: true, color: strokeColor, lineWidth: max(0.5, widthPt * ptToPx), dashPattern: dash)
    }

    private static func parseShadow(_ effectLst: XMLElement?, theme: PPTXTheme) -> ShadowEffect? {
        guard let outer = effectLst?.elements(forName: "a:outerShdw").first else { return nil }
        let rc = resolveColor(outer, theme: theme)
        let blurPx = emu(outer.attribute(forName: "blurRad")?.stringValue) / emuPerPx
        let distPx = emu(outer.attribute(forName: "dist")?.stringValue) / emuPerPx
        let dirRad = (emu(outer.attribute(forName: "dir")?.stringValue) / 60000.0) * .pi / 180.0
        let shadowColor = rc.alpha < 1
            ? CodableColor(red: rc.color.red, green: rc.color.green, blue: rc.color.blue, opacity: rc.alpha)
            : rc.color
        return ShadowEffect(
            isEnabled: true,
            color: shadowColor,
            radius: max(1, blurPx * 0.5), // SwiftUI radius ≈ blur/2
            x: cos(dirRad) * distPx,
            y: sin(dirRad) * distPx
        )
    }

    // MARK: Shape Kind Mapping

    private static func mapShapeKind(prst: String, w: Double, h: Double) -> ShapeKind {
        switch prst {
        case "roundRect": return .roundedRectangle
        case "ellipse", "circle": return .circle // renders ellipse inscribed in rect (handles w≠h)
        case "triangle", "rtTriangle": return .triangle
        case "diamond": return .diamond
        case "parallelogram": return .parallelogram
        case "trapezoid": return .trapezoid
        case "star5", "star4", "star6", "star8": return .star
        case "heart": return .heart
        case "cloud": return .cloud
        case "donut": return .donut
        case "moon": return .crescentMoon
        case "rightArrow": return .arrow
        case "chevron": return .chevron
        case "hexagon": return .polygon
        case "mathPlus", "plus": return .cross
        case "lightningBolt": return .lightning
        case "line", "straightConnector1", "bentConnector2", "bentConnector3":
            return h <= 4 || w <= 4 ? .line : .rectangle
        default: return .rectangle
        }
    }

    private static func prettyShapeName(_ prst: String) -> String {
        prst.replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression).capitalized
    }

    /// OOXML roundRect adj: percentage of min(w,h) in 1/100000 (default 16667 ≈ 16.667%)
    private static func roundRectRadius(prstGeom: XMLElement?, w: Double, h: Double) -> Double {
        var adj: Double = 16667
        if let avLst = prstGeom?.elements(forName: "a:avLst").first,
           let val = avLst.elements(forName: "a:gd").first?.attribute(forName: "fmla")?.stringValue {
            // fmla="val 12345"
            let parts = val.split(separator: " ")
            if parts.count >= 2, let v = Double(parts[1]) { adj = v }
        }
        let frac = min(0.5, adj / 100000.0)
        return min(w, h) * frac
    }

    // MARK: Images (with srcRect crop support)

    private static func makeImageElement(
        target: String, tempDir: URL,
        x: Double, y: Double, w: Double, h: Double,
        srcRect: XMLElement?, rotation: Double, opacity: Double,
        name: String,
        zIndex: Int
    ) -> CanvasElement? {
        let imgURL = tempDir.appendingPathComponent("ppt").appendingPathComponent(normalizeTarget(target))
        let ext = imgURL.pathExtension.lowercased()

        var nsImage = NSImage(contentsOf: imgURL)

        // Windows metafiles (EMF/WMF) are common in Office decks (equations, diagrams,
        // pasted screenshots). NSImage cannot read them, but most are simple wrappers
        // around an uncompressed DIB bitmap which we CAN extract directly.
        if nsImage == nil && (ext == "emf" || ext == "wmf") {
            nsImage = extractBitmapFromMetafile(imgURL)
        }

        // Last resort: give up (caller decides whether to draw a placeholder).
        if nsImage == nil {
            return nil
        }
        var image = nsImage!

        // srcRect crop (l/t/r/b in 1/100000 of image dimension)
        if let srcRect = srcRect {
            let l = emu(srcRect.attribute(forName: "l")?.stringValue) / 100000.0
            let t = emu(srcRect.attribute(forName: "t")?.stringValue) / 100000.0
            let r = emu(srcRect.attribute(forName: "r")?.stringValue) / 100000.0
            let b = emu(srcRect.attribute(forName: "b")?.stringValue) / 100000.0
            if let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                let px = CGFloat(cg.width), py = CGFloat(cg.height)
                let crop = CGRect(
                    x: px * CGFloat(l),
                    y: py * CGFloat(b), // CG origin is bottom-left
                    width: px * CGFloat(max(0.01, 1 - l - r)),
                    height: py * CGFloat(max(0.01, 1 - t - b))
                )
                if let cropped = cg.cropping(to: crop) {
                    image = NSImage(cgImage: cropped, size: NSSize(width: cropped.width, height: cropped.height))
                }
            }
        }

        // Downscale to at most 2x the display size (retina) — imported decks often carry
        // huge bitmaps; keeping full resolution balloons memory and file size with no
        // visible benefit at slide scale.
        let displayW = max(8, w), displayH = max(8, h)
        if let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            let maxW = displayW * 2
            let maxH = displayH * 2
            let scaleFactor = min(Double(cg.width) / maxW, Double(cg.height) / maxH, 1.0)
            if scaleFactor < 0.98 {
                let targetW = max(1, Int(Double(cg.width) / scaleFactor))
                let targetH = max(1, Int(Double(cg.height) / scaleFactor))
                if let resized = NSImage(cgImage: cg, size: NSSize(width: cg.width, height: cg.height)).resizedTo(width: targetW, height: targetH) {
                    image = resized
                }
            }
        }

        // Opaque sources (Office metafiles, photos) encode via the fast JPEG path.
        let sourceExt = imgURL.pathExtension.lowercased()
        let opaqueSource = ["emf", "wmf", "jpg", "jpeg", "tif", "tiff"].contains(sourceExt)
        guard let base64 = ImageUtils.base64String(from: image, allowJPEG: opaqueSource) else { return nil }
        return CanvasElement(
            name: name,
            payload: .image(ImageContent(
                imageBase64: base64,
                contentMode: .fill,
                cornerRadius: 0,
                originalWidth: Double(image.size.width),
                originalHeight: Double(image.size.height)
            )),
            x: x, y: y,
            width: max(8, w), height: max(8, h),
            rotation: rotation,
            opacity: opacity,
            zIndex: zIndex
        )
    }

    // MARK: Windows Metafile (EMF) Bitmap Extraction

    /// Extracts an embedded bitmap from an EMF file. The vast majority of EMFs found in
    /// real PowerPoint decks (pasted screenshots, equations, chart snapshots) consist of a
    /// single EMR_STRETCHDIBITS record wrapping an uncompressed DIB — which we decode here.
    private static func extractBitmapFromMetafile(_ url: URL) -> NSImage? {
        guard let data = try? Data(contentsOf: url), data.count > 108 else { return nil }
        let ext = url.pathExtension.lowercased()

        if ext == "emf" {
            let le32at = { (data: Data, offset: Int) -> Int in
                guard offset + 4 <= data.count else { return 0 }
                let v: UInt32 = data.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: offset, as: UInt32.self) }
                return Int(v)
            }
            var off = 0
            var bestBits: Data?
            var bestBmi: Data?
            var bestSize = 0
            while off + 8 <= data.count {
                let type = le32at(data, off)
                let size = le32at(data, off + 4)
                guard size >= 8, off + size <= data.count else { break }
                // EMR_STRETCHDIBITS = 81. Fields after the 8-byte header + 16-byte bounds:
                // xDest yDest xSrc ySrc cxSrc cySrc (24) offBmi cbBmi offBits cbBits (40) ...
                if type == 81, off + 64 <= off + size {
                    let offBmi = le32at(data, off + 48)
                    let cbBmi = le32at(data, off + 52)
                    let offBits = le32at(data, off + 56)
                    let cbBits = le32at(data, off + 60)
                    if cbBmi > 0, cbBits > bestSize,
                       off + offBmi + cbBmi <= data.count,
                       off + offBits + cbBits <= data.count {
                        bestBmi = data.subdata(in: (off + offBmi)..<(off + offBmi + cbBmi))
                        bestBits = data.subdata(in: (off + offBits)..<(off + offBits + cbBits))
                        bestSize = cbBits
                    }
                }
                off += size
            }
            if let bmi = bestBmi, let bits = bestBits {
                return imageFromDIB(bmi: bmi, bits: bits)
            }
            return nil
        }

        // WMF: look for a BITMAPINFOHEADER signature followed by plausible values.
        // (Rare in modern decks; best-effort scan.)
        if ext == "wmf" {
            var off = 0
            while off + 40 + 4 <= data.count {
                if le32at(data, off) == 40 { // biSize == sizeof(BITMAPINFOHEADER)
                    let w = le32at(data, off + 4)
                    let hRaw = le32at(data, off + 8)
                    let planes = le16(data, off + 12)
                    let bpp = le16(data, off + 14)
                    let h = abs(hRaw)
                    if w > 0, w < 20000, h > 0, h < 20000, planes == 1, [24, 32].contains(bpp) {
                        let rowBytes = (w * bpp / 8 + 3) & ~3
                        let needed = rowBytes * h
                        if off + 40 + needed <= data.count {
                            let bmi = data.subdata(in: off..<(off + 40))
                            let bits = data.subdata(in: (off + 40)..<(off + 40 + needed))
                            return imageFromDIB(bmi: bmi, bits: bits)
                        }
                    }
                }
                off += 2
            }
            return nil
        }
        return nil
    }

    private static func le16(_ data: Data, _ offset: Int) -> Int {
        guard offset + 2 <= data.count else { return 0 }
        let v: UInt16 = data.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: offset, as: UInt16.self) }
        return Int(v)
    }

    /// Decodes an uncompressed (BI_RGB) DIB into an NSImage. Handles 32-bpp BGRA and
    /// 24-bpp BGR pixels, paletted 8-bpp, and bottom-up / top-down row order.
    private static func imageFromDIB(bmi: Data, bits: Data) -> NSImage? {
        guard bmi.count >= 40 else { return nil }
        let w = le32at(bmi, 4)
        let hRaw = le32at(bmi, 8)
        let bpp = le16(bmi, 14)
        let compression = le32at(bmi, 16)
        let clrUsed = le32at(bmi, 32)
        let topDown = hRaw < 0
        let h = abs(hRaw)
        guard w > 0, h > 0, w < 30000, h < 30000, compression == 0, bits.count > 0 else { return nil }

        let rowBytes = (w * bpp / 8 + 3) & ~3
        guard bits.count >= rowBytes * h else { return nil }

        var rgba = [UInt8](repeating: 0, count: w * h * 4)

        func row(_ y: Int) -> Int { (topDown ? y : h - 1 - y) * rowBytes }

        switch bpp {
        case 32:
            bits.withUnsafeBytes { (raw: UnsafeRawBufferPointer) in
                for y in 0..<h {
                    let src = row(y)
                    for x in 0..<w {
                        let s = src + x * 4
                        let d = (y * w + x) * 4
                        rgba[d] = raw[s + 2]     // R
                        rgba[d + 1] = raw[s + 1] // G
                        rgba[d + 2] = raw[s]     // B
                        rgba[d + 3] = 255        // BI_RGB has no real alpha
                    }
                }
            }
        case 24:
            bits.withUnsafeBytes { (raw: UnsafeRawBufferPointer) in
                for y in 0..<h {
                    let src = row(y)
                    for x in 0..<w {
                        let s = src + x * 3
                        let d = (y * w + x) * 4
                        rgba[d] = raw[s + 2]
                        rgba[d + 1] = raw[s + 1]
                        rgba[d + 2] = raw[s]
                        rgba[d + 3] = 255
                    }
                }
            }
        case 8:
            // Palette follows the 40-byte header (or the 108/124-byte V4/V5 header)
            let headerSize = le32at(bmi, 0)
            var palette: [[UInt8]] = []
            let entries = clrUsed > 0 ? clrUsed : (1 << min(8, bpp))
            if bmi.count >= headerSize + Int(entries) * 4 {
                for i in 0..<Int(entries) {
                    let p = headerSize + i * 4
                    palette.append([le8(bmi, p + 2), le8(bmi, p + 1), le8(bmi, p)]) // BGR → RGB
                }
            }
            guard !palette.isEmpty else { return nil }
            bits.withUnsafeBytes { (raw: UnsafeRawBufferPointer) in
                for y in 0..<h {
                    let src = row(y)
                    for x in 0..<w {
                        let idx = Int(raw[src + x])
                        let c = idx < palette.count ? palette[idx] : [0, 0, 0]
                        let d = (y * w + x) * 4
                        rgba[d] = c[0]; rgba[d + 1] = c[1]; rgba[d + 2] = c[2]; rgba[d + 3] = 255
                    }
                }
            }
        default:
            return nil
        }

        let out = rgba.withUnsafeBufferPointer { buf -> CGImage? in
            guard let base = buf.baseAddress else { return nil }
            let ctx = CGContext(
                data: UnsafeMutableRawPointer(mutating: base),
                width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
            return ctx?.makeImage()
        }
        guard let cg = out else { return nil }
        return NSImage(cgImage: cg, size: NSSize(width: cg.width, height: cg.height))
    }

    private static func le8(_ data: Data, _ offset: Int) -> UInt8 {
        guard offset + 1 <= data.count else { return 0 }
        return data[offset]
    }

    private static func le32at(_ data: Data, _ offset: Int) -> Int {
        guard offset + 4 <= data.count else { return 0 }
        let v: UInt32 = data.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: offset, as: UInt32.self) }
        return Int(v)
    }

    /// Visible stand-in for images that could not be decoded, so imported slides keep
    /// their structure instead of silently losing content.
    private static func makeUnsupportedImagePlaceholder(
        name: String, x: Double, y: Double, w: Double, h: Double,
        rotation: Double, zIndex: Int, detail: String
    ) -> [CanvasElement] {
        guard w > 4, h > 4 else { return [] }
        return [
            CanvasElement(
                name: name,
                payload: .shape(ShapeContent(
                    kind: .roundedRectangle,
                    cornerRadius: 6,
                    fill: .solid(CodableColor(red: 0.93, green: 0.93, blue: 0.95, opacity: 1)),
                    stroke: StrokeStyle(isEnabled: true, color: CodableColor(hex: "#B8B8C0"), lineWidth: 1, dashPattern: .dashed)
                )),
                x: x, y: y, width: w, height: h,
                rotation: rotation, zIndex: zIndex
            ),
            CanvasElement(
                name: "Unsupported image label",
                payload: .text(TextContent(
                    text: "🖼 \(detail) image\n(decode unsupported — replace with your own)",
                    fontFamily: "Helvetica Neue",
                    fontSize: max(9, min(14, h * 0.12)),
                    fontWeight: 500,
                    alignment: .center,
                    textColor: CodableColor(hex: "#6B6B74"),
                    letterSpacing: 0,
                    lineSpacing: 2
                )),
                x: x + 4, y: y + h / 2 - 18, width: max(20, w - 8), height: 36,
                rotation: rotation, zIndex: zIndex + 1
            )
        ]
    }

    // MARK: Native PowerPoint Charts (c:chart → rendered bar/line/pie image)

    fileprivate enum PPTXChartKind {
        case barCol, barHorz, line, pie, area, scatter
    }

    private struct PPTXChartSeries {
        var name: String = ""
        var categories: [String] = []
        var values: [Double] = []
        var colorHex: String? = nil
    }

    /// Parses ppt/charts/chartN.xml (via the slide relationship) and renders the chart
    /// with CoreGraphics into a crisp image element at the graphic frame's position.
    private static func parseChart(
        _ frameNode: XMLElement,
        chartTarget: String,
        tempDir: URL,
        theme: PPTXTheme,
        groupStack: [GroupTransform],
        zIndex: inout Int
    ) -> CanvasElement? {
        let chartURL = tempDir.appendingPathComponent("ppt").appendingPathComponent(normalizeTarget(chartTarget))
        guard let data = try? Data(contentsOf: chartURL),
              let doc = try? XMLDocument(data: data),
              let root = doc.rootElement() else { return nil }

        guard let plotArea = root.elements(forName: "c:chart").first?.elements(forName: "c:plotArea").first else { return nil }

        // Detect chart type
        var kind: PPTXChartKind = .barCol
        var seriesElems: [XMLElement] = []
        if let bar = plotArea.elements(forName: "c:barChart").first {
            seriesElems = bar.elements(forName: "c:ser")
            let dir = bar.elements(forName: "c:barDir").first?.attribute(forName: "val")?.stringValue ?? "col"
            kind = dir == "bar" ? .barHorz : .barCol
        } else if let line = plotArea.elements(forName: "c:lineChart").first {
            seriesElems = line.elements(forName: "c:ser")
            kind = .line
        } else if let pie = plotArea.elements(forName: "c:pieChart").first {
            seriesElems = pie.elements(forName: "c:ser")
            kind = .pie
        } else if let area = plotArea.elements(forName: "c:areaChart").first {
            seriesElems = area.elements(forName: "c:ser")
            kind = .area
        } else if plotArea.elements(forName: "c:scatterChart").first != nil {
            seriesElems = plotArea.elements(forName: "c:scatterChart").first!.elements(forName: "c:ser")
            kind = .scatter
        }
        guard !seriesElems.isEmpty else { return nil }

        // Parse series (cached values — no external workbook needed)
        var series: [PPTXChartSeries] = []
        for serEl in seriesElems {
            var s = PPTXChartSeries()
            if let txCache = serEl.elements(forName: "c:tx").first?.elements(forName: "c:strRef").first?.elements(forName: "c:strCache").first {
                s.name = txCache.elements(forName: "c:pt").first?.elements(forName: "c:v").first?.stringValue ?? ""
            }
            let catRef = serEl.elements(forName: "c:cat").first
            let strCache = catRef?.elements(forName: "c:strRef").first?.elements(forName: "c:strCache").first
            let numCatCache = catRef?.elements(forName: "c:numRef").first?.elements(forName: "c:numCache").first
            var cats: [(Int, String)] = []
            for pt in strCache?.elements(forName: "c:pt") ?? [] {
                if let idx = Int(pt.attribute(forName: "idx")?.stringValue ?? ""), let v = pt.elements(forName: "c:v").first?.stringValue {
                    cats.append((idx, v))
                }
            }
            for pt in numCatCache?.elements(forName: "c:pt") ?? [] {
                if let idx = Int(pt.attribute(forName: "idx")?.stringValue ?? ""), let v = pt.elements(forName: "c:v").first?.stringValue {
                    cats.append((idx, v))
                }
            }
            s.categories = cats.sorted { $0.0 < $1.0 }.map { $0.1 }

            var vals: [(Int, Double)] = []
            let valCache = serEl.elements(forName: "c:val").first?.elements(forName: "c:numRef").first?.elements(forName: "c:numCache").first
            for pt in valCache?.elements(forName: "c:pt") ?? [] {
                if let idx = Int(pt.attribute(forName: "idx")?.stringValue ?? ""),
                   let v = Double(pt.elements(forName: "c:v").first?.stringValue ?? "") {
                    vals.append((idx, v))
                }
            }
            s.values = vals.sorted { $0.0 < $1.0 }.map { $0.1 }

            // Explicit series color from spPr solidFill srgbClr
            if let srgb = serEl.elements(forName: "c:spPr").first?.elements(forName: "a:solidFill").first?.elements(forName: "a:srgbClr").first?.attribute(forName: "val")?.stringValue {
                s.colorHex = "#" + srgb
            }
            if !s.values.isEmpty {
                series.append(s)
            }
        }
        guard !series.isEmpty else { return nil }

        // Chart title
        var chartTitle: String? = nil
        if let titleEl = root.elements(forName: "c:chart").first?.elements(forName: "c:title").first {
            var t = ""
            for v in titleEl.elements(forName: "c:tx").first?.elements(forName: "c:rich").first?.elements(forName: "a:p").first?.elements(forName: "a:r") ?? [] {
                t += v.elements(forName: "a:t").first?.stringValue ?? ""
            }
            if !t.isEmpty { chartTitle = t }
        }

        // Geometry (EMU → px, group-aware)
        guard let xfrm = frameNode.elements(forName: "p:xfrm").first else { return nil }
        let gx = emu(xfrm.elements(forName: "a:off").first?.attribute(forName: "x")?.stringValue)
        let gy = emu(xfrm.elements(forName: "a:off").first?.attribute(forName: "y")?.stringValue)
        let gw = emu(xfrm.elements(forName: "a:ext").first?.attribute(forName: "cx")?.stringValue)
        let gh = emu(xfrm.elements(forName: "a:ext").first?.attribute(forName: "cy")?.stringValue)
        guard gw > 40, gh > 40 else { return nil }
        var rect = CGRect(x: gx, y: gy, width: gw, height: gh)
        for g in groupStack.reversed() { rect = g.apply(rect) }
        let fx = rect.minX / emuPerPx
        let fy = rect.minY / emuPerPx
        let fw = rect.width / emuPerPx
        let fh = rect.height / emuPerPx

        // Render at 2× for crisp text
        let scale: CGFloat = 2.0
        let w = fw * scale
        let h = fh * scale
        let image = renderChartImage(series: series, kind: kind, title: chartTitle, width: w, height: h, theme: theme)
        guard let base64 = ImageUtils.base64String(from: image, allowJPEG: false) else { return nil }

        zIndex += 1
        return CanvasElement(
            name: "Chart\(chartTitle.map { ": \($0)" } ?? "")",
            payload: .image(ImageContent(
                imageBase64: base64,
                contentMode: .fit,
                cornerRadius: 0,
                originalWidth: Double(w),
                originalHeight: Double(h)
            )),
            x: fx, y: fy,
            width: fw, height: fh,
            zIndex: zIndex
        )
    }

    /// Renders a chart (axes, gridlines, series, labels, legend) with CoreGraphics.
    private static func renderChartImage(
        series: [PPTXChartSeries],
        kind: PPTXChartKind,
        title: String?,
        width: CGFloat,
        height: CGFloat,
        theme: PPTXTheme
    ) -> NSImage {
        let officePalette = ["#4472C4", "#ED7D31", "#A5A5A5", "#FFC000", "#5B9BD5", "#70AD47", "#264478", "#9E480E"]

        let image = NSImage(size: NSSize(width: width, height: height), flipped: false) { _ in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }

            // Flip to y-down for easier layout math
            context.translateBy(x: 0, y: height)
            context.scaleBy(x: 1, y: -1)
            func Y(_ v: CGFloat) -> CGFloat { height - v }

            let bg = NSColor.white
            context.setFillColor(bg.cgColor)
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))

            let ink = NSColor(srgbRed: 0.16, green: 0.16, blue: 0.18, alpha: 1)
            let grid = NSColor(white: 0.88, alpha: 1)

            var top: CGFloat = 10
            if let title = title, !title.isEmpty {
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: max(11, height * 0.045), weight: .bold),
                    .foregroundColor: ink
                ]
                (title as NSString).draw(at: CGPoint(x: 12, y: Y(top + 14)), withAttributes: attrs)
                top += 26
            }

            let legendSpace: CGFloat = series.count > 1 ? 24 : 0
            let plot = CGRect(x: 46, y: top + 6, width: width - 60, height: height - top - 30 - legendSpace)

            func seriesColor(_ i: Int, _ explicit: String?) -> NSColor {
                if let hex = explicit { return NSColor(hex: hex) }
                let hex = officePalette[i % officePalette.count]
                return NSColor(hex: hex)
            }

            switch kind {
            case .pie:
                let data = series[0]
                let total = max(0.0001, data.values.reduce(0, +))
                let center = CGPoint(x: plot.midX, y: Y(plot.midY))
                let radius = min(plot.width, plot.height) / 2.0 - 6
                var startAngle: CGFloat = -.pi / 2
                let pieColors: [NSColor] = data.values.indices.map { i in
                    seriesColor(i, nil)
                }
                for (i, v) in data.values.enumerated() {
                    let sweep = CGFloat(v / total) * 2 * .pi
                    let path = CGMutablePath()
                    path.move(to: center)
                    path.addArc(center: center, radius: radius, startAngle: -startAngle, endAngle: -(startAngle + sweep), clockwise: true)
                    path.closeSubpath()
                    context.setFillColor(pieColors[i].cgColor)
                    context.addPath(path)
                    context.fillPath()
                    context.setStrokeColor(NSColor.white.cgColor)
                    context.setLineWidth(1.5)
                    context.addPath(path)
                    context.strokePath()
                    startAngle += sweep
                }
                // Legend for pie
                drawPieLegend(context, categories: data.categories, colors: pieColors, plot: plot, canvasH: height)

            default:
                let catCount = max(1, series.map { $0.values.count }.max() ?? 1)
                let allValues = series.flatMap { $0.values }
                var maxVal = allValues.max() ?? 1
                var minVal = allValues.min() ?? 0
                if minVal > 0 { minVal = 0 }
                if maxVal == minVal { maxVal = minVal + 1 }
                maxVal = niceCeil(maxVal)

                // Gridlines & value labels
                let gridCount = 4
                context.setStrokeColor(grid.cgColor)
                context.setLineWidth(0.8)
                let labelAttrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.monospacedDigitSystemFont(ofSize: 8.5, weight: .regular),
                    .foregroundColor: NSColor(white: 0.42, alpha: 1)
                ]
                for g in 0...gridCount {
                    let frac = CGFloat(g) / CGFloat(gridCount)
                    let value = minVal + (maxVal - minVal) * Double(frac)
                    let y = Y(plot.minY + plot.height * frac)
                    context.move(to: CGPoint(x: plot.minX, y: y))
                    context.addLine(to: CGPoint(x: plot.maxX, y: y))
                    context.strokePath()
                    let label = formatChartNumber(value)
                    let size = (label as NSString).size(withAttributes: labelAttrs)
                    (label as NSString).draw(at: CGPoint(x: plot.minX - size.width - 5, y: y - size.height / 2), withAttributes: labelAttrs)
                }

                let slot = plot.width / CGFloat(catCount)
                let catAttrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 8.5, weight: .medium),
                    .foregroundColor: NSColor(white: 0.35, alpha: 1)
                ]
                let categories = series.first?.categories ?? []
                if kind != .barHorz {
                    for c in 0..<catCount {
                        if c < categories.count {
                            let label = categories[c]
                            let size = (label as NSString).size(withAttributes: catAttrs)
                            let cx = plot.minX + slot * CGFloat(c) + slot / 2.0
                            (label as NSString).draw(at: CGPoint(x: cx - size.width / 2, y: Y(plot.maxY + 14)), withAttributes: catAttrs)
                        }
                    }
                }

                let zeroY = Y(plot.minY + plot.height * CGFloat((0 - minVal) / max(0.0001, maxVal - minVal)))
                let groupCount = series.count
                let barW = kind == .barHorz
                    ? plot.height / CGFloat(catCount) * 0.62 / CGFloat(max(1, groupCount))
                    : slot * 0.62 / CGFloat(max(1, groupCount))

                for (si, s) in series.enumerated() {
                    let color = seriesColor(si, s.colorHex)
                    for (ci, v) in s.values.enumerated() {
                        guard ci < catCount else { break }
                        let frac = CGFloat((v - minVal) / max(0.0001, maxVal - minVal))
                        switch kind {
                        case .barCol, .barHorz:
                            let groupOffset = CGFloat(si) * barW - CGFloat(groupCount) * barW / 2.0
                            if kind == .barCol {
                                let cx = plot.minX + slot * CGFloat(ci) + slot / 2.0 + groupOffset
                                let barRect = CGRect(x: cx, y: min(zeroY, Y(plot.minY + plot.height * frac)), width: barW * 0.8, height: abs(Y(plot.minY + plot.height * frac) - zeroY))
                                context.setFillColor(color.cgColor)
                                context.fill(barRect)
                            } else {
                                let cy = plot.minY + plot.height * (CGFloat(ci) + 0.5) / CGFloat(catCount) + groupOffset
                                let valueX = plot.minX + plot.width * frac
                                let barRect = CGRect(x: min(plot.minX, valueX), y: Y(cy) - barW * 0.8, width: abs(valueX - plot.minX), height: barW * 0.8)
                                context.setFillColor(color.cgColor)
                                context.fill(barRect)
                            }
                        case .line, .area:
                            let cx = plot.minX + slot * CGFloat(ci) + slot / 2.0
                            let cy = Y(plot.minY + plot.height * frac)
                            if si == 0 {
                                // draw later as polyline; store nothing here
                            }
                            _ = cx; _ = cy
                        default:
                            break
                        }
                    }
                }

                // Lines & areas drawn as connected polylines
                if kind == .line || kind == .area {
                    for (si, s) in series.enumerated() {
                        let color = seriesColor(si, s.colorHex)
                        var points: [CGPoint] = []
                        for (ci, v) in s.values.enumerated() {
                            let frac = CGFloat((v - minVal) / max(0.0001, maxVal - minVal))
                            let cx = plot.minX + slot * CGFloat(ci) + slot / 2.0
                            let cy = plot.minY + plot.height * frac
                            points.append(CGPoint(x: cx, y: Y(cy)))
                        }
                        if kind == .area && !points.isEmpty {
                            var areaPath = CGMutablePath()
                            areaPath.move(to: CGPoint(x: points[0].x, y: zeroY))
                            for p in points { areaPath.addLine(to: p) }
                            areaPath.addLine(to: CGPoint(x: points[points.count - 1].x, y: zeroY))
                            areaPath.closeSubpath()
                            context.setFillColor(color.withAlphaComponent(0.18).cgColor)
                            context.addPath(areaPath)
                            context.fillPath()
                        }
                        guard points.count > 1 else { continue }
                        let linePath = CGMutablePath()
                        linePath.move(to: points[0])
                        for p in points.dropFirst() { linePath.addLine(to: p) }
                        context.setStrokeColor(color.cgColor)
                        context.setLineWidth(2.2)
                        context.addPath(linePath)
                        context.strokePath()
                        for p in points {
                            let dot = CGRect(x: p.x - 2.6, y: p.y - 2.6, width: 5.2, height: 5.2)
                            context.setFillColor(color.cgColor)
                            context.fillEllipse(in: dot)
                        }
                    }
                }

                // Axis baseline
                context.setStrokeColor(NSColor(white: 0.6, alpha: 1).cgColor)
                context.setLineWidth(1)
                if kind != .barHorz {
                    context.move(to: CGPoint(x: plot.minX, y: zeroY))
                    context.addLine(to: CGPoint(x: plot.maxX, y: zeroY))
                    context.strokePath()
                }
            }

            // Legend (non-pie)
            if series.count > 1 && kind != .pie {
                let legendAttrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 9, weight: .medium),
                    .foregroundColor: NSColor(white: 0.3, alpha: 1)
                ]
                var lx: CGFloat = plot.minX
                let ly = height - 14
                for (si, s) in series.enumerated() {
                    let swatch = CGRect(x: lx, y: Y(ly) - 3, width: 9, height: 9)
                    context.setFillColor(seriesColor(si, s.colorHex).cgColor)
                    context.fill(swatch)
                    let name = s.name.isEmpty ? "Series \(si + 1)" : s.name
                    (name as NSString).draw(at: CGPoint(x: lx + 13, y: Y(ly)), withAttributes: legendAttrs)
                    lx += 13 + (name as NSString).size(withAttributes: legendAttrs).width + 14
                    if lx > width - 60 { break }
                }
            }
            return true
        }
        return image
    }

    private static func drawPieLegend(_ context: CGContext, categories: [String], colors: [NSColor], plot: CGRect, canvasH: CGFloat) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 9, weight: .medium),
            .foregroundColor: NSColor(white: 0.3, alpha: 1)
        ]
        var ly = canvasH - 16
        var lx = plot.minX + 4
        for (i, cat) in categories.prefix(8).enumerated() {
            let swatch = CGRect(x: lx, y: canvasH - ly - 3, width: 9, height: 9)
            context.setFillColor(colors[i % colors.count].cgColor)
            context.fill(swatch)
            (cat as NSString).draw(at: CGPoint(x: lx + 13, y: canvasH - ly), withAttributes: attrs)
            lx += 13 + (cat as NSString).size(withAttributes: attrs).width + 12
            if lx > plot.maxX - 40 { lx = plot.minX + 4; ly -= 14; if ly < 4 { break } }
        }
    }

    private static func niceCeil(_ value: Double) -> Double {
        guard value > 0 else { return 1 }
        let exp = pow(10, floor(log10(value)))
        let f = value / exp
        let nice: Double = f <= 1 ? 1 : f <= 2 ? 2 : f <= 5 ? 5 : 10
        return nice * exp
    }

    private static func formatChartNumber(_ v: Double) -> String {
        if abs(v.rounded() - v) < 0.0001 {
            let i = Int(v)
            if abs(i) >= 1_000_000 { return String(format: "%.1fM", Double(i) / 1_000_000) }
            if abs(i) >= 10_000 { return String(format: "%.0fK", Double(i) / 1_000) }
            return "\(i)"
        }
        return String(format: "%.1f", v)
    }

    // MARK: SmartArt (drawing diagram) — render node text as a styled vertical list

    private static func parseSmartArtFallback(
        _ frameNode: XMLElement,
        _ relIds: XMLElement,
        theme: PPTXTheme,
        relMap: [String: String],
        tempDir: URL,
        groupStack: [GroupTransform],
        zIndex: inout Int
    ) -> [CanvasElement]? {
        guard let dmId = relIds.attribute(forName: "r:dm")?.stringValue,
              let dataTarget = relMap[dmId] else { return nil }
        let dataURL = tempDir.appendingPathComponent("ppt").appendingPathComponent(normalizeTarget(dataTarget))
        guard let data = try? Data(contentsOf: dataURL),
              let doc = try? XMLDocument(data: data),
              let root = doc.rootElement() else { return nil }

        // Diagram nodes (dgm:pt with type "node" or no type) carrying text
        var texts: [String] = []
        for pt in root.elements(forName: "dgm:ptLst").first?.elements(forName: "dgm:pt") ?? [] {
            let type = pt.attribute(forName: "type")?.stringValue ?? "node"
            guard type == "node" else { continue }
            let runs = pt.elements(forName: "dgm:t").first?.elements(forName: "a:bodyP").first
            let body = pt.elements(forName: "dgm:t").first
            var line = ""
            for r in body?.elements(forName: "a:p") ?? [] {
                for run in r.elements(forName: "a:r") {
                    line += decodeTextWhitespace(run.elements(forName: "a:t").first?.stringValue ?? "")
                }
                line += "\n"
            }
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { texts.append(trimmed) }
        }
        guard !texts.isEmpty else { return nil }

        guard let xfrm = frameNode.elements(forName: "p:xfrm").first else { return nil }
        let gx = emu(xfrm.elements(forName: "a:off").first?.attribute(forName: "x")?.stringValue)
        let gy = emu(xfrm.elements(forName: "a:off").first?.attribute(forName: "y")?.stringValue)
        let gw = emu(xfrm.elements(forName: "a:ext").first?.attribute(forName: "cx")?.stringValue)
        let gh = emu(xfrm.elements(forName: "a:ext").first?.attribute(forName: "cy")?.stringValue)
        guard gw > 0, gh > 0 else { return nil }

        var rect = CGRect(x: gx, y: gy, width: gw, height: gh)
        for g in groupStack.reversed() { rect = g.apply(rect) }
        let fx = rect.minX / emuPerPx
        let fy = rect.minY / emuPerPx
        let fw = rect.width / emuPerPx
        let fh = rect.height / emuPerPx

        let accent = theme.color("accent1") ?? CodableColor(hex: "#4472C4")
        var out: [CanvasElement] = []
        let slotH = fh / Double(texts.count)
        for (i, txt) in texts.enumerated() {
            let inset = min(24, fw * 0.06)
            let chipY = fy + slotH * Double(i) + slotH * 0.12
            let chipH = slotH * 0.76
            let isFirst = i == 0
            let fill = isFirst ? accent : mixColor(accent, with: .white, amount: 0.82)
            let textColor: CodableColor = isFirst ? .white : .inkBlack

            zIndex += 1
            out.append(CanvasElement(
                name: "SmartArt Item \(i + 1)",
                payload: .shape(ShapeContent(
                    kind: .roundedRectangle,
                    cornerRadius: min(12, chipH * 0.3),
                    fill: .solid(fill),
                    stroke: StrokeStyle(isEnabled: false)
                )),
                x: fx + inset, y: chipY,
                width: fw - inset * 2, height: chipH,
                zIndex: zIndex
            ))

            zIndex += 1
            out.append(CanvasElement(
                name: "SmartArt Text \(i + 1)",
                payload: .text(TextContent(
                    text: txt,
                    fontFamily: theme.minorFont,
                    fontSize: max(12, min(chipH * 0.42, 24)),
                    fontWeight: isFirst ? 700 : 400,
                    alignment: .center,
                    textColor: textColor,
                    letterSpacing: 0,
                    lineSpacing: 0
                )),
                x: fx + inset + 12, y: chipY,
                width: fw - inset * 2 - 24, height: chipH,
                zIndex: zIndex
            ))
        }
        return out.isEmpty ? nil : out
    }

    // MARK: Tables (a:tbl) → rect + text grid

    /// Predefined table style (from ppt/tableStyles.xml), simplified
    private struct PPTXTableStyle {
        var wholeFill: ResolvedColor?
        var firstRowFill: ResolvedColor?
        var lastRowFill: ResolvedColor?
        var band1HFill: ResolvedColor?
        var firstRowTextColor: ResolvedColor?
        var firstRowBold = false
    }

    private static func parseTableStyles(tempDir: URL, theme: PPTXTheme) -> [String: PPTXTableStyle] {
        var result: [String: PPTXTableStyle] = [:]
        let url = tempDir.appendingPathComponent("ppt/tableStyles.xml")
        guard let data = try? Data(contentsOf: url),
              let doc = try? XMLDocument(data: data),
              let root = doc.rootElement() else { return result }

        func fill(of part: XMLElement?) -> ResolvedColor? {
            guard let part = part else { return nil }
            if let solid = part.elements(forName: "a:fill").first?.elements(forName: "a:solidFill").first {
                return resolveColor(solid, theme: theme)
            }
            if let fr = part.elements(forName: "a:fillRef").first, fr.attribute(forName: "idx")?.stringValue != "0" {
                return resolveColor(fr, theme: theme)
            }
            if let solid = part.elements(forName: "a:solidFill").first {
                return resolveColor(solid, theme: theme)
            }
            return nil
        }

        for styleEl in root.elements(forName: "a:tblStyle") {
            guard let styleId = styleEl.attribute(forName: "styleId")?.stringValue else { continue }
            var ts = PPTXTableStyle()
            ts.wholeFill = fill(of: styleEl.elements(forName: "a:wholeTbl").first)
            ts.firstRowFill = fill(of: styleEl.elements(forName: "a:firstRow").first)
            ts.lastRowFill = fill(of: styleEl.elements(forName: "a:lastRow").first)
            ts.band1HFill = fill(of: styleEl.elements(forName: "a:band1H").first)
            if let tx = styleEl.elements(forName: "a:firstRow").first?.elements(forName: "a:tcTxStyle").first {
                if let solid = tx.elements(forName: "a:solidFill").first {
                    ts.firstRowTextColor = resolveColor(solid, theme: theme)
                }
                ts.firstRowBold = tx.attribute(forName: "b")?.stringValue == "1"
            }
            result[styleId] = ts
        }
        return result
    }

    private static func parseTable(
        _ tbl: XMLElement,
        frameNode: XMLElement,
        theme: PPTXTheme,
        tableStyles: [String: PPTXTableStyle],
        groupStack: [GroupTransform],
        zIndex: inout Int
    ) -> [CanvasElement]? {
        guard let xfrm = frameNode.elements(forName: "p:xfrm").first else { return nil }

        let gx = emu(xfrm.elements(forName: "a:off").first?.attribute(forName: "x")?.stringValue)
        let gy = emu(xfrm.elements(forName: "a:off").first?.attribute(forName: "y")?.stringValue)
        let gw = emu(xfrm.elements(forName: "a:ext").first?.attribute(forName: "cx")?.stringValue)
        let gh = emu(xfrm.elements(forName: "a:ext").first?.attribute(forName: "cy")?.stringValue)
        guard gw > 0, gh > 0 else { return nil }

        var rect = CGRect(x: gx, y: gy, width: gw, height: gh)
        for g in groupStack.reversed() { rect = g.apply(rect) }
        let ox = rect.minX / emuPerPx
        let oy = rect.minY / emuPerPx
        let tw = rect.width / emuPerPx
        let th = rect.height / emuPerPx

        // Column widths & row heights (EMU)
        let colWidths = tbl.elements(forName: "a:tblGrid").first?.elements(forName: "a:gridCol").compactMap { Double($0.attribute(forName: "w")?.stringValue ?? "") } ?? []
        guard !colWidths.isEmpty else { return nil }
        let totalColW = colWidths.reduce(0, +)

        // Table style lookup (firstRow / bandRow flags + styleId)
        let tblPr = tbl.elements(forName: "a:tblPr").first
        let firstRowOn = tblPr?.attribute(forName: "firstRow")?.stringValue == "1"
        let lastRowOn = tblPr?.attribute(forName: "lastRow")?.stringValue == "1"
        let bandRowOn = tblPr?.attribute(forName: "bandRow")?.stringValue != "0"
        let styleId = tblPr?.elements(forName: "a:tableStyleId").first?.stringValue
        var style = styleId.flatMap { tableStyles[$0] }
        if style == nil, styleId != nil {
            // Built-in PowerPoint table style (not stored in tableStyles.xml).
            // Approximate the default "Medium Style 2 - Accent 1" look from the theme.
            let accent = theme.color("accent1") ?? CodableColor(hex: "#4472C4")
            style = PPTXTableStyle(
                wholeFill: ResolvedColor(.white, 1),
                firstRowFill: ResolvedColor(accent, 1),
                lastRowFill: nil,
                band1HFill: ResolvedColor(mixColor(accent, with: .white, amount: 0.8), 1),
                firstRowTextColor: ResolvedColor(.white, 1),
                firstRowBold: true
            )
        }

        var elements: [CanvasElement] = []
        var rowY: Double = 0
        let rows = tbl.elements(forName: "a:tr")
        let totalRowH = rows.compactMap { Double($0.attribute(forName: "h")?.stringValue ?? "") }.reduce(0, +)
        let rowCount = rows.count

        for (rowIdx, tr) in rows.enumerated() {
            let rowHEmu = Double(tr.attribute(forName: "h")?.stringValue ?? "") ?? (totalRowH > 0 ? totalRowH / Double(rows.count) : gh / Double(max(1, rows.count)))
            let rowHPx = rowHEmu / emuPerPx

            // Style resolution for this row
            var rowFill: ResolvedColor? = nil
            var rowTextColor: ResolvedColor? = nil
            var rowBold = false
            if firstRowOn && rowIdx == 0 {
                rowFill = style?.firstRowFill
                rowTextColor = style?.firstRowTextColor
                rowBold = style?.firstRowBold ?? false
            } else if lastRowOn && rowIdx == rowCount - 1 && rowCount > 1 {
                rowFill = style?.lastRowFill
            } else if bandRowOn && style?.band1HFill != nil && (rowIdx % 2) == 1 {
                rowFill = style?.band1HFill
            }
            if rowFill == nil { rowFill = style?.wholeFill }

            var colX: Double = 0
            let cells = tr.elements(forName: "a:tc")
            for (colIdx, tc) in cells.enumerated() {
                guard colIdx < colWidths.count else { break }
                let colWPx = (colWidths[colIdx] / totalColW) * tw
                let tcPr = tc.elements(forName: "a:tcPr").first
                var cellFill: FillStyle?
                if let tcPr = tcPr {
                    if let solid = tcPr.elements(forName: "a:solidFill").first {
                        let rc = resolveColor(solid, theme: theme)
                        cellFill = .solid(CodableColor(red: rc.color.red, green: rc.color.green, blue: rc.color.blue, opacity: rc.color.opacity * rc.alpha))
                    } else if tcPr.elements(forName: "a:noFill").first != nil {
                        cellFill = .solid(.clear)
                    }
                    if tc.attribute(forName: "hMerge")?.stringValue == "1" || tc.attribute(forName: "vMerge")?.stringValue == "1" {
                        colX += colWPx
                        continue
                    }
                }
                if cellFill == nil, let rf = rowFill {
                    cellFill = .solid(CodableColor(red: rf.color.red, green: rf.color.green, blue: rf.color.blue, opacity: rf.color.opacity * rf.alpha))
                }
                if cellFill == nil { cellFill = .solid(.white) }

                // Subtle border so cells are visible on white fills (PowerPoint tables always show gridlines)
                let f = (cellFill ?? .solid(.white)).solidColor
                let lum = f.red * 0.299 + f.green * 0.587 + f.blue * 0.114
                let borderColor: CodableColor = lum > 0.55
                    ? CodableColor(hex: "#BFBFBF")
                    : CodableColor(red: 1, green: 1, blue: 1, opacity: 0.85)

                zIndex += 1
                elements.append(CanvasElement(
                    name: "Table Cell",
                    payload: .shape(ShapeContent(
                        kind: .rectangle,
                        cornerRadius: 0,
                        fill: cellFill ?? .solid(.white),
                        stroke: StrokeStyle(isEnabled: true, color: borderColor, lineWidth: 1)
                    )),
                    x: ox + colX, y: oy + rowY,
                    width: colWPx, height: rowHPx,
                    zIndex: zIndex
                ))

                // Cell text
                if let txBody = tc.elements(forName: "a:txBody").first {
                    var textZ = zIndex
                    // Cell insets (marL/marR/marT/marB on a:tcPr, default 91440/45720 EMU)
                    let marL = emu(tcPr?.attribute(forName: "marL")?.stringValue, default: 91440) / emuPerPx
                    let marR = emu(tcPr?.attribute(forName: "marR")?.stringValue, default: 91440) / emuPerPx
                    let marT = emu(tcPr?.attribute(forName: "marT")?.stringValue, default: 45720) / emuPerPx
                    let marB = emu(tcPr?.attribute(forName: "marB")?.stringValue, default: 45720) / emuPerPx
                    let anchorC = tcPr?.attribute(forName: "anchor")?.stringValue ?? "t"
                    var textEls = parseTextBody(
                        txBody, theme: theme,
                        x: ox + colX, y: oy + rowY, w: colWPx, h: rowHPx, rotation: 0,
                        lIns: marL, rIns: marR, tIns: marT, bIns: marB,
                        autofitScale: 1.0, anchor: anchorC,
                        phType: nil, inheritedSizePt: nil,
                        majorFont: theme.majorFont, minorFont: theme.minorFont,
                        styleDefaultColor: rowTextColor,
                        slideW: tw, zIndex: &textZ
                    )
                    if !textEls.isEmpty {
                        // Table style bold (e.g. header rows)
                        if rowBold {
                            for i in textEls.indices {
                                if case .text(var t) = textEls[i].payload {
                                    t.fontWeight = 700
                                    textEls[i].payload = .text(t)
                                }
                            }
                        }
                        elements.append(contentsOf: textEls)
                        zIndex = textZ
                    }
                }
                colX += colWPx
            }
            rowY += rowHPx
            if rowIdx == rows.count - 1 { break }
        }

        // Outer table stroke on each cell is skipped; return the grid
        _ = th
        return elements.isEmpty ? nil : elements
    }

    // MARK: Custom Geometry (a:custGeom) → rasterized vector image

    private static func rasterizeCustomGeometry(
        _ custGeom: XMLElement,
        fill: FillStyle?,
        stroke: StrokeStyle?,
        x: Double, y: Double, w: Double, h: Double,
        rotation: Double, opacity: Double, zIndex: Int
    ) -> CanvasElement? {
        guard w > 1, h > 1 else { return nil }
        let pathList = custGeom.elements(forName: "a:pathLst").first
        guard let paths = pathList?.elements(forName: "a:path"), !paths.isEmpty else { return nil }

        let cgPath = CGMutablePath()
        for pathEl in paths {
            let pathW = emu(pathEl.attribute(forName: "w")?.stringValue, default: 0)
            let pathH = emu(pathEl.attribute(forName: "h")?.stringValue, default: 0)
            let sx = pathW > 0 ? w / pathW : 1
            let sy = pathH > 0 ? h / pathH : 1
            var current = CGPoint.zero
            var subpathOpen = false

            for cmd in pathEl.children ?? [] {
                guard let cmd = cmd as? XMLElement else { continue }
                let pts = cmd.elements(forName: "a:pt").map { pt -> CGPoint in
                    CGPoint(x: (Double(pt.attribute(forName: "x")?.stringValue ?? "0") ?? 0) * sx,
                            y: (Double(pt.attribute(forName: "y")?.stringValue ?? "0") ?? 0) * sy)
                }
                switch cmd.name ?? "" {
                case "a:moveTo":
                    if let p = pts.first { cgPath.move(to: p, transform: .identity); current = p; subpathOpen = true }
                case "a:lnTo":
                    for p in pts { cgPath.addLine(to: p, transform: .identity); current = p }
                    subpathOpen = !pts.isEmpty
                case "a:cubicBezTo" where pts.count >= 3:
                    cgPath.addCurve(to: pts[2], control1: pts[0], control2: pts[1], transform: .identity)
                    current = pts[2]
                case "a:quadBezTo" where pts.count >= 2:
                    cgPath.addQuadCurve(to: pts[1], control: pts[0], transform: .identity)
                    current = pts[1]
                case "a:close":
                    cgPath.closeSubpath()
                    subpathOpen = false
                    current = .zero
                case "a:arcTo":
                    // Elliptical arc: radii wR/hR (path space), start angle stAng, swing swAng.
                    // The current point lies on the ellipse at stAng; sweep swAng (clockwise, y-down).
                    let wR = (emu(cmd.attribute(forName: "wR")?.stringValue)) * sx
                    let hR = (emu(cmd.attribute(forName: "hR")?.stringValue)) * sy
                    let stAng = emu(cmd.attribute(forName: "stAng")?.stringValue) / 60000.0 * .pi / 180.0
                    let swAng = emu(cmd.attribute(forName: "swAng")?.stringValue) / 60000.0 * .pi / 180.0
                    if wR > 0 || hR > 0 {
                        let ccx = current.x - wR * cos(stAng)
                        let ccy = current.y - hR * sin(stAng)
                        let steps = max(4, min(64, Int(abs(swAng) / (.pi / 24))))
                        var last = current
                        for k in 1...steps {
                            let a = stAng + swAng * Double(k) / Double(steps)
                            last = CGPoint(x: ccx + wR * cos(a), y: ccy + hR * sin(a))
                            cgPath.addLine(to: last, transform: .identity)
                        }
                        current = last
                        subpathOpen = true
                    } else if let p = pts.last {
                        cgPath.addLine(to: p, transform: .identity)
                        current = p
                    }
                default:
                    break
                }
            }
            if subpathOpen { cgPath.closeSubpath() }
        }

        // Rasterize at 2x for crisp edges
        let scale: CGFloat = 2
        let size = NSSize(width: w * scale, height: h * scale)
        let image = NSImage(size: size, flipped: true) { _ in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            context.saveGState()
            context.scaleBy(x: scale, y: scale)
            context.addPath(cgPath)

            var fillColor = NSColor.clear
            if let f = fill {
                switch f.type {
                case .solid:
                    fillColor = NSColor(srgbRed: f.solidColor.red, green: f.solidColor.green, blue: f.solidColor.blue, alpha: f.solidColor.opacity)
                default:
                    // Gradients approximated by first stop color for freeform rasterization
                    if let stop = f.gradientStops.first {
                        fillColor = NSColor(srgbRed: stop.color.red, green: stop.color.green, blue: stop.color.blue, alpha: stop.color.opacity)
                    } else {
                        fillColor = NSColor(srgbRed: f.solidColor.red, green: f.solidColor.green, blue: f.solidColor.blue, alpha: f.solidColor.opacity)
                    }
                }
            }
            context.setFillColor(fillColor.cgColor)
            context.fillPath()

            if let s = stroke, s.isEnabled, s.lineWidth > 0 {
            context.setStrokeColor(NSColor(srgbRed: s.color.red, green: s.color.green, blue: s.color.blue, alpha: s.color.opacity).cgColor)
                context.setLineWidth(s.lineWidth)
                switch s.dashPattern {
                case .dashed: context.setLineDash(phase: 0, lengths: [s.lineWidth * 3, s.lineWidth * 3])
                case .dotted: context.setLineDash(phase: 0, lengths: [s.lineWidth, s.lineWidth * 2])
                case .solid: break
                }
                context.addPath(cgPath)
                context.strokePath()
            }
            context.restoreGState()
            return true
        }

        guard let base64 = ImageUtils.base64String(from: image) else { return nil }
        return CanvasElement(
            name: "Vector Shape",
            payload: .image(ImageContent(
                imageBase64: base64,
                contentMode: .fill,
                cornerRadius: 0,
                originalWidth: w,
                originalHeight: h
            )),
            x: x, y: y,
            width: max(2, w), height: max(2, h),
            rotation: rotation,
            opacity: opacity,
            zIndex: zIndex
        )
    }

    // MARK: Placeholders (layout & master inheritance)

    private static func placeholderMap(from doc: XMLDocument?) -> [String: PlaceholderInfo] {
        guard let root = doc?.rootElement(),
              let cSld = root.elements(forName: "p:cSld").first,
              let spTree = cSld.elements(forName: "p:spTree").first else { return [:] }

        var map: [String: PlaceholderInfo] = [:]

        // Master text styles (titleStyle / bodyStyle / otherStyle lvl1pPr defRPr sz)
        var masterStyles: [String: Double] = [:]
        if let txStyles = root.elements(forName: "p:txStyles").first {
            for (styleName, key) in [("p:titleStyle", "title"), ("p:bodyStyle", "body"), ("p:otherStyle", "other")] {
                if let style = txStyles.elements(forName: styleName).first,
                   let lvl1 = style.elements(forName: "a:lvl1pPr").first,
                   let defRPr = lvl1.elements(forName: "a:defRPr").first,
                   let sz = Double(defRPr.attribute(forName: "sz")?.stringValue ?? "") {
                    masterStyles[key] = sz / 100.0
                }
            }
        }

        for sp in spTree.elements(forName: "p:sp") {
            let ph = sp.elements(forName: "p:nvSpPr").first?.elements(forName: "p:nvPr").first?.elements(forName: "p:ph").first
            guard let ph = ph else { continue }
            let type = ph.attribute(forName: "type")?.stringValue ?? "body"
            let idx = ph.attribute(forName: "idx")?.stringValue ?? ""
            let key = phKey(type: type, idx: idx)

            var info = PlaceholderInfo()

            if let xfrm = sp.elements(forName: "p:spPr").first?.elements(forName: "a:xfrm").first {
                let x = emu(xfrm.elements(forName: "a:off").first?.attribute(forName: "x")?.stringValue)
                let y = emu(xfrm.elements(forName: "a:off").first?.attribute(forName: "y")?.stringValue)
                let w = emu(xfrm.elements(forName: "a:ext").first?.attribute(forName: "cx")?.stringValue)
                let h = emu(xfrm.elements(forName: "a:ext").first?.attribute(forName: "cy")?.stringValue)
                if w > 0, h > 0 {
                    info.frame = CGRect(x: x, y: y, width: w, height: h)
                }
            }

            // Font size from this placeholder's own lvl1pPr defRPr
            let isTitle = type == "title" || type == "ctrTitle"
            if let txBody = sp.elements(forName: "p:txBody").first {
                let bodyPr = txBody.elements(forName: "a:bodyPr").first
                _ = bodyPr
                if let lstStyle = txBody.elements(forName: "a:lstStyle").first,
                   let lvl1 = lstStyle.elements(forName: "a:lvl1pPr").first,
                   let defRPr = lvl1.elements(forName: "a:defRPr").first,
                   let sz = Double(defRPr.attribute(forName: "sz")?.stringValue ?? "") {
                    info.fontSizePx = (sz / 100.0) * ptToPx
                    info.fontPxIsTitle = isTitle
                }
            }
            if info.fontSizePx == nil {
                if isTitle, let s = masterStyles["title"] {
                    info.fontSizePx = s * ptToPx
                    info.fontPxIsTitle = true
                } else if let s = masterStyles["body"] {
                    info.fontSizePx = s * ptToPx
                }
            }

            map[key] = info
            map[type] = info // type-only fallback key
        }
        return map
    }

    private static func inheritedPlaceholder(
        phType: String?, phIdx: String?,
        layoutPH: [String: PlaceholderInfo], masterPH: [String: PlaceholderInfo]
    ) -> PlaceholderInfo {
        let type = phType ?? "body"
        let idx = phIdx ?? ""
        // Layout by exact (type,idx) → type-only; then master same chain
        if let hit = layoutPH[phKey(type: type, idx: idx)] ?? layoutPH[type] {
            return hit
        }
        if let hit = masterPH[phKey(type: type, idx: idx)] ?? masterPH[type] {
            return hit
        }
        return PlaceholderInfo()
    }

    private static func phKey(type: String, idx: String) -> String {
        idx.isEmpty ? type : "\(type)|\(idx)"
    }

    // MARK: Theme & Relationships

    private static func parseTheme(tempDir: URL) -> PPTXTheme {
        var theme = PPTXTheme()
        // Find first theme file (theme1.xml usually)
        let themeDir = tempDir.appendingPathComponent("ppt/theme")
        guard let files = try? FileManager.default.contentsOfDirectory(at: themeDir, includingPropertiesForKeys: nil).sorted(by: { $0.lastPathComponent < $1.lastPathComponent }),
              let themeURL = files.first(where: { $0.pathExtension == "xml" }),
              let doc = try? XMLDocument(contentsOf: themeURL),
              let clrScheme = doc.rootElement()?.elements(forName: "a:themeElements").first?.elements(forName: "a:clrScheme").first else {
            return theme
        }

        for child in clrScheme.children ?? [] {
            guard let el = child as? XMLElement, let rawName = el.name else { continue }
            let name = rawName.components(separatedBy: ":").last ?? rawName // strip "a:" prefix
            if let srgb = el.elements(forName: "a:srgbClr").first?.attribute(forName: "val")?.stringValue {
                theme.colors[name] = CodableColor(hex: "#" + srgb)
            } else if let sys = el.elements(forName: "a:sysClr").first {
                let last = sys.attribute(forName: "lastClr")?.stringValue ?? (sys.attribute(forName: "val")?.stringValue == "window" ? "FFFFFF" : "000000")
                theme.colors[name] = CodableColor(hex: "#" + last)
            }
        }

        if let fontScheme = doc.rootElement()?.elements(forName: "a:themeElements").first?.elements(forName: "a:fontScheme").first {
            if let major = fontScheme.elements(forName: "a:majorFont").first?.elements(forName: "a:latin").first?.attribute(forName: "typeface")?.stringValue, !major.isEmpty, !major.hasPrefix("+") {
                theme.majorFont = mapFontName(major)
            }
            if let minor = fontScheme.elements(forName: "a:minorFont").first?.elements(forName: "a:latin").first?.attribute(forName: "typeface")?.stringValue, !minor.isEmpty, !minor.hasPrefix("+") {
                theme.minorFont = mapFontName(minor)
            }
        }

        // fmtScheme lnStyleLst: widths (EMU) of the 3 named line styles
        if let fmtScheme = doc.rootElement()?.elements(forName: "a:themeElements").first?.elements(forName: "a:fmtScheme").first,
           let lnStyleLst = fmtScheme.elements(forName: "a:lnStyleLst").first {
            let widths = lnStyleLst.elements(forName: "a:ln").compactMap { ln -> Double? in
                guard let s = ln.attribute(forName: "w")?.stringValue, let v = Double(s) else { return nil }
                return v / emuPerPt
            }
            if widths.count == 3 { theme.lineStyleWidthsPt = widths }
        }
        return theme
    }

    /// Map common Windows/Office fonts to close macOS built-ins so text renders
    /// with near-identical metrics when the original font isn't installed.
    private static func mapFontName(_ name: String) -> String {
        let known: [String: String] = [
            "Calibri": "Avenir Next",
            "Calibri Light": "Avenir Next",
            "Cambria": "Georgia",
            "Candara": "Avenir Next",
            "Corbel": "Avenir Next",
            "Constantia": "Georgia",
            "Segoe UI": "Helvetica Neue",
            "Tahoma": "Geneva",
            "MS Gothic": "Hiragino Sans",
            "Meiryo": "Hiragino Sans",
            "Microsoft YaHei": "PingFang SC",
            "SimSun": "Songti SC"
        ]
        if let mapped = known[name] { return mapped }
        // If macOS actually has the font, keep it (Arial, Georgia, Verdana, etc.)
        if NSFont(name: name, size: 12) != nil { return name }
        return name
    }

    private static func parseRelationships(_ url: URL) -> [String: String] {
        guard let data = try? Data(contentsOf: url),
              let doc = try? XMLDocument(data: data) else { return [:] }
        var map: [String: String] = [:]
        for rel in doc.rootElement()?.elements(forName: "Relationship") ?? [] {
            if let id = rel.attribute(forName: "Id")?.stringValue,
               let target = rel.attribute(forName: "Target")?.stringValue {
                map[id] = target
            }
        }
        return map
    }

    private static func normalizeTarget(_ target: String) -> String {
        // "../media/image1.png" and "media/image1.png" → "media/image1.png"
        var t = target
        while t.hasPrefix("../") { t.removeFirst(3) }
        if t.hasPrefix("/") { t.removeFirst() }
        return t
    }

    // MARK: Whitespace-only run preservation

    /// Foundation's XML parser DROPS whitespace-only text nodes (e.g. `<a:t> </a:t>` runs that
    /// carry the spaces between words in real PowerPoint decks). Encode their content into
    /// private-use marker characters before parsing, decode when reading `a:t` values.
    private static func encodeWhitespaceOnlyTextRuns(_ data: Data) -> Data {
        guard var s = String(data: data, encoding: .utf8) else { return data }
        guard let regex = try? NSRegularExpression(pattern: "(<a:t[^>]*>)([\\t\n\r ]+)(</a:t>)") else { return data }
        let ns = NSMutableString(string: s)
        regex.enumerateMatches(in: s, range: NSRange(s.startIndex..., in: s)) { match, _, _ in
            guard let match = match, match.numberOfRanges == 4,
                  let openR = Range(match.range(at: 1), in: s),
                  let wsR = Range(match.range(at: 2), in: s),
                  let closeR = Range(match.range(at: 3), in: s) else { return }
            let encoded = s[wsR].map { c -> String in
                switch c {
                case " ": return "\u{E001}"
                case "\t": return "\u{E002}"
                case "\n": return "\u{E003}"
                case "\r": return "\u{E004}"
                default: return String(c)
                }
            }.joined()
            ns.replaceCharacters(in: match.range, with: String(s[openR]) + encoded + String(s[closeR]))
        }
        s = ns as String
        return Data(s.utf8)
    }

    private static func decodeTextWhitespace(_ s: String) -> String {
        var r = s
        r = r.replacingOccurrences(of: "\u{E001}", with: " ")
        r = r.replacingOccurrences(of: "\u{E002}", with: "\t")
        r = r.replacingOccurrences(of: "\u{E003}", with: "\n")
        r = r.replacingOccurrences(of: "\u{E004}", with: "\r")
        return r
    }

    // MARK: Numeric Helpers

    private static func emu(_ s: String?, default value: Double = 0) -> Double {
        guard let s = s else { return value }
        return Double(s) ?? value
    }

    // =========================================================================
    // 2. CANVA MULTI-PAGE & STANDARD PDF IMPORTER (PDFKit Engine)
    // =========================================================================
    public static func importFromPDF(url: URL, projectName: String) -> CanvasProject? {
        guard let pdfDoc = PDFDocument(url: url), pdfDoc.pageCount > 0 else { return nil }

        var pages: [CanvasPage] = []
        let scaleMultiplier: CGFloat = 2.0 // Render at 2x Retina resolution for razor-sharp fidelity

        for pageIndex in 0..<pdfDoc.pageCount {
            guard let pdfPage = pdfDoc.page(at: pageIndex) else { continue }
            let mediaBox = pdfPage.bounds(for: .mediaBox)

            let targetWidth = Double(max(200, mediaBox.width * scaleMultiplier))
            let targetHeight = Double(max(200, mediaBox.height * scaleMultiplier))

            let imgSize = NSSize(width: targetWidth, height: targetHeight)
            let image = NSImage(size: imgSize, flipped: false) { rect in
                guard let context = NSGraphicsContext.current?.cgContext else { return false }
                context.setFillColor(NSColor.white.cgColor)
                context.fill(rect)

                context.saveGState()
                context.scaleBy(x: scaleMultiplier, y: scaleMultiplier)
                pdfPage.draw(with: .mediaBox, to: context)
                context.restoreGState()
                return true
            }

            var elements: [CanvasElement] = []

            if let base64 = ImageUtils.base64String(from: image) {
                let bgElement = CanvasElement(
                    name: "Canva Page \(pageIndex + 1) Visual",
                    payload: .image(ImageContent(
                        imageBase64: base64,
                        contentMode: .fill,
                        cornerRadius: 0,
                        originalWidth: targetWidth,
                        originalHeight: targetHeight
                    )),
                    x: 0,
                    y: 0,
                    width: targetWidth,
                    height: targetHeight,
                    opacity: 1.0,
                    isLocked: false,
                    zIndex: 0
                )
                elements.append(bgElement)
            }

            // NOTE: No synthetic text overlay. The 2x raster already contains all text
            // exactly as rendered — overlaying re-typed guesses at fixed positions made
            // imports look different from the original Canva/PDF document.

            let canvasPage = CanvasPage(
                name: "Page \(pageIndex + 1)",
                width: targetWidth,
                height: targetHeight,
                background: FillStyle(type: .solid, solidColor: .white),
                elements: elements
            )
            pages.append(canvasPage)
        }

        guard !pages.isEmpty else { return nil }

        return CanvasProject(
            name: "\(projectName) (from Canva)",
            pages: pages
        )
    }

    // =========================================================================
    // 3. CANVA VECTOR SVG IMPORTER
    // =========================================================================
    public static func importFromSVG(url: URL, projectName: String) -> CanvasProject? {
        guard let data = try? Data(contentsOf: url) else { return nil }

        var docWidth: Double = 1080
        var docHeight: Double = 1080

        if let svgString = String(data: data, encoding: .utf8),
           let viewBoxRange = svgString.range(of: "viewBox=\"[^\"]+\"", options: .regularExpression) {
            let vbStr = String(svgString[viewBoxRange])
                .replacingOccurrences(of: "viewBox=\"", with: "")
                .replacingOccurrences(of: "\"", with: "")
            let parts = vbStr.split(whereSeparator: { $0 == " " || $0 == "," }).compactMap { Double($0) }
            if parts.count >= 4 {
                docWidth = parts[2]
                docHeight = parts[3]
            }
        }

        var elements: [CanvasElement] = []
        if let nsImage = NSImage(data: data) {
            let base64 = ImageUtils.base64String(from: nsImage) ?? ""
            let element = CanvasElement(
                name: "Canva SVG Graphic",
                payload: .image(ImageContent(
                    imageBase64: base64,
                    contentMode: .fit,
                    cornerRadius: 0,
                    originalWidth: docWidth,
                    originalHeight: docHeight
                )),
                x: 0,
                y: 0,
                width: docWidth,
                height: docHeight,
                zIndex: 0
            )
            elements.append(element)
        }

        let page = CanvasPage(
            name: "Page 1",
            width: docWidth,
            height: docHeight,
            background: FillStyle(type: .solid, solidColor: .white),
            elements: elements
        )

        return CanvasProject(
            name: "\(projectName) (SVG Import)",
            pages: [page]
        )
    }

    // =========================================================================
    // 4. CANVA IMAGE (PNG, JPG, WebP) SINGLE OR MULTI-SLIDE IMPORTER
    // =========================================================================
    public static func importFromImage(url: URL, projectName: String) -> CanvasProject? {
        guard let nsImage = NSImage(contentsOf: url),
              let base64 = ImageUtils.base64String(from: nsImage) else { return nil }

        let width = Double(max(300, nsImage.size.width))
        let height = Double(max(300, nsImage.size.height))

        let element = CanvasElement(
            name: "Imported Artwork",
            payload: .image(ImageContent(
                imageBase64: base64,
                contentMode: .fill,
                cornerRadius: 0,
                originalWidth: width,
                originalHeight: height
            )),
            x: 0,
            y: 0,
            width: width,
            height: height,
            zIndex: 0
        )

        let page = CanvasPage(
            name: "Page 1",
            width: width,
            height: height,
            background: FillStyle(type: .solid, solidColor: .white),
            elements: [element]
        )

        return CanvasProject(
            name: "\(projectName) (Imported)",
            pages: [page]
        )
    }

    // =========================================================================
    // 5. CANVA MULTI-PAGE ZIP ARCHIVE IMPORTER
    // =========================================================================
    public static func importFromZIP(url: URL, projectName: String) -> CanvasProject? {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-q", url.path, "-d", tempDir.path]
        try? process.run()
        process.waitUntilExit()

        guard let enumerator = FileManager.default.enumerator(at: tempDir, includingPropertiesForKeys: nil) else {
            return nil
        }

        var imageURLs: [URL] = []
        let validImageExts = ["png", "jpg", "jpeg", "webp", "heic", "tiff"]

        for case let fileURL as URL in enumerator {
            if validImageExts.contains(fileURL.pathExtension.lowercased()) && !fileURL.lastPathComponent.starts(with: ".") {
                imageURLs.append(fileURL)
            }
        }

        imageURLs.sort { $0.lastPathComponent < $1.lastPathComponent }
        guard !imageURLs.isEmpty else { return nil }

        var pages: [CanvasPage] = []

        for (idx, imgURL) in imageURLs.enumerated() {
            guard let nsImage = NSImage(contentsOf: imgURL),
                  let base64 = ImageUtils.base64String(from: nsImage) else { continue }

            let width = Double(max(300, nsImage.size.width))
            let height = Double(max(300, nsImage.size.height))

            let elem = CanvasElement(
                name: "Slide \(idx + 1) Background",
                payload: .image(ImageContent(
                    imageBase64: base64,
                    contentMode: .fill,
                    cornerRadius: 0,
                    originalWidth: width,
                    originalHeight: height
                )),
                x: 0,
                y: 0,
                width: width,
                height: height,
                zIndex: 0
            )

            let page = CanvasPage(
                name: "Slide \(idx + 1)",
                width: width,
                height: height,
                background: FillStyle(type: .solid, solidColor: .white),
                elements: [elem]
            )
            pages.append(page)
        }

        try? FileManager.default.removeItem(at: tempDir)
        guard !pages.isEmpty else { return nil }

        return CanvasProject(
            name: "\(projectName) (Canva Multi-Page)",
            pages: pages
        )
    }

    // =========================================================================
    // 6. PLUMA / JSON DOCUMENT IMPORTER
    // =========================================================================
    public static func importFromJSON(url: URL) -> CanvasProject? {
        guard let data = try? Data(contentsOf: url),
              let project = try? JSONDecoder().decode(CanvasProject.self, from: data) else { return nil }
        return project
    }
}
