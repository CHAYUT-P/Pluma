import Foundation
import SwiftUI

/// Software-engineer component presets: multi-element composites (browser
/// chrome, status badges, API chips, diagram stamps) built from existing
/// element types so they render everywhere (canvas, thumbnails, export, PPTX).
///
/// Each builder returns elements positioned relative to (0,0); the view model's
/// `insertElements` translates the whole bundle to the insertion point, gives
/// it a shared groupId and assigns stacking order.
public enum DevKitPresets {

    // MARK: - Palette

    private static let ink = CodableColor(hex: "#1C1917")
    private static let paper = CodableColor(hex: "#FAF9F7")
    private static let slate = CodableColor(hex: "#334155")
    private static let termBg = CodableColor(hex: "#161618")
    private static let green = CodableColor(hex: "#10B981")
    private static let blue = CodableColor(hex: "#3B82F6")
    private static let amber = CodableColor(hex: "#F59E0B")
    private static let red = CodableColor(hex: "#EF4444")
    private static let violet = CodableColor(hex: "#8B5CF6")
    private static let chrome = CodableColor(hex: "#E7E5E4")
    private static let terracotta = CodableColor(hex: "#C2410C")
    private static let mono = "Menlo"

    // MARK: - Helpers

    private static func shape(
        _ kind: ShapeKind, x: Double, y: Double, w: Double, h: Double,
        fill: CodableColor, corner: Double = 10, name: String,
        stroke: StrokeStyle = StrokeStyle(isEnabled: false), opacity: Double = 1
    ) -> CanvasElement {
        CanvasElement(
            name: name,
            payload: .shape(ShapeContent(kind: kind, cornerRadius: corner, fill: .solid(fill), stroke: stroke)),
            x: x, y: y, width: w, height: h, opacity: opacity, zIndex: 0
        )
    }

    private static func label(
        _ text: String, x: Double, y: Double, w: Double, h: Double,
        size: Double, weight: Double = 500, color: CodableColor,
        align: TextAlignmentKind = .left, family: String = "Menlo", name: String
    ) -> CanvasElement {
        CanvasElement(
            name: name,
            payload: .text(TextContent(
                text: text, fontFamily: family, fontSize: size, fontWeight: weight,
                alignment: align, textColor: color, letterSpacing: 0, lineSpacing: 0
            )),
            x: x, y: y, width: w, height: h, zIndex: 0
        )
    }

    private static func line(_ x: Double, _ y: Double, _ w: Double, _ h: Double, color: CodableColor, name: String = "Rule") -> CanvasElement {
        // `.line` is an open path — it only paints via its stroke.
        shape(.line, x: x, y: y, w: w, h: h, fill: color, corner: 0, name: name,
              stroke: StrokeStyle(isEnabled: true, color: color, lineWidth: max(2, h)))
    }

    // MARK: - Single-element components

    /// Terminal window: a code block pre-styled as a shell session.
    @MainActor
    public static func terminalWindow() -> [CanvasElement] {
        var content = CodeContent()
        content.language = .bash
        content.theme = .carbonDark
        content.windowTitle = "zsh — ~/project"
        content.code = """
        $ git status
        On branch main — nothing to commit
        $ swift build && swift test
        Build complete! (2.4s)
        ✔ 128 tests passed
        $ _
        """
        let h = CanvasDocumentViewModel.calculateCodeBlockHeight(for: content)
        return [CanvasElement(
            name: "Terminal Window",
            payload: .code(content),
            x: 0, y: 0, width: 560, height: h,
            shadow: .elevated, zIndex: 0
        )]
    }

    /// Database cylinder (native shape kind).
    public static func databaseCylinder() -> [CanvasElement] {
        [shape(.database, x: 0, y: 0, w: 150, h: 170, fill: blue, corner: 0,
               name: "Database", stroke: StrokeStyle(isEnabled: true, color: ink, lineWidth: 2))]
    }

    // MARK: - Composite components

    /// Browser window chrome: traffic lights + URL bar + viewport.
    public static func browserWindow() -> [CanvasElement] {
        [
            shape(.roundedRectangle, x: 0, y: 0, w: 480, h: 320, fill: .white, corner: 14,
                  name: "Browser Window", stroke: StrokeStyle(isEnabled: true, color: chrome, lineWidth: 1.5)),
            shape(.roundedRectangle, x: 0, y: 0, w: 480, h: 40, fill: chrome, corner: 14, name: "Chrome Bar"),
            shape(.circle, x: 14, y: 14, w: 11, h: 11, fill: CodableColor(hex: "#FF5F57"), corner: 0, name: "Close Dot"),
            shape(.circle, x: 32, y: 14, w: 11, h: 11, fill: CodableColor(hex: "#FEBC2E"), corner: 0, name: "Min Dot"),
            shape(.circle, x: 50, y: 14, w: 11, h: 11, fill: CodableColor(hex: "#28C840"), corner: 0, name: "Max Dot"),
            shape(.pill, x: 76, y: 9, w: 320, h: 22, fill: .white, corner: 0, name: "URL Pill",
                  stroke: StrokeStyle(isEnabled: true, color: CodableColor(hex: "#D6D3D1"), lineWidth: 1)),
            label("https://localhost:3000", x: 92, y: 13, w: 290, h: 16, size: 11, weight: 500,
                  color: slate, name: "URL Text"),
        ]
    }

    /// One rack unit: dark chassis, slot lines, status LED.
    public static func serverUnit() -> [CanvasElement] {
        [
            shape(.roundedRectangle, x: 0, y: 0, w: 260, h: 64, fill: slate, corner: 8, name: "Server Unit"),
            shape(.roundedRectangle, x: 14, y: 16, w: 150, h: 8, fill: CodableColor(hex: "#475569"), corner: 4, name: "Slot 1"),
            shape(.roundedRectangle, x: 14, y: 30, w: 150, h: 8, fill: CodableColor(hex: "#475569"), corner: 4, name: "Slot 2"),
            shape(.roundedRectangle, x: 14, y: 44, w: 90, h: 6, fill: CodableColor(hex: "#64748B"), corner: 3, name: "Label Slot"),
            shape(.circle, x: 228, y: 24, w: 12, h: 12, fill: green, corner: 0, name: "Status LED"),
        ]
    }

    /// shields.io-style two-tone status badge ("build | passing").
    public static func statusBadge(left: String = "build", right: String = "passing", rightColor: CodableColor = CodableColor(hex: "#10B981")) -> [CanvasElement] {
        [
            shape(.roundedRectangle, x: 0, y: 0, w: 148, h: 28, fill: CodableColor(hex: "#555555"), corner: 5, name: "Badge Base"),
            shape(.roundedRectangle, x: 62, y: 0, w: 86, h: 28, fill: rightColor, corner: 5, name: "Badge Value"),
            shape(.rectangle, x: 62, y: 0, w: 8, h: 28, fill: rightColor, corner: 0, name: "Badge Seam"),
            label(left, x: 0, y: 6, w: 62, h: 16, size: 11, weight: 700, color: .white, align: .center, name: "Badge Key"),
            label(right, x: 62, y: 6, w: 86, h: 16, size: 11, weight: 700, color: .white, align: .center, name: "Badge Label"),
        ]
    }

    /// API endpoint chip: colored method pill + monospaced path.
    public static func apiChip(method: String = "GET", path: String = "/api/v1/users") -> [CanvasElement] {
        let methodColor: CodableColor
        switch method.uppercased() {
        case "POST": methodColor = amber
        case "PUT", "PATCH": methodColor = blue
        case "DELETE": methodColor = red
        default: methodColor = green
        }
        let mw: Double = method.count > 4 ? 84 : 62
        return [
            shape(.roundedRectangle, x: 0, y: 0, w: mw + 250, h: 34, fill: CodableColor(hex: "#0F172A"), corner: 8, name: "API Chip"),
            shape(.roundedRectangle, x: 5, y: 5, w: mw - 10, h: 24, fill: methodColor, corner: 5, name: "Method"),
            label(method.uppercased(), x: 5, y: 10, w: mw - 10, h: 14, size: 10, weight: 800, color: .white, align: .center, name: "Method Label"),
            label(path, x: mw + 8, y: 9, w: 240, h: 16, size: 12, weight: 600, color: CodableColor(hex: "#E2E8F0"), name: "Path"),
        ]
    }

    /// Keyboard keycap: ⌘ K style.
    public static func keyCap(_ glyph: String = "⌘") -> [CanvasElement] {
        [
            shape(.roundedRectangle, x: 0, y: 3, w: 44, h: 44, fill: CodableColor(hex: "#D6D3D1"), corner: 9, name: "Keycap Shadow"),
            shape(.roundedRectangle, x: 0, y: 0, w: 44, h: 44, fill: paper, corner: 9, name: "Keycap",
                  stroke: StrokeStyle(isEnabled: true, color: CodableColor(hex: "#A8A29E"), lineWidth: 1)),
            label(glyph, x: 0, y: 11, w: 44, h: 22, size: 17, weight: 700, color: ink, align: .center, name: "Glyph"),
        ]
    }

    /// TODO sticky note, engineer yellow.
    public static func todoSticky() -> [CanvasElement] {
        [CanvasElement(
            name: "TODO Sticky",
            payload: .text(TextContent(
                text: "TODO:\n", fontFamily: "Indie Flower", fontSize: 16, fontWeight: 700,
                alignment: .left, textColor: CodableColor(hex: "#854D0E"), lineSpacing: 4,
                cardBackground: CodableColor(hex: "#FEF08A"), cardBorderColor: CodableColor(hex: "#FDE047"),
                cardBorderWidth: 1, cardCornerRadius: 10, cardPadding: 16
            )),
            x: 0, y: 0, width: 220, height: 200, shadow: .subtle, zIndex: 0
        )]
    }

    // MARK: - Diagram stamps

    /// Client → API Server → Database request flow with labeled arrows.
    public static func requestFlowDiagram() -> [CanvasElement] {
        var els: [CanvasElement] = []
        // Nodes
        els.append(shape(.pill, x: 0, y: 30, w: 140, h: 56, fill: blue, corner: 0, name: "Client"))
        els.append(label("Client", x: 0, y: 48, w: 140, h: 20, size: 14, weight: 700, color: .white, align: .center, family: "Helvetica Neue", name: "Client Label"))
        els.append(shape(.roundedRectangle, x: 240, y: 16, w: 160, h: 84, fill: slate, corner: 10, name: "API Server"))
        els.append(label("API Server", x: 240, y: 44, w: 160, h: 22, size: 15, weight: 700, color: .white, align: .center, family: "Helvetica Neue", name: "Server Label"))
        els.append(shape(.database, x: 500, y: 6, w: 120, h: 104, fill: green, name: "DB",
                         stroke: StrokeStyle(isEnabled: true, color: ink, lineWidth: 1.5)))
        els.append(label("PostgreSQL", x: 480, y: 116, w: 160, h: 18, size: 12, weight: 600, color: slate, align: .center, family: "Helvetica Neue", name: "DB Label"))
        // Arrows
        els.append(shape(.arrow, x: 150, y: 52, w: 80, h: 12, fill: ink, corner: 0, name: "Req Arrow"))
        els.append(shape(.arrow, x: 410, y: 52, w: 80, h: 12, fill: ink, corner: 0, name: "Query Arrow"))
        els.append(label("HTTPS", x: 150, y: 30, w: 80, h: 14, size: 10, weight: 600, color: terracotta, align: .center, name: "HTTPS Label"))
        els.append(label("SQL", x: 410, y: 30, w: 80, h: 14, size: 10, weight: 600, color: terracotta, align: .center, name: "SQL Label"))
        return els
    }

    /// CI/CD pipeline chain: code → build → test → deploy.
    public static func cicdPipeline() -> [CanvasElement] {
        let stages: [(String, CodableColor)] = [
            ("Commit", violet), ("Build", blue), ("Test", amber), ("Deploy", green)
        ]
        var els: [CanvasElement] = []
        var x: Double = 0
        for (i, st) in stages.enumerated() {
            els.append(shape(.roundedRectangle, x: x, y: 0, w: 120, h: 48, fill: st.1, corner: 10, name: "Stage \(st.0)"))
            els.append(label(st.0, x: x, y: 15, w: 120, h: 18, size: 13, weight: 700, color: .white, align: .center, family: "Helvetica Neue", name: "Label \(st.0)"))
            if i < stages.count - 1 {
                els.append(shape(.chevron, x: x + 124, y: 14, w: 26, h: 20, fill: ink, corner: 0, name: "Pipe Chevron"))
            }
            x += 150
        }
        return els
    }

    /// Mini Kanban: three columns with cards.
    public static func kanbanBoard() -> [CanvasElement] {
        let columns: [(String, CodableColor, [String])] = [
            ("TODO", slate, ["Write RFC", "Schema design"]),
            ("DOING", amber, ["Auth flow"]),
            ("DONE", green, ["CI pipeline", "Repo setup"])
        ]
        var els: [CanvasElement] = []
        var x: Double = 0
        for col in columns {
            els.append(shape(.roundedRectangle, x: x, y: 0, w: 190, h: 300, fill: CodableColor(hex: "#F5F5F4"), corner: 10, name: "Col \(col.0)",
                             stroke: StrokeStyle(isEnabled: true, color: CodableColor(hex: "#E7E5E4"), lineWidth: 1)))
            els.append(label(col.0, x: x + 14, y: 12, w: 162, h: 18, size: 12, weight: 800, color: col.1, name: "Col Title \(col.0)"))
            var cy: Double = 44
            for card in col.2 {
                els.append(shape(.roundedRectangle, x: x + 12, y: cy, w: 166, h: 52, fill: .white, corner: 8, name: "Card",
                                 stroke: StrokeStyle(isEnabled: true, color: CodableColor(hex: "#E7E5E4"), lineWidth: 1)))
                els.append(label(card, x: x + 24, y: cy + 16, w: 142, h: 18, size: 11, weight: 600, color: ink, family: "Helvetica Neue", name: "Card Text"))
                cy += 62
            }
            x += 206
        }
        return els
    }

    /// Git flow: main line with commits + a feature branch.
    public static func gitFlow() -> [CanvasElement] {
        var els: [CanvasElement] = []
        // main line
        els.append(line(0, 110, 560, 3, color: slate, name: "Main Line"))
        let commits: [Double] = [20, 140, 260, 440, 540]
        for (i, cx) in commits.enumerated() {
            els.append(shape(.circle, x: cx, y: 102, w: 18, h: 18, fill: i == 4 ? green : blue, corner: 0, name: "Commit",
                             stroke: StrokeStyle(isEnabled: true, color: .white, lineWidth: 2)))
        }
        // feature branch
        els.append(line(152, 44, 220, 3, color: violet, name: "Feature Line"))
        for cx in [170.0, 270.0, 360.0] {
            els.append(shape(.circle, x: cx, y: 36, w: 18, h: 18, fill: violet, corner: 0, name: "Feature Commit",
                             stroke: StrokeStyle(isEnabled: true, color: .white, lineWidth: 2)))
        }
        // branch-off + merge links (simple diagonal arrows)
        els.append(label("main", x: 0, y: 126, w: 60, h: 18, size: 11, weight: 700, color: slate, name: "main tag"))
        els.append(label("feature/auth", x: 170, y: 10, w: 120, h: 18, size: 11, weight: 700, color: violet, name: "branch tag"))
        els.append(label("merge →", x: 430, y: 68, w: 80, h: 18, size: 11, weight: 600, color: green, name: "merge tag"))
        return els
    }
}
