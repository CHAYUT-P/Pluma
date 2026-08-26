import Foundation
import Network
import AppKit
import CoreGraphics

// MARK: - Pluma AI Bridge
//
// A tiny localhost-only HTTP server embedded in the app that lets AI agents
// (via the MCP server in scripts/pluma_mcp_server.py) read and edit the LIVE
// design: add/update/delete elements, manage pages, apply templates, undo/redo,
// and — crucially — request PNG screenshots so the agent can SEE its work.
//
// Security: binds to 127.0.0.1 only. Disable with env PLUMA_BRIDGE=0.
// Port: env PLUMA_PORT, default 9470.

@MainActor
public final class PlumaBridgeServer: ObservableObject {
    public static let shared = PlumaBridgeServer()

    @Published public private(set) var isRunning: Bool = false
    @Published public private(set) var port: UInt16 = 0
    @Published public private(set) var lastClient: String = "—"
    @Published public private(set) var requestCount: Int = 0

    private var listener: NWListener? = nil
    private weak var viewModel: CanvasDocumentViewModel?

    private init() {}

    // MARK: - Lifecycle

    public func start(viewModel: CanvasDocumentViewModel) {
        self.viewModel = viewModel

        guard ProcessInfo.processInfo.environment["PLUMA_BRIDGE"] != "0" else {
            NSLog("PlumaBridge: disabled via PLUMA_BRIDGE=0")
            return
        }

        let requestedPort = ProcessInfo.processInfo.environment["PLUMA_PORT"]
            .flatMap { UInt16($0) } ?? 9470

        let params = NWParameters.tcp
        params.allowLocalEndpointReuse = true
        guard let listener = try? NWListener(using: params, on: NWEndpoint.Port(rawValue: requestedPort) ?? 9470) else {
            // Port busy — likely another Pluma instance already owns the bridge.
            NSLog("PlumaBridge: port \(requestedPort) unavailable; bridge not started")
            return
        }
        self.listener = listener

        listener.newConnectionHandler = { [weak self] connection in
            connection.start(queue: DispatchQueue(label: "pluma.bridge.client"))
            self?.receive(on: connection, buffer: Data())
        }

        listener.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in
                switch state {
                case .ready:
                    self?.isRunning = true
                    self?.port = listener.port?.rawValue ?? 0
                    NSLog("PlumaBridge: listening on 127.0.0.1:\(self?.port ?? 0)")
                case .failed(let error):
                    NSLog("PlumaBridge failed: \(error)")
                    self?.isRunning = false
                default:
                    break
                }
            }
        }
        listener.start(queue: DispatchQueue(label: "pluma.bridge.listener"))
    }

    // MARK: - HTTP Plumbing (minimal, sufficient for JSON requests)

    nonisolated private func receive(on connection: NWConnection, buffer: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 8 * 1024 * 1024) { [weak self] data, _, isComplete, error in
            guard let self = self else { return }
            var buf = buffer
            if let data = data { buf.append(data) }

            let bytes = [UInt8](buf)
            if let headerEnd = Self.findHeaderEnd(bytes) {
                let headData = Data(bytes[0..<headerEnd])
                let head = String(data: headData, encoding: .utf8) ?? ""
                let contentLength = Self.headerValue(head, "Content-Length").flatMap { Int($0) } ?? 0
                let bodyStart = headerEnd + 4
                let bodyEnd = min(bytes.count, bodyStart + contentLength)
                if bytes.count >= bodyEnd {
                    let body = bodyStart <= bodyEnd ? Data(bytes[bodyStart..<bodyEnd]) : Data()
                    self.handle(connection: connection, head: head, body: body)
                    return
                }
            }

            if error != nil || isComplete {
                if !buf.isEmpty { self.handle(connection: connection, head: "", body: buf) }
                return
            }
            self.receive(on: connection, buffer: buf)
        }
    }

    nonisolated private static func findHeaderEnd(_ bytes: [UInt8]) -> Int? {
        guard bytes.count >= 4 else { return nil }
        for i in 0...(bytes.count - 4) {
            if bytes[i] == 13, bytes[i + 1] == 10, bytes[i + 2] == 13, bytes[i + 3] == 10 {
                return i
            }
        }
        return nil
    }

    nonisolated private static func headerValue(_ head: String, _ key: String) -> String? {
        for line in head.components(separatedBy: "\r\n") {
            let parts = line.split(separator: ":", maxSplits: 1)
            if parts.count == 2, parts[0].trimmingCharacters(in: .whitespaces).caseInsensitiveCompare(key) == .orderedSame {
                return parts[1].trimmingCharacters(in: .whitespaces)
            }
        }
        return nil
    }

    nonisolated private func handle(connection: NWConnection, head: String, body: Data) {
        let requestLine = head.components(separatedBy: "\r\n").first ?? "GET / HTTP/1.1"
        let parts = requestLine.split(separator: " ")
        let method = parts.count > 0 ? String(parts[0]) : "GET"
        let rawPath = parts.count > 1 ? String(parts[1]) : "/"

        Task { @MainActor in
            self.requestCount += 1
            let (status, json) = await self.route(method: method, path: rawPath, body: body)
            let response = "HTTP/1.1 \(status)\r\nContent-Type: application/json\r\nContent-Length: \(json.utf8.count)\r\nConnection: close\r\n\r\n\(json)"
            connection.send(content: Data(response.utf8), completion: .contentProcessed { _ in
                connection.cancel()
            })
        }
    }

    private func respond(_ status: String, _ payload: Any) -> (String, String) {
        let json: String
        if let data = try? JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys]),
           let s = String(data: data, encoding: .utf8) {
            json = s
        } else {
            json = "{\"ok\":false,\"error\":\"serialization failed\"}"
        }
        return (status, json)
    }

    // MARK: - Routing

    private func route(method: String, path: String, body: Data) async -> (String, String) {
        let params = Self.queryParams(path)
        let pathOnly = String(path.split(separator: "?").first ?? "/")
        let vm = viewModel

        guard let vm = vm else {
            return respond("503 Service Unavailable", ["ok": false, "error": "no document open"])
        }

        switch (method, pathOnly) {

        case ("GET", "/health"):
            return respond("200 OK", [
                "ok": true,
                "app": "Pluma",
                "version": "2.1.0",
                "project": vm.project.name,
                "projectId": vm.project.id.uuidString,
                "pages": vm.project.pages.count,
                "activePage": vm.activePageIndex + 1,
                "elementCount": vm.currentPage.elements.count
            ])

        case ("GET", "/project"):
            return respond("200 OK", ["ok": true, "project": vm.project.dictionarySummary()])

        case ("GET", "/page"):
            let index = (params["page"].flatMap { Int($0) } ?? vm.activePageIndex + 1) - 1
            guard index >= 0, index < vm.project.pages.count else {
                return respond("404 Not Found", ["ok": false, "error": "page out of range"])
            }
            let page = vm.project.pages[index]
            return respond("200 OK", [
                "ok": true,
                "pageIndex": index + 1,
                "name": page.name,
                "width": page.width,
                "height": page.height,
                "elements": page.elements.map { $0.bridgeJSON }
            ])

        case ("GET", "/screenshot"):
            let index = (params["page"].flatMap { Int($0) } ?? vm.activePageIndex + 1) - 1
            guard index >= 0, index < vm.project.pages.count else {
                return respond("404 Not Found", ["ok": false, "error": "page out of range"])
            }
            let scale = min(2.0, max(0.25, params["scale"].flatMap { Double($0) } ?? 1.0))
            guard let image = ExportEngine.renderImage(page: vm.project.pages[index], scale: scale),
                  let tiff = image.tiffRepresentation,
                  let rep = NSBitmapImageRep(data: tiff),
                  let png = rep.representation(using: .png, properties: [:]) else {
                return respond("500 Internal Server Error", ["ok": false, "error": "render failed"])
            }
            return respond("200 OK", [
                "ok": true,
                "page": index + 1,
                "width": Int(vm.project.pages[index].width * scale),
                "height": Int(vm.project.pages[index].height * scale),
                "png_base64": png.base64EncodedString()
            ])

        case ("POST", "/element/add"):
            guard let req = try? JSONSerialization.jsonObject(with: body) as? [String: Any] else {
                return respond("400 Bad Request", ["ok": false, "error": "invalid JSON"])
            }
            return addElement(vm: vm, req: req)

        case ("POST", "/element/update"):
            guard let req = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
                  let idStr = req["id"] as? String,
                  let id = UUID(uuidString: idStr),
                  let props = req["props"] as? [String: Any] else {
                return respond("400 Bad Request", ["ok": false, "error": "need {id, props{…}}"])
            }
            guard let idx = vm.currentPage.elements.firstIndex(where: { $0.id == id }) else {
                return respond("404 Not Found", ["ok": false, "error": "element not found on active page"])
            }
            var el = vm.currentPage.elements[idx]
            el.applyBridgeProps(props)
            vm.currentPage.elements[idx] = el
            vm.syncConnectors(touching: [id])
            ProjectStorage.shared.saveProjectDebounced(vm.project)
            return respond("200 OK", ["ok": true, "element": vm.currentPage.elements[idx].bridgeJSON])

        case ("POST", "/element/delete"):
            guard let req = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
                  let idStr = req["id"] as? String,
                  let id = UUID(uuidString: idStr) else {
                return respond("400 Bad Request", ["ok": false, "error": "need {id}"])
            }
            vm.currentPage.elements.removeAll {
                $0.id == id || (isConnectorOf($0, endpoint: id))
            }
            ProjectStorage.shared.saveProjectDebounced(vm.project)
            return respond("200 OK", ["ok": true])

        case ("POST", "/element/duplicate"), ("POST", "/element/copy"):
            guard let req = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
                  let idStr = req["id"] as? String,
                  let id = UUID(uuidString: idStr),
                  let el = vm.currentPage.elements.first(where: { $0.id == id }) else {
                return respond("400 Bad Request", ["ok": false, "error": "need {id}"])
            }
            var copy = el
            copy.id = UUID()
            copy.x += 24
            copy.y += 24
            copy.connector = nil // copies are static unless re-linked
            copy.zIndex = (vm.currentPage.elements.map { $0.zIndex }.max() ?? 0) + 1
            vm.currentPage.elements.append(copy)
            ProjectStorage.shared.saveProjectDebounced(vm.project)
            return respond("200 OK", ["ok": true, "element": copy.bridgeJSON])

        case ("POST", "/element/reorder"):
            guard let req = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
                  let idStr = req["id"] as? String,
                  let id = UUID(uuidString: idStr),
                  let action = req["action"] as? String else {
                return respond("400 Bad Request", ["ok": false, "error": "need {id, action: front|back|forward|backward}"])
            }
            vm.selectedElementIds = [id]
            switch action {
            case "front": vm.bringToFront()
            case "back": vm.sendToBack()
            case "forward": vm.bringForward()
            case "backward": vm.sendBackward()
            default: return respond("400 Bad Request", ["ok": false, "error": "unknown action"])
            }
            vm.selectedElementIds.removeAll()
            return respond("200 OK", ["ok": true])

        case ("POST", "/page/add"):
            let req = (try? JSONSerialization.jsonObject(with: body) as? [String: Any]) ?? [:]
            vm.addPage()
            if let name = req["name"] as? String, !name.isEmpty {
                vm.renamePage(at: vm.project.pages.count - 1, to: name)
            }
            return respond("200 OK", ["ok": true, "pages": vm.project.pages.count, "activePage": vm.activePageIndex + 1])

        case ("POST", "/page/select"):
            guard let req = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
                  let index = req["page"] as? Int, index >= 1, index <= vm.project.pages.count else {
                return respond("400 Bad Request", ["ok": false, "error": "need {page: 1-based}"])
            }
            vm.activePageIndex = index - 1
            return respond("200 OK", ["ok": true, "activePage": index])

        case ("POST", "/undo"): vm.undo(); return respond("200 OK", ["ok": true])
        case ("POST", "/redo"): vm.redo(); return respond("200 OK", ["ok": true])

        case ("POST", "/save"):
            ProjectStorage.shared.saveProject(vm.project)
            return respond("200 OK", ["ok": true, "saved": vm.project.name])

        case ("GET", "/templates"):
            var all: [[String: Any]] = []
            for t in TemplateCatalog.templates {
                all.append(["id": t.id, "title": t.title, "category": t.category, "pages": t.pages.count])
            }
            return respond("200 OK", ["ok": true, "templates": all])

        case ("POST", "/template"):
            guard let req = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
                  let id = req["id"] as? String,
                  let template = TemplateCatalog.templates.first(where: { $0.id == id }) else {
                return respond("400 Bad Request", ["ok": false, "error": "need {id} of a template (GET /templates)"])
            }
            vm.applyTemplate(template)
            ProjectStorage.shared.saveProjectDebounced(vm.project)
            return respond("200 OK", ["ok": true, "applied": template.title, "pages": vm.project.pages.count])

        case ("POST", "/open"):
            // Raises the editor UI (used after bridge-driven template/import changes)
            NotificationCenter.default.post(name: .openEditor, object: nil)
            return respond("200 OK", ["ok": true])

        case ("POST", "/connect"):
            guard let req = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
                  let from = (req["from"] as? String).flatMap(UUID.init(uuidString:)),
                  let to = (req["to"] as? String).flatMap(UUID.init(uuidString:)) else {
                return respond("400 Bad Request", ["ok": false, "error": "need {from, to} element ids"])
            }
            if let el = vm.makeConnector(from: from, to: to) {
                ProjectStorage.shared.saveProjectDebounced(vm.project)
                return respond("200 OK", ["ok": true, "element": el.bridgeJSON])
            }
            return respond("400 Bad Request", ["ok": false, "error": "elements not found on active page"])

        case ("GET", "/help"), ("GET", "/"):
            return respond("200 OK", [
                "ok": true,
                "endpoints": [
                    "GET /health", "GET /project", "GET /page?page=N",
                    "GET /screenshot?page=N&scale=1 (returns png_base64 — use it to SEE the design)",
                    "POST /element/add {type:text|rectangle|circle|star|arrow|sticky|code, text?, x?, y?, width?, height?, fill?, fontSize?, fontWeight?, color?, align?, page?}",
                    "POST /element/update {id, props{x,y,width,height,rotation,opacity,text,fill,color,fontSize,fontWeight,align,...}}",
                    "POST /element/delete {id}", "POST /element/duplicate {id}", "POST /element/reorder {id, action}",
                    "POST /connect {from, to}", "POST /page/add {name?}", "POST /page/select {page}",
                    "POST /undo", "POST /redo", "POST /save", "GET /templates", "POST /template {id}"
                ]
            ])

        default:
            return respond("404 Not Found", ["ok": false, "error": "unknown endpoint \(method) \(pathOnly) — GET /help"])
        }
    }

    private func isConnectorOf(_ el: CanvasElement, endpoint: UUID) -> Bool {
        guard let conn = el.connector else { return false }
        return conn.fromID == endpoint || conn.toID == endpoint
    }

    // MARK: - Element Creation

    private func addElement(vm: CanvasDocumentViewModel, req: [String: Any]) -> (String, String) {
        let type = (req["type"] as? String ?? "text").lowercased()
        let pageIdx = ((req["page"] as? Int ?? vm.activePageIndex + 1) - 1)
        guard pageIdx >= 0, pageIdx < vm.project.pages.count else {
            return respond("400 Bad Request", ["ok": false, "error": "page out of range"])
        }

        let pageW = vm.project.pages[pageIdx].width
        let pageH = vm.project.pages[pageIdx].height

        let x = req["x"] as? Double ?? pageW / 2.0 - 200
        let y = req["y"] as? Double ?? pageH / 2.0 - 60
        let width = req["width"] as? Double ?? 400
        let height = req["height"] as? Double ?? 80
        let rotation = req["rotation"] as? Double ?? 0
        let opacity = req["opacity"] as? Double ?? 1
        let name = req["name"] as? String

        let fillHex = req["fill"] as? String ?? "#C2410C"
        let fill = FillStyle.solid(CodableColor(hex: fillHex))
        let stroke = StrokeStyle(isEnabled: false)

        var element: CanvasElement
        switch type {
        case "text":
            let textContent = TextContent(
                text: req["text"] as? String ?? "Double-click to edit",
                fontFamily: req["fontFamily"] as? String ?? "Playfair Display",
                fontSize: req["fontSize"] as? Double ?? 44,
                fontWeight: req["fontWeight"] as? Double ?? 700,
                alignment: TextAlignmentKind(rawValue: (req["align"] as? String) ?? "") ?? .center,
                textColor: CodableColor(hex: req["color"] as? String ?? "#1C1917"),
                letterSpacing: req["letterSpacing"] as? Double ?? 0.5,
                lineSpacing: req["lineSpacing"] as? Double ?? 4
            )
            element = CanvasElement(name: name ?? "Text", payload: .text(textContent), x: x, y: y, width: width, height: height, rotation: rotation, opacity: opacity, zIndex: 0)
        case "sticky":
            let colorHex = req["fill"] as? String ?? "#FEF08A"
            let textContent = TextContent(
                text: req["text"] as? String ?? "New note",
                fontFamily: "Indie Flower",
                fontSize: req["fontSize"] as? Double ?? 16,
                fontWeight: 700,
                alignment: .left,
                textColor: CodableColor(hex: req["color"] as? String ?? "#854D0E"),
                lineSpacing: 4,
                cardBackground: CodableColor(hex: colorHex),
                cardCornerRadius: 10,
                cardPadding: 16
            )
            element = CanvasElement(name: name ?? "Sticky Note", payload: .text(textContent), x: x, y: y, width: width, height: height, rotation: rotation, opacity: opacity, shadow: .subtle, zIndex: 0)
        case "code":
            element = CanvasElement(name: name ?? "Code Block", payload: .code(CodeContent()), x: x, y: y, width: width, height: height, shadow: .elevated, zIndex: 0)
        case "image":
            guard let base64 = req["imageBase64"] as? String, !base64.isEmpty,
                  let data = Data(base64Encoded: base64), let img = NSImage(data: data) else {
                return respond("400 Bad Request", ["ok": false, "error": "image type needs valid imageBase64 (PNG/JPEG)"])
            }
            let content = ImageContent(
                imageBase64: ImageUtils.base64String(from: img) ?? base64,
                contentMode: .fill,
                originalWidth: img.size.width,
                originalHeight: img.size.height
            )
            element = CanvasElement(name: name ?? "Image", payload: .image(content), x: x, y: y, width: width, height: height, rotation: rotation, opacity: opacity, zIndex: 0)
        default:
            // Shapes
            let kind: ShapeKind
            switch type {
            case "rectangle", "rect": kind = .roundedRectangle
            case "square": kind = .rectangle
            case "circle", "ellipse": kind = .circle
            case "triangle": kind = .triangle
            case "star": kind = .star
            case "arrow": kind = .arrow
            case "diamond": kind = .diamond
            case "heart": kind = .heart
            case "speech", "speechbubble": kind = .speechBubble
            case "line": kind = .line
            case "pill": kind = .pill
            case "hexagon": kind = .polygon
            case "lightning": kind = .lightning
            default: kind = .roundedRectangle
            }
            element = CanvasElement(
                name: name ?? "Shape",
                payload: .shape(ShapeContent(kind: kind, cornerRadius: 12, fill: fill, stroke: stroke)),
                x: x, y: y, width: width, height: height,
                rotation: rotation, opacity: opacity, zIndex: 0
            )
        }

        // Place on the requested page with top z-index
        let maxZ = vm.project.pages[pageIdx].elements.map { $0.zIndex }.max() ?? 0
        element.zIndex = maxZ + 1
        vm.project.pages[pageIdx].elements.append(element)
        ProjectStorage.shared.saveProjectDebounced(vm.project)
        return respond("200 OK", ["ok": true, "id": element.id.uuidString, "element": element.bridgeJSON])
    }

    // MARK: - Query helpers

    private static func queryParams(_ path: String) -> [String: String] {
        guard let qIndex = path.firstIndex(of: "?") else { return [:] }
        var result: [String: String] = [:]
        let query = path[path.index(after: qIndex)...]
        for pair in query.split(separator: "&") {
            let kv = pair.split(separator: "=", maxSplits: 1)
            guard let k = kv.first else { continue }
            let v = kv.count > 1 ? kv[1] : ""
            result[String(k)] = String(v).replacingOccurrences(of: "%2F", with: "/")
        }
        return result
    }
}

// MARK: - JSON projections for the bridge

extension CanvasElement {
    /// Compact JSON description used by the AI bridge.
    var bridgeJSON: [String: Any] {
        var out: [String: Any] = [
            "id": id.uuidString,
            "name": name,
            "x": x, "y": y,
            "width": width, "height": height,
            "rotation": rotation,
            "opacity": opacity,
            "zIndex": zIndex,
            "locked": isLocked,
            "visible": isVisible
        ]
        if let conn = connector {
            out["connector"] = ["from": conn.fromID.uuidString, "to": conn.toID.uuidString]
        }
        switch payload {
        case .text(let t):
            out["type"] = "text"
            out["text"] = t.text
            out["fontFamily"] = t.fontFamily
            out["fontSize"] = t.fontSize
            out["fontWeight"] = t.fontWeight
            out["color"] = t.textColor.hexString
            out["align"] = t.alignment.rawValue
            out["letterSpacing"] = t.letterSpacing
            out["lineSpacing"] = t.lineSpacing
            if let bg = t.cardBackground { out["cardBackground"] = bg.hexString }
        case .shape(let s):
            out["type"] = "shape"
            out["shape"] = s.kind.rawValue
            out["fill"] = s.fill.solidColor.hexString
            out["cornerRadius"] = s.cornerRadius
        case .image(let i):
            out["type"] = "image"
            out["imageBytes"] = i.imageBase64.count
            out["originalWidth"] = i.originalWidth
            out["originalHeight"] = i.originalHeight
        case .icon(let i):
            out["type"] = "icon"
            out["symbol"] = i.symbolName
        case .drawing(let d):
            out["type"] = "drawing"
            out["points"] = d.points.count
        case .code(let c):
            out["type"] = "code"
            out["language"] = c.language.rawValue
        }
        return out
    }

    /// Applies partial updates from the bridge (only provided keys change).
    mutating func applyBridgeProps(_ props: [String: Any]) {
        if let v = props["x"] as? Double { x = v }
        if let v = props["y"] as? Double { y = v }
        if let v = props["width"] as? Double { width = max(5, v) }
        if let v = props["height"] as? Double { height = max(5, v) }
        if let v = props["rotation"] as? Double { rotation = v }
        if let v = props["opacity"] as? Double { opacity = max(0, min(1, v)) }
        if let v = props["name"] as? String { name = v }
        if let v = props["visible"] as? Bool { isVisible = v }
        if let v = props["locked"] as? Bool { isLocked = v }

        switch payload {
        case .text(var t):
            if let v = props["text"] as? String { t.text = v }
            if let v = props["fontSize"] as? Double { t.fontSize = max(6, v) }
            if let v = props["fontWeight"] as? Double { t.fontWeight = max(100, min(900, v)) }
            if let v = props["fontFamily"] as? String { t.fontFamily = v }
            if let v = props["color"] as? String { t.textColor = CodableColor(hex: v) }
            if let v = props["fill"] as? String { t.cardBackground = CodableColor(hex: v) }
            if let v = props["align"] as? String, let a = TextAlignmentKind(rawValue: v) { t.alignment = a }
            if let v = props["letterSpacing"] as? Double { t.letterSpacing = v }
            if let v = props["lineSpacing"] as? Double { t.lineSpacing = v }
            payload = .text(t)
        case .shape(var s):
            if let v = props["fill"] as? String { s.fill = .solid(CodableColor(hex: v)) }
            if let v = props["cornerRadius"] as? Double { s.cornerRadius = max(0, v) }
            if let v = props["shape"] as? String, let k = ShapeKind(rawValue: v) { s.kind = k }
            payload = .shape(s)
        case .image(var i):
            if let v = props["cornerRadius"] as? Double { i.cornerRadius = max(0, v) }
            if let v = props["imageBase64"] as? String, !v.isEmpty { i.imageBase64 = v }
            payload = .image(i)
        default:
            break
        }
    }
}

extension CanvasProject {
    /// Lightweight summary (no base64 payloads).
    func dictionarySummary() -> [String: Any] {
        [
            "id": id.uuidString,
            "name": name,
            "pages": pages.enumerated().map { (idx, page) in
                [
                    "index": idx + 1,
                    "name": page.name,
                    "width": page.width,
                    "height": page.height,
                    "elements": page.elements.map { $0.bridgeJSON }
                ] as [String: Any]
            }
        ]
    }
}
