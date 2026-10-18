import AppKit
import SwiftUI
import PDFKit
import UniformTypeIdentifiers

public enum ExportFormat: String, CaseIterable, Identifiable {
    case png = "PNG High-Res Image (.png)"
    case jpeg = "JPEG Pressed Image (.jpg)"
    case pdf = "PDF Vector Document (.pdf)"
    case pptx = "PowerPoint Presentation (.pptx)"
    case svg = "SVG Vector Markup (.svg)"
    case project = "Pluma Native Project (.canv)"

    public var id: String { rawValue }

    public var fileExtension: String {
        switch self {
        case .png: return "png"
        case .jpeg: return "jpg"
        case .pdf: return "pdf"
        case .pptx: return "pptx"
        case .svg: return "svg"
        case .project: return "canv"
        }
    }

    public var utType: UTType {
        switch self {
        case .png: return .png
        case .jpeg: return .jpeg
        case .pdf: return .pdf
        case .pptx: return UTType(filenameExtension: "pptx") ?? .data
        case .svg: return .svg
        case .project: return .json
        }
    }
}

public enum ExportEngine {
    /// Renders a canvas page to an NSImage at specified scale factor
    public static func renderImage(page: CanvasPage, scale: Double = 2.0) -> NSImage? {
        let size = NSSize(width: page.width * scale, height: page.height * scale)
        let image = NSImage(size: size, flipped: false) { _ in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }

            context.saveGState()
            context.scaleBy(x: CGFloat(scale), y: CGFloat(scale))
            let pageRect = CGRect(x: 0, y: 0, width: page.width, height: page.height)

            // Draw Background
            if !page.isTransparent {
                drawFill(page.background, in: pageRect, context: context)
            }

            // Draw Elements sorted by zIndex
            let sortedElements = page.elements
                .filter { $0.isVisible }
                .sorted { $0.zIndex < $1.zIndex }

            for element in sortedElements {
                let flippedY = page.height - element.y - element.height
                let elemRect = CGRect(x: element.x, y: flippedY, width: element.width, height: element.height)

                context.saveGState()
                if element.opacity < 1.0 {
                    context.setAlpha(CGFloat(element.opacity))
                }
                if element.rotation != 0 {
                    let center = CGPoint(x: elemRect.midX, y: elemRect.midY)
                    context.translateBy(x: center.x, y: center.y)
                    context.rotate(by: -CGFloat(element.rotation * .pi / 180.0))
                    context.translateBy(x: -center.x, y: -center.y)
                }
                if element.isFlippedH || element.isFlippedV {
                    let cx = elemRect.midX, cy = elemRect.midY
                    context.translateBy(x: cx, y: cy)
                    context.scaleBy(x: element.isFlippedH ? -1 : 1, y: element.isFlippedV ? -1 : 1)
                    context.translateBy(x: -cx, y: -cy)
                }

                drawElement(element, in: elemRect, context: context)
                context.restoreGState()
            }

            context.restoreGState()
            return true
        }
        return image
    }

    /// Exports page as PNG Data
    public static func exportPNG(page: CanvasPage, scale: Double = 2.0) -> Data? {
        guard let image = renderImage(page: page, scale: scale),
              let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return bitmap.representation(using: NSBitmapImageRep.FileType.png, properties: [:])
    }

    /// Copies rendered page image directly to macOS NSPasteboard
    @discardableResult
    public static func copyImageToClipboard(page: CanvasPage, scale: Double = 2.0) -> Bool {
        guard let image = renderImage(page: page, scale: scale) else { return false }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        return pasteboard.writeObjects([image])
    }

    /// Exports page as JPEG Data
    public static func exportJPEG(page: CanvasPage, scale: Double = 2.0, quality: Double = 0.9) -> Data? {
        guard let image = renderImage(page: page, scale: scale),
              let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return bitmap.representation(using: NSBitmapImageRep.FileType.jpeg, properties: [.compressionFactor: NSNumber(value: quality)])
    }

    /// Exports page as PDF Data
    public static func exportPDF(page: CanvasPage) -> Data? {
        let pdfData = NSMutableData()
        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData) else { return nil }

        var mediaBox = CGRect(x: 0, y: 0, width: page.width, height: page.height)
        guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else { return nil }

        context.beginPage(mediaBox: &mediaBox)

        // Draw Background
        if !page.isTransparent {
            drawFill(page.background, in: mediaBox, context: context)
        }

        // Draw Elements
        let sortedElements = page.elements
            .filter { $0.isVisible }
            .sorted { $0.zIndex < $1.zIndex }

        for element in sortedElements {
            let flippedY = page.height - element.y - element.height
            let elemRect = CGRect(x: element.x, y: flippedY, width: element.width, height: element.height)

            context.saveGState()
            if element.opacity < 1.0 {
                context.setAlpha(CGFloat(element.opacity))
            }
            if element.rotation != 0 {
                let center = CGPoint(x: elemRect.midX, y: elemRect.midY)
                context.translateBy(x: center.x, y: center.y)
                context.rotate(by: -CGFloat(element.rotation * .pi / 180.0))
                context.translateBy(x: -center.x, y: -center.y)
            }
            if element.isFlippedH || element.isFlippedV {
                let cx = elemRect.midX, cy = elemRect.midY
                context.translateBy(x: cx, y: cy)
                context.scaleBy(x: element.isFlippedH ? -1 : 1, y: element.isFlippedV ? -1 : 1)
                context.translateBy(x: -cx, y: -cy)
            }

            drawElement(element, in: elemRect, context: context)
            context.restoreGState()
        }

        context.endPage()
        context.closePDF()
        return pdfData as Data
    }

    /// Exports entire project as Multi-Page PDF Document
    public static func exportMultiPagePDF(project: CanvasProject) -> Data? {
        let pdfData = NSMutableData()
        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData) else { return nil }

        let firstPage = project.pages.first ?? CanvasPage()
        var defaultBox = CGRect(x: 0, y: 0, width: firstPage.width, height: firstPage.height)
        guard let context = CGContext(consumer: consumer, mediaBox: &defaultBox, nil) else { return nil }

        for page in project.pages {
            var mediaBox = CGRect(x: 0, y: 0, width: page.width, height: page.height)
            context.beginPage(mediaBox: &mediaBox)

            if !page.isTransparent {
                drawFill(page.background, in: mediaBox, context: context)
            }

            let sortedElements = page.elements
                .filter { $0.isVisible }
                .sorted { $0.zIndex < $1.zIndex }

            for element in sortedElements {
                let flippedY = page.height - element.y - element.height
                let elemRect = CGRect(x: element.x, y: flippedY, width: element.width, height: element.height)

                context.saveGState()
                if element.opacity < 1.0 {
                    context.setAlpha(CGFloat(element.opacity))
                }
                if element.rotation != 0 {
                    let center = CGPoint(x: elemRect.midX, y: elemRect.midY)
                    context.translateBy(x: center.x, y: center.y)
                    context.rotate(by: -CGFloat(element.rotation * .pi / 180.0))
                    context.translateBy(x: -center.x, y: -center.y)
                }
                if element.isFlippedH || element.isFlippedV {
                    let cx = elemRect.midX, cy = elemRect.midY
                    context.translateBy(x: cx, y: cy)
                    context.scaleBy(x: element.isFlippedH ? -1 : 1, y: element.isFlippedV ? -1 : 1)
                    context.translateBy(x: -cx, y: -cy)
                }

                drawElement(element, in: elemRect, context: context)
                context.restoreGState()
            }

            context.endPage()
        }

        context.closePDF()
        return pdfData as Data
    }

    // =========================================================================
    // POWERPOINT PRESENTATION (.pptx) MULTI-SLIDE OPENXML EXPORTER
    // =========================================================================
    public static func exportPPTX(project: CanvasProject) -> Data? {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let slidesRelDir = tempDir.appendingPathComponent("ppt/slides/_rels")
        let slideMastersRelDir = tempDir.appendingPathComponent("ppt/slideMasters/_rels")
        let slideLayoutsRelDir = tempDir.appendingPathComponent("ppt/slideLayouts/_rels")
        let themeDir = tempDir.appendingPathComponent("ppt/theme")
        let mediaDir = tempDir.appendingPathComponent("ppt/media")
        let rootRelsDir = tempDir.appendingPathComponent("_rels")
        let pptRelsDir = tempDir.appendingPathComponent("ppt/_rels")
        let docPropsDir = tempDir.appendingPathComponent("docProps")

        try? FileManager.default.createDirectory(at: slidesRelDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: slideMastersRelDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: slideLayoutsRelDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: themeDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: mediaDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: rootRelsDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: pptRelsDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: docPropsDir, withIntermediateDirectories: true)

        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        func escape(_ s: String) -> String {
            return s.replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
                .replacingOccurrences(of: "\"", with: "&quot;")
                .replacingOccurrences(of: "'", with: "&apos;")
        }

        let firstPage = project.pages.first ?? CanvasPage()
        let cx = Int(round(firstPage.width * 9525.0))
        let cy = Int(round(firstPage.height * 9525.0))
        let pageCount = max(1, project.pages.count)

        // 1. [Content_Types].xml
        var overrides = ""
        for i in 1...pageCount {
            overrides += "  <Override PartName=\"/ppt/slides/slide\(i).xml\" ContentType=\"application/vnd.openxmlformats-officedocument.presentationml.slide+xml\"/>\n"
        }
        let contentTypesXML = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
          <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
          <Default Extension="xml" ContentType="application/xml"/>
          <Default Extension="png" ContentType="image/png"/>
          <Default Extension="jpeg" ContentType="image/jpeg"/>
          <Default Extension="jpg" ContentType="image/jpeg"/>
          <Override PartName="/ppt/presentation.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml"/>
          <Override PartName="/ppt/slideMasters/slideMaster1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideMaster+xml"/>
          <Override PartName="/ppt/slideLayouts/slideLayout1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideLayout+xml"/>
          <Override PartName="/ppt/theme/theme1.xml" ContentType="application/vnd.openxmlformats-officedocument.drawingml.theme+xml"/>
        \(overrides)  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
          <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
        </Types>
        """
        try? contentTypesXML.write(to: tempDir.appendingPathComponent("[Content_Types].xml"), atomically: true, encoding: .utf8)

        // 2. _rels/.rels
        let rootRelsXML = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
          <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="ppt/presentation.xml"/>
          <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
          <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
        </Relationships>
        """
        try? rootRelsXML.write(to: rootRelsDir.appendingPathComponent(".rels"), atomically: true, encoding: .utf8)

        // 3. docProps/app.xml & docProps/core.xml
        let appXML = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties">
          <Application>Pluma Design Studio</Application>
          <Slides>\(pageCount)</Slides>
        </Properties>
        """
        try? appXML.write(to: docPropsDir.appendingPathComponent("app.xml"), atomically: true, encoding: .utf8)

        let coreXML = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/">
          <dc:title>\(escape(project.name))</dc:title>
          <dc:creator>Pluma Native App</dc:creator>
        </cp:coreProperties>
        """
        try? coreXML.write(to: docPropsDir.appendingPathComponent("core.xml"), atomically: true, encoding: .utf8)

        // 4. ppt/presentation.xml & ppt/_rels/presentation.xml.rels
        var sldIdLst = ""
        var presRels = "  <Relationship Id=\"rIdMaster1\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster\" Target=\"slideMasters/slideMaster1.xml\"/>\n"
        for i in 1...pageCount {
            sldIdLst += "    <p:sldId id=\"\(255 + i)\" r:id=\"rIdSlide\(i)\"/>\n"
            presRels += "  <Relationship Id=\"rIdSlide\(i)\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide\" Target=\"slides/slide\(i).xml\"/>\n"
        }
        let presXML = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <p:presentation xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
          <p:sldMasterIdLst>
            <p:sldMasterId id="2147483648" r:id="rIdMaster1"/>
          </p:sldMasterIdLst>
          <p:sldIdLst>
        \(sldIdLst)  </p:sldIdLst>
          <p:sldSz cx="\(cx)" cy="\(cy)"/>
        </p:presentation>
        """
        try? presXML.write(to: tempDir.appendingPathComponent("ppt/presentation.xml"), atomically: true, encoding: .utf8)

        let presRelsXML = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
        \(presRels)</Relationships>
        """
        try? presRelsXML.write(to: pptRelsDir.appendingPathComponent("presentation.xml.rels"), atomically: true, encoding: .utf8)

        // 5. ppt/theme/theme1.xml
        let themeXML = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <a:theme xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" name="Pluma Theme">
          <a:themeElements>
            <a:clrScheme name="Studio">
              <a:dk1><a:srgbClr val="18181B"/></a:dk1>
              <a:lt1><a:srgbClr val="FFFFFF"/></a:lt1>
              <a:dk2><a:srgbClr val="27272A"/></a:dk2>
              <a:lt2><a:srgbClr val="FAF7F0"/></a:lt2>
              <a:accent1><a:srgbClr val="C2410C"/></a:accent1>
              <a:accent2><a:srgbClr val="2563EB"/></a:accent2>
              <a:accent3><a:srgbClr val="10B981"/></a:accent3>
              <a:accent4><a:srgbClr val="F59E0B"/></a:accent4>
              <a:accent5><a:srgbClr val="8B5CF6"/></a:accent5>
              <a:accent6><a:srgbClr val="EC4899"/></a:accent6>
              <a:hlink><a:srgbClr val="2563EB"/></a:hlink>
              <a:folHlink><a:srgbClr val="7C3AED"/></a:folHlink>
            </a:clrScheme>
            <a:fontScheme name="Modern">
              <a:majorFont><a:latin typeface="Playfair Display"/></a:majorFont>
              <a:minorFont><a:latin typeface="Inter"/></a:minorFont>
            </a:fontScheme>
            <a:fmtScheme name="Office"><a:fillStyleLst/><a:lnStyleLst/><a:effectStyleLst/><a:bgFillStyleLst/></a:fmtScheme>
          </a:themeElements>
        </a:theme>
        """
        try? themeXML.write(to: themeDir.appendingPathComponent("theme1.xml"), atomically: true, encoding: .utf8)

        // 6. ppt/slideMasters/slideMaster1.xml & rels
        let slideMasterXML = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <p:sldMaster xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
          <p:cSld><p:spTree><p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr></p:spTree></p:cSld>
          <p:clrMap bg1="lt1" tx1="dk1" bg2="lt2" tx2="dk2" accent1="accent1" accent2="accent2" accent3="accent3" accent4="accent4" accent5="accent5" accent6="accent6" hlink="hlink" folHlink="folHlink"/>
          <p:sldLayoutIdLst><p:sldLayoutId id="2147483649" r:id="rIdLayout1"/></p:sldLayoutIdLst>
        </p:sldMaster>
        """
        try? slideMasterXML.write(to: tempDir.appendingPathComponent("ppt/slideMasters/slideMaster1.xml"), atomically: true, encoding: .utf8)

        let masterRelsXML = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
          <Relationship Id="rIdLayout1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml"/>
          <Relationship Id="rIdTheme1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme" Target="../theme/theme1.xml"/>
        </Relationships>
        """
        try? masterRelsXML.write(to: slideMastersRelDir.appendingPathComponent("slideMaster1.xml.rels"), atomically: true, encoding: .utf8)

        // 7. ppt/slideLayouts/slideLayout1.xml & rels
        let slideLayoutXML = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <p:sldLayout xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" type="blank" preserve="1">
          <p:cSld name="Blank"><p:spTree><p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr></p:spTree></p:cSld>
        </p:sldLayout>
        """
        try? slideLayoutXML.write(to: tempDir.appendingPathComponent("ppt/slideLayouts/slideLayout1.xml"), atomically: true, encoding: .utf8)

        let layoutRelsXML = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
          <Relationship Id="rIdMaster" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" Target="../slideMasters/slideMaster1.xml"/>
        </Relationships>
        """
        try? layoutRelsXML.write(to: slideLayoutsRelDir.appendingPathComponent("slideLayout1.xml.rels"), atomically: true, encoding: .utf8)

        // 8. Process Each Slide in Project
        var globalImageIndex = 0

        for (pageIdx, page) in project.pages.enumerated() {
            let slideNumber = pageIdx + 1
            var slideElementsXML = ""
            var slideRels = "  <Relationship Id=\"rIdLayout\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout\" Target=\"../slideLayouts/slideLayout1.xml\"/>\n"
            var slideRelCounter = 1

            // Slide Background
            let bgHex = page.background.solidColor.hexString.replacingOccurrences(of: "#", with: "")
            let bgXML = """
            <p:bg><p:bgPr><a:solidFill><a:srgbClr val="\(bgHex)"/></a:solidFill></p:bgPr></p:bg>
            """

            let sortedElements = page.elements
                .filter { $0.isVisible }
                .sorted { $0.zIndex < $1.zIndex }

            for (elemIdx, element) in sortedElements.enumerated() {
                let ex = Int(round(element.x * 9525.0))
                let ey = Int(round(element.y * 9525.0))
                let ew = Int(round(max(10, element.width) * 9525.0))
                let eh = Int(round(max(10, element.height) * 9525.0))
                let elemId = 100 + elemIdx

                switch element.payload {
                case .text(let text):
                    let alignStr: String
                    switch text.alignment {
                    case .center: alignStr = "ctr"
                    case .right: alignStr = "r"
                    case .justified: alignStr = "just"
                    case .left: alignStr = "l"
                    }
                    let tColor = text.textColor.hexString.replacingOccurrences(of: "#", with: "")
                    let sz = Int(max(8.0, text.fontSize) * 100.0)
                    let isBold = (text.fontWeight >= 700) ? "1" : "0"
                    let isItalic = text.isItalic ? "1" : "0"

                    var paragraphsXML = ""
                    let lines = text.text.components(separatedBy: .newlines)
                    for line in lines {
                        paragraphsXML += """
                        <a:p><a:pPr algn="\(alignStr)"/><a:r><a:rPr lang="en-US" sz="\(sz)" b="\(isBold)" i="\(isItalic)"><a:solidFill><a:srgbClr val="\(tColor)"/></a:solidFill><a:latin typeface="\(escape(text.fontFamily))"/><a:ea typeface="\(escape(text.fontFamily))"/><a:cs typeface="\(escape(text.fontFamily))"/></a:rPr><a:t>\(escape(line))</a:t></a:r></a:p>
                        """
                    }

                    slideElementsXML += """
                    <p:sp>
                      <p:nvSpPr><p:cNvPr id="\(elemId)" name="\(escape(element.name))"/><p:cNvSpPr txBox="1"/><p:nvPr/></p:nvSpPr>
                      <p:spPr><a:xfrm><a:off x="\(ex)" y="\(ey)"/><a:ext cx="\(ew)" cy="\(eh)"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></p:spPr>
                      <p:txBody><a:bodyPr rtlCol="0" anchor="t"/><a:lstStyle/>\(paragraphsXML)</p:txBody>
                    </p:sp>
                    """

                case .image(let imageContent):
                    // Emit the rel + <p:pic> ONLY when the media payload actually
                    // lands — a dangling rel makes PowerPoint refuse/repair the file.
                    let imgFilename = "image\(globalImageIndex + 1).png"
                    if let imgData = ImageUtils.nsImage(from: imageContent.imageBase64)?.tiffRepresentation,
                       let bitmap = NSBitmapImageRep(data: imgData),
                       let pngBytes = bitmap.representation(using: .png, properties: [:]),
                       (try? pngBytes.write(to: mediaDir.appendingPathComponent(imgFilename))) != nil {
                        globalImageIndex += 1
                        slideRelCounter += 1
                        let rId = "rId\(slideRelCounter)"

                        slideRels += "  <Relationship Id=\"\(rId)\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/image\" Target=\"../media/\(imgFilename)\"/>\n"

                        let geomStr = (imageContent.frameKind == .circle) ? "ellipse" : (imageContent.cornerRadius > 0 ? "roundRect" : "rect")

                        slideElementsXML += """
                        <p:pic>
                          <p:nvPicPr><p:cNvPr id="\(elemId)" name="\(escape(element.name))"/><p:cNvPicPr><a:picLocks noChangeAspect="1"/></p:cNvPicPr><p:nvPr/></p:nvPicPr>
                          <p:blipFill><a:blip r:embed="\(rId)"/><a:stretch><a:fillRect/></a:stretch></p:blipFill>
                          <p:spPr><a:xfrm><a:off x="\(ex)" y="\(ey)"/><a:ext cx="\(ew)" cy="\(eh)"/></a:xfrm><a:prstGeom prst="\(geomStr)"><a:avLst/></a:prstGeom></p:spPr>
                        </p:pic>
                        """
                    }

                case .shape(let shape):
                    let geomStr: String
                    switch shape.kind {
                    case .roundedRectangle: geomStr = "roundRect"
                    case .circle: geomStr = "ellipse"
                    case .triangle: geomStr = "triangle"
                    case .star, .starburst, .sparkleStar: geomStr = "star5"
                    case .diamond: geomStr = "diamond"
                    case .line: geomStr = "line"
                    default: geomStr = "rect"
                    }
                    let sCol = shape.fill.solidColor.hexString.replacingOccurrences(of: "#", with: "")
                    var lnXML = ""
                    if shape.stroke.isEnabled {
                        let strokeCol = shape.stroke.color.hexString.replacingOccurrences(of: "#", with: "")
                        let sW = Int(round(shape.stroke.lineWidth * 12700.0))
                        lnXML = "<a:ln w=\"\(sW)\"><a:solidFill><a:srgbClr val=\"\(strokeCol)\"/></a:solidFill></a:ln>"
                    }

                    slideElementsXML += """
                    <p:sp>
                      <p:nvSpPr><p:cNvPr id="\(elemId)" name="\(escape(element.name))"/><p:cNvSpPr/><p:nvPr/></p:nvSpPr>
                      <p:spPr><a:xfrm><a:off x="\(ex)" y="\(ey)"/><a:ext cx="\(ew)" cy="\(eh)"/></a:xfrm><a:prstGeom prst="\(geomStr)"><a:avLst/></a:prstGeom><a:solidFill><a:srgbClr val="\(sCol)"/></a:solidFill>\(lnXML)</p:spPr>
                    </p:sp>
                    """

                case .code(let code):
                    let cardHex = code.theme.backgroundColor.hexString.replacingOccurrences(of: "#", with: "")
                    let codeTextHex = code.theme.defaultTextColor.hexString.replacingOccurrences(of: "#", with: "")
                    let sz = Int(max(8.0, Double(code.fontSize)) * 100.0)

                    var codeLinesXML = ""
                    for line in code.code.components(separatedBy: .newlines) {
                        codeLinesXML += """
                        <a:p><a:r><a:rPr lang="en-US" sz="\(sz)"><a:solidFill><a:srgbClr val="\(codeTextHex)"/></a:solidFill><a:latin typeface="SF Mono"/><a:ea typeface="SF Mono"/><a:cs typeface="SF Mono"/></a:rPr><a:t>\(escape(line))</a:t></a:r></a:p>
                        """
                    }

                    slideElementsXML += """
                    <p:sp>
                      <p:nvSpPr><p:cNvPr id="\(elemId)" name="Code Card"/><p:cNvSpPr/><p:nvPr/></p:nvSpPr>
                      <p:spPr><a:xfrm><a:off x="\(ex)" y="\(ey)"/><a:ext cx="\(ew)" cy="\(eh)"/></a:xfrm><a:prstGeom prst="roundRect"><a:avLst/></a:prstGeom><a:solidFill><a:srgbClr val="\(cardHex)"/></a:solidFill></p:spPr>
                      <p:txBody><a:bodyPr rtlCol="0" anchor="t" lIns="182880" tIns="182880"/><a:lstStyle/>\(codeLinesXML)</p:txBody>
                    </p:sp>
                    """

                case .icon(let icon):
                    // Same dangling-rel guard as .image above.
                    let imgFilename = "image\(globalImageIndex + 1).png"
                    if let iconImg = NSImage(systemSymbolName: icon.symbolName, accessibilityDescription: nil),
                       let tiff = iconImg.tiffRepresentation,
                       let bitmap = NSBitmapImageRep(data: tiff),
                       let pngBytes = bitmap.representation(using: NSBitmapImageRep.FileType.png, properties: [:]),
                       (try? pngBytes.write(to: mediaDir.appendingPathComponent(imgFilename))) != nil {
                        globalImageIndex += 1
                        slideRelCounter += 1
                        let rId = "rId\(slideRelCounter)"

                        slideRels += "  <Relationship Id=\"\(rId)\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/image\" Target=\"../media/\(imgFilename)\"/>\n"

                        slideElementsXML += """
                        <p:pic>
                          <p:nvPicPr><p:cNvPr id="\(elemId)" name="\(escape(element.name))"/><p:cNvPicPr><a:picLocks noChangeAspect="1"/></p:cNvPicPr><p:nvPr/></p:nvPicPr>
                          <p:blipFill><a:blip r:embed="\(rId)"/><a:stretch><a:fillRect/></a:stretch></p:blipFill>
                          <p:spPr><a:xfrm><a:off x="\(ex)" y="\(ey)"/><a:ext cx="\(ew)" cy="\(eh)"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></p:spPr>
                        </p:pic>
                        """
                    }

                case .drawing:
                    break
                }
            }

            let slideXML = """
            <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
            <p:sld xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
              <p:cSld>
                \(bgXML)
                <p:spTree>
                  <p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>
                  <p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr>
                  \(slideElementsXML)
                </p:spTree>
              </p:cSld>
            </p:sld>
            """
            try? slideXML.write(to: tempDir.appendingPathComponent("ppt/slides/slide\(slideNumber).xml"), atomically: true, encoding: .utf8)

            let slideRelsXML = """
            <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
            <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
            \(slideRels)</Relationships>
            """
            try? slideRelsXML.write(to: slidesRelDir.appendingPathComponent("slide\(slideNumber).xml.rels"), atomically: true, encoding: .utf8)
        }

        // 9. Zip Package
        let zipFileURL = tempDir.appendingPathComponent("presentation.pptx")
        let process = Process()
        process.currentDirectoryURL = tempDir
        process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        process.arguments = ["-q", "-r", zipFileURL.path, "."]
        try? process.run()
        process.waitUntilExit()

        return try? Data(contentsOf: zipFileURL)
    }

    /// Exports entire canvas page to SVG Vector String
    public static func exportSVG(page: CanvasPage) -> String {
        var svg = """
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 \(page.width) \(page.height)" width="\(page.width)" height="\(page.height)">
        <defs>
        """

        if case .linearGradient = page.background.type {
            svg += svgLinearGradientDef(id: "pageBgGrad", fill: page.background)
        }

        for (idx, elem) in page.elements.enumerated() {
            if case .shape(let s) = elem.payload, case .linearGradient = s.fill.type {
                svg += svgLinearGradientDef(id: "elemGrad_\(idx)", fill: s.fill)
            }
        }

        svg += "</defs>\n"

        if !page.isTransparent {
            if case .linearGradient = page.background.type {
                svg += "<rect width=\"100%\" height=\"100%\" fill=\"url(#pageBgGrad)\" />\n"
            } else {
                svg += "<rect width=\"100%\" height=\"100%\" fill=\"\(page.background.solidColor.hexString)\" />\n"
            }
        }

        let sorted = page.elements
            .filter { $0.isVisible }
            .sorted { $0.zIndex < $1.zIndex }

        for (idx, elem) in sorted.enumerated() {
            svg += svgElement(elem, index: idx)
        }

        svg += "</svg>"
        return svg
    }

    /// Copies SVG vector markup onto the macOS clipboard for 1-click paste into Figma or Illustrator
    @discardableResult
    public static func copySVGToClipboard(page: CanvasPage) -> Bool {
        let svgString = exportSVG(page: page)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        let customSVGType = NSPasteboard.PasteboardType("public.svg-image")
        pasteboard.declareTypes([customSVGType, .string], owner: nil)
        pasteboard.setString(svgString, forType: customSVGType)
        pasteboard.setString(svgString, forType: .string)
        return true
    }

    // MARK: - Private Drawing Helpers (CoreGraphics)

    private static func drawFill(_ fill: FillStyle, in rect: CGRect, context: CGContext) {
        switch fill.type {
        case .solid, .newsprint, .kraft, .vintageParchment, .graphPaper, .glass:
            context.setFillColor(fill.solidColor.cgColor)
            context.fill(rect)

        case .pattern:
            context.setFillColor(fill.solidColor.cgColor)
            context.fill(rect)
            context.saveGState()
            context.clip(to: rect)
            PatternFillCG.draw(fill: fill, in: rect, context: context)
            context.restoreGState()

        case .linearGradient:
            let colors = fill.gradientStops.map { $0.color.cgColor } as CFArray
            let locations = fill.gradientStops.map { CGFloat($0.location) }
            guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
                  let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) else {
                context.setFillColor(fill.solidColor.cgColor)
                context.fill(rect)
                return
            }
            let angleRad = fill.gradientAngle * .pi / 180.0
            let start = CGPoint(x: rect.midX - cos(angleRad) * rect.width/2, y: rect.midY - sin(angleRad) * rect.height/2)
            let end = CGPoint(x: rect.midX + cos(angleRad) * rect.width/2, y: rect.midY + sin(angleRad) * rect.height/2)
            context.drawLinearGradient(gradient, start: start, end: end, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])

        case .radialGradient:
            let colors = fill.gradientStops.map { $0.color.cgColor } as CFArray
            let locations = fill.gradientStops.map { CGFloat($0.location) }
            guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
                  let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) else {
                context.setFillColor(fill.solidColor.cgColor)
                context.fill(rect)
                return
            }
            context.drawRadialGradient(gradient, startCenter: CGPoint(x: rect.midX, y: rect.midY), startRadius: 0, endCenter: CGPoint(x: rect.midX, y: rect.midY), endRadius: max(rect.width, rect.height)/1.5, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        }
    }

    private static func drawElement(_ element: CanvasElement, in elemRect: CGRect, context: CGContext) {
        switch element.payload {
        case .shape(let shape):
            drawShape(shape, in: elemRect, context: context)
        case .text(let text):
            drawText(text, in: elemRect, context: context)
        case .image(let imageContent):
            drawImage(imageContent, in: elemRect, context: context)
        case .icon(let icon):
            drawIcon(icon, in: elemRect, context: context)
        case .drawing(let drawing):
            drawDrawing(drawing, context: context)
        case .code(let codeContent):
            drawCode(codeContent, in: elemRect, context: context)
        }
    }

    private static func drawShape(_ shape: ShapeContent, in rect: CGRect, context: CGContext) {
        let path = CustomShapePath.cgPath(for: shape.kind, in: rect, cornerRadius: shape.cornerRadius, starPoints: shape.starPoints, polygonSides: shape.polygonSides)
        context.saveGState()
        context.addPath(path)
        context.clip()
        drawFill(shape.fill, in: rect, context: context)
        context.restoreGState()

        if shape.stroke.isEnabled && shape.stroke.lineWidth > 0 {
            context.saveGState()
            context.addPath(path)
            context.setStrokeColor(shape.stroke.color.cgColor)
            context.setLineWidth(CGFloat(shape.stroke.lineWidth))
            context.strokePath()
            context.restoreGState()
        }
    }

    private static func drawText(_ text: TextContent, in rect: CGRect, context: CGContext) {
        // Shared attribute pipeline (font cache, weight/italic/underline-aware)
        // so exports match the canvas, editor, and importer exactly.
        let attrs = TextMeasurement.attributes(for: text)

        // Same content-area + vertical-anchor placement as the canvas (see
        // TextBoxLayout), so thumbnails/exports match what's on screen.
        let cardPad = text.cardBackground != nil ? CGFloat(text.cardPadding) : 0
        let contentW = max(1, rect.width - CGFloat(text.insetLeft + text.insetRight) - cardPad * 2)
        let areaH = max(0, rect.height - CGFloat(text.insetTop + text.insetBottom) - cardPad * 2)

        let attrStr = NSAttributedString(string: text.text, attributes: attrs)
        // Lay out with TextKit — the same engine as TextMeasurement.blockHeight
        // and the canvas NSTextView, so measured and drawn heights agree.
        // (attrStr.draw(in:) lays out via NSStringDrawing, whose line metrics
        // are looser than usedRect's — it clipped the last wrapped line
        // whenever a box was sized tight.)
        let storage = NSTextStorage(attributedString: attrStr)
        let layoutManager = NSLayoutManager()
        storage.addLayoutManager(layoutManager)
        let container = NSTextContainer(size: NSSize(width: contentW, height: .greatestFiniteMagnitude))
        container.lineFragmentPadding = 0
        layoutManager.addTextContainer(container)
        layoutManager.ensureLayout(for: container)
        let contentH = layoutManager.usedRect(for: container).height
        let runH = max(1, min(areaH, ceil(contentH)))
        let slack = max(0, areaH - runH)
        let anchorShift: CGFloat
        switch text.verticalAnchor {
        case .top: anchorShift = 0
        case .center: anchorShift = slack / 2
        case .bottom: anchorShift = slack
        }

        // The page context is y-up, so flip into top-left local coordinates
        // (same pattern as drawCode): draw(in:) then anchors the run's visual
        // top to drawRect.minY, exactly like the canvas. In the unflipped space
        // insets/anchorShift must hang off rect.maxY, not rect.minY.
        let drawRect = CGRect(
            x: CGFloat(text.insetLeft) + cardPad,
            y: CGFloat(text.insetTop) + cardPad + anchorShift,
            width: contentW,
            height: runH
        )
        // Sticky-note card behind the text (same as the canvas: full-rect
        // rounded card + optional border), drawn in the unflipped page space.
        if let bg = text.cardBackground {
            let cardPath = CGPath(roundedRect: rect, cornerWidth: CGFloat(text.cardCornerRadius), cornerHeight: CGFloat(text.cardCornerRadius), transform: nil)
            context.saveGState()
            context.addPath(cardPath)
            context.setFillColor(bg.cgColor)
            context.fillPath()
            if let border = text.cardBorderColor, text.cardBorderWidth > 0 {
                context.addPath(cardPath)
                context.setStrokeColor(border.cgColor)
                context.setLineWidth(CGFloat(text.cardBorderWidth))
                context.strokePath()
            }
            context.restoreGState()
        }

        context.saveGState()
        context.translateBy(x: rect.minX, y: rect.maxY)
        context.scaleBy(x: 1, y: -1)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: true)
        context.clip(to: drawRect)
        layoutManager.drawGlyphs(
            forGlyphRange: layoutManager.glyphRange(for: container),
            at: drawRect.origin
        )
        NSGraphicsContext.restoreGraphicsState()
        context.restoreGState()
    }

    private static func drawImage(_ imageContent: ImageContent, in rect: CGRect, context: CGContext) {
        guard let nsImage = ImageUtils.nsImage(from: imageContent.imageBase64) else {
            return
        }

        context.saveGState()
        if let frameKind = imageContent.frameKind {
            let path = CustomShapePath.cgPath(for: frameKind, in: rect, cornerRadius: imageContent.cornerRadius)
            context.addPath(path)
            context.clip()
        } else if imageContent.cornerRadius > 0 {
            let path = CGPath(roundedRect: rect, cornerWidth: CGFloat(imageContent.cornerRadius), cornerHeight: CGFloat(imageContent.cornerRadius), transform: nil)
            context.addPath(path)
            context.clip()
        }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
        // .sourceOver preserves PNG transparency; .copy flattens it to black.
        nsImage.draw(in: rect, from: NSRect(origin: .zero, size: nsImage.size), operation: .sourceOver, fraction: 1.0)
        NSGraphicsContext.restoreGraphicsState()

        context.restoreGState()
    }

    private static func drawIcon(_ icon: IconContent, in rect: CGRect, context: CGContext) {
        guard let img = NSImage(systemSymbolName: icon.symbolName, accessibilityDescription: nil) else { return }
        let tinted = NSImage(size: img.size, flipped: false) { bounds in
            img.draw(in: bounds)
            icon.primaryColor.nsColor.set()
            bounds.fill(using: .sourceAtop)
            return true
        }
        // Set the context explicitly — PDF export has no ambient one, so icons
        // would otherwise silently drop from the output.
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
        tinted.draw(in: rect)
        NSGraphicsContext.restoreGraphicsState()
    }

    private static func drawDrawing(_ drawing: DrawingContent, context: CGContext) {
        guard drawing.points.count > 1 else { return }
        context.saveGState()
        context.setStrokeColor(drawing.strokeColor.cgColor)
        context.setLineWidth(CGFloat(drawing.lineWidth))
        context.setLineCap(.round)
        context.setLineJoin(.round)

        context.beginPath()
        context.move(to: CGPoint(x: drawing.points[0].x, y: drawing.points[0].y))
        for pt in drawing.points.dropFirst() {
            context.addLine(to: CGPoint(x: pt.x, y: pt.y))
        }
        context.strokePath()
        context.restoreGState()
    }

    private static func drawCode(_ codeContent: CodeContent, in rect: CGRect, context: CGContext) {
        let cardRect = rect
        let corner = CGFloat(codeContent.cornerRadius)

        // Card background (drawn in the unflipped page space)
        context.saveGState()
        let path = CGPath(roundedRect: cardRect, cornerWidth: corner, cornerHeight: corner, transform: nil)
        context.addPath(path)
        context.setFillColor(codeContent.theme.backgroundColor.cgColor)
        context.fillPath()
        context.restoreGState()

        // Flip into top-left local coordinates so the window chrome and code
        // lines lay out top-down exactly like the on-canvas SwiftUI view.
        context.saveGState()
        context.translateBy(x: cardRect.minX, y: cardRect.maxY)
        context.scaleBy(x: 1, y: -1)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: true)

        let local = CGRect(x: 0, y: 0, width: cardRect.width, height: cardRect.height)
        context.saveGState()
        context.addPath(CGPath(roundedRect: local, cornerWidth: corner, cornerHeight: corner, transform: nil))
        context.clip()

        let headerH: CGFloat = codeContent.showWindowHeader ? 30 : 0
        let pad = CGFloat(codeContent.padding)
        let fontSize = CGFloat(codeContent.fontSize)
        let mono = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .medium)

        if codeContent.showWindowHeader {
            // Header band + separator
            context.setFillColor(codeContent.theme.backgroundColor.cgColor)
            context.fill(CGRect(x: 0, y: 0, width: local.width, height: headerH))
            context.setFillColor(NSColor.white.withAlphaComponent(0.08).cgColor)
            context.fill(CGRect(x: 0, y: headerH - 1, width: local.width, height: 1))

            // Traffic lights
            let dotR: CGFloat = 5
            let dotY = headerH / 2 - dotR
            for (i, c) in [NSColor.systemRed, NSColor.systemYellow, NSColor.systemGreen].enumerated() {
                context.setFillColor(c.cgColor)
                context.fillEllipse(in: CGRect(x: 12 + CGFloat(i) * 16, y: dotY, width: dotR * 2, height: dotR * 2))
            }

            // Window title, centered
            let title = codeContent.windowTitle.isEmpty ? "snippet.\(codeContent.language.fileExtension)" : codeContent.windowTitle
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .medium),
                .foregroundColor: codeContent.theme.commentColor.nsColor
            ]
            let t = NSAttributedString(string: title, attributes: titleAttrs)
            let tSize = t.size()
            t.draw(at: CGPoint(x: (local.width - tSize.width) / 2, y: (headerH - tSize.height) / 2))

            // Language badge, right-aligned
            let badgeAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedSystemFont(ofSize: 8.5, weight: .bold),
                .foregroundColor: codeContent.theme.keywordColor.nsColor
            ]
            let badge = NSAttributedString(string: codeContent.language.rawValue.uppercased(), attributes: badgeAttrs)
            badge.draw(at: CGPoint(x: local.width - badge.size().width - 12, y: (headerH - badge.size().height) / 2))
        }

        // Syntax-highlighted code lines (same highlighter as the canvas view)
        let lines = CodeHighlighter.highlight(code: codeContent.code, language: codeContent.language, theme: codeContent.theme)
        let digitCount = max(2, String(max(1, lines.count)).count)
        let gutterW = codeContent.showLineNumbers
            ? max(28, CGFloat(digitCount) * fontSize * 0.65 + 8)
            : 0
        let lineH = fontSize * 1.35 + 3
        var curY = headerH + pad
        let maxY = local.height - pad * 0.5

        for line in lines {
            if curY + lineH > maxY { break }
            var x = pad

            if codeContent.showLineNumbers {
                let numAttrs: [NSAttributedString.Key: Any] = [
                    .font: mono,
                    .foregroundColor: codeContent.theme.commentColor.nsColor.withAlphaComponent(0.55)
                ]
                let num = NSAttributedString(string: "\(line.lineNumber)", attributes: numAttrs)
                num.draw(at: CGPoint(x: pad + gutterW - num.size().width, y: curY))
            }
            x += gutterW + (codeContent.showLineNumbers ? 10 : 0)

            for token in line.tokens {
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: mono,
                    .foregroundColor: NSColor(token.color)
                ]
                let s = NSAttributedString(string: token.text, attributes: attrs)
                s.draw(at: CGPoint(x: x, y: curY))
                x += s.size().width
                if x > local.width - pad { break }
            }
            curY += lineH
        }

        context.restoreGState()
        NSGraphicsContext.restoreGraphicsState()
        context.restoreGState()
    }

    private static func svgLinearGradientDef(id: String, fill: FillStyle) -> String {
        var stops = ""
        for s in fill.gradientStops {
            stops += "<stop offset=\"\(Int(s.location * 100))%\" stop-color=\"\(s.color.hexString)\" />\n"
        }
        return """
        <linearGradient id="\(id)" x1="0%" y1="0%" x2="100%" y2="100%">
        \(stops)</linearGradient>
        """
    }

    private static func svgElement(_ elem: CanvasElement, index: Int) -> String {
        let opacity = elem.opacity < 1.0 ? " opacity=\"\(elem.opacity)\"" : ""
        var svgTransform = elem.rotation != 0 ? " rotate(\(elem.rotation) \(elem.center.x) \(elem.center.y))" : ""
        if elem.isFlippedH || elem.isFlippedV {
            let sx = elem.isFlippedH ? -1 : 1
            let sy = elem.isFlippedV ? -1 : 1
            svgTransform += " translate(\(elem.center.x) \(elem.center.y)) scale(\(sx) \(sy)) translate(\(-elem.center.x) \(-elem.center.y))"
        }
        let transform = svgTransform.isEmpty ? "" : " transform=\"\(svgTransform)\"" 

        switch elem.payload {
        case .shape(let shape):
            let fillStr: String
            if case .linearGradient = shape.fill.type {
                fillStr = "url(#elemGrad_\(index))"
            } else {
                fillStr = shape.fill.solidColor.hexString
            }
            let strokeStr = shape.stroke.isEnabled ? " stroke=\"\(shape.stroke.color.hexString)\" stroke-width=\"\(shape.stroke.lineWidth)\"" : ""
            let rx = shape.kind == .roundedRectangle ? " rx=\"\(shape.cornerRadius)\"" : ""

            if shape.kind == .circle {
                return "<ellipse cx=\"\(elem.center.x)\" cy=\"\(elem.center.y)\" rx=\"\(elem.width/2)\" ry=\"\(elem.height/2)\" fill=\"\(fillStr)\"\(strokeStr)\(opacity)\(transform) />\n"
            } else {
                return "<rect x=\"\(elem.x)\" y=\"\(elem.y)\" width=\"\(elem.width)\" height=\"\(elem.height)\"\(rx) fill=\"\(fillStr)\"\(strokeStr)\(opacity)\(transform) />\n"
            }

        case .text(let text):
            // Respect internal insets + vertical anchor (SVG is y-down like the
            // canvas, so offsets hang off elem.y directly).
            let cardPad = text.cardBackground != nil ? text.cardPadding : 0
            let areaH = max(0, elem.height - text.insetTop - text.insetBottom - cardPad * 2)
            let contentH = TextMeasurement.contentHeight(for: text, boxWidth: elem.width)
            let slack = max(0, areaH - min(areaH, contentH))
            let anchorShift = text.verticalAnchor == .center ? slack / 2 : (text.verticalAnchor == .bottom ? slack : 0)
            let anchor = text.alignment == .center ? "text-anchor=\"middle\"" : (text.alignment == .right ? "text-anchor=\"end\"" : "")
            let tx = text.alignment == .center ? elem.center.x
                : (text.alignment == .right ? elem.x + elem.width - text.insetRight - cardPad
                : elem.x + text.insetLeft + cardPad)
            let ty = elem.y + text.insetTop + cardPad + anchorShift + text.fontSize
            var out = ""
            if let bg = text.cardBackground {
                let border = (text.cardBorderColor != nil && text.cardBorderWidth > 0)
                    ? " stroke=\"\(text.cardBorderColor!.hexString)\" stroke-width=\"\(text.cardBorderWidth)\"" : ""
                out += "<rect x=\"\(elem.x)\" y=\"\(elem.y)\" width=\"\(elem.width)\" height=\"\(elem.height)\" rx=\"\(text.cardCornerRadius)\" fill=\"\(bg.hexString)\"\(border)\(opacity)\(transform) />\n"
            }
            let escaped = text.text
                .replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
            out += "<text x=\"\(tx)\" y=\"\(ty)\" font-family=\"\(text.fontFamily)\" font-size=\"\(text.fontSize)\" font-weight=\"\(Int(text.fontWeight))\" fill=\"\(text.textColor.hexString)\" \(anchor)\(opacity)\(transform)>\(escaped)</text>\n"
            return out

        default:
            return ""
        }
    }
}
