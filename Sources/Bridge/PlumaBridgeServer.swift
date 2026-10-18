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
    @Published public private(set) var requestCount: Int = 0

    private var listener: NWListener? = nil
    private weak var viewModel: CanvasDocumentViewModel?

    /// Hard limits so a hostile or buggy local client can't exhaust memory or
    /// overflow the body-length math. Bodies are bounded by the largest legit
    /// payload (base64-encoded images via /element/add).
    private nonisolated static let maxHeaderBytes = 64 * 1024
    private nonisolated static let maxBodyBytes = 64 * 1024 * 1024
    private nonisolated static let headerTerminator = Data([13, 10, 13, 10])

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
        // Without this the listener binds 0.0.0.0 — the (unauthenticated) edit
        // endpoints would be reachable from anything on the LAN.
        params.requiredInterfaceType = .loopback
        guard let listener = try? NWListener(using: params, on: NWEndpoint.Port(rawValue: requestedPort) ?? 9470) else {
            // Port busy — likely another Pluma instance already owns the bridge.
            NSLog("PlumaBridge: port \(requestedPort) unavailable; bridge not started")
            return
        }
        self.listener = listener

        listener.newConnectionHandler = { [weak self] connection in
            let queue = DispatchQueue(label: "pluma.bridge.client")
            connection.start(queue: queue)
            // Lifetime cap: a client that connects but never finishes a request
            // would leak the connection forever (no read timeout on receive).
            // Once a request is dispatched the deadline is re-armed with a
            // wider window so a heavy render isn't truncated mid-flight.
            let deadline = ConnectionDeadline(connection: connection, queue: queue)
            deadline.arm(seconds: 30)
            self?.receive(on: connection, buffer: Data(), deadline: deadline)
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

    /// Per-connection lifetime cap, re-armable via generation check. While the
    /// request bytes are still arriving the cap is short (slowloris); once a
    /// request is dispatched it can be extended so heavy renders finish.
    /// @unchecked Sendable: `generation` is only touched on the connection's
    /// serial dispatch queue — every arm() call originates inside a receive
    /// callback running on that queue.
    private final class ConnectionDeadline: @unchecked Sendable {
        private let connection: NWConnection
        private let queue: DispatchQueue
        private var generation = 0

        init(connection: NWConnection, queue: DispatchQueue) {
            self.connection = connection
            self.queue = queue
        }

        func arm(seconds: Double) {
            generation += 1
            let gen = generation
            queue.asyncAfter(deadline: .now() + seconds) { [weak self] in
                guard let self = self, self.generation == gen else { return }
                self.connection.cancel()
            }
        }
    }

    nonisolated private func receive(on connection: NWConnection, buffer: Data, deadline: ConnectionDeadline) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 8 * 1024 * 1024) { [weak self] data, _, isComplete, error in
            guard let self = self else { return }
            var buf = buffer
            if let data = data { buf.append(data) }

            // Scan the Data buffer directly — the old per-chunk [UInt8](buf)
            // copy made streaming a large body O(n²) (~256 GB memcpy for 64 MB).
            if let headerRange = buf.range(of: Self.headerTerminator) {
                let head = String(data: buf[buf.startIndex..<headerRange.lowerBound], encoding: .utf8) ?? ""
                let contentLength = Self.headerValue(head, "Content-Length").flatMap { Int($0) } ?? 0
                // Reject before computing bodyEnd: a huge Content-Length would
                // overflow the addition and crash the app, and unbounded
                // lengths would let a client exhaust memory.
                guard contentLength >= 0, contentLength <= Self.maxBodyBytes else {
                    self.reject(connection: connection, status: "413 Payload Too Large",
                                json: "{\"ok\":false,\"error\":\"request body too large\"}")
                    return
                }
                let bodyEnd = headerRange.upperBound + contentLength
                if buf.count >= bodyEnd {
                    let body = buf[headerRange.upperBound..<bodyEnd]
                    self.handle(connection: connection, head: head, body: body, deadline: deadline)
                    return
                }
            } else if buf.count > Self.maxHeaderBytes {
                self.reject(connection: connection, status: "431 Request Header Fields Too Large",
                            json: "{\"ok\":false,\"error\":\"request headers too large\"}")
                return
            }

            if error != nil || isComplete {
                if !buf.isEmpty { self.handle(connection: connection, head: "", body: buf, deadline: deadline) }
                return
            }
            self.receive(on: connection, buffer: buf, deadline: deadline)
        }
    }

    nonisolated private func reject(connection: NWConnection, status: String, json: String) {
        let response = "HTTP/1.1 \(status)\r\nContent-Type: application/json\r\nContent-Length: \(json.utf8.count)\r\nConnection: close\r\n\r\n\(json)"
        connection.send(content: Data(response.utf8), completion: .contentProcessed { _ in
            connection.cancel()
        })
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

    /// The bridge is a LOCAL api for the app's own tooling (MCP, CLI). Two
    /// browser-attack surfaces are closed here:
    ///
    /// 1. DNS-rebinding reads: a victim page on attacker.example (rebound to
    ///    127.0.0.1) could same-origin read /page, /project, /screenshot →
    ///    document exfiltration. Mitigation: Host must literally name a
    ///    loopback authority — a rebound Host is rejected.
    /// 2. CSRF writes: any webpage can fire fetch()/form POSTs at a loopback
    ///    port (e.g. /page/clear wipes the canvas). Browsers ALWAYS attach
    ///    Origin on POST fetches and Sec-Fetch-* metadata on every request;
    ///    curl/urllib/MCP clients never do → reject any request carrying them.
    nonisolated private static func isAllowedHost(_ host: String?) -> Bool {
        guard let host = host else { return false }
        let authority = host.lowercased()
        for base in ["127.0.0.1", "localhost", "[::1]"] {
            if authority == base || authority.hasPrefix(base + ":") { return true }
        }
        return false
    }

    nonisolated private static func hasBrowserHeaders(_ head: String) -> Bool {
        for line in head.components(separatedBy: "\r\n").dropFirst() {
            let key = line.split(separator: ":", maxSplits: 1).first?
                .trimmingCharacters(in: .whitespaces).lowercased() ?? ""
            if key == "origin" || key == "referer" || key.hasPrefix("sec-fetch-") {
                return true
            }
        }
        return false
    }

    nonisolated private func handle(connection: NWConnection, head: String, body: Data, deadline: ConnectionDeadline) {
        let requestLine = head.components(separatedBy: "\r\n").first ?? "GET / HTTP/1.1"
        let parts = requestLine.split(separator: " ")
        let method = parts.count > 0 ? String(parts[0]) : "GET"
        let rawPath = parts.count > 1 ? String(parts[1]) : "/"

        // Re-arm the connection cap for endpoints that can legitimately exceed
        // the short receipt window (e.g. rendering a 500-element page).
        let pathOnly = String(rawPath.split(separator: "?").first ?? "/")
        if pathOnly == "/screenshot" {
            deadline.arm(seconds: 120)
        }

        // CORS preflights only come from browsers — refuse outright.
        guard method != "OPTIONS" else {
            self.reject(connection: connection, status: "403 Forbidden",
                        json: "{\"ok\":false,\"error\":\"forbidden\"}")
            return
        }
        guard Self.isAllowedHost(Self.headerValue(head, "Host")),
              !Self.hasBrowserHeaders(head) else {
            self.reject(connection: connection, status: "403 Forbidden",
                        json: "{\"ok\":false,\"error\":\"browser requests are not allowed\"}")
            return
        }

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

        case ("POST", "/element/select"):
            // {"ids": [...]} or {"id": "..."}; empty list clears the selection.
            let req = (try? JSONSerialization.jsonObject(with: body) as? [String: Any]) ?? [:]
            let raw = (req["ids"] as? [String]) ?? ((req["id"] as? String).map { [$0] } ?? [])
            let onPage = Set(vm.currentPage.elements.map(\.id))
            let ids = Set(raw.compactMap(UUID.init(uuidString:))).intersection(onPage)
            vm.selectedElementIds = vm.expandSelectionForGroups(ids)
            return respond("200 OK", ["ok": true, "selected": vm.selectedElementIds.map(\.uuidString)])

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
            vm.saveHistoryState()
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
            guard vm.currentPage.elements.contains(where: { $0.id == id }) else {
                return respond("404 Not Found", ["ok": false, "error": "element not found on active page"])
            }
            vm.saveHistoryState()
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
            vm.saveHistoryState()
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
            guard ["front", "back", "forward", "backward"].contains(action) else {
                return respond("400 Bad Request", ["ok": false, "error": "unknown action"])
            }
            guard vm.currentPage.elements.contains(where: { $0.id == id }) else {
                return respond("404 Not Found", ["ok": false, "error": "element not found on active page"])
            }
            // The reorder methods save history themselves.
            let savedSelection = vm.selectedElementIds
            vm.selectedElementIds = [id]
            defer { vm.selectedElementIds = savedSelection }
            switch action {
            case "front": vm.bringToFront()
            case "back": vm.sendToBack()
            case "forward": vm.bringForward()
            default: vm.sendBackward()
            }
            ProjectStorage.shared.saveProjectDebounced(vm.project)
            return respond("200 OK", ["ok": true])

        case ("POST", "/page/add"):
            let req = (try? JSONSerialization.jsonObject(with: body) as? [String: Any]) ?? [:]
            vm.addPage()
            if let name = req["name"] as? String, !name.isEmpty {
                vm.renamePage(at: vm.project.pages.count - 1, to: name)
            }
            ProjectStorage.shared.saveProjectDebounced(vm.project)
            return respond("200 OK", ["ok": true, "pages": vm.project.pages.count, "activePage": vm.activePageIndex + 1])

        case ("POST", "/page/select"):
            guard let req = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
                  let index = req["page"] as? Int, index >= 1, index <= vm.project.pages.count else {
                return respond("400 Bad Request", ["ok": false, "error": "need {page: 1-based}"])
            }
            vm.activePageIndex = index - 1
            return respond("200 OK", ["ok": true, "activePage": index])

        case ("POST", "/page/clear"):
            // Wipes every element on a page (default: active) — used by agents
            // rebuilding a layout from scratch. Undoable via /undo.
            let req = (try? JSONSerialization.jsonObject(with: body) as? [String: Any]) ?? [:]
            let index = (req["page"] as? Int ?? vm.activePageIndex + 1) - 1
            guard index >= 0, index < vm.project.pages.count else {
                return respond("400 Bad Request", ["ok": false, "error": "page out of range"])
            }
            vm.saveHistoryState()
            let removed = vm.project.pages[index].elements.count
            vm.project.pages[index].elements.removeAll()
            if index == vm.activePageIndex { vm.selectedElementIds.removeAll() }
            ProjectStorage.shared.saveProjectDebounced(vm.project)
            return respond("200 OK", ["ok": true, "removed": removed, "page": index + 1])

        case ("POST", "/undo"):
            vm.undo()
            ProjectStorage.shared.saveProjectDebounced(vm.project)
            return respond("200 OK", ["ok": true])
        case ("POST", "/redo"):
            vm.redo()
            ProjectStorage.shared.saveProjectDebounced(vm.project)
            return respond("200 OK", ["ok": true])

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

        case ("POST", "/present"):
            // {"on": true|false} — start/stop full-screen presentation mode.
            let req = (try? JSONSerialization.jsonObject(with: body) as? [String: Any]) ?? [:]
            vm.isPresentingFullscreen = (req["on"] as? Bool) ?? true
            return respond("200 OK", ["ok": true, "presenting": vm.isPresentingFullscreen])

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
            guard from != to,
                  vm.currentPage.elements.contains(where: { $0.id == from }),
                  vm.currentPage.elements.contains(where: { $0.id == to }) else {
                return respond("404 Not Found", ["ok": false, "error": "elements not found on active page"])
            }
            vm.saveHistoryState()
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
                    "POST /element/select {ids[]}", "POST /present {on}",
                    "POST /connect {from, to}", "POST /page/add {name?}", "POST /page/select {page}", "POST /page/clear {page?}",
                    "POST /undo", "POST /redo", "POST /save", "GET /templates", "POST /template {id}"
                ],
                "limits": [
                    "request body ≤ \(Self.maxBodyBytes / 1024 / 1024) MB (~45 MB decoded image via imageBase64)",
                    "request headers ≤ \(Self.maxHeaderBytes / 1024) KB",
                    "loopback connections only"
                ]
            ])

        default:
            return respond("404 Not Found", ["ok": false, "error": "unknown endpoint \(method) \(pathOnly) — GET /help"])
        }
    }

    /// Matches "halftoneFade", "Halftone Fade", "crosshatch", etc.
    nonisolated fileprivate static func patternStyle(named name: String) -> PatternStyle {
        let key = name.replacingOccurrences(of: " ", with: "").lowercased()
        return PatternStyle.allCases.first(where: {
            $0.rawValue.replacingOccurrences(of: " ", with: "").lowercased() == key
                || $0.rawValue.lowercased() == key
        }) ?? .halftone
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
        let fill: FillStyle
        if fillHex == "pattern" {
            let style = Self.patternStyle(named: req["pattern"] as? String ?? "halftone")
            fill = FillStyle(
                type: .pattern,
                solidColor: CodableColor(hex: req["baseColor"] as? String ?? "#FAF9F7"),
                patternStyle: style,
                patternScale: req["patternScale"] as? Double ?? 24,
                patternColor: (req["patternColor"] as? String).map { CodableColor(hex: $0) }
            )
        } else {
            fill = FillStyle.solid(CodableColor(hex: fillHex))
        }
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
            // Canva parity: an explicit height wins; otherwise fit the box to
            // the rendered content — the generic 80pt default clips wraps.
            let textHeight = req["height"] as? Double
                ?? TextMeasurement.fittedHeight(for: textContent, width: width)
            element = CanvasElement(name: name ?? "Text", payload: .text(textContent), x: x, y: y, width: width, height: textHeight, rotation: rotation, opacity: opacity, zIndex: 0)
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
            var content = CodeContent()
            if let v = req["code"] as? String { content.code = v }
            if let v = req["language"] as? String,
               let lang = CodeLanguage.allCases.first(where: {
                   $0.rawValue.caseInsensitiveCompare(v) == .orderedSame || $0.fileExtension.caseInsensitiveCompare(v) == .orderedSame
               }) {
                content.language = lang
                // A Swift-flavored default title on a Python card is wrong —
                // track the language unless the caller names the file.
                if req["title"] == nil { content.windowTitle = "snippet.\(lang.fileExtension)" }
            }
            if let v = req["theme"] as? String,
               let theme = CodeTheme.allCases.first(where: { $0.rawValue.caseInsensitiveCompare(v) == .orderedSame }) {
                content.theme = theme
            }
            if let v = req["title"] as? String { content.windowTitle = v }
            if let v = req["lineNumbers"] as? Bool { content.showLineNumbers = v }
            if let v = req["fontSize"] as? Double { content.fontSize = max(8, v) }
            // Without an explicit height, size the card to its line count — the
            // generic 80pt default would clip all but ~2 lines.
            let codeHeight = req["height"] as? Double
                ?? CanvasDocumentViewModel.calculateCodeBlockHeight(for: content)
            element = CanvasElement(name: name ?? "Code Block", payload: .code(content), x: x, y: y, width: width, height: codeHeight, shadow: .elevated, zIndex: 0)
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
            // Shapes — friendly aliases first, then any ShapeKind raw value
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
            case "database", "cylinder", "db": kind = .database
            case "chevron": kind = .chevron
            case "cross", "plus": kind = .cross
            default:
                kind = ShapeKind.allCases.first(where: {
                    $0.rawValue.caseInsensitiveCompare(type) == .orderedSame
                }) ?? .roundedRectangle
            }
            // `.line` is an open path — invisible unless stroked in the fill color.
            let shapeStroke = kind == .line
                ? StrokeStyle(isEnabled: true, color: fill.solidColor, lineWidth: max(2, height))
                : stroke
            element = CanvasElement(
                name: name ?? "Shape",
                payload: .shape(ShapeContent(kind: kind, cornerRadius: 12, fill: fill, stroke: shapeStroke)),
                x: x, y: y, width: width, height: height,
                rotation: rotation, opacity: opacity, zIndex: 0
            )
        }

        vm.saveHistoryState()
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
            out["insets"] = ["left": t.insetLeft, "right": t.insetRight, "top": t.insetTop, "bottom": t.insetBottom]
            out["anchor"] = t.verticalAnchor.rawValue
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
            out["theme"] = c.theme.rawValue
            out["title"] = c.windowTitle
            out["code"] = c.code
        }
        return out
    }

    /// Applies partial updates from the bridge (only provided keys change).
    /// Main-actor: height reflows go through the view model's measuring code.
    @MainActor mutating func applyBridgeProps(_ props: [String: Any]) {
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
            if let v = props["insetLeft"] as? Double { t.insetLeft = max(0, v) }
            if let v = props["insetRight"] as? Double { t.insetRight = max(0, v) }
            if let v = props["insetTop"] as? Double { t.insetTop = max(0, v) }
            if let v = props["insetBottom"] as? Double { t.insetBottom = max(0, v) }
            if let v = props["anchor"] as? String,
               let a = TextVerticalAnchor.allCases.first(where: {
                   $0.rawValue.caseInsensitiveCompare(v) == .orderedSame
               }) { t.verticalAnchor = a }
            payload = .text(t)
            // Canva parity: content/metric edits reflow; an explicit height wins.
            if props["height"] == nil,
               props["text"] != nil || props["fontSize"] != nil || props["fontWeight"] != nil
                || props["fontFamily"] != nil || props["letterSpacing"] != nil
                || props["lineSpacing"] != nil || props["width"] != nil
                || props["insetLeft"] != nil || props["insetRight"] != nil
                || props["insetTop"] != nil || props["insetBottom"] != nil {
                height = TextMeasurement.fittedHeight(for: t, width: width)
            }
        case .shape(var s):
            if let v = props["fill"] as? String {
                if v == "pattern" {
                    let style = PlumaBridgeServer.patternStyle(named: props["pattern"] as? String ?? "halftone")
                    s.fill = FillStyle(
                        type: .pattern,
                        solidColor: CodableColor(hex: props["baseColor"] as? String ?? "#FAF9F7"),
                        patternStyle: style,
                        patternScale: props["patternScale"] as? Double ?? 24,
                        patternColor: (props["patternColor"] as? String).map { CodableColor(hex: $0) }
                    )
                } else {
                    s.fill = .solid(CodableColor(hex: v))
                }
            }
            if let v = props["cornerRadius"] as? Double { s.cornerRadius = max(0, v) }
            if let v = props["shape"] as? String, let k = ShapeKind(rawValue: v) { s.kind = k }
            payload = .shape(s)
        case .image(var i):
            if let v = props["cornerRadius"] as? Double { i.cornerRadius = max(0, v) }
            if let v = props["imageBase64"] as? String, !v.isEmpty { i.imageBase64 = v }
            payload = .image(i)
        case .code(var c):
            if let v = props["code"] as? String { c.code = v }
            if let v = props["language"] as? String,
               let lang = CodeLanguage.allCases.first(where: {
                   $0.rawValue.caseInsensitiveCompare(v) == .orderedSame || $0.fileExtension.caseInsensitiveCompare(v) == .orderedSame
               }) { c.language = lang }
            if let v = props["theme"] as? String,
               let theme = CodeTheme.allCases.first(where: { $0.rawValue.caseInsensitiveCompare(v) == .orderedSame }) {
                c.theme = theme
            }
            if let v = props["title"] as? String { c.windowTitle = v }
            if let v = props["fontSize"] as? Double { c.fontSize = max(8, v) }
            payload = .code(c)
            // Reflow like text: code edits change the fitted card height
            // unless the caller pinned an explicit height.
            if props["height"] == nil, props["code"] != nil || props["fontSize"] != nil {
                height = CanvasDocumentViewModel.calculateCodeBlockHeight(for: c)
            }
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
