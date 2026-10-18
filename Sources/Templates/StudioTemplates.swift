import Foundation

/// Studio-quality template collection — modern decks, CVs, and documents
/// designed around the principles used by professional studios:
/// restrained palettes, two-typeface systems, strict grids, and one idea per page.
public enum StudioTemplates {

    // MARK: - Element helpers (keeps page definitions readable)

    /// Text element shorthand.
    private static func tx(_ s: String, _ fam: String, _ size: Double, _ weight: Double = 400,
                           align: TextAlignmentKind = .left, _ color: CodableColor,
                           ls: Double = 0, lsp: Double = 0, italic: Bool = false,
                           _ x: Double, _ y: Double, _ w: Double, _ h: Double, _ z: Int) -> CanvasElement {
        CanvasElement(
            name: "Text",
            payload: .text(TextContent(
                text: s, fontFamily: fam, fontSize: size, fontWeight: weight,
                isItalic: italic, alignment: align, textColor: color,
                letterSpacing: ls, lineSpacing: lsp
            )),
            x: x, y: y, width: w, height: h, zIndex: z
        )
    }

    /// Filled/stroked shape shorthand.
    private static func bx(_ x: Double, _ y: Double, _ w: Double, _ h: Double,
                           _ fill: CodableColor, corner: Double = 0,
                           line: CodableColor? = nil, lw: Double = 1,
                           kind: ShapeKind = .rectangle, z: Int, opacity: Double = 1) -> CanvasElement {
        CanvasElement(
            name: "Shape",
            payload: .shape(ShapeContent(
                kind: kind, cornerRadius: corner,
                fill: .solid(fill),
                stroke: StrokeStyle(isEnabled: line != nil, color: line ?? .clear, lineWidth: lw)
            )),
            x: x, y: y, width: w, height: h, opacity: opacity, zIndex: z
        )
    }

    /// Pattern-filled shape shorthand (halftone, stripes, grid).
    private static func pat(_ x: Double, _ y: Double, _ w: Double, _ h: Double,
                            base: CodableColor, ink: CodableColor, style: PatternStyle,
                            scale: Double = 24, kind: ShapeKind = .rectangle,
                            z: Int, opacity: Double = 1) -> CanvasElement {
        CanvasElement(
            name: "Pattern",
            payload: .shape(ShapeContent(
                kind: kind, cornerRadius: 0,
                fill: FillStyle(type: .pattern, solidColor: base, patternStyle: style, patternScale: scale, patternColor: ink),
                stroke: StrokeStyle()
            )),
            x: x, y: y, width: w, height: h, opacity: opacity, zIndex: z
        )
    }

    /// SF Symbol icon shorthand.
    private static func ic(_ name: String, _ color: CodableColor,
                           _ x: Double, _ y: Double, _ w: Double, _ h: Double, _ z: Int) -> CanvasElement {
        CanvasElement(
            name: "Icon",
            payload: .icon(IconContent(symbolName: name, primaryColor: color)),
            x: x, y: y, width: w, height: h, zIndex: z
        )
    }

    // ======================================================================
    // MARK: - 1. MERIDIAN KEYNOTE — dark product launch deck (5 slides)
    // Design: near-black field, one electric indigo accent, Avenir Next
    // display type, centered keynote compositions, single idea per slide.
    // ======================================================================

    private enum M {
        static let bg = CodableColor(hex: "#0B0B10")
        static let panel = CodableColor(hex: "#15151D")
        static let border = CodableColor(hex: "#26262F")
        static let ink = CodableColor(hex: "#F4F4F7")
        static let sub = CodableColor(hex: "#9B9BA6")
        static let accent = CodableColor(hex: "#6366F1")
        static let accentSoft = CodableColor(hex: "#A5B4FC")
        static let display = "Avenir Next"
        static let body = "Inter"
    }

    public static func createMeridianKeynoteTemplate() -> CanvasTemplate {
        // --- Slide 1: Cover ---
        let s1 = CanvasPage(
            name: "Cover", width: 1920, height: 1080,
            background: .solid(M.bg),
            elements: [
                pat(1260, -280, 780, 780, base: CodableColor(hex: "#101018"), ink: CodableColor(hex: "#37377F"), style: .halftoneFade, scale: 26, kind: .circle, z: 0, opacity: 0.55),
                tx("MERIDIAN — SPRING KEYNOTE 2026", M.body, 15, 700, align: .center, M.accentSoft, ls: 4, 0, 268, 1920, 24, 2),
                tx("Design at the\nSpeed of Thought", M.display, 100, 600, align: .center, M.ink, ls: -2, lsp: 6, 160, 300, 1600, 300, 3),
                bx(860, 640, 200, 6, M.accent, corner: 3, z: 4),
                tx("One canvas for every craft — type, paint, code, and ship.", M.body, 22, 400, align: .center, M.sub, 0, 680, 1920, 34, 4),
                bx(120, 952, 1680, 1, M.border, z: 4),
                tx("March 20 · SF Design Week", M.body, 14, 500, M.sub, 120, 976, 600, 22, 4),
                tx("meridian.app", M.body, 14, 600, align: .right, M.accentSoft, 1200, 976, 600, 22, 4)
            ]
        )

        // --- Slide 2: Hero stat ---
        let s2 = CanvasPage(
            name: "Traction", width: 1920, height: 1080,
            background: .solid(M.bg),
            elements: [
                tx("TRACTION", M.body, 14, 700, M.accent, ls: 4, 160, 150, 400, 22, 1),
                bx(160, 186, 56, 2, M.accent, z: 1),
                tx("3.2×", M.display, 230, 700, align: .center, M.ink, ls: -6, 0, 300, 1920, 280, 2),
                tx("faster from first idea to shipped asset", M.body, 24, 400, align: .center, M.sub, 0, 610, 1920, 34, 2),
                bx(360, 700, 1200, 1, M.border, z: 2),
                tx("40 ms", M.display, 46, 600, align: .center, M.ink, 360, 760, 400, 60, 2),
                tx("median export time", M.body, 15, 400, align: .center, M.sub, 360, 830, 400, 24, 2),
                tx("0", M.display, 46, 600, align: .center, M.ink, 760, 760, 400, 60, 2),
                tx("plugins required", M.body, 15, 400, align: .center, M.sub, 760, 830, 400, 24, 2),
                tx("120 fps", M.display, 46, 600, align: .center, M.ink, 1160, 760, 400, 60, 2),
                tx("canvas at full load", M.body, 15, 400, align: .center, M.sub, 1160, 830, 400, 24, 2)
            ]
        )

        // --- Slide 3: Feature trio ---
        func featCard(_ x: Double, icon: String, title: String, desc: String) -> [CanvasElement] {
            [
                bx(x, 360, 420, 520, M.panel, corner: 20, line: M.border, lw: 1, kind: .roundedRectangle, z: 1),
                bx(x + 36, 400, 64, 64, M.accent, corner: 16, kind: .roundedRectangle, z: 2),
                ic(icon, .white, x + 52, 416, 32, 32, 3),
                tx(title, M.display, 23, 600, M.ink, x + 36, 500, 348, 34, 3),
                tx(desc, M.body, 16, 400, M.sub, x + 36, 546, 348, 150, 3),
                tx("Learn more →", M.body, 14, 600, M.accentSoft, x + 36, 806, 200, 22, 3)
            ]
        }
        var s3els: [CanvasElement] = [
            tx("WHAT'S NEW", M.body, 14, 700, M.accent, ls: 4, 160, 140, 400, 22, 1),
            bx(160, 176, 56, 2, M.accent, z: 1),
            tx("Built for the craft.", M.display, 56, 600, M.ink, ls: -1, 160, 206, 900, 74, 2),
            tx("Three primitives. Infinite outcomes.", M.body, 20, 400, M.sub, 160, 288, 700, 30, 2)
        ]
        s3els += featCard(160, icon: "paintpalette.fill", title: "Procedural Fills",
                          desc: "Halftones, crosshatch, and grain rendered natively — no assets, infinite resolution.")
        s3els += featCard(750, icon: "bolt.fill", title: "Zero-Latency Canvas",
                          desc: "Every interaction lands inside the frame budget, even with ten thousand elements.")
        s3els += featCard(1340, icon: "square.grid.2x2.fill", title: "Layout Intelligence",
                          desc: "A constraint engine that keeps every composition aligned while you iterate.")
        let s3 = CanvasPage(name: "Features", width: 1920, height: 1080, background: .solid(M.bg), elements: s3els)

        // --- Slide 4: Quote divider ---
        let s4 = CanvasPage(
            name: "Quote", width: 1920, height: 1080,
            background: .solid(M.bg),
            elements: [
                bx(930, 300, 60, 6, M.accent, corner: 3, z: 1),
                tx("“The rare tool that respects\nboth craft and speed.”", "Playfair Display", 58, 500, align: .center, M.ink, lsp: 10, italic: true, 260, 340, 1400, 200, 2),
                tx("— THE INTERFACE REVIEW", M.body, 15, 700, align: .center, M.accentSoft, ls: 3, 0, 620, 1920, 24, 2),
                tx("Issue 41 · February 2026", M.body, 13, 400, align: .center, M.sub, 0, 656, 1920, 20, 2)
            ]
        )

        // --- Slide 5: Call to action ---
        let s5 = CanvasPage(
            name: "CTA", width: 1920, height: 1080,
            background: .solid(M.bg),
            elements: [
                pat(-300, 640, 720, 720, base: CodableColor(hex: "#101018"), ink: CodableColor(hex: "#37377F"), style: .halftoneFade, scale: 26, kind: .circle, z: 0, opacity: 0.45),
                tx("See it in motion.", M.display, 78, 600, align: .center, M.ink, ls: -1, 0, 330, 1920, 100, 2),
                tx("Free for 30 days. No card, no catch.", M.body, 20, 400, align: .center, M.sub, 0, 452, 1920, 30, 2),
                bx(800, 530, 320, 80, M.accent, corner: 40, kind: .roundedRectangle, z: 2),
                tx("Try Meridian free", M.body, 18, 700, align: .center, .white, 800, 556, 320, 30, 3),
                bx(120, 952, 1680, 1, M.border, z: 2),
                tx("© 2026 Meridian Labs", M.body, 13, 400, M.sub, 120, 976, 500, 20, 3),
                tx("Designed in California", M.body, 13, 400, align: .right, M.sub, 1300, 976, 500, 20, 3)
            ]
        )

        return CanvasTemplate(
            id: "meridian_keynote",
            title: "Meridian Launch Keynote (5 Slides)",
            category: "Presentations & Screens",
            docType: .presentation,
            themeName: "Dark Keynote",
            preset: CanvasPreset.presets[7],
            pages: [s1, s2, s3, s4, s5],
            previewColorHex: "#0B0B10"
        )
    }

    // ======================================================================
    // MARK: - 2. GRID ZÜRICH — Swiss International Style deck (5 slides)
    // Design: pure white, Helvetica Neue only, black + signal red,
    // hairline rules, numbered index — Müller-Brockmann discipline.
    // ======================================================================

    private enum Z {
        static let paper = CodableColor(hex: "#FCFCFA")
        static let black = CodableColor(hex: "#141414")
        static let red = CodableColor(hex: "#E2001A")
        static let gray = CodableColor(hex: "#6E6E6E")
        static let hair = CodableColor(hex: "#D8D8D2")
        static let tint = CodableColor(hex: "#F1F1EC")
        static let helv = "Helvetica Neue"
    }

    public static func createGridZurichTemplate() -> CanvasTemplate {
        // --- Slide 1: Cover ---
        let s1 = CanvasPage(
            name: "Cover", width: 1920, height: 1080,
            background: .solid(Z.paper),
            elements: [
                tx("01", Z.helv, 28, 800, Z.black, 120, 96, 200, 40, 1),
                tx("TYPOGRAPHY LECTURE SERIES", Z.helv, 14, 700, align: .right, Z.black, ls: 3, 1300, 106, 500, 22, 1),
                bx(120, 158, 1680, 2, Z.black, z: 1),
                bx(120, 560, 28, 28, Z.red, z: 1),
                tx("SWISS GRID\nSYSTEMS", Z.helv, 108, 800, Z.black, ls: -3, lsp: 4, 120, 630, 1300, 290, 2),
                tx("A systematic approach to composition — Basel, 1957", Z.helv, 16, 400, Z.gray, 120, 960, 800, 24, 2),
                tx("EST. 1957", Z.helv, 14, 700, align: .right, Z.red, ls: 3, 1500, 960, 300, 22, 2)
            ]
        )

        // --- Slide 2: Index ---
        var s2els: [CanvasElement] = [
            tx("CONTENTS", Z.helv, 14, 700, Z.red, ls: 4, 160, 120, 400, 22, 1),
            bx(160, 156, 56, 2, Z.red, z: 1)
        ]
        let topics = ["The Grid", "Typography as Picture", "Whitespace as Material", "Hierarchy & Rhythm"]
        let tags = ["STRUCTURE", "FORM", "SPACE", "ORDER"]
        for (i, t) in topics.enumerated() {
            let y = 260.0 + Double(i) * 175
            s2els.append(tx("0\(i + 1)", Z.helv, 26, 800, Z.red, 160, y, 100, 40, 2))
            s2els.append(tx(t, Z.helv, 42, 700, Z.black, ls: -1, 300, y - 6, 1050, 56, 2))
            s2els.append(tx(tags[i], Z.helv, 14, 700, align: .right, Z.gray, ls: 3, 1400, y + 8, 400, 22, 2))
            s2els.append(bx(160, y + 92, 1640, 1, Z.hair, z: 1))
        }
        let s2 = CanvasPage(name: "Index", width: 1920, height: 1080, background: .solid(Z.paper), elements: s2els)

        // --- Slide 3: Content two-column ---
        let s3 = CanvasPage(
            name: "Typography", width: 1920, height: 1080,
            background: .solid(Z.paper),
            elements: [
                tx("02", Z.helv, 22, 800, Z.red, 160, 150, 100, 32, 1),
                tx("TYPOGRAPHY", Z.helv, 14, 700, Z.black, ls: 3, 160, 190, 240, 22, 1),
                bx(160, 224, 56, 2, Z.black, z: 1),
                tx("Type is the picture.", Z.helv, 50, 800, Z.black, ls: -1, 480, 150, 900, 66, 2),
                tx("When the grid is honest, typography carries the entire image. Nothing needs to decorate what is already clear. Size, weight, and position are enough.", Z.helv, 19, 400, Z.gray, lsp: 8, 480, 240, 740, 160, 2),
                bx(480, 500, 660, 380, Z.tint, z: 1),
                tx("Aa", Z.helv, 150, 700, align: .center, Z.black, 480, 590, 660, 200, 2),
                tx("Helvetica, 1957", Z.helv, 14, 400, align: .center, Z.gray, 480, 810, 660, 22, 2),
                tx("NOTE — The specimen above is set at 150 pt on a 6 pt baseline grid. Observe the negative space doing the work.", Z.helv, 14, 400, Z.gray, lsp: 7, 1240, 500, 420, 200, 2),
                bx(1240, 760, 420, 1, Z.hair, z: 1),
                tx("READ MORE — Müller-Brockmann, Grid Systems, 1981", Z.helv, 12, 700, Z.red, ls: 2, 1240, 790, 420, 20, 2)
            ]
        )

        // --- Slide 4: Numbers ---
        var s4els: [CanvasElement] = [
            tx("03 — FACTS", Z.helv, 14, 700, Z.red, ls: 4, 160, 120, 400, 22, 1),
            bx(160, 156, 56, 2, Z.red, z: 1),
            tx("Structure in numbers", Z.helv, 50, 800, Z.black, ls: -1, 160, 190, 1000, 66, 2)
        ]
        let stats: [(String, String, String)] = [
            ("6 pt", "BASELINE GRID", "Every measure on this deck resolves to a six-point vertical rhythm."),
            ("1 : 1.618", "GOLDEN RATIO", "Column widths follow the golden section — 1,040 pt to 640 pt."),
            ("1957", "YEAR OF HELVETICA", "Neue Haas Grotesk, later Helvetica — the voice of the movement.")
        ]
        for (i, s) in stats.enumerated() {
            let x = 160.0 + Double(i) * 560
            s4els.append(bx(x, 400, 480, 8, Z.red, z: 1))
            s4els.append(tx(s.0, Z.helv, 84, 800, Z.black, ls: -2, x, 450, 480, 110, 2))
            s4els.append(tx(s.1, Z.helv, 15, 700, Z.black, ls: 3, x, 590, 480, 24, 2))
            s4els.append(tx(s.2, Z.helv, 15, 400, Z.gray, lsp: 6, x, 630, 440, 110, 2))
        }
        s4els.append(bx(160, 900, 1640, 1, Z.hair, z: 1))
        s4els.append(tx("SOURCE — Grid Systems in Graphic Design", Z.helv, 12, 400, Z.gray, ls: 2, 160, 930, 800, 20, 1))
        let s4 = CanvasPage(name: "Facts", width: 1920, height: 1080, background: .solid(Z.paper), elements: s4els)

        // --- Slide 5: Closing ---
        let s5 = CanvasPage(
            name: "Close", width: 1920, height: 1080,
            background: .solid(Z.paper),
            elements: [
                tx("04", Z.helv, 28, 800, Z.black, 120, 96, 200, 40, 1),
                bx(120, 158, 1680, 2, Z.black, z: 1),
                tx("MERCI.", Z.helv, 150, 800, Z.black, ls: -3, 120, 400, 1200, 200, 2),
                bx(660, 530, 34, 34, Z.red, z: 2),
                tx("Questions — studio@gridzuerich.ch", Z.helv, 20, 400, Z.gray, 120, 700, 800, 30, 2),
                tx("TYPOGRAPHY LECTURE SERIES — 04 / 04", Z.helv, 13, 700, Z.gray, ls: 3, 120, 960, 800, 20, 2)
            ]
        )

        return CanvasTemplate(
            id: "grid_zurich",
            title: "Swiss Grid Lecture (5 Slides)",
            category: "Presentations & Screens",
            docType: .presentation,
            themeName: "Swiss Minimal",
            preset: CanvasPreset.presets[7],
            pages: [s1, s2, s3, s4, s5],
            previewColorHex: "#E2001A"
        )
    }

    // ======================================================================
    // MARK: - 3. NORTHWIND PITCH — investor deck (5 slides)
    // Design: warm off-white, Inter with weight contrast, one indigo accent,
    // card-based layouts — the Sequoia/Arc narrative arc.
    // ======================================================================

    private enum P {
        static let bg = CodableColor(hex: "#FBFBF8")
        static let ink = CodableColor(hex: "#0F172A")
        static let sub = CodableColor(hex: "#64748B")
        static let accent = CodableColor(hex: "#4F46E5")
        static let accentSoft = CodableColor(hex: "#EEF0FF")
        static let border = CodableColor(hex: "#E5E8F0")
        static let green = CodableColor(hex: "#059669")
        static let barTint = CodableColor(hex: "#C7D2FE")
        static let font = "Inter"
    }

    public static func createFounderPitchTemplate() -> CanvasTemplate {
        // --- Slide 1: Cover ---
        let s1 = CanvasPage(
            name: "Cover", width: 1920, height: 1080,
            background: .solid(P.bg),
            elements: [
                pat(1240, 160, 520, 520, base: CodableColor(hex: "#F3F4FF"), ink: P.barTint, style: .dots, scale: 34, z: 0),
                bx(120, 108, 52, 52, P.accent, corner: 14, kind: .roundedRectangle, z: 1),
                tx("N", P.font, 26, 800, align: .center, .white, 120, 120, 52, 32, 2),
                tx("NORTHWIND", P.font, 20, 800, P.ink, ls: 2, 190, 124, 400, 30, 2),
                tx("SERIES A — MARCH 2026", P.font, 13, 700, P.accent, ls: 4, 120, 320, 500, 20, 1),
                tx("The operating system\nfor field teams.", P.font, 76, 800, P.ink, ls: -2, lsp: 6, 120, 362, 1100, 210, 2),
                tx("Northwind gives 40,000 field crews real-time schedules, documents, and sign-off — offline-first, on any device.", P.font, 21, 400, P.sub, lsp: 7, 120, 600, 980, 100, 2),
                bx(120, 940, 1680, 1, P.border, z: 1),
                tx("northwind.co", P.font, 14, 600, P.ink, 120, 964, 400, 22, 2),
                tx("PRIVATE & CONFIDENTIAL", P.font, 12, 700, align: .right, P.sub, ls: 3, 1400, 966, 400, 20, 2)
            ]
        )

        // --- Slide 2: Problem ---
        func painCard(_ x: Double, icon: String, stat: String, desc: String) -> [CanvasElement] {
            [
                bx(x, 390, 480, 460, .white, corner: 16, line: P.border, lw: 1, kind: .roundedRectangle, z: 1),
                bx(x + 40, 430, 60, 60, P.accentSoft, corner: 14, kind: .roundedRectangle, z: 2),
                ic(icon, P.accent, x + 55, 445, 30, 30, 3),
                tx(stat, P.font, 34, 800, P.ink, ls: -1, x + 40, 530, 400, 46, 3),
                tx(desc, P.font, 16, 400, P.sub, lsp: 6, x + 40, 596, 400, 130, 3)
            ]
        }
        var s2els: [CanvasElement] = [
            tx("THE PROBLEM", P.font, 13, 700, P.accent, ls: 4, 120, 110, 500, 20, 1),
            tx("Field work still runs on paper.", P.font, 52, 800, P.ink, ls: -1, 120, 158, 1200, 68, 2),
            tx("And the cost shows up in every project review.", P.font, 20, 400, P.sub, 120, 240, 900, 30, 2)
        ]
        s2els += painCard(120, icon: "clock.fill", stat: "6 hrs lost / week",
                          desc: "Crews re-enter the same data at the site trailer after every shift.")
        s2els += painCard(720, icon: "doc.on.doc.fill", stat: "3 systems patched",
                          desc: "Schedules in one tool, documents in another, sign-off still on paper.")
        s2els += painCard(1320, icon: "exclamationmark.triangle.fill", stat: "$4,200 / rework",
                          desc: "Stale drawings cause one rework cycle per project, on average.")
        let s2 = CanvasPage(name: "Problem", width: 1920, height: 1080, background: .solid(P.bg), elements: s2els)

        // --- Slide 3: Solution ---
        func bullet(_ y: Double, _ title: String, _ desc: String) -> [CanvasElement] {
            [
                ic("checkmark.circle.fill", P.accent, 120, y, 28, 28, 2),
                tx(title, P.font, 20, 700, P.ink, 166, y - 2, 700, 28, 2),
                tx(desc, P.font, 15, 400, P.sub, 166, y + 30, 700, 50, 2)
            ]
        }
        var s3els: [CanvasElement] = [
            tx("THE SOLUTION", P.font, 13, 700, P.accent, ls: 4, 120, 110, 500, 20, 1),
            tx("One app for the whole site.", P.font, 52, 800, P.ink, ls: -1, 120, 158, 1200, 68, 2)
        ]
        s3els += bullet(400, "Offline-first sync", "Everything works in a dead zone; sync resolves when signal returns.")
        s3els += bullet(530, "Live schedules & documents", "One source of truth — the trailer and the field see the same revision.")
        s3els += bullet(660, "Digital sign-off trail", "Time-stamped approvals that satisfy auditors without a filing cabinet.")
        // Abstract product mock (dark device card)
        s3els += [
            bx(1030, 240, 770, 640, CodableColor(hex: "#0F172A"), corner: 28, kind: .roundedRectangle, z: 1),
            bx(1062, 280, 706, 56, CodableColor(hex: "#1E293B"), corner: 12, kind: .roundedRectangle, z: 2),
            bx(1084, 300, 120, 16, CodableColor(hex: "#475569"), corner: 8, kind: .roundedRectangle, z: 3),
            bx(1062, 360, 180, 470, CodableColor(hex: "#1E293B"), corner: 12, kind: .roundedRectangle, z: 2),
            bx(1270, 360, 498, 140, CodableColor(hex: "#1E293B"), corner: 12, kind: .roundedRectangle, z: 2),
            bx(1292, 388, 200, 18, CodableColor(hex: "#94A3B8"), corner: 9, kind: .roundedRectangle, z: 3),
            bx(1292, 424, 320, 12, CodableColor(hex: "#475569"), corner: 6, kind: .roundedRectangle, z: 3),
            bx(1292, 448, 260, 12, CodableColor(hex: "#475569"), corner: 6, kind: .roundedRectangle, z: 3),
            bx(1270, 524, 240, 140, CodableColor(hex: "#1E293B"), corner: 12, kind: .roundedRectangle, z: 2),
            bx(1528, 524, 240, 140, CodableColor(hex: "#1E293B"), corner: 12, kind: .roundedRectangle, z: 2),
            bx(1270, 688, 498, 142, CodableColor(hex: "#1E293B"), corner: 12, kind: .roundedRectangle, z: 2),
            bx(1552, 756, 190, 52, P.accent, corner: 12, kind: .roundedRectangle, z: 3),
            tx("Approve", P.font, 15, 700, align: .center, .white, 1552, 770, 190, 24, 4)
        ]
        let s3 = CanvasPage(name: "Solution", width: 1920, height: 1080, background: .solid(P.bg), elements: s3els)

        // --- Slide 4: Traction ---
        func kpiTile(_ x: Double, _ value: String, _ label: String, _ delta: String) -> [CanvasElement] {
            [
                bx(x, 380, 480, 240, .white, corner: 16, line: P.border, lw: 1, kind: .roundedRectangle, z: 1),
                tx(label, P.font, 14, 700, P.sub, ls: 2, x + 40, 420, 400, 22, 2),
                tx(value, P.font, 56, 800, P.ink, ls: -2, x + 40, 456, 400, 72, 2),
                tx(delta, P.font, 14, 600, P.green, x + 40, 552, 400, 22, 2)
            ]
        }
        var s4els: [CanvasElement] = [
            tx("TRACTION", P.font, 13, 700, P.accent, ls: 4, 120, 110, 500, 20, 1),
            tx("Growing with the industry.", P.font, 52, 800, P.ink, ls: -1, 120, 158, 1200, 68, 2)
        ]
        s4els += kpiTile(120, "142%", "REVENUE GROWTH YOY", "▲ 12 pts vs last quarter")
        s4els += kpiTile(720, "$1.2M", "ARR — SIGNED", "▲ $310k this quarter")
        s4els += kpiTile(1320, "38", "ENTERPRISE CREWS", "▲ 9 added this quarter")
        let barHeights: [Double] = [40, 55, 72, 90, 104, 118, 138, 158, 182, 210]
        for (i, h) in barHeights.enumerated() {
            let x = 120.0 + Double(i) * 174
            s4els.append(bx(x, 940 - h, 110, h, i == barHeights.count - 1 ? P.accent : P.barTint, corner: 8, kind: .roundedRectangle, z: 1))
        }
        s4els.append(bx(120, 940, 1680, 1, P.border, z: 1))
        s4els.append(tx("NET NEW ARR BY MONTH — LAST 10 MONTHS", P.font, 12, 600, P.sub, ls: 2, 120, 962, 800, 20, 1))
        let s4 = CanvasPage(name: "Traction", width: 1920, height: 1080, background: .solid(P.bg), elements: s4els)

        // --- Slide 5: The Ask ---
        var s5els: [CanvasElement] = [
            tx("THE ASK", P.font, 13, 700, P.accent, ls: 4, 120, 110, 500, 20, 1),
            tx("Raising $4M to scale.", P.font, 56, 800, P.ink, ls: -1, 120, 158, 1100, 74, 2),
            tx("USE OF FUNDS", P.font, 13, 700, P.sub, ls: 3, 120, 330, 500, 20, 1)
        ]
        let funds: [(String, String, Double)] = [
            ("Engineering", "55%", 0.55), ("Go-to-market", "30%", 0.30), ("Operations", "15%", 0.15)
        ]
        for (i, f) in funds.enumerated() {
            let y = 390.0 + Double(i) * 130
            s5els.append(tx(f.0, P.font, 18, 700, P.ink, 120, y, 400, 26, 2))
            s5els.append(tx(f.1, P.font, 18, 700, align: .right, P.accent, 620, y, 200, 26, 2))
            s5els.append(bx(120, y + 40, 700, 10, P.accentSoft, corner: 5, kind: .roundedRectangle, z: 1))
            s5els.append(bx(120, y + 40, 700 * f.2, 10, P.accent, corner: 5, kind: .roundedRectangle, z: 2))
        }
        s5els += [
            bx(980, 330, 820, 480, P.accentSoft, corner: 24, kind: .roundedRectangle, z: 1),
            tx("Let's talk.", P.font, 38, 800, P.ink, ls: -1, 1040, 390, 600, 52, 2),
            tx("We're opening the round this month and reserving allocation for partners who know the built world.", P.font, 17, 400, P.sub, lsp: 7, 1040, 460, 660, 100, 2),
            bx(1040, 600, 340, 68, P.accent, corner: 34, kind: .roundedRectangle, z: 2),
            tx("founders@northwind.co", P.font, 16, 700, align: .center, .white, 1040, 622, 340, 26, 3),
            tx("We reply within a day.", P.font, 14, 400, P.sub, 1040, 700, 400, 22, 2),
            bx(120, 940, 1680, 1, P.border, z: 1),
            tx("NORTHWIND — SERIES A", P.font, 12, 700, P.sub, ls: 3, 120, 962, 500, 20, 1),
            tx("PRIVATE & CONFIDENTIAL", P.font, 12, 700, align: .right, P.sub, ls: 3, 1400, 962, 400, 20, 1)
        ]
        let s5 = CanvasPage(name: "Ask", width: 1920, height: 1080, background: .solid(P.bg), elements: s5els)

        return CanvasTemplate(
            id: "northwind_pitch",
            title: "Series A Pitch Deck (5 Slides)",
            category: "Presentations & Screens",
            docType: .presentation,
            themeName: "Indigo Startup",
            preset: CanvasPreset.presets[7],
            pages: [s1, s2, s3, s4, s5],
            previewColorHex: "#4F46E5"
        )
    }

    // ======================================================================
    // MARK: - 4. QUARTERLY REVIEW — executive navy deck (4 slides)
    // Design: deep navy + muted gold, Playfair Display headlines over
    // Inter data — boardroom register, not startup register.
    // ======================================================================

    private enum Q {
        static let navy = CodableColor(hex: "#1A2F4F")
        static let deepNavy = CodableColor(hex: "#12233C")
        static let paper = CodableColor(hex: "#FAF8F3")
        static let gold = CodableColor(hex: "#C9A227")
        static let slate = CodableColor(hex: "#51627A")
        static let mist = CodableColor(hex: "#A9B8CC")
        static let line = CodableColor(hex: "#E7E2D6")
        static let serif = "Playfair Display"
        static let sans = "Inter"
    }

    public static func createQuarterlyReviewTemplate() -> CanvasTemplate {
        // --- Slide 1: Cover ---
        let s1 = CanvasPage(
            name: "Cover", width: 1920, height: 1080,
            background: .solid(Q.navy),
            elements: [
                bx(0, 0, 1920, 1080, Q.deepNavy, z: 0, opacity: 0.35),
                bx(120, 140, 80, 3, Q.gold, z: 1),
                tx("QUARTERLY BUSINESS REVIEW", Q.sans, 14, 700, Q.gold, ls: 4, 120, 170, 700, 22, 1),
                tx("Momentum,\nMeasured.", Q.serif, 86, 700, .white, lsp: 8, 120, 380, 1100, 230, 2),
                tx("Q3 FY2026 — Office of the Chief Operating Officer", Q.sans, 18, 400, Q.mist, 120, 660, 900, 28, 2),
                bx(120, 940, 1680, 1, CodableColor(hex: "#2C4568"), z: 1),
                tx("October 14, 2026", Q.sans, 14, 600, Q.gold, 120, 964, 400, 22, 2),
                tx("PRIVATE & CONFIDENTIAL", Q.sans, 12, 700, align: .right, Q.mist, ls: 3, 1400, 966, 400, 20, 2)
            ]
        )

        // --- Slide 2: Agenda ---
        var s2els: [CanvasElement] = [
            tx("AGENDA", Q.sans, 14, 700, Q.gold, ls: 4, 160, 120, 400, 22, 1),
            tx("This quarter, in four parts", Q.serif, 46, 700, Q.navy, 160, 156, 1000, 62, 2)
        ]
        let items = ["Highlights", "Scorecard", "Deep Dive — Retention", "Priorities for Q4"]
        let minutes = ["5 MIN", "10 MIN", "20 MIN", "10 MIN"]
        for (i, t) in items.enumerated() {
            let y = 320.0 + Double(i) * 160
            s2els.append(tx("0\(i + 1)", Q.serif, 30, 700, Q.gold, 160, y, 90, 42, 2))
            s2els.append(tx(t, Q.sans, 34, 700, Q.navy, 280, y, 1100, 48, 2))
            s2els.append(tx(minutes[i], Q.sans, 13, 700, align: .right, Q.slate, ls: 2, 1500, y + 10, 300, 20, 2))
            s2els.append(bx(160, y + 84, 1640, 1, Q.line, z: 1))
        }
        let s2 = CanvasPage(name: "Agenda", width: 1920, height: 1080, background: .solid(Q.paper), elements: s2els)

        // --- Slide 3: Scorecard ---
        func kpiCard(_ x: Double, _ label: String, _ value: String, _ delta: String, up: Bool = true) -> [CanvasElement] {
            [
                bx(x, 330, 405, 290, .white, corner: 14, line: Q.line, lw: 1, kind: .roundedRectangle, z: 1),
                tx(label, Q.sans, 13, 700, Q.slate, ls: 2, x + 36, 372, 340, 20, 2),
                tx(value, Q.sans, 54, 700, Q.navy, ls: -1, x + 36, 410, 340, 72, 2),
                bx(x + 36, 514, 90, 4, up ? Q.gold : Q.slate, z: 2),
                tx(delta, Q.sans, 14, 600, up ? Q.gold : Q.slate, x + 36, 540, 340, 24, 2)
            ]
        }
        var s3els: [CanvasElement] = [
            tx("SCORECARD — Q3", Q.sans, 14, 700, Q.gold, ls: 4, 120, 110, 500, 20, 1),
            tx("Quarter at a glance", Q.serif, 46, 700, Q.navy, 120, 146, 1000, 62, 2)
        ]
        s3els += kpiCard(120, "REVENUE", "$8.4M", "▲ 12% vs Q2")
        s3els += kpiCard(565, "NET REVENUE RETENTION", "118%", "▲ 3 pts")
        s3els += kpiCard(1010, "HEADCOUNT", "214", "▲ 19 this quarter")
        s3els += kpiCard(1455, "MONTHLY BURN", "$310k", "▼ 9% — improving", up: false)
        let qHeights: [Double] = [60, 84, 78, 105, 120, 110, 140, 168]
        for (i, h) in qHeights.enumerated() {
            let x = 160.0 + Double(i) * 214
            s3els.append(bx(x, 900 - h, 130, h, i == qHeights.count - 1 ? Q.gold : Q.navy, corner: 6, kind: .roundedRectangle, z: 1))
        }
        s3els.append(bx(160, 900, 1600, 1, Q.line, z: 1))
        s3els.append(tx("NET NEW ARR BY MONTH ($K)", Q.sans, 12, 600, Q.slate, ls: 2, 160, 922, 800, 20, 1))
        let s3 = CanvasPage(name: "Scorecard", width: 1920, height: 1080, background: .solid(Q.paper), elements: s3els)

        // --- Slide 4: Priorities ---
        func priority(_ y: Double, _ title: String, _ desc: String, _ owner: String) -> [CanvasElement] {
            [
                bx(120, y, 1680, 150, .white, corner: 14, line: Q.line, lw: 1, kind: .roundedRectangle, z: 1),
                bx(170, y + 58, 30, 30, .white, corner: 8, line: Q.gold, lw: 2, kind: .roundedRectangle, z: 2),
                tx(title, Q.sans, 22, 700, Q.navy, 230, y + 30, 900, 32, 2),
                tx(desc, Q.sans, 15, 400, Q.slate, 230, y + 72, 1100, 60, 2),
                bx(1560, y + 52, 190, 46, Q.paper, corner: 23, line: Q.line, lw: 1, kind: .roundedRectangle, z: 2),
                tx(owner, Q.sans, 13, 700, align: .center, Q.navy, 1560, y + 66, 190, 20, 3)
            ]
        }
        var s4els: [CanvasElement] = [
            tx("PRIORITIES — Q4", Q.sans, 14, 700, Q.gold, ls: 4, 120, 110, 500, 20, 1),
            tx("Three commitments", Q.serif, 46, 700, Q.navy, 120, 146, 1000, 62, 2)
        ]
        s4els += priority(300, "Ship the contractor portal",
                          "Self-serve onboarding for the 400 subcontractors joining in Q4.", "P. ANAND — ENG")
        s4els += priority(490, "Close the retention gap",
                          "Bring logo churn under 2.5% with the new success playbook.", "L. MOREAU — CS")
        s4els += priority(680, "Hold burn under $300k",
                          "Efficiency guardrails stay on while hiring resumes in January.", "R. FIELD — FIN")
        s4els.append(tx("Questions → coo@meridian.co", Q.sans, 15, 600, Q.slate, 120, 920, 800, 24, 2))
        let s4 = CanvasPage(name: "Priorities", width: 1920, height: 1080, background: .solid(Q.paper), elements: s4els)

        return CanvasTemplate(
            id: "quarterly_review",
            title: "Quarterly Business Review (4 Slides)",
            category: "Presentations & Screens",
            docType: .presentation,
            themeName: "Executive Navy",
            preset: CanvasPreset.presets[7],
            pages: [s1, s2, s3, s4],
            previewColorHex: "#1A2F4F"
        )
    }

    // ======================================================================
    // MARK: - 5. ZÜRICH CV — Swiss timeline resume (A4)
    // Design: strict two-column grid — right-aligned dates in the rail,
    // black rules, one red accent. Scannable in six seconds.
    // ======================================================================

    public static func createZurichCVTemplate() -> CanvasTemplate {
        let black = CodableColor(hex: "#141414")
        let red = CodableColor(hex: "#E2001A")
        let gray = CodableColor(hex: "#57575F")
        let soft = CodableColor(hex: "#3F3F46")
        let helv = "Helvetica Neue"
        let W: Double = 1240

        // Section header: small-caps label on the rail, rule across the content column.
        func section(_ label: String, _ y: Double) -> [CanvasElement] {
            [
                tx(label, helv, 13, 800, black, ls: 3, 90, y, 160, 20, 1),
                bx(270, y + 8, 880, 1.5, black, z: 1)
            ]
        }
        // Entry: date right-aligned in the rail, role/org/desc in the content column.
        func entry(_ y: Double, _ date: String, _ role: String, _ org: String, _ desc: String) -> [CanvasElement] {
            [
                tx(date, helv, 11.5, 600, align: .right, gray, 90, y + 3, 150, 18, 1),
                tx(role, helv, 14.5, 700, black, 270, y, 500, 22, 2),
                tx(org, helv, 12, 600, red, 270, y + 26, 500, 18, 2),
                tx(desc, helv, 11.5, 400, soft, lsp: 4, 270, y + 52, 880, 60, 2)
            ]
        }

        var els: [CanvasElement] = [
            bx(90, 88, 22, 22, red, z: 1),
            tx("JONAS WEBER", helv, 42, 800, black, ls: -1, 90, 126, 700, 56, 2),
            tx("SENIOR PRODUCT ENGINEER", helv, 13, 700, red, ls: 3, 90, 192, 600, 20, 2),
            tx("jonas.weber@helvetia.ch\n+41 44 555 01 20\nZürich, Switzerland", helv, 11.5, 400, align: .right, gray, lsp: 5, W - 500, 126, 410, 70, 2),
            bx(90, 250, 1060, 2, black, z: 1)
        ]
        els += section("PROFILE", 310)
        els.append(tx("Product engineer with nine years shipping design-critical software. Led three platform rebuilds; care most about the last five percent that makes software feel inevitable.", helv, 12.5, 400, soft, lsp: 5, 270, 348, 880, 60, 2))
        els += section("EXPERIENCE", 480)
        els += entry(520, "2021 — NOW", "Senior Product Engineer", "Helvetia Systems · Zürich",
                     "Own the editor surface end-to-end. Cut input latency 60%; shipped the layout engine used by 40k teams.")
        els += entry(680, "2017 — 2021", "Software Engineer", "Format AG · Basel",
                     "Built the real-time collaboration layer and the PDF export pipeline from scratch.")
        els += entry(840, "2014 — 2017", "Junior Engineer", "Studio Nord · Bern",
                     "Front-end for three museum microsites; introduced the design-token system still in use.")
        els += section("EDUCATION", 1030)
        els += entry(1070, "2010 — 2014", "BSc Computer Science", "ETH Zürich",
                     "Focus on computer graphics and human-computer interaction.")
        els += section("SKILLS", 1210)
        els.append(tx("Swift · Rust · TypeScript", helv, 12.5, 700, black, 270, 1250, 880, 22, 2))
        els.append(tx("Design systems · Rendering pipelines · Prototyping · Technical writing", helv, 11.5, 400, soft, lsp: 4, 270, 1280, 880, 40, 2))
        els += section("LANGUAGES", 1380)
        els.append(tx("German — native   ·   English — fluent   ·   French — working", helv, 11.5, 400, soft, 270, 1420, 880, 22, 2))
        els.append(bx(90, 1520, 1060, 1, CodableColor(hex: "#D8D8D2"), z: 1))
        els.append(tx("REFERENCES AVAILABLE ON REQUEST", helv, 10, 600, gray, ls: 2, 90, 1542, 600, 16, 1))

        return CanvasTemplate(
            id: "zurich_cv",
            title: "Swiss Grid CV",
            category: "Resumes & CVs",
            docType: .resume,
            themeName: "Swiss Minimal",
            preset: CanvasPreset.presets[10],
            page: CanvasPage(name: "Swiss CV", width: W, height: 1754, background: .solid(.white), elements: els),
            previewColorHex: "#E2001A"
        )
    }

    // ======================================================================
    // MARK: - 6. SCHOLAR CV — academic curriculum vitae (A4)
    // Design: centered masthead, Baskerville throughout, numbered
    // publications, navy accents only on section heads.
    // ======================================================================

    public static func createScholarCVTemplate() -> CanvasTemplate {
        let ink = CodableColor(hex: "#1C1917")
        let navy = CodableColor(hex: "#25405E")
        let gray = CodableColor(hex: "#57534E")
        let hair = CodableColor(hex: "#D6D1C8")
        let serif = "Baskerville"
        let W: Double = 1240

        func head(_ label: String, _ y: Double) -> [CanvasElement] {
            [
                tx(label, serif, 13, 700, navy, ls: 3, 90, y, 300, 20, 1),
                bx(90, y + 30, 1060, 0.75, hair, z: 1)
            ]
        }
        func item(_ y: Double, _ year: String, _ title: String, _ sub: String) -> [CanvasElement] {
            var r: [CanvasElement] = [
                tx(year, serif, 11.5, 600, gray, 90, y + 2, 110, 18, 1),
                tx(title, serif, 13.5, 700, ink, 220, y, 930, 22, 2)
            ]
            if !sub.isEmpty { r.append(tx(sub, serif, 12, 400, gray, italic: true, 220, y + 24, 930, 20, 2)) }
            return r
        }

        var els: [CanvasElement] = [
            tx("DR. ELENA MARCHETTI", serif, 32, 600, align: .center, ink, ls: 1, 0, 90, W, 46, 2),
            tx("CURRICULUM VITAE", serif, 11, 600, align: .center, navy, ls: 5, 0, 148, W, 18, 2),
            tx("Department of Computational Linguistics  ·  e.marchetti@university.edu  ·  ORCID 0000-0002-1825-0097", serif, 11.5, 400, align: .center, gray, 0, 180, W, 18, 2),
            bx(90, 230, 1060, 2, ink, z: 1),
            bx(90, 236, 1060, 0.75, ink, z: 1)
        ]
        els += head("EDUCATION", 290)
        els += item(330, "2014", "Ph.D. Computational Linguistics", "University of Edinburgh — summa cum laude")
        els += item(390, "2009", "M.A. Language Sciences", "Université de Genève")
        els += item(440, "2007", "B.A. Linguistics & Philosophy", "Università di Bologna")
        els += head("APPOINTMENTS", 540)
        els += item(580, "2021—", "Associate Professor", "Department of Computational Linguistics")
        els += item(636, "2017—21", "Assistant Professor", "Department of Computational Linguistics")
        els += item(692, "2014—17", "Postdoctoral Fellow", "Institute for Language, Cognition and Computation")
        els += head("SELECTED PUBLICATIONS", 790)
        let pubs = [
            "Marchetti, E. (2025). “Prosody as Structure: What Speech Rhythm Teaches Language Models.” Journal of Computational Linguistics, 51(2).",
            "Marchetti, E., & Roth, A. (2024). “Evaluation Without Tears: Human Judgment at Scale.” Proceedings of ACL.",
            "Marchetti, E. (2023). “Low-Resource Morphology with Neural Transducers.” Transactions of the ACL, 11.",
            "Marchetti, E. (2021). “A Grammar of Pauses.” Phonology Today, 38(4)."
        ]
        for (i, p) in pubs.enumerated() {
            let y = 830.0 + Double(i) * 64
            els.append(tx("[\(i + 1)]", serif, 12, 600, navy, 90, y, 60, 18, 1))
            els.append(tx(p, serif, 12, 400, ink, lsp: 4, 160, y, 990, 56, 2))
        }
        els += head("HONOURS & GRANTS", 1140)
        els += item(1180, "2025", "Excellence in Research Award", "Faculty of Arts — CHF 40,000")
        els += item(1236, "2022", "Early Career Grant", "Swiss National Science Foundation — CHF 250,000")
        els += item(1292, "2019", "Best Paper Award", "Annual Meeting of the ACL")
        els.append(tx("References, teaching portfolio, and full publication list available on request.", serif, 11, 400, align: .center, gray, italic: true, 0, 1500, W, 18, 2))

        return CanvasTemplate(
            id: "scholar_cv",
            title: "Academic Scholar CV",
            category: "Resumes & CVs",
            docType: .resume,
            themeName: "Academic Serif",
            preset: CanvasPreset.presets[10],
            page: CanvasPage(name: "Scholar CV", width: W, height: 1754, background: .solid(CodableColor(hex: "#FDFCF9")), elements: els),
            previewColorHex: "#25405E"
        )
    }

    // ======================================================================
    // MARK: - 7. STUDIO CV — creative two-column resume (A4)
    // Design: dark slate rail for identity + skills, light content column
    // for experience — the studio-portfolio register, kept readable.
    // ======================================================================

    public static func createStudioCVTemplate() -> CanvasTemplate {
        let rail = CodableColor(hex: "#1E293B")
        let railSoft = CodableColor(hex: "#334155")
        let teal = CodableColor(hex: "#2DD4BF")
        let mist = CodableColor(hex: "#94A3B8")
        let ink = CodableColor(hex: "#111827")
        let slate = CodableColor(hex: "#5B6472")
        let cardBg = CodableColor(hex: "#F1F5F9")
        let cardLine = CodableColor(hex: "#E2E8F0")
        let W: Double = 1240

        var els: [CanvasElement] = [
            // Dark rail
            bx(0, 0, 380, 1754, rail, z: 0),
            bx(115, 80, 150, 150, railSoft, kind: .circle, z: 1),
            tx("AR", "Avenir Next", 44, 700, align: .center, teal, 115, 122, 150, 56, 2),
            tx("AMARA\nREYES", "Avenir Next", 34, 700, .white, ls: 1, lsp: 4, 40, 268, 300, 100, 2),
            tx("Brand & Product Designer", "Inter", 15, 600, teal, 40, 382, 300, 24, 2),

            tx("CONTACT", "Inter", 11, 700, mist, ls: 3, 40, 470, 200, 18, 1),
            ic("envelope.fill", mist, 40, 506, 15, 15, 1),
            tx("amara@reyes.studio", "Inter", 12, 400, .white, 66, 502, 270, 20, 2),
            ic("phone.fill", mist, 40, 536, 15, 15, 1),
            tx("+1 415 555 0134", "Inter", 12, 400, .white, 66, 532, 270, 20, 2),
            ic("globe", mist, 40, 566, 15, 15, 1),
            tx("reyes.studio", "Inter", 12, 400, .white, 66, 562, 270, 20, 2),
            ic("mappin.and.ellipse", mist, 40, 596, 15, 15, 1),
            tx("Oakland, CA", "Inter", 12, 400, .white, 66, 592, 270, 20, 2),

            tx("SKILLS", "Inter", 11, 700, mist, ls: 3, 40, 680, 200, 18, 1)
        ]
        // Skill pills — two per row
        let skills = ["Identity systems", "Art direction", "Motion", "Design ops", "Typography", "Prototyping"]
        for (i, s) in skills.enumerated() {
            let col = i % 2, row = i / 2
            let x = 40.0 + Double(col) * 170, y = 716.0 + Double(row) * 46
            els.append(bx(x, y, 160, 34, railSoft, corner: 17, kind: .roundedRectangle, z: 1))
            els.append(tx(s, "Inter", 10.5, 600, align: .center, .white, x, y + 9, 160, 18, 2))
        }
        els += [
            tx("TOOLS", "Inter", 11, 700, mist, ls: 3, 40, 890, 200, 18, 1),
            tx("Pluma · Figma · After Effects\nBlender · TouchDesigner", "Inter", 12, 400, .white, lsp: 7, 40, 924, 300, 70, 2),
            tx("LANGUAGES", "Inter", 11, 700, mist, ls: 3, 40, 1040, 200, 18, 1),
            tx("English — native\nSpanish — native\nPortuguese — fluent", "Inter", 12, 400, .white, lsp: 7, 40, 1074, 300, 90, 2),
            bx(40, 1250, 300, 1, railSoft, z: 1),
            tx("“Design is the last\ncompetitive advantage.”", "Avenir Next", 17, 500, .white, lsp: 6, italic: true, 40, 1290, 300, 90, 2)
        ]

        // Content column
        func label(_ s: String, _ y: Double) -> [CanvasElement] {
            [
                tx(s, "Inter", 11, 700, teal, ls: 3, 430, y, 300, 18, 1),
                bx(430, y + 26, 770, 1, cardLine, z: 1)
            ]
        }
        func job(_ y: Double, _ role: String, _ org: String, _ date: String, _ desc: String) -> [CanvasElement] {
            [
                tx(role, "Inter", 15, 700, ink, 430, y, 520, 22, 2),
                tx(date, "Inter", 11.5, 600, align: .right, slate, 950, y + 3, 250, 18, 2),
                tx(org, "Inter", 12, 600, teal, 430, y + 26, 520, 18, 2),
                tx(desc, "Inter", 11.5, 400, slate, lsp: 4, 430, y + 50, 770, 60, 2)
            ]
        }
        els += label("PROFILE", 90)
        els.append(tx("Designer of identities and interfaces for cultural institutions and early-stage teams. Ten years, forty launches, zero templates.", "Inter", 12.5, 400, slate, lsp: 5, 430, 132, 770, 60, 2))
        els += label("EXPERIENCE", 250)
        els += job(292, "Design Lead", "Fieldnotes — Series B startup", "2022 — NOW",
                   "Built the brand and product surface in parallel. Led the design system behind a 3× engagement lift.")
        els += job(430, "Senior Designer", "Studio Meridian — design practice", "2018 — 2022",
                   "Identity and digital work for museums, festivals, and two national pavilions.")
        els += job(568, "Designer", "Canto & Co.", "2015 — 2018",
                   "Print-first studio; learned to make systems that survive handoff to other hands.")
        els += label("SELECTED WORK", 720)
        let works: [(String, String)] = [
            ("Biennale identity", "Wayfinding + print system, 2025"),
            ("Fieldnotes rebrand", "Naming through launch, 2024"),
            ("Meridian typeface", "Custom display face, 2023"),
            ("Civic archive", "Digitisation + public interface")
        ]
        for (i, wk) in works.enumerated() {
            let col = i % 2, row = i / 2
            let x = 430.0 + Double(col) * 395, y = 762.0 + Double(row) * 124
            els.append(bx(x, y, 375, 108, cardBg, corner: 12, line: cardLine, lw: 1, kind: .roundedRectangle, z: 1))
            els.append(tx(wk.0, "Inter", 13, 700, ink, x + 22, y + 24, 330, 20, 2))
            els.append(tx(wk.1, "Inter", 11, 400, slate, x + 22, y + 50, 330, 18, 2))
        }
        els += label("EDUCATION", 1030)
        els.append(tx("BFA Communication Design", "Inter", 13.5, 700, ink, 430, 1072, 520, 20, 2))
        els.append(tx("California College of the Arts — 2015", "Inter", 11.5, 400, slate, 430, 1096, 520, 18, 2))

        return CanvasTemplate(
            id: "studio_cv",
            title: "Studio Creative CV",
            category: "Resumes & CVs",
            docType: .resume,
            themeName: "Studio Slate",
            preset: CanvasPreset.presets[10],
            page: CanvasPage(name: "Studio CV", width: W, height: 1754, background: .solid(.white), elements: els),
            previewColorHex: "#1E293B"
        )
    }

    // ======================================================================
    // MARK: - 8. ANNUAL REPORT — corporate 2-page document (A4)
    // Design: navy masthead + gold rule, serif display title, KPI strip,
    // then a letter-style interior page with a data table.
    // ======================================================================

    public static func createAnnualReportTemplate() -> CanvasTemplate {
        let navy = CodableColor(hex: "#1A2F4F")
        let gold = CodableColor(hex: "#C9A227")
        let paper = CodableColor(hex: "#FBFAF7")
        let slate = CodableColor(hex: "#51627A")
        let mist = CodableColor(hex: "#A9B8CC")
        let line = CodableColor(hex: "#E7E2D6")
        let W: Double = 1240

        // Page 1 — cover
        var p1els: [CanvasElement] = [
            bx(0, 0, W, 1020, navy, z: 0),
            bx(100, 150, 70, 3, gold, z: 1),
            tx("MERIDIAN INDUSTRIES", "Inter", 14, 700, gold, ls: 4, 100, 186, 600, 22, 2),
            tx("Annual\nReport", "Playfair Display", 100, 700, .white, lsp: 8, 100, 330, 900, 270, 2),
            tx("FISCAL YEAR 2026", "Inter", 15, 600, mist, ls: 3, 100, 660, 500, 24, 2),
            tx("A year of disciplined growth — audited, annotated, and explained in plain language.", "Inter", 15, 400, mist, lsp: 6, 100, 720, 760, 70, 2),
            bx(100, 900, 1040, 1, CodableColor(hex: "#2C4568"), z: 1),
            tx("ESTABLISHED 1987", "Inter", 11, 700, mist, ls: 3, 100, 928, 400, 18, 2),
            tx("NYSE: MRDI", "Inter", 11, 700, align: .right, gold, ls: 3, 740, 928, 400, 18, 2)
        ]
        let stats: [(String, String)] = [("$8.4B", "REVENUE"), ("118", "MARKETS"), ("21,400", "EMPLOYEES"), ("4.2%", "YIELD")]
        for (i, s) in stats.enumerated() {
            let x = 100.0 + Double(i) * 270
            p1els.append(tx(s.0, "Inter", 34, 800, navy, x, 1120, 240, 46, 2))
            p1els.append(tx(s.1, "Inter", 11, 700, slate, ls: 2, x, 1180, 240, 18, 2))
        }
        p1els.append(bx(100, 1240, 1040, 1, line, z: 1))
        p1els.append(tx("Cover: Meridian Works No. 4, Rotterdam", "Inter", 10.5, 400, slate, italic: true, 100, 1270, 700, 18, 2))
        let p1 = CanvasPage(name: "Cover", width: W, height: 1754, background: .solid(paper), elements: p1els)

        // Page 2 — letter + figures
        var p2els: [CanvasElement] = [
            tx("MERIDIAN INDUSTRIES — FY2026", "Inter", 11, 700, navy, ls: 2, 90, 80, 700, 18, 1),
            tx("02", "Inter", 11, 700, align: .right, gold, 1040, 80, 110, 18, 1),
            bx(90, 116, 1060, 2, gold, z: 1),
            tx("Letter from the CEO", "Playfair Display", 24, 700, navy, 90, 160, 520, 34, 2),
            tx("Shareholders —\n\nThis year we chose boring on purpose. We consolidated three divisions, declined two fashionable acquisitions, and spent the difference on tooling our people actually use.\n\nThe result is the quietest strong year in our history: revenue up twelve percent, attrition down a third, and not a single restructuring charge to explain away.", "Georgia", 12.5, 400, slate, lsp: 6, 90, 214, 520, 400, 2),
            bx(90, 650, 4, 160, gold, z: 1),
            tx("“We would rather be\npredictable than\nfashionable.”", "Playfair Display", 19, 500, navy, lsp: 6, italic: true, 120, 650, 480, 170, 2),
            tx("— M. Okafor, Chief Executive", "Inter", 11, 600, slate, 120, 840, 480, 18, 2),
            tx("Key figures", "Playfair Display", 24, 700, navy, 660, 160, 490, 34, 2)
        ]
        let rows: [(String, String)] = [
            ("Revenue", "$8.4B  ·  ▲ 12%"),
            ("Operating margin", "18.6%"),
            ("Free cash flow", "$1.1B"),
            ("R&D investment", "$640M"),
            ("Dividend / share", "$2.10"),
            ("Net debt / EBITDA", "0.8×")
        ]
        for (i, r) in rows.enumerated() {
            let y = 230.0 + Double(i) * 72
            p2els.append(tx(r.0, "Inter", 13, 400, slate, 660, y, 300, 20, 2))
            p2els.append(tx(r.1, "Inter", 13, 700, align: .right, navy, 860, y, 290, 20, 2))
            p2els.append(bx(660, y + 34, 490, 1, line, z: 1))
        }
        p2els += [
            bx(660, 720, 490, 200, CodableColor(hex: "#F0EDE4"), corner: 10, kind: .roundedRectangle, z: 1),
            tx("FIVE-YEAR VIEW", "Inter", 10, 700, slate, ls: 2, 690, 750, 400, 16, 2),
            tx("Revenue grew every year since 2022 — 9.8% CAGR.", "Inter", 12.5, 400, slate, lsp: 4, 690, 780, 430, 60, 2),
            bx(90, 1560, 1060, 1, line, z: 1),
            tx("© 2026 Meridian Industries — This report contains forward-looking statements.", "Inter", 10, 400, align: .center, slate, 0, 1584, W, 16, 1)
        ]
        let p2 = CanvasPage(name: "Inside", width: W, height: 1754, background: .solid(paper), elements: p2els)

        return CanvasTemplate(
            id: "annual_report",
            title: "Annual Report (2 Pages)",
            category: "Print & Documents",
            docType: .a4,
            themeName: "Executive Navy",
            preset: CanvasPreset.presets[10],
            pages: [p1, p2],
            previewColorHex: "#1A2F4F"
        )
    }

    // ======================================================================
    // MARK: - 9. DESIGN WEEK POSTER — typographic event poster (1200 × 1800)
    // Design: stacked Impact masthead, halftone band, ticket-style footer —
    // classic festival-poster grammar, updated.
    // ======================================================================

    public static func createDesignWeekPosterTemplate() -> CanvasTemplate {
        let paper = CodableColor(hex: "#F2EDE3")
        let black = CodableColor(hex: "#17140F")
        let accent = CodableColor(hex: "#C2410C")
        let gray = CodableColor(hex: "#6B6455")

        let els: [CanvasElement] = [
            tx("OCTOBER 12 — 18", "Inter", 16, 700, black, ls: 4, 80, 80, 500, 22, 1),
            tx("MESSE BASEL · HALL 3", "Inter", 16, 700, align: .right, black, ls: 4, 620, 80, 500, 22, 1),
            bx(80, 130, 1040, 2, black, z: 1),

            tx("DESIGN", "Impact", 175, 400, black, ls: -2, 70, 190, 1100, 220, 2),
            tx("WEEK", "Impact", 175, 400, accent, ls: -2, 70, 390, 1100, 220, 2),

            pat(0, 680, 1200, 400, base: paper, ink: accent, style: .halftoneFade, scale: 22, z: 1, opacity: 0.8),
            tx("TWENTY SPEAKERS  ·  SIX WORKSHOPS  ·  ONE CITY", "Inter", 19, 700, align: .center, black, ls: 3, 0, 850, 1200, 26, 2),

            // Info grid
            tx("DATES", "Inter", 12, 700, gray, ls: 3, 80, 1160, 300, 18, 2),
            tx("Oct 12–18, 2026", "Inter", 21, 700, black, 80, 1188, 340, 28, 2),
            tx("VENUE", "Inter", 12, 700, gray, ls: 3, 450, 1160, 300, 18, 2),
            tx("Messe Basel, Hall 3", "Inter", 21, 700, black, 450, 1188, 340, 28, 2),
            tx("TICKETS", "Inter", 12, 700, gray, ls: 3, 820, 1160, 300, 18, 2),
            tx("designweek.ch", "Inter", 21, 700, black, 820, 1188, 340, 28, 2),
            bx(80, 1270, 1040, 1, gray, z: 2),
            tx("Early-bird until August 31 — students 40% off with valid ID.", "Inter", 14, 400, gray, 80, 1298, 800, 22, 2),

            // Footer ticket bar
            bx(0, 1560, 1200, 240, black, z: 1),
            tx("GET TICKETS — DESIGNWEEK.CH", "Inter", 30, 800, align: .center, paper, ls: 3, 0, 1640, 1200, 40, 2),
            tx("SPONSORED BY THE BASEL DESIGN FOUNDATION", "Inter", 11, 700, align: .center, CodableColor(hex: "#8A8371"), ls: 3, 0, 1700, 1200, 18, 2)
        ]

        return CanvasTemplate(
            id: "design_week_poster",
            title: "Design Week Poster",
            category: "Print & Documents",
            docType: .a4,
            themeName: "Festival Type",
            preset: CanvasPreset.presets[13],
            page: CanvasPage(name: "Poster", width: 1200, height: 1800, background: .solid(paper), elements: els),
            previewColorHex: "#C2410C"
        )
    }

    // ======================================================================
    // MARK: - 10. NIMBUS DROP — product launch post (1080 × 1080)
    // Design: dark slate field, single orange accent, abstract product card.
    // ======================================================================

    public static func createProductDropTemplate() -> CanvasTemplate {
        let bg = CodableColor(hex: "#0F172A")
        let card = CodableColor(hex: "#1E293B")
        let cardSoft = CodableColor(hex: "#334155")
        let accent = CodableColor(hex: "#F97316")
        let mist = CodableColor(hex: "#94A3B8")

        let els: [CanvasElement] = [
            pat(700, -180, 560, 560, base: CodableColor(hex: "#151F33"), ink: CodableColor(hex: "#7C3AED"), style: .halftoneFade, scale: 20, kind: .circle, z: 0, opacity: 0.5),
            bx(80, 80, 160, 42, accent, corner: 21, kind: .roundedRectangle, z: 1),
            tx("NEW DROP", "Inter", 13, 800, align: .center, .white, ls: 2, 80, 92, 160, 20, 2),
            tx("10.24", "Inter", 14, 600, align: .right, mist, 880, 92, 120, 20, 1),

            // Abstract product card
            bx(280, 230, 520, 480, card, corner: 32, kind: .roundedRectangle, z: 1),
            bx(330, 290, 190, 190, cardSoft, corner: 24, kind: .roundedRectangle, z: 2),
            ic("backpack.fill", accent, 375, 335, 100, 100, 3),
            bx(550, 300, 200, 20, cardSoft, corner: 10, kind: .roundedRectangle, z: 2),
            bx(550, 336, 140, 20, cardSoft, corner: 10, kind: .roundedRectangle, z: 2),
            bx(330, 540, 420, 14, cardSoft, corner: 7, kind: .roundedRectangle, z: 2),
            bx(330, 570, 300, 14, cardSoft, corner: 7, kind: .roundedRectangle, z: 2),
            bx(330, 640, 180, 44, accent, corner: 22, kind: .roundedRectangle, z: 2),
            tx("€129", "Inter", 16, 800, align: .center, .white, 330, 652, 180, 24, 3),

            tx("Nimbus Pack 02", "Avenir Next", 56, 700, .white, ls: -1, 80, 800, 700, 70, 2),
            tx("Weatherproof · 18L · 500 units only", "Inter", 19, 400, mist, 80, 890, 700, 28, 2),
            tx("SHOP THE DROP →", "Inter", 15, 800, align: .right, accent, ls: 2, 780, 818, 220, 24, 2)
        ]

        return CanvasTemplate(
            id: "nimbus_drop",
            title: "Product Drop Post",
            category: "Social Media",
            docType: .square,
            themeName: "Midnight Drop",
            preset: CanvasPreset.presets[0],
            page: CanvasPage(name: "Drop", width: 1080, height: 1080, background: .solid(bg), elements: els),
            previewColorHex: "#F97316"
        )
    }

    // ======================================================================
    // MARK: - 11. MAKERS PODCAST — episode thumbnail (1280 × 720)
    // Design: dark violet field, waveform equaliser, bold episode title.
    // ======================================================================

    public static func createPodcastThumbTemplate() -> CanvasTemplate {
        let bg = CodableColor(hex: "#131022")
        let accent = CodableColor(hex: "#8B5CF6")
        let mist = CodableColor(hex: "#A5A0C2")

        var els: [CanvasElement] = [
            bx(70, 90, 170, 40, accent, corner: 20, kind: .roundedRectangle, z: 1),
            tx("EPISODE 42", "Inter", 13, 800, align: .center, .white, ls: 2, 70, 101, 170, 20, 2),
            tx("The Craft of\nShipping", "Avenir Next", 64, 700, .white, ls: -1, lsp: 6, 70, 200, 680, 210, 2),
            tx("with Lena Torres", "Inter", 21, 500, mist, 70, 430, 500, 30, 2),
            tx("Why the last 10% takes 90% of the time — and how finishing is a skill you can practise.", "Inter", 16, 400, mist, lsp: 5, 70, 480, 640, 60, 2),
            tx("THE MAKERS PODCAST", "Inter", 12, 700, CodableColor(hex: "#6E6A8C"), ls: 3, 70, 640, 500, 18, 1)
        ]
        let bars: [Double] = [90, 150, 210, 280, 180, 320, 240, 150, 290, 200, 120, 250, 170, 90]
        for (i, h) in bars.enumerated() {
            let x = 800.0 + Double(i) * 32
            els.append(bx(x, 360 - h / 2, 18, h, i == 5 ? .white : accent, corner: 9, kind: .roundedRectangle, z: 1, opacity: i == 5 ? 1 : 0.9))
        }

        return CanvasTemplate(
            id: "makers_podcast",
            title: "Podcast Episode Thumbnail",
            category: "Social Media",
            docType: .thumbnail,
            themeName: "Violet Wave",
            preset: CanvasPreset.presets[3],
            page: CanvasPage(name: "Episode", width: 1280, height: 720, background: .solid(bg), elements: els),
            previewColorHex: "#8B5CF6"
        )
    }

    // ======================================================================
    // MARK: - 12. HELVETIA CARD — Swiss minimal business card (1050 × 600)
    // ======================================================================

    public static func createHelvetiaCardTemplate() -> CanvasTemplate {
        let black = CodableColor(hex: "#141414")
        let red = CodableColor(hex: "#E2001A")
        let gray = CodableColor(hex: "#6E6E6E")

        let els: [CanvasElement] = [
            bx(80, 78, 20, 20, red, z: 1),
            tx("Jonas Weber", "Helvetica Neue", 30, 800, black, ls: -0.5, 116, 68, 600, 40, 2),
            tx("SENIOR PRODUCT ENGINEER", "Helvetica Neue", 11, 700, gray, ls: 2.5, 116, 114, 500, 18, 2),
            tx("HELVETIA\nSYSTEMS", "Helvetica Neue", 11, 700, align: .right, black, ls: 2, lsp: 2, 800, 72, 170, 40, 2),
            bx(80, 470, 890, 1, CodableColor(hex: "#D8D8D2"), z: 1),
            tx("hello@jonasweber.ch", "Helvetica Neue", 12, 400, gray, 80, 496, 300, 18, 2),
            tx("+41 44 555 01 20", "Helvetica Neue", 12, 400, align: .center, gray, 375, 496, 300, 18, 2),
            tx("Zürich, CH", "Helvetica Neue", 12, 400, align: .right, gray, 670, 496, 300, 18, 2)
        ]

        return CanvasTemplate(
            id: "helvetia_card",
            title: "Swiss Minimal Business Card",
            category: "Print & Documents",
            docType: .businessCard,
            themeName: "Swiss Minimal",
            preset: CanvasPreset.presets[12],
            page: CanvasPage(name: "Card", width: 1050, height: 600, background: .solid(.white), elements: els),
            previewColorHex: "#E2001A"
        )
    }
}
