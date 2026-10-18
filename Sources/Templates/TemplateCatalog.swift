import Foundation
import SwiftUI

public enum DocumentTypeGroup: String, CaseIterable, Identifiable {
    case whiteboard = "Whiteboard & Mindmap"
    case resume = "Resumes & CVs"
    case a4 = "A4 Documents"
    case square = "Instagram / Square"
    case presentation = "Presentation (16:9)"
    case story = "Story / Vertical (9:16)"
    case thumbnail = "YouTube Thumbnail"
    case businessCard = "Business Cards"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .whiteboard: return "brain.head.profile"
        case .resume: return "person.text.rectangle.fill"
        case .a4: return "doc.text.fill"
        case .square: return "camera.fill"
        case .presentation: return "tv.fill"
        case .story: return "iphone"
        case .thumbnail: return "play.rectangle.fill"
        case .businessCard: return "creditcard.fill"
        }
    }

    public func matches(width: Double, height: Double) -> Bool {
        let aspect = width / height
        switch self {
        case .whiteboard:
            return (width >= 2400 && height >= 1800) || (width == 3200 && height == 2000) || (width == 3600 && height == 2400)
        case .resume:
            return (width == 1240 && height == 1754) || (width == 1275 && height == 1650) || (width == 800 && height == 1130)
        case .a4:
            return (abs(aspect - (1240.0 / 1754.0)) < 0.12) || (width == 1240 && height == 1754) || (width == 1275 && height == 1650)
        case .square:
            return abs(aspect - 1.0) < 0.08
        case .presentation:
            return abs(aspect - (16.0 / 9.0)) < 0.08 && width >= 1500
        case .story:
            return abs(aspect - (9.0 / 16.0)) < 0.08 && height > width
        case .thumbnail:
            return abs(aspect - (16.0 / 9.0)) < 0.08 && width < 1500
        case .businessCard:
            return abs(aspect - (1050.0 / 600.0)) < 0.15 || (width == 1050 && height == 600)
        }
    }

    public static func detect(width: Double, height: Double) -> DocumentTypeGroup {
        for group in allCases {
            if group.matches(width: width, height: height) {
                return group
            }
        }
        let aspect = width / height
        if aspect > 1.3 { return .presentation }
        if aspect < 0.8 { return .a4 }
        return .square
    }
}

public struct CanvasTemplate: Identifiable {
    public var id: String
    public var title: String
    public var category: String
    public var docType: DocumentTypeGroup
    public var themeName: String
    public var preset: CanvasPreset
    public var pages: [CanvasPage]
    public var previewColorHex: String

    public var page: CanvasPage {
        pages.first ?? CanvasPage()
    }

    public init(
        id: String,
        title: String,
        category: String,
        docType: DocumentTypeGroup,
        themeName: String,
        preset: CanvasPreset,
        pages: [CanvasPage],
        previewColorHex: String = "#D97706"
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.docType = docType
        self.themeName = themeName
        self.preset = preset
        self.pages = pages
        self.previewColorHex = previewColorHex
    }

    public init(
        id: String,
        title: String,
        category: String,
        docType: DocumentTypeGroup,
        themeName: String,
        preset: CanvasPreset,
        page: CanvasPage,
        previewColorHex: String = "#D97706"
    ) {
        self.init(
            id: id,
            title: title,
            category: category,
            docType: docType,
            themeName: themeName,
            preset: preset,
            pages: [page],
            previewColorHex: previewColorHex
        )
    }
}

public enum TemplateCatalog {
    public static let templates: [CanvasTemplate] = [
        // ==================== -1. WHITEBOARDS, MINDMAPS & FREEFORM BOARDS ====================
        WhiteboardTemplates.createProductStrategyMindmapTemplate(),
        WhiteboardTemplates.createSystemArchitectureFlowchartTemplate(),
        WhiteboardTemplates.createAgileStickyNoteBoardTemplate(),
        WhiteboardTemplates.createKanbanDeliveryBoardTemplate(),
        WhiteboardTemplates.createSWOTAnalysisTemplate(),
        WhiteboardTemplates.createUserJourneyMapTemplate(),

        // ==================== 0. PROFESSIONAL RESUMES & CVS (A4 - 1240 × 1754) ====================
        ResumeTemplates.createTechLeadResumeTemplate(),
        ResumeTemplates.createExecutiveLeadershipResumeTemplate(),
        ResumeTemplates.createCreativeDirectorResumeTemplate(),
        ResumeTemplates.createIvyLeagueAcademicResumeTemplate(),
        ResumeTemplates.createGrowthMarketingResumeTemplate(),
        ResumeTemplates.createTwoColumnMinimalResumeTemplate(),
        ResumeTemplates.createBoldImpactResumeTemplate(),
        ResumeTemplates.createHealthcareResumeTemplate(),
        ResumeTemplates.createStudentInternshipResumeTemplate(),
        ResumeTemplates.createSalesManagerResumeTemplate(),
        StudioTemplates.createZurichCVTemplate(),           // Swiss timeline grid
        StudioTemplates.createScholarCVTemplate(),          // Academic publications CV
        StudioTemplates.createStudioCVTemplate(),           // Creative two-column CV

        // ==================== 1. PRESENTATION (16:9) FULL 5-SLIDE DECKS ====================
        createCuratorialGalleryTemplate(),          // 5 Slides: Cover -> Topics -> Deep Dive -> Comparison -> Summary
        createArtisanPortfolioDeckTemplate(),       // 5 Slides: Project Cover -> Process Topics -> Challenge & Solution -> System Specs -> Results & Impact
        createProductVisionKeynoteTemplate(),       // 5 Slides: Keynote Hero -> Agenda Pillars -> Speed & ProMotion -> Tactile System -> Next Chapter
        StudioTemplates.createMeridianKeynoteTemplate(),   // 5 Slides: dark launch keynote
        StudioTemplates.createGridZurichTemplate(),        // 5 Slides: Swiss International Style
        StudioTemplates.createFounderPitchTemplate(),      // 5 Slides: Series A investor pitch
        StudioTemplates.createQuarterlyReviewTemplate(),   // 4 Slides: executive QBR

        // ==================== 2. A4 DOCUMENTS (1240 × 1754 - MULTI-PAGE) ====================
        createRetroNewspaperTemplate(),             // 3 Pages
        createMetropolitanBroadsheetTemplate(),     // 3 Pages
        createHauteCoutureLookbookTemplate(),       // 4 Pages
        createVCInvestmentMemoTemplate(),           // 3 Pages
        createBauhausReviewTemplate(),             // 3 Pages
        createLetterpressPosterTemplate(),
        createMinimalistResumeTemplate(),
        createNordicInvoiceTemplate(),
        StudioTemplates.createAnnualReportTemplate(),       // 2 Pages: navy + gold
        StudioTemplates.createDesignWeekPosterTemplate(),   // Typographic event poster

        // ==================== 3. INSTAGRAM / SQUARE (1080 × 1080) ====================
        createPaperCollageTemplate(),
        createVintageZineTemplate(),
        createFlashSaleTemplate(),
        createThoughtLeadershipQuoteTemplate(),
        createNordicEventPassTemplate(),
        StudioTemplates.createProductDropTemplate(),        // Dark product drop

        // ==================== 4. STORIES / VERTICAL (9:16 - 1080 × 1920) ====================
        createScrapbookStoryTemplate(),
        createFlashCountdownStoryTemplate(),
        createTechTipStoryTemplate(),

        // ==================== 5. YOUTUBE THUMBNAILS (16:9 - 1280 × 720) ====================
        createRetroDocThumbnailTemplate(),
        createDesignSecretsThumbnailTemplate(),
        StudioTemplates.createPodcastThumbTemplate(),       // Waveform episode thumb

        // ==================== 6. BUSINESS CARDS (1050 × 600) ====================
        createBusinessCardTemplate(),
        createStudioDirectorCardTemplate(),
        StudioTemplates.createHelvetiaCardTemplate()
    ]

    // =========================================================================
    // MARK: - 1. PRESENTATION (16:9 - 1920 × 1080) 5-SLIDE COMPLETE DECKS
    // =========================================================================

    // 1.1 Curatorial Exhibition Deck (5 Complete Presentation Slides - Warm Vintage Paper)
    public static func createCuratorialGalleryTemplate() -> CanvasTemplate {
        // Slide 1: Cover Slide
        let slide1 = CanvasPage(
            name: "Slide 1: Exhibition Cover",
            width: 1920, height: 1080,
            background: FillStyle(type: .vintageParchment, solidColor: CodableColor(hex: "#FAF7F0")),
            elements: [
                // Elegant Outer Border Frame
                CanvasElement(name: "Border", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(.clear), stroke: StrokeStyle(isEnabled: true, color: .inkBlack, lineWidth: 2))), x: 80, y: 80, width: 1760, height: 920, zIndex: 0),
                CanvasElement(name: "Inner Thin Border", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(.clear), stroke: StrokeStyle(isEnabled: true, color: CodableColor(hex: "#C2410C"), lineWidth: 0.8))), x: 92, y: 92, width: 1736, height: 896, zIndex: 1),
                CanvasElement(name: "Symposium Tag", payload: .text(TextContent(text: "ANNUAL CURATORIAL SYMPOSIUM • ESTABLISHED 1924", fontFamily: "Georgia", fontSize: 14, fontWeight: 700, alignment: .center, textColor: CodableColor(hex: "#C2410C"), letterSpacing: 4)), x: 120, y: 150, width: 1680, height: 30, zIndex: 2),
                CanvasElement(name: "Main Title", payload: .text(TextContent(text: "Tactile Design &\nThe Digital Craft", fontFamily: "Playfair Display", fontSize: 80, fontWeight: 900, alignment: .center, textColor: .inkBlack, letterSpacing: 2, lineSpacing: 8)), x: 120, y: 220, width: 1680, height: 220, zIndex: 3),
                CanvasElement(name: "Rule Divider", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#C2410C")))), x: 860, y: 480, width: 200, height: 3, zIndex: 4),
                CanvasElement(name: "Deck Subtitle", payload: .text(TextContent(text: "A comprehensive inquiry into physical printmaking, historical typography, and the restoration of warmth to modern digital software.", fontFamily: "Georgia", fontSize: 20, fontWeight: 400, isItalic: true, alignment: .center, textColor: CodableColor(hex: "#44403C"), lineSpacing: 6)), x: 360, y: 520, width: 1200, height: 70, zIndex: 5),
                CanvasElement(name: "Presenter Card", payload: .shape(ShapeContent(kind: .roundedRectangle, cornerRadius: 6, fill: FillStyle.solid(CodableColor(hex: "#EFE8DA")), stroke: StrokeStyle(isEnabled: true, color: CodableColor(hex: "#D6C7B2"), lineWidth: 1))), x: 660, y: 840, width: 600, height: 60, zIndex: 6),
                CanvasElement(name: "Presenter Info", payload: .text(TextContent(text: "PRESENTED BY ELEANOR VANCE • ARCHIVES DIRECTOR", fontFamily: "Inter", fontSize: 13, fontWeight: 800, alignment: .center, textColor: .inkBlack, letterSpacing: 2)), x: 660, y: 858, width: 600, height: 25, zIndex: 7)
            ]
        )

        // Slide 2: Topics Overview / Agenda Slide
        let slide2 = CanvasPage(
            name: "Slide 2: Topics Overview",
            width: 1920, height: 1080,
            background: FillStyle(type: .vintageParchment, solidColor: CodableColor(hex: "#FAF7F0")),
            elements: [
                CanvasElement(name: "Agenda Tag", payload: .text(TextContent(text: "SECTION 01 / SYMPOSIUM AGENDA", fontFamily: "Georgia", fontSize: 14, fontWeight: 700, alignment: .left, textColor: CodableColor(hex: "#C2410C"), letterSpacing: 3)), x: 120, y: 100, width: 800, height: 25, zIndex: 0),
                CanvasElement(name: "Agenda Title", payload: .text(TextContent(text: "Presentation Topics & Overview", fontFamily: "Playfair Display", fontSize: 54, fontWeight: 900, alignment: .left, textColor: .inkBlack)), x: 120, y: 135, width: 1200, height: 70, zIndex: 1),
                CanvasElement(name: "Agenda Rule", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(.inkBlack))), x: 120, y: 220, width: 1680, height: 2, zIndex: 2),
                // 4 Topic Cards
                // Topic 1
                CanvasElement(name: "Topic 1 Box", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#F4EFE6")), stroke: StrokeStyle(isEnabled: true, color: .inkBlack, lineWidth: 1.5))), x: 120, y: 260, width: 390, height: 500, zIndex: 3),
                CanvasElement(name: "T1 Num", payload: .text(TextContent(text: "TOPIC 01", fontFamily: "Inter", fontSize: 13, fontWeight: 900, alignment: .left, textColor: CodableColor(hex: "#C2410C"), letterSpacing: 2)), x: 150, y: 295, width: 330, height: 25, zIndex: 4),
                CanvasElement(name: "T1 Title", payload: .text(TextContent(text: "Heritage of the\nLetterpress", fontFamily: "Playfair Display", fontSize: 26, fontWeight: 800, alignment: .left, textColor: .inkBlack, lineSpacing: 4)), x: 150, y: 330, width: 330, height: 75, zIndex: 5),
                CanvasElement(name: "T1 Desc", payload: .text(TextContent(text: "Exploring 1920s broadside printing, lead glyph casting, and the physical constraints that birthed modern editorial design.", fontFamily: "Georgia", fontSize: 15, alignment: .left, textColor: CodableColor(hex: "#44403C"), lineSpacing: 6)), x: 150, y: 430, width: 330, height: 200, zIndex: 6),
                // Topic 2
                CanvasElement(name: "Topic 2 Box", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#F4EFE6")), stroke: StrokeStyle(isEnabled: true, color: .inkBlack, lineWidth: 1.5))), x: 550, y: 260, width: 390, height: 500, zIndex: 7),
                CanvasElement(name: "T2 Num", payload: .text(TextContent(text: "TOPIC 02", fontFamily: "Inter", fontSize: 13, fontWeight: 900, alignment: .left, textColor: CodableColor(hex: "#C2410C"), letterSpacing: 2)), x: 580, y: 295, width: 330, height: 25, zIndex: 8),
                CanvasElement(name: "T2 Title", payload: .text(TextContent(text: "The Tactile\nImperative", fontFamily: "Playfair Display", fontSize: 26, fontWeight: 800, alignment: .left, textColor: .inkBlack, lineSpacing: 4)), x: 580, y: 330, width: 330, height: 75, zIndex: 9),
                CanvasElement(name: "T2 Desc", payload: .text(TextContent(text: "Why contemporary users experience screen fatigue, and how physical textures, paper grain, and ink bleed restore creative emotion.", fontFamily: "Georgia", fontSize: 15, alignment: .left, textColor: CodableColor(hex: "#44403C"), lineSpacing: 6)), x: 580, y: 430, width: 330, height: 200, zIndex: 10),
                // Topic 3
                CanvasElement(name: "Topic 3 Box", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#F4EFE6")), stroke: StrokeStyle(isEnabled: true, color: .inkBlack, lineWidth: 1.5))), x: 980, y: 260, width: 390, height: 500, zIndex: 11),
                CanvasElement(name: "T3 Num", payload: .text(TextContent(text: "TOPIC 03", fontFamily: "Inter", fontSize: 13, fontWeight: 900, alignment: .left, textColor: CodableColor(hex: "#C2410C"), letterSpacing: 2)), x: 1010, y: 295, width: 330, height: 25, zIndex: 12),
                CanvasElement(name: "T3 Title", payload: .text(TextContent(text: "Digital Surface\nTranslations", fontFamily: "Playfair Display", fontSize: 26, fontWeight: 800, alignment: .left, textColor: .inkBlack, lineSpacing: 4)), x: 1010, y: 330, width: 330, height: 75, zIndex: 13),
                CanvasElement(name: "T3 Desc", payload: .text(TextContent(text: "Case study analysis of native GPU shaders translating organic fiber textures onto 120 FPS Retina displays with zero lag.", fontFamily: "Georgia", fontSize: 15, alignment: .left, textColor: CodableColor(hex: "#44403C"), lineSpacing: 6)), x: 1010, y: 430, width: 330, height: 200, zIndex: 14),
                // Topic 4
                CanvasElement(name: "Topic 4 Box", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#F4EFE6")), stroke: StrokeStyle(isEnabled: true, color: .inkBlack, lineWidth: 1.5))), x: 1410, y: 260, width: 390, height: 500, zIndex: 15),
                CanvasElement(name: "T4 Num", payload: .text(TextContent(text: "TOPIC 04", fontFamily: "Inter", fontSize: 13, fontWeight: 900, alignment: .left, textColor: CodableColor(hex: "#C2410C"), letterSpacing: 2)), x: 1440, y: 295, width: 330, height: 25, zIndex: 16),
                CanvasElement(name: "T4 Title", payload: .text(TextContent(text: "The Next Era\nof Tools", fontFamily: "Playfair Display", fontSize: 26, fontWeight: 800, alignment: .left, textColor: .inkBlack, lineSpacing: 4)), x: 1440, y: 330, width: 330, height: 75, zIndex: 17),
                CanvasElement(name: "T4 Desc", payload: .text(TextContent(text: "Core principles for architecting software that respects user attention, device hardware, and artisanal graphic traditions.", fontFamily: "Georgia", fontSize: 15, alignment: .left, textColor: CodableColor(hex: "#44403C"), lineSpacing: 6)), x: 1440, y: 430, width: 330, height: 200, zIndex: 18)
            ]
        )

        // Slide 3: Topic 1 Deep Dive / Thesis Slide
        let slide3 = CanvasPage(
            name: "Slide 3: Deep Dive Analysis",
            width: 1920, height: 1080,
            background: FillStyle(type: .vintageParchment, solidColor: CodableColor(hex: "#FAF7F0")),
            elements: [
                CanvasElement(name: "Tag", payload: .text(TextContent(text: "TOPIC 01 • HISTORICAL FOUNDATION", fontFamily: "Georgia", fontSize: 14, fontWeight: 700, alignment: .left, textColor: CodableColor(hex: "#C2410C"), letterSpacing: 3)), x: 120, y: 100, width: 800, height: 25, zIndex: 0),
                CanvasElement(name: "Title", payload: .text(TextContent(text: "The Architecture of Physical Type", fontFamily: "Playfair Display", fontSize: 52, fontWeight: 900, alignment: .left, textColor: .inkBlack)), x: 120, y: 135, width: 1200, height: 70, zIndex: 1),
                CanvasElement(name: "Rule", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(.inkBlack))), x: 120, y: 220, width: 1680, height: 2, zIndex: 2),
                // Left Column Thesis Card
                CanvasElement(name: "Thesis Box", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#F4EFE6")), stroke: StrokeStyle(isEnabled: true, color: .inkBlack, lineWidth: 1))), x: 120, y: 260, width: 780, height: 620, zIndex: 3),
                CanvasElement(name: "Thesis Quote", payload: .text(TextContent(text: "“When typography is treated as physical architecture rather than ephemeral pixels, every word carries weight, permanence, and human intention.”", fontFamily: "Playfair Display", fontSize: 32, fontWeight: 700, isItalic: true, alignment: .left, textColor: .inkBlack, lineSpacing: 10)), x: 160, y: 310, width: 700, height: 240, zIndex: 4),
                CanvasElement(name: "Thesis Author", payload: .text(TextContent(text: "— ELEANOR VANCE, FROM 'THE TACTILE EYE' (1924)", fontFamily: "Inter", fontSize: 13, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#C2410C"), letterSpacing: 2)), x: 160, y: 580, width: 700, height: 25, zIndex: 5),
                // Right Column 3 Key Points
                CanvasElement(name: "Point 1 Card", payload: .shape(ShapeContent(kind: .roundedRectangle, cornerRadius: 6, fill: FillStyle.solid(.white), stroke: StrokeStyle(isEnabled: true, color: CodableColor(hex: "#D6D3CD"), lineWidth: 1))), x: 940, y: 260, width: 860, height: 180, zIndex: 6),
                CanvasElement(name: "P1 Title", payload: .text(TextContent(text: "1. Proportional Harmonies Over Rigid Grids", fontFamily: "Playfair Display", fontSize: 22, fontWeight: 800, alignment: .left, textColor: .inkBlack)), x: 970, y: 290, width: 800, height: 30, zIndex: 7),
                CanvasElement(name: "P1 Body", payload: .text(TextContent(text: "Classic book design followed golden canons and Fibonacci division, creating layouts that breathe naturally with generous outer margins.", fontFamily: "Georgia", fontSize: 15, alignment: .left, textColor: CodableColor(hex: "#44403C"), lineSpacing: 5)), x: 970, y: 330, width: 800, height: 80, zIndex: 8),
                CanvasElement(name: "Point 2 Card", payload: .shape(ShapeContent(kind: .roundedRectangle, cornerRadius: 6, fill: FillStyle.solid(.white), stroke: StrokeStyle(isEnabled: true, color: CodableColor(hex: "#D6D3CD"), lineWidth: 1))), x: 940, y: 470, width: 860, height: 180, zIndex: 9),
                CanvasElement(name: "P2 Title", payload: .text(TextContent(text: "2. The Materiality of Inks and Fibers", fontFamily: "Playfair Display", fontSize: 22, fontWeight: 800, alignment: .left, textColor: .inkBlack)), x: 970, y: 500, width: 800, height: 30, zIndex: 10),
                CanvasElement(name: "P2 Body", payload: .text(TextContent(text: "Physical paper grain diffuses illumination and eliminates the harsh glare that plagues flat, sterilized modern software interfaces.", fontFamily: "Georgia", fontSize: 15, alignment: .left, textColor: CodableColor(hex: "#44403C"), lineSpacing: 5)), x: 970, y: 540, width: 800, height: 80, zIndex: 11),
                CanvasElement(name: "Point 3 Card", payload: .shape(ShapeContent(kind: .roundedRectangle, cornerRadius: 6, fill: FillStyle.solid(.white), stroke: StrokeStyle(isEnabled: true, color: CodableColor(hex: "#D6D3CD"), lineWidth: 1))), x: 940, y: 680, width: 860, height: 180, zIndex: 12),
                CanvasElement(name: "P3 Title", payload: .text(TextContent(text: "3. Direct Engagement Without Intermediaries", fontFamily: "Playfair Display", fontSize: 22, fontWeight: 800, alignment: .left, textColor: .inkBlack)), x: 970, y: 710, width: 800, height: 30, zIndex: 13),
                CanvasElement(name: "P3 Body", payload: .text(TextContent(text: "Tools that operate at sub-millisecond speeds allow the artisan's hand and mind to work in complete synchrony.", fontFamily: "Georgia", fontSize: 15, alignment: .left, textColor: CodableColor(hex: "#44403C"), lineSpacing: 5)), x: 970, y: 750, width: 800, height: 80, zIndex: 14)
            ]
        )

        // Slide 4: Case Study & Comparison Slide
        let slide4 = CanvasPage(
            name: "Slide 4: Case Study Comparison",
            width: 1920, height: 1080,
            background: FillStyle(type: .vintageParchment, solidColor: CodableColor(hex: "#FAF7F0")),
            elements: [
                CanvasElement(name: "Tag", payload: .text(TextContent(text: "TOPIC 02 • CASE STUDY SYNTHESIS", fontFamily: "Georgia", fontSize: 14, fontWeight: 700, alignment: .left, textColor: CodableColor(hex: "#C2410C"), letterSpacing: 3)), x: 120, y: 100, width: 800, height: 25, zIndex: 0),
                CanvasElement(name: "Title", payload: .text(TextContent(text: "Physical Craft vs Digital Translation", fontFamily: "Playfair Display", fontSize: 52, fontWeight: 900, alignment: .left, textColor: .inkBlack)), x: 120, y: 135, width: 1200, height: 70, zIndex: 1),
                CanvasElement(name: "Rule", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(.inkBlack))), x: 120, y: 220, width: 1680, height: 2, zIndex: 2),
                // Card A: Historical Letterpress
                CanvasElement(name: "Card A", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#F4EFE6")), stroke: StrokeStyle(isEnabled: true, color: .inkBlack, lineWidth: 1.5))), x: 120, y: 260, width: 810, height: 480, zIndex: 3),
                CanvasElement(name: "Card A Header", payload: .text(TextContent(text: "HISTORICAL LETTERPRESS (1924)", fontFamily: "Inter", fontSize: 13, fontWeight: 900, alignment: .left, textColor: CodableColor(hex: "#C2410C"), letterSpacing: 2)), x: 160, y: 295, width: 730, height: 25, zIndex: 4),
                CanvasElement(name: "Card A Bullets", payload: .text(TextContent(text: "• Hand-set lead type with tactile micro-indentations\n• Organic cotton rag paper with natural deckle edges\n• Heavy pigment density and physical ink diffusion\n• Unhurried artisan workflow requiring profound discipline", fontFamily: "Georgia", fontSize: 17, alignment: .left, textColor: .inkBlack, lineSpacing: 12)), x: 160, y: 340, width: 730, height: 360, zIndex: 5),
                // Card B: Native Digital Craft
                CanvasElement(name: "Card B", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#F4EFE6")), stroke: StrokeStyle(isEnabled: true, color: .inkBlack, lineWidth: 1.5))), x: 990, y: 260, width: 810, height: 480, zIndex: 6),
                CanvasElement(name: "Card B Header", payload: .text(TextContent(text: "TECHNIART NATIVE ENGINE (2026)", fontFamily: "Inter", fontSize: 13, fontWeight: 900, alignment: .left, textColor: CodableColor(hex: "#C2410C"), letterSpacing: 2)), x: 1030, y: 295, width: 730, height: 25, zIndex: 7),
                CanvasElement(name: "Card B Bullets", payload: .text(TextContent(text: "• Sub-millisecond Apple Silicon Metal shader rendering\n• Procedural paper grain & fiber diffusion simulation\n• Instant WYSIWYG typography via native CoreText\n• 40 MB memory footprint ensuring total creative flow", fontFamily: "Georgia", fontSize: 17, alignment: .left, textColor: .inkBlack, lineSpacing: 12)), x: 1030, y: 340, width: 730, height: 360, zIndex: 8),
                // Bottom Takeaway Banner
                CanvasElement(name: "Takeaway Banner", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(.inkBlack))), x: 120, y: 780, width: 1680, height: 100, zIndex: 9),
                CanvasElement(name: "Takeaway Text", payload: .text(TextContent(text: "SYNTHESIS: DIGITAL TOOLS ATTAIN ARTISTRY WHEN THEY RESPECT PHYSICAL PROPORTIONS AND INSTANT FEEDBACK.", fontFamily: "Inter", fontSize: 14, fontWeight: 800, alignment: .center, textColor: .white, letterSpacing: 3)), x: 140, y: 820, width: 1640, height: 25, zIndex: 10)
            ]
        )

        // Slide 5: Conclusion & Summary Slide
        let slide5 = CanvasPage(
            name: "Slide 5: Summary & Q&A",
            width: 1920, height: 1080,
            background: FillStyle(type: .vintageParchment, solidColor: CodableColor(hex: "#FAF7F0")),
            elements: [
                CanvasElement(name: "Tag", payload: .text(TextContent(text: "CONCLUSION & FUTURE INQUIRY", fontFamily: "Georgia", fontSize: 14, fontWeight: 700, alignment: .left, textColor: CodableColor(hex: "#C2410C"), letterSpacing: 3)), x: 120, y: 100, width: 800, height: 25, zIndex: 0),
                CanvasElement(name: "Title", payload: .text(TextContent(text: "Key Takeaways & Open Discussion", fontFamily: "Playfair Display", fontSize: 52, fontWeight: 900, alignment: .left, textColor: .inkBlack)), x: 120, y: 135, width: 1200, height: 70, zIndex: 1),
                CanvasElement(name: "Rule", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(.inkBlack))), x: 120, y: 220, width: 1680, height: 2, zIndex: 2),
                // 3 Summary Columns
                CanvasElement(name: "Sum 1", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#F4EFE6")), stroke: StrokeStyle(isEnabled: true, color: .inkBlack, lineWidth: 1.5))), x: 120, y: 260, width: 520, height: 460, zIndex: 3),
                CanvasElement(name: "S1 Num", payload: .text(TextContent(text: "01", fontFamily: "Impact", fontSize: 44, fontWeight: 900, alignment: .left, textColor: CodableColor(hex: "#C2410C"))), x: 155, y: 290, width: 200, height: 50, zIndex: 4),
                CanvasElement(name: "S1 Title", payload: .text(TextContent(text: "Texture Evokes Emotion", fontFamily: "Playfair Display", fontSize: 24, fontWeight: 800, alignment: .left, textColor: .inkBlack)), x: 155, y: 350, width: 450, height: 35, zIndex: 5),
                CanvasElement(name: "S1 Body", payload: .text(TextContent(text: "Surfaces with tactile depth engage human intuition far deeper than flat, sterile corporate interfaces.", fontFamily: "Georgia", fontSize: 16, alignment: .left, textColor: CodableColor(hex: "#44403C"), lineSpacing: 6)), x: 155, y: 400, width: 450, height: 180, zIndex: 6),

                CanvasElement(name: "Sum 2", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#F4EFE6")), stroke: StrokeStyle(isEnabled: true, color: .inkBlack, lineWidth: 1.5))), x: 700, y: 260, width: 520, height: 460, zIndex: 7),
                CanvasElement(name: "S2 Num", payload: .text(TextContent(text: "02", fontFamily: "Impact", fontSize: 44, fontWeight: 900, alignment: .left, textColor: CodableColor(hex: "#C2410C"))), x: 735, y: 290, width: 200, height: 50, zIndex: 8),
                CanvasElement(name: "S2 Title", payload: .text(TextContent(text: "Speed Is Craftsmanship", fontFamily: "Playfair Display", fontSize: 24, fontWeight: 800, alignment: .left, textColor: .inkBlack)), x: 735, y: 350, width: 450, height: 35, zIndex: 9),
                CanvasElement(name: "S2 Body", payload: .text(TextContent(text: "Zero latency and lightweight memory footprint allow the creator to remain in deep unbroken focus.", fontFamily: "Georgia", fontSize: 16, alignment: .left, textColor: CodableColor(hex: "#44403C"), lineSpacing: 6)), x: 735, y: 400, width: 450, height: 180, zIndex: 10),

                CanvasElement(name: "Sum 3", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#F4EFE6")), stroke: StrokeStyle(isEnabled: true, color: .inkBlack, lineWidth: 1.5))), x: 1280, y: 260, width: 520, height: 460, zIndex: 11),
                CanvasElement(name: "S3 Num", payload: .text(TextContent(text: "03", fontFamily: "Impact", fontSize: 44, fontWeight: 900, alignment: .left, textColor: CodableColor(hex: "#C2410C"))), x: 1315, y: 290, width: 200, height: 50, zIndex: 12),
                CanvasElement(name: "S3 Title", payload: .text(TextContent(text: "Respect The Material", fontFamily: "Playfair Display", fontSize: 24, fontWeight: 800, alignment: .left, textColor: .inkBlack)), x: 1315, y: 350, width: 450, height: 35, zIndex: 13),
                CanvasElement(name: "S3 Body", payload: .text(TextContent(text: "Whether lead type or Apple Silicon hardware, master creators honor the native capabilities of their medium.", fontFamily: "Georgia", fontSize: 16, alignment: .left, textColor: CodableColor(hex: "#44403C"), lineSpacing: 6)), x: 1315, y: 400, width: 450, height: 180, zIndex: 14),

                // Q&A Footer Card
                CanvasElement(name: "QA Banner", payload: .shape(ShapeContent(kind: .roundedRectangle, cornerRadius: 8, fill: FillStyle.solid(CodableColor(hex: "#C2410C")))), x: 120, y: 760, width: 1680, height: 120, zIndex: 15),
                CanvasElement(name: "QA Text", payload: .text(TextContent(text: "THANK YOU • OPEN FOR QUESTIONS & DISCUSSION\narchive@curatorial.art • www.curatorial.art", fontFamily: "Inter", fontSize: 18, fontWeight: 900, alignment: .center, textColor: .white, letterSpacing: 3, lineSpacing: 6)), x: 140, y: 795, width: 1640, height: 55, zIndex: 16)
            ]
        )

        return CanvasTemplate(
            id: "curatorial_gallery",
            title: "Curatorial Exhibition (5 Slides)",
            category: "Presentations & Screens",
            docType: .presentation,
            themeName: "Vintage Paper",
            preset: CanvasPreset.presets[7],
            pages: [slide1, slide2, slide3, slide4, slide5],
            previewColorHex: "#FAF7F0"
        )
    }

    // 1.2 Artisan Case Study & Portfolio Deck (5 Complete Presentation Slides - Paper & Washi Tape)
    public static func createArtisanPortfolioDeckTemplate() -> CanvasTemplate {
        // Slide 1: Case Study Cover
        let slide1 = CanvasPage(
            name: "Slide 1: Case Study Cover",
            width: 1920, height: 1080,
            background: FillStyle(type: .vintageParchment, solidColor: CodableColor(hex: "#FAF7F0")),
            elements: [
                CanvasElement(name: "Washi Tape Top", payload: .shape(ShapeContent(kind: .washiTape, fill: FillStyle.solid(CodableColor(hex: "#FB923C")))), x: 120, y: 75, width: 280, height: 42, rotation: -4, zIndex: 0),
                CanvasElement(name: "Case Tag", payload: .text(TextContent(text: "PORTFOLIO CASE STUDY • BRAND IDENTITY", fontFamily: "Georgia", fontSize: 14, fontWeight: 700, alignment: .left, textColor: CodableColor(hex: "#C2410C"), letterSpacing: 3)), x: 120, y: 140, width: 800, height: 25, zIndex: 1),
                CanvasElement(name: "Case Title", payload: .text(TextContent(text: "The Modern Letterpress\nBrand & Identity System", fontFamily: "Playfair Display", fontSize: 68, fontWeight: 900, alignment: .left, textColor: .inkBlack, lineSpacing: 8)), x: 120, y: 180, width: 950, height: 180, zIndex: 2),
                CanvasElement(name: "Case Subtitle", payload: .text(TextContent(text: "Designing a cohesive tactile visual identity for a heritage artisan printshop in San Francisco.", fontFamily: "Georgia", fontSize: 19, fontWeight: 400, isItalic: true, alignment: .left, textColor: CodableColor(hex: "#44403C"), lineSpacing: 5)), x: 120, y: 380, width: 880, height: 60, zIndex: 3),
                // Polaroid Mockup Frame
                CanvasElement(name: "Polaroid Card", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(.white), stroke: StrokeStyle(isEnabled: true, color: CodableColor(hex: "#D6D3CD"), lineWidth: 1))), x: 1120, y: 140, width: 680, height: 740, rotation: 2.5, shadow: ShadowEffect.elevated, zIndex: 4),
                CanvasElement(name: "Polaroid Photo", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#EFE8DA")))), x: 1160, y: 180, width: 600, height: 560, rotation: 2.5, zIndex: 5),
                CanvasElement(name: "Polaroid Text", payload: .text(TextContent(text: "STUDIO SPECIMEN 01 • HAND-PULLED PRINTS", fontFamily: "Inter", fontSize: 12, fontWeight: 800, alignment: .center, textColor: CodableColor(hex: "#C2410C"), letterSpacing: 2)), x: 1160, y: 770, width: 600, height: 25, rotation: 2.5, zIndex: 6),
                // Project Metadata Box
                CanvasElement(name: "Meta Box", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#F4EFE6")), stroke: StrokeStyle(isEnabled: true, color: .inkBlack, lineWidth: 1))), x: 120, y: 800, width: 880, height: 90, zIndex: 7),
                CanvasElement(name: "Meta Text", payload: .text(TextContent(text: "CLIENT: ATELIER PRESS   •   TIMELINE: 8 WEEKS   •   ROLE: LEAD BRAND ARCHITECT", fontFamily: "SF Mono", fontSize: 12, fontWeight: 700, alignment: .center, textColor: .inkBlack, letterSpacing: 1.5)), x: 140, y: 835, width: 840, height: 20, zIndex: 8)
            ]
        )

        // Slide 2: Project Phases & Agenda
        let slide2 = CanvasPage(
            name: "Slide 2: Project Phases",
            width: 1920, height: 1080,
            background: FillStyle(type: .vintageParchment, solidColor: CodableColor(hex: "#FAF7F0")),
            elements: [
                CanvasElement(name: "Tag", payload: .text(TextContent(text: "01 / DESIGN PROCESS & TOPICS", fontFamily: "Georgia", fontSize: 14, fontWeight: 700, alignment: .left, textColor: CodableColor(hex: "#C2410C"), letterSpacing: 3)), x: 120, y: 100, width: 800, height: 25, zIndex: 0),
                CanvasElement(name: "Title", payload: .text(TextContent(text: "Four Phases of the Case Study", fontFamily: "Playfair Display", fontSize: 54, fontWeight: 900, alignment: .left, textColor: .inkBlack)), x: 120, y: 135, width: 1200, height: 70, zIndex: 1),
                CanvasElement(name: "Rule", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(.inkBlack))), x: 120, y: 220, width: 1680, height: 2, zIndex: 2),
                // 4 Phase Cards
                CanvasElement(name: "P1 Box", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#F4EFE6")), stroke: StrokeStyle(isEnabled: true, color: .inkBlack, lineWidth: 1.5))), x: 120, y: 260, width: 390, height: 500, zIndex: 3),
                CanvasElement(name: "P1 Tag", payload: .text(TextContent(text: "PHASE 01", fontFamily: "Inter", fontSize: 13, fontWeight: 900, alignment: .left, textColor: CodableColor(hex: "#C2410C"), letterSpacing: 2)), x: 150, y: 295, width: 330, height: 25, zIndex: 4),
                CanvasElement(name: "P1 Title", payload: .text(TextContent(text: "Archival Research\n& Discovery", fontFamily: "Playfair Display", fontSize: 26, fontWeight: 800, alignment: .left, textColor: .inkBlack, lineSpacing: 4)), x: 150, y: 330, width: 330, height: 75, zIndex: 5),
                CanvasElement(name: "P1 Desc", payload: .text(TextContent(text: "Audited 100 years of California letterpress specimens, woodblock fonts, and traditional ink mixing formulas.", fontFamily: "Georgia", fontSize: 15, alignment: .left, textColor: CodableColor(hex: "#44403C"), lineSpacing: 6)), x: 150, y: 430, width: 330, height: 200, zIndex: 6),

                CanvasElement(name: "P2 Box", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#F4EFE6")), stroke: StrokeStyle(isEnabled: true, color: .inkBlack, lineWidth: 1.5))), x: 550, y: 260, width: 390, height: 500, zIndex: 7),
                CanvasElement(name: "P2 Tag", payload: .text(TextContent(text: "PHASE 02", fontFamily: "Inter", fontSize: 13, fontWeight: 900, alignment: .left, textColor: CodableColor(hex: "#C2410C"), letterSpacing: 2)), x: 580, y: 295, width: 330, height: 25, zIndex: 8),
                CanvasElement(name: "P2 Title", payload: .text(TextContent(text: "Visual Identity\n& Typography", fontFamily: "Playfair Display", fontSize: 26, fontWeight: 800, alignment: .left, textColor: .inkBlack, lineSpacing: 4)), x: 580, y: 330, width: 330, height: 75, zIndex: 9),
                CanvasElement(name: "P2 Desc", payload: .text(TextContent(text: "Created custom monogram seals, high-contrast Playfair typography pairings, and warm terracotta color palettes.", fontFamily: "Georgia", fontSize: 15, alignment: .left, textColor: CodableColor(hex: "#44403C"), lineSpacing: 6)), x: 580, y: 430, width: 330, height: 200, zIndex: 10),

                CanvasElement(name: "P3 Box", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#F4EFE6")), stroke: StrokeStyle(isEnabled: true, color: .inkBlack, lineWidth: 1.5))), x: 980, y: 260, width: 390, height: 500, zIndex: 11),
                CanvasElement(name: "P3 Tag", payload: .text(TextContent(text: "PHASE 03", fontFamily: "Inter", fontSize: 13, fontWeight: 900, alignment: .left, textColor: CodableColor(hex: "#C2410C"), letterSpacing: 2)), x: 1010, y: 295, width: 330, height: 25, zIndex: 12),
                CanvasElement(name: "P3 Title", payload: .text(TextContent(text: "Packaging &\nPrint Deliverables", fontFamily: "Playfair Display", fontSize: 26, fontWeight: 800, alignment: .left, textColor: .inkBlack, lineSpacing: 4)), x: 1010, y: 330, width: 330, height: 75, zIndex: 13),
                CanvasElement(name: "P3 Desc", payload: .text(TextContent(text: "Produced embossed stationery, wax-sealed packaging boxes, and digital broadsheet lookbook collateral.", fontFamily: "Georgia", fontSize: 15, alignment: .left, textColor: CodableColor(hex: "#44403C"), lineSpacing: 6)), x: 1010, y: 430, width: 330, height: 200, zIndex: 14),

                CanvasElement(name: "P4 Box", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#F4EFE6")), stroke: StrokeStyle(isEnabled: true, color: .inkBlack, lineWidth: 1.5))), x: 1410, y: 260, width: 390, height: 500, zIndex: 15),
                CanvasElement(name: "P4 Tag", payload: .text(TextContent(text: "PHASE 04", fontFamily: "Inter", fontSize: 13, fontWeight: 900, alignment: .left, textColor: CodableColor(hex: "#C2410C"), letterSpacing: 2)), x: 1440, y: 295, width: 330, height: 25, zIndex: 16),
                CanvasElement(name: "P4 Title", payload: .text(TextContent(text: "Commercial Impact\n& Press Coverage", fontFamily: "Playfair Display", fontSize: 26, fontWeight: 800, alignment: .left, textColor: .inkBlack, lineSpacing: 4)), x: 1440, y: 330, width: 330, height: 75, zIndex: 17),
                CanvasElement(name: "P4 Desc", payload: .text(TextContent(text: "Delivered a 340% surge in bespoke print commissions and won 12 international graphic design distinctions.", fontFamily: "Georgia", fontSize: 15, alignment: .left, textColor: CodableColor(hex: "#44403C"), lineSpacing: 6)), x: 1440, y: 430, width: 330, height: 200, zIndex: 18)
            ]
        )

        // Slide 3: Creative Challenge & Strategic Solution
        let slide3 = CanvasPage(
            name: "Slide 3: Challenge & Solution",
            width: 1920, height: 1080,
            background: FillStyle(type: .vintageParchment, solidColor: CodableColor(hex: "#FAF7F0")),
            elements: [
                CanvasElement(name: "Tag", payload: .text(TextContent(text: "PHASE 01 • THE CREATIVE CHALLENGE", fontFamily: "Georgia", fontSize: 14, fontWeight: 700, alignment: .left, textColor: CodableColor(hex: "#C2410C"), letterSpacing: 3)), x: 120, y: 100, width: 800, height: 25, zIndex: 0),
                CanvasElement(name: "Title", payload: .text(TextContent(text: "Bridging 100 Years of Heritage with Modern Utility", fontFamily: "Playfair Display", fontSize: 52, fontWeight: 900, alignment: .left, textColor: .inkBlack)), x: 120, y: 135, width: 1400, height: 70, zIndex: 1),
                CanvasElement(name: "Rule", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(.inkBlack))), x: 120, y: 220, width: 1680, height: 2, zIndex: 2),
                // Challenge Card
                CanvasElement(name: "Chal Card", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#F4EFE6")), stroke: StrokeStyle(isEnabled: true, color: .inkBlack, lineWidth: 1.5))), x: 120, y: 260, width: 810, height: 580, zIndex: 3),
                CanvasElement(name: "Chal Header", payload: .text(TextContent(text: "THE CHALLENGE", fontFamily: "Inter", fontSize: 14, fontWeight: 900, alignment: .left, textColor: CodableColor(hex: "#C2410C"), letterSpacing: 2)), x: 160, y: 300, width: 730, height: 25, zIndex: 4),
                CanvasElement(name: "Chal Title", payload: .text(TextContent(text: "Avoiding Nostalgia Pitfalls", fontFamily: "Playfair Display", fontSize: 32, fontWeight: 800, alignment: .left, textColor: .inkBlack)), x: 160, y: 335, width: 730, height: 45, zIndex: 5),
                CanvasElement(name: "Chal Body", payload: .text(TextContent(text: "Traditional print shops often fall into faux-vintage tropes that feel dated rather than timeless.\n\nThe challenge was to celebrate 1920s letterpress roots while maintaining an uncompromising, modern editorial presence that appeals to luxury fashion and technology clients.", fontFamily: "Georgia", fontSize: 17, alignment: .left, textColor: CodableColor(hex: "#44403C"), lineSpacing: 8)), x: 160, y: 400, width: 730, height: 380, zIndex: 6),
                // Solution Card
                CanvasElement(name: "Sol Card", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#F4EFE6")), stroke: StrokeStyle(isEnabled: true, color: .inkBlack, lineWidth: 1.5))), x: 990, y: 260, width: 810, height: 580, zIndex: 7),
                CanvasElement(name: "Sol Header", payload: .text(TextContent(text: "THE STRATEGIC SOLUTION", fontFamily: "Inter", fontSize: 14, fontWeight: 900, alignment: .left, textColor: CodableColor(hex: "#C2410C"), letterSpacing: 2)), x: 1030, y: 300, width: 730, height: 25, zIndex: 8),
                CanvasElement(name: "Sol Title", payload: .text(TextContent(text: "Tactile Minimalism", fontFamily: "Playfair Display", fontSize: 32, fontWeight: 800, alignment: .left, textColor: .inkBlack)), x: 1030, y: 335, width: 730, height: 45, zIndex: 9),
                CanvasElement(name: "Sol Body", payload: .text(TextContent(text: "We established a design grammar based on:\n\n1. Monospaced technical labels paired with high-contrast display serif typography.\n2. Genuine paper textures and subtle washi tape accents.\n3. Extreme negative space that commands respect and quiet confidence.", fontFamily: "Georgia", fontSize: 17, alignment: .left, textColor: CodableColor(hex: "#44403C"), lineSpacing: 8)), x: 1030, y: 400, width: 730, height: 380, zIndex: 10)
            ]
        )

        // Slide 4: Design System Specifications
        let slide4 = CanvasPage(
            name: "Slide 4: Design System Specs",
            width: 1920, height: 1080,
            background: FillStyle(type: .vintageParchment, solidColor: CodableColor(hex: "#FAF7F0")),
            elements: [
                CanvasElement(name: "Tag", payload: .text(TextContent(text: "PHASE 02 • VISUAL SYSTEM SPECIFICATIONS", fontFamily: "Georgia", fontSize: 14, fontWeight: 700, alignment: .left, textColor: CodableColor(hex: "#C2410C"), letterSpacing: 3)), x: 120, y: 100, width: 800, height: 25, zIndex: 0),
                CanvasElement(name: "Title", payload: .text(TextContent(text: "Typography, Color Palette & Paper Physics", fontFamily: "Playfair Display", fontSize: 52, fontWeight: 900, alignment: .left, textColor: .inkBlack)), x: 120, y: 135, width: 1400, height: 70, zIndex: 1),
                CanvasElement(name: "Rule", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(.inkBlack))), x: 120, y: 220, width: 1680, height: 2, zIndex: 2),
                // 3 Specimen Blocks
                // Block 1: Palette
                CanvasElement(name: "Spec 1", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(.white), stroke: StrokeStyle(isEnabled: true, color: CodableColor(hex: "#D6D3CD"), lineWidth: 1))), x: 120, y: 260, width: 520, height: 580, zIndex: 3),
                CanvasElement(name: "S1 Tag", payload: .text(TextContent(text: "COLOR PALETTE", fontFamily: "Inter", fontSize: 13, fontWeight: 900, alignment: .left, textColor: CodableColor(hex: "#C2410C"), letterSpacing: 2)), x: 155, y: 295, width: 450, height: 25, zIndex: 4),
                CanvasElement(name: "S1 Title", payload: .text(TextContent(text: "Artisan Earth Tones", fontFamily: "Playfair Display", fontSize: 26, fontWeight: 800, alignment: .left, textColor: .inkBlack)), x: 155, y: 330, width: 450, height: 35, zIndex: 5),
                CanvasElement(name: "Swatch 1", payload: .shape(ShapeContent(kind: .roundedRectangle, cornerRadius: 4, fill: FillStyle.solid(CodableColor(hex: "#C2410C")))), x: 155, y: 390, width: 450, height: 50, zIndex: 6),
                CanvasElement(name: "Swatch 1 Lbl", payload: .text(TextContent(text: "Terracotta #C2410C — Primary Signature", fontFamily: "SF Mono", fontSize: 12, fontWeight: 700, alignment: .left, textColor: .white)), x: 170, y: 405, width: 420, height: 20, zIndex: 7),
                CanvasElement(name: "Swatch 2", payload: .shape(ShapeContent(kind: .roundedRectangle, cornerRadius: 4, fill: FillStyle.solid(CodableColor(hex: "#1C1917")))), x: 155, y: 455, width: 450, height: 50, zIndex: 8),
                CanvasElement(name: "Swatch 2 Lbl", payload: .text(TextContent(text: "Ink Black #1C1917 — Typography", fontFamily: "SF Mono", fontSize: 12, fontWeight: 700, alignment: .left, textColor: .white)), x: 170, y: 470, width: 420, height: 20, zIndex: 9),
                CanvasElement(name: "Swatch 3", payload: .shape(ShapeContent(kind: .roundedRectangle, cornerRadius: 4, fill: FillStyle.solid(CodableColor(hex: "#F4EFE6")), stroke: StrokeStyle(isEnabled: true, color: CodableColor(hex: "#D6D3CD"), lineWidth: 1))), x: 155, y: 520, width: 450, height: 50, zIndex: 10),
                CanvasElement(name: "Swatch 3 Lbl", payload: .text(TextContent(text: "Warm Parchment #FAF7F0 — Canvas Sheet", fontFamily: "SF Mono", fontSize: 12, fontWeight: 700, alignment: .left, textColor: .inkBlack)), x: 170, y: 535, width: 420, height: 20, zIndex: 11),
                // Block 2: Typography
                CanvasElement(name: "Spec 2", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(.white), stroke: StrokeStyle(isEnabled: true, color: CodableColor(hex: "#D6D3CD"), lineWidth: 1))), x: 700, y: 260, width: 520, height: 580, zIndex: 12),
                CanvasElement(name: "S2 Tag", payload: .text(TextContent(text: "TYPOGRAPHY SPECIMENS", fontFamily: "Inter", fontSize: 13, fontWeight: 900, alignment: .left, textColor: CodableColor(hex: "#C2410C"), letterSpacing: 2)), x: 735, y: 295, width: 450, height: 25, zIndex: 13),
                CanvasElement(name: "S2 Title", payload: .text(TextContent(text: "Playfair & Georgia", fontFamily: "Playfair Display", fontSize: 26, fontWeight: 800, alignment: .left, textColor: .inkBlack)), x: 735, y: 330, width: 450, height: 35, zIndex: 14),
                CanvasElement(name: "S2 Specimen", payload: .text(TextContent(text: "Aa Bb Gg 123", fontFamily: "Playfair Display", fontSize: 44, fontWeight: 900, alignment: .left, textColor: .inkBlack)), x: 735, y: 380, width: 450, height: 60, zIndex: 15),
                CanvasElement(name: "S2 Body", payload: .text(TextContent(text: "High-contrast Didone serifs evoke the precision of 18th century punch-cutting, paired with Georgia for effortless reading.", fontFamily: "Georgia", fontSize: 14, alignment: .left, textColor: CodableColor(hex: "#44403C"), lineSpacing: 6)), x: 735, y: 460, width: 450, height: 180, zIndex: 16),
                // Block 3: Materials
                CanvasElement(name: "Spec 3", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(.white), stroke: StrokeStyle(isEnabled: true, color: CodableColor(hex: "#D6D3CD"), lineWidth: 1))), x: 1280, y: 260, width: 520, height: 580, zIndex: 17),
                CanvasElement(name: "S3 Tag", payload: .text(TextContent(text: "PHYSICAL TEXTURES", fontFamily: "Inter", fontSize: 13, fontWeight: 900, alignment: .left, textColor: CodableColor(hex: "#C2410C"), letterSpacing: 2)), x: 1315, y: 295, width: 450, height: 25, zIndex: 18),
                CanvasElement(name: "S3 Title", payload: .text(TextContent(text: "Cotton Rag & Washi", fontFamily: "Playfair Display", fontSize: 26, fontWeight: 800, alignment: .left, textColor: .inkBlack)), x: 1315, y: 330, width: 450, height: 35, zIndex: 19),
                CanvasElement(name: "S3 Body", payload: .text(TextContent(text: "• 600 GSM Cotton Letterpress stock\n• Semi-translucent Japanese washi tape trims\n• Debossed sealing wax medallions\n• Anti-glare micro-texture surface shaders", fontFamily: "Georgia", fontSize: 15, alignment: .left, textColor: CodableColor(hex: "#44403C"), lineSpacing: 10)), x: 1315, y: 390, width: 450, height: 240, zIndex: 20)
            ]
        )

        // Slide 5: Results, Impact & Testimonial
        let slide5 = CanvasPage(
            name: "Slide 5: Results & Impact",
            width: 1920, height: 1080,
            background: FillStyle(type: .vintageParchment, solidColor: CodableColor(hex: "#FAF7F0")),
            elements: [
                CanvasElement(name: "Tag", payload: .text(TextContent(text: "PHASE 04 • COMMERCIAL IMPACT & OUTCOMES", fontFamily: "Georgia", fontSize: 14, fontWeight: 700, alignment: .left, textColor: CodableColor(hex: "#C2410C"), letterSpacing: 3)), x: 120, y: 100, width: 800, height: 25, zIndex: 0),
                CanvasElement(name: "Title", payload: .text(TextContent(text: "Transformative Growth & Acclaim", fontFamily: "Playfair Display", fontSize: 52, fontWeight: 900, alignment: .left, textColor: .inkBlack)), x: 120, y: 135, width: 1200, height: 70, zIndex: 1),
                CanvasElement(name: "Rule", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(.inkBlack))), x: 120, y: 220, width: 1680, height: 2, zIndex: 2),
                // 3 Metric Stat Boxes
                CanvasElement(name: "Stat 1", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#F4EFE6")), stroke: StrokeStyle(isEnabled: true, color: .inkBlack, lineWidth: 1.5))), x: 120, y: 260, width: 520, height: 220, zIndex: 3),
                CanvasElement(name: "St1 Num", payload: .text(TextContent(text: "+340%", fontFamily: "Impact", fontSize: 64, fontWeight: 900, alignment: .left, textColor: CodableColor(hex: "#C2410C"))), x: 155, y: 290, width: 450, height: 75, zIndex: 4),
                CanvasElement(name: "St1 Lbl", payload: .text(TextContent(text: "Increase in bespoke studio commissions within the first 90 days of launch.", fontFamily: "Georgia", fontSize: 15, alignment: .left, textColor: .inkBlack)), x: 155, y: 380, width: 450, height: 70, zIndex: 5),

                CanvasElement(name: "Stat 2", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#F4EFE6")), stroke: StrokeStyle(isEnabled: true, color: .inkBlack, lineWidth: 1.5))), x: 700, y: 260, width: 520, height: 220, zIndex: 6),
                CanvasElement(name: "St2 Num", payload: .text(TextContent(text: "12", fontFamily: "Impact", fontSize: 64, fontWeight: 900, alignment: .left, textColor: CodableColor(hex: "#C2410C"))), x: 735, y: 290, width: 450, height: 75, zIndex: 7),
                CanvasElement(name: "St2 Lbl", payload: .text(TextContent(text: "Global Design Awards including TDC Tokyo and Graphis Platinum.", fontFamily: "Georgia", fontSize: 15, alignment: .left, textColor: .inkBlack)), x: 735, y: 380, width: 450, height: 70, zIndex: 8),

                CanvasElement(name: "Stat 3", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#F4EFE6")), stroke: StrokeStyle(isEnabled: true, color: .inkBlack, lineWidth: 1.5))), x: 1280, y: 260, width: 520, height: 220, zIndex: 9),
                CanvasElement(name: "St3 Num", payload: .text(TextContent(text: "4.9 / 5", fontFamily: "Impact", fontSize: 64, fontWeight: 900, alignment: .left, textColor: CodableColor(hex: "#C2410C"))), x: 1315, y: 290, width: 450, height: 75, zIndex: 10),
                CanvasElement(name: "St3 Lbl", payload: .text(TextContent(text: "Client satisfaction rating across 80+ luxury editorial packaging projects.", fontFamily: "Georgia", fontSize: 15, alignment: .left, textColor: .inkBlack)), x: 1315, y: 380, width: 450, height: 70, zIndex: 11),

                // Testimonial Card
                CanvasElement(name: "Quote Card", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(.inkBlack))), x: 120, y: 520, width: 1680, height: 260, zIndex: 12),
                CanvasElement(name: "Quote Body", payload: .text(TextContent(text: "“Pluma helped us distill a century of artisanal tradition into a brand identity that commands attention globally. The response from our clients has been breathtaking.”", fontFamily: "Playfair Display", fontSize: 24, fontWeight: 700, isItalic: true, alignment: .center, textColor: .white, lineSpacing: 8)), x: 180, y: 560, width: 1560, height: 110, zIndex: 13),
                CanvasElement(name: "Quote Author", payload: .text(TextContent(text: "— JULIAN STERLING, MASTER PRINTER & FOUNDER OF ATELIER PRESS", fontFamily: "Inter", fontSize: 13, fontWeight: 800, alignment: .center, textColor: CodableColor(hex: "#FB923C"), letterSpacing: 3)), x: 180, y: 690, width: 1560, height: 25, zIndex: 14),

                // Footer Banner
                CanvasElement(name: "Footer", payload: .text(TextContent(text: "STUDIO ARCHIVE • VIEW FULL CASE STUDY AT ARTISANPRESS.DESIGN", fontFamily: "SF Mono", fontSize: 12, fontWeight: 700, alignment: .center, textColor: CodableColor(hex: "#78716C"), letterSpacing: 2)), x: 120, y: 830, width: 1680, height: 25, zIndex: 15)
            ]
        )

        return CanvasTemplate(
            id: "artisan_portfolio_deck",
            title: "Artisan Case Study (5 Slides)",
            category: "Presentations & Screens",
            docType: .presentation,
            themeName: "Vintage Paper",
            preset: CanvasPreset.presets[7],
            pages: [slide1, slide2, slide3, slide4, slide5],
            previewColorHex: "#FAF7F0"
        )
    }

    // 1.3 Product Vision Keynote Deck (5 Complete Presentation Slides - Terracotta Modern)
    public static func createProductVisionKeynoteTemplate() -> CanvasTemplate {
        // Slide 1: Keynote Hero Cover
        let slide1 = CanvasPage(
            name: "Slide 1: Keynote Title",
            width: 1920, height: 1080,
            background: FillStyle.solid(CodableColor(hex: "#C2410C")),
            elements: [
                CanvasElement(name: "Year Tag", payload: .text(TextContent(text: "PRODUCT VISION KEYNOTE • 2026 & BEYOND", fontFamily: "Inter", fontSize: 15, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#FED7AA"), letterSpacing: 4)), x: 120, y: 120, width: 800, height: 30, zIndex: 0),
                CanvasElement(name: "Vision Headline", payload: .text(TextContent(text: "Empowering Next-Gen Creators\nWith Native Speed & Craft", fontFamily: "Playfair Display", fontSize: 72, fontWeight: 900, alignment: .left, textColor: .white, lineSpacing: 10)), x: 120, y: 180, width: 1400, height: 200, zIndex: 1),
                CanvasElement(name: "Vision Subtitle", payload: .text(TextContent(text: "Why sub-millisecond responsiveness and tactile simplicity are the future of creative tools on Apple Silicon.", fontFamily: "Georgia", fontSize: 22, fontWeight: 400, isItalic: true, alignment: .left, textColor: CodableColor(hex: "#FED7AA"), lineSpacing: 6)), x: 120, y: 410, width: 1200, height: 70, zIndex: 2),
                CanvasElement(name: "Presenter Tag", payload: .text(TextContent(text: "ALEXANDER CHEN • CHIEF PRODUCT ARCHITECT", fontFamily: "SF Mono", fontSize: 13, fontWeight: 700, alignment: .left, textColor: .white, letterSpacing: 2)), x: 120, y: 880, width: 800, height: 25, zIndex: 3)
            ]
        )

        // Slide 2: Agenda & Four Pillars
        let slide2 = CanvasPage(
            name: "Slide 2: Agenda & Four Pillars",
            width: 1920, height: 1080,
            background: FillStyle.solid(CodableColor(hex: "#C2410C")),
            elements: [
                CanvasElement(name: "Tag", payload: .text(TextContent(text: "01 / PRESENTATION AGENDA", fontFamily: "Inter", fontSize: 14, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#FED7AA"), letterSpacing: 3)), x: 120, y: 100, width: 600, height: 25, zIndex: 0),
                CanvasElement(name: "Title", payload: .text(TextContent(text: "Four Pillars of the 2026 Vision", fontFamily: "Playfair Display", fontSize: 54, fontWeight: 900, alignment: .left, textColor: .white)), x: 120, y: 135, width: 1400, height: 70, zIndex: 1),
                // 4 Topic Pillar Cards
                CanvasElement(name: "P1 Box", payload: .shape(ShapeContent(kind: .roundedRectangle, cornerRadius: 10, fill: FillStyle.solid(CodableColor(hex: "#9A3412")))), x: 120, y: 250, width: 380, height: 520, zIndex: 2),
                CanvasElement(name: "P1 Num", payload: .text(TextContent(text: "01", fontFamily: "Impact", fontSize: 44, fontWeight: 900, alignment: .left, textColor: CodableColor(hex: "#FED7AA"))), x: 155, y: 285, width: 200, height: 50, zIndex: 3),
                CanvasElement(name: "P1 Title", payload: .text(TextContent(text: "The Fall of Web Bloat", fontFamily: "Playfair Display", fontSize: 24, fontWeight: 800, alignment: .left, textColor: .white)), x: 155, y: 345, width: 310, height: 35, zIndex: 4),
                CanvasElement(name: "P1 Body", payload: .text(TextContent(text: "Analyzing why 4GB memory consumption and sluggish Electron web wrappers ruin creative flow.", fontFamily: "Georgia", fontSize: 15, alignment: .left, textColor: CodableColor(hex: "#FED7AA"), lineSpacing: 6)), x: 155, y: 395, width: 310, height: 200, zIndex: 5),

                CanvasElement(name: "P2 Box", payload: .shape(ShapeContent(kind: .roundedRectangle, cornerRadius: 10, fill: FillStyle.solid(CodableColor(hex: "#9A3412")))), x: 540, y: 250, width: 380, height: 520, zIndex: 6),
                CanvasElement(name: "P2 Num", payload: .text(TextContent(text: "02", fontFamily: "Impact", fontSize: 44, fontWeight: 900, alignment: .left, textColor: CodableColor(hex: "#FED7AA"))), x: 575, y: 285, width: 200, height: 50, zIndex: 7),
                CanvasElement(name: "P2 Title", payload: .text(TextContent(text: "Sub-ms Metal Pipelines", fontFamily: "Playfair Display", fontSize: 24, fontWeight: 800, alignment: .left, textColor: .white)), x: 575, y: 345, width: 310, height: 35, zIndex: 8),
                CanvasElement(name: "P2 Body", payload: .text(TextContent(text: "Unlocking 120 FPS ProMotion rendering directly on unified Apple Silicon GPU memory.", fontFamily: "Georgia", fontSize: 15, alignment: .left, textColor: CodableColor(hex: "#FED7AA"), lineSpacing: 6)), x: 575, y: 395, width: 310, height: 200, zIndex: 9),

                CanvasElement(name: "P3 Box", payload: .shape(ShapeContent(kind: .roundedRectangle, cornerRadius: 10, fill: FillStyle.solid(CodableColor(hex: "#9A3412")))), x: 960, y: 250, width: 380, height: 520, zIndex: 10),
                CanvasElement(name: "P3 Num", payload: .text(TextContent(text: "03", fontFamily: "Impact", fontSize: 44, fontWeight: 900, alignment: .left, textColor: CodableColor(hex: "#FED7AA"))), x: 995, y: 285, width: 200, height: 50, zIndex: 11),
                CanvasElement(name: "P3 Title", payload: .text(TextContent(text: "Tactile Paper Physics", fontFamily: "Playfair Display", fontSize: 24, fontWeight: 800, alignment: .left, textColor: .white)), x: 995, y: 345, width: 310, height: 35, zIndex: 12),
                CanvasElement(name: "P3 Body", payload: .text(TextContent(text: "Bringing warmth, woodcut press aesthetics, and human touch back into digital workspaces.", fontFamily: "Georgia", fontSize: 15, alignment: .left, textColor: CodableColor(hex: "#FED7AA"), lineSpacing: 6)), x: 995, y: 395, width: 310, height: 200, zIndex: 13),

                CanvasElement(name: "P4 Box", payload: .shape(ShapeContent(kind: .roundedRectangle, cornerRadius: 10, fill: FillStyle.solid(CodableColor(hex: "#9A3412")))), x: 1380, y: 250, width: 380, height: 520, zIndex: 14),
                CanvasElement(name: "P4 Num", payload: .text(TextContent(text: "04", fontFamily: "Impact", fontSize: 44, fontWeight: 900, alignment: .left, textColor: CodableColor(hex: "#FED7AA"))), x: 1415, y: 285, width: 200, height: 50, zIndex: 15),
                CanvasElement(name: "P4 Title", payload: .text(TextContent(text: "Global Ecosystem", fontFamily: "Playfair Display", fontSize: 24, fontWeight: 800, alignment: .left, textColor: .white)), x: 1415, y: 345, width: 310, height: 35, zIndex: 16),
                CanvasElement(name: "P4 Body", payload: .text(TextContent(text: "Building community template repositories, live pairing, and extensible Swift plugins.", fontFamily: "Georgia", fontSize: 15, alignment: .left, textColor: CodableColor(hex: "#FED7AA"), lineSpacing: 6)), x: 1415, y: 395, width: 310, height: 200, zIndex: 17)
            ]
        )

        // Slide 3: Pillar 1 & 2 Performance & Speed
        let slide3 = CanvasPage(
            name: "Slide 3: Speed & Architecture",
            width: 1920, height: 1080,
            background: FillStyle.solid(CodableColor(hex: "#C2410C")),
            elements: [
                CanvasElement(name: "Tag", payload: .text(TextContent(text: "PILLAR 01 • RAW SPEED & ARCHITECTURE", fontFamily: "Inter", fontSize: 14, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#FED7AA"), letterSpacing: 3)), x: 120, y: 100, width: 600, height: 25, zIndex: 0),
                CanvasElement(name: "Title", payload: .text(TextContent(text: "Zero-Lag Creativity: 120 FPS Direct Rendering", fontFamily: "Playfair Display", fontSize: 54, fontWeight: 900, alignment: .left, textColor: .white)), x: 120, y: 135, width: 1400, height: 70, zIndex: 1),
                // 2 Huge Stat Cards
                CanvasElement(name: "Stat 1", payload: .shape(ShapeContent(kind: .roundedRectangle, cornerRadius: 12, fill: FillStyle.solid(CodableColor(hex: "#9A3412")))), x: 120, y: 250, width: 800, height: 550, zIndex: 2),
                CanvasElement(name: "S1 Stat", payload: .text(TextContent(text: "120 FPS", fontFamily: "Inter", fontSize: 80, fontWeight: 900, alignment: .left, textColor: .white)), x: 160, y: 290, width: 720, height: 95, zIndex: 3),
                CanvasElement(name: "S1 Sub", payload: .text(TextContent(text: "NATIVE PROMOTION REFRESH RATE", fontFamily: "SF Mono", fontSize: 14, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#FED7AA"), letterSpacing: 2)), x: 160, y: 390, width: 720, height: 25, zIndex: 4),
                CanvasElement(name: "S1 Desc", payload: .text(TextContent(text: "Every pan, zoom, element drag, and bezier curve adjustment completes within an 8.3-millisecond frame deadline without dropping frames.", fontFamily: "Georgia", fontSize: 17, alignment: .left, textColor: .white, lineSpacing: 8)), x: 160, y: 440, width: 720, height: 200, zIndex: 5),

                CanvasElement(name: "Stat 2", payload: .shape(ShapeContent(kind: .roundedRectangle, cornerRadius: 12, fill: FillStyle.solid(CodableColor(hex: "#9A3412")))), x: 1000, y: 250, width: 800, height: 550, zIndex: 6),
                CanvasElement(name: "S2 Stat", payload: .text(TextContent(text: "40 MB", fontFamily: "Inter", fontSize: 80, fontWeight: 900, alignment: .left, textColor: .white)), x: 1040, y: 290, width: 720, height: 95, zIndex: 7),
                CanvasElement(name: "S2 Sub", payload: .text(TextContent(text: "BASE MEMORY FOOTPRINT", fontFamily: "SF Mono", fontSize: 14, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#FED7AA"), letterSpacing: 2)), x: 1040, y: 390, width: 720, height: 25, zIndex: 8),
                CanvasElement(name: "S2 Desc", payload: .text(TextContent(text: "99% reduction in memory overhead compared to web-based platforms, eliminating battery drain and keeping laptop fans silent all day.", fontFamily: "Georgia", fontSize: 17, alignment: .left, textColor: .white, lineSpacing: 8)), x: 1040, y: 440, width: 720, height: 200, zIndex: 9)
            ]
        )

        // Slide 4: Pillar 3 Tactile System & Vision AI
        let slide4 = CanvasPage(
            name: "Slide 4: Tactile & Vision Systems",
            width: 1920, height: 1080,
            background: FillStyle.solid(CodableColor(hex: "#C2410C")),
            elements: [
                CanvasElement(name: "Tag", payload: .text(TextContent(text: "PILLAR 02 • THE TACTILE SYSTEM", fontFamily: "Inter", fontSize: 14, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#FED7AA"), letterSpacing: 3)), x: 120, y: 100, width: 600, height: 25, zIndex: 0),
                CanvasElement(name: "Title", payload: .text(TextContent(text: "Software That Feels Like Physical Paper", fontFamily: "Playfair Display", fontSize: 54, fontWeight: 900, alignment: .left, textColor: .white)), x: 120, y: 135, width: 1400, height: 70, zIndex: 1),
                // 3 Feature Cards
                CanvasElement(name: "F1", payload: .shape(ShapeContent(kind: .roundedRectangle, cornerRadius: 10, fill: FillStyle.solid(CodableColor(hex: "#9A3412")))), x: 120, y: 250, width: 520, height: 550, zIndex: 2),
                CanvasElement(name: "F1 Title", payload: .text(TextContent(text: "1. CoreText WYSIWYG", fontFamily: "Inter", fontSize: 24, fontWeight: 800, alignment: .left, textColor: .white)), x: 155, y: 290, width: 450, height: 35, zIndex: 3),
                CanvasElement(name: "F1 Body", payload: .text(TextContent(text: "Direct integration with macOS typography subsystem ensures zero font jumps between in-place editing and fullscreen presentation.", fontFamily: "Georgia", fontSize: 16, alignment: .left, textColor: CodableColor(hex: "#FED7AA"), lineSpacing: 6)), x: 155, y: 340, width: 450, height: 200, zIndex: 4),

                CanvasElement(name: "F2", payload: .shape(ShapeContent(kind: .roundedRectangle, cornerRadius: 10, fill: FillStyle.solid(CodableColor(hex: "#9A3412")))), x: 700, y: 250, width: 520, height: 550, zIndex: 5),
                CanvasElement(name: "F2 Title", payload: .text(TextContent(text: "2. Offline Vision AI", fontFamily: "Inter", fontSize: 24, fontWeight: 800, alignment: .left, textColor: .white)), x: 735, y: 290, width: 450, height: 35, zIndex: 6),
                CanvasElement(name: "F2 Body", payload: .text(TextContent(text: "Instant background removal powered by Apple Neural Engine in 0.1 seconds without cloud connectivity or subscription fees.", fontFamily: "Georgia", fontSize: 16, alignment: .left, textColor: CodableColor(hex: "#FED7AA"), lineSpacing: 6)), x: 735, y: 340, width: 450, height: 200, zIndex: 7),

                CanvasElement(name: "F3", payload: .shape(ShapeContent(kind: .roundedRectangle, cornerRadius: 10, fill: FillStyle.solid(CodableColor(hex: "#9A3412")))), x: 1280, y: 250, width: 520, height: 550, zIndex: 8),
                CanvasElement(name: "F3 Title", payload: .text(TextContent(text: "3. Vector Export", fontFamily: "Inter", fontSize: 24, fontWeight: 800, alignment: .left, textColor: .white)), x: 1315, y: 290, width: 450, height: 35, zIndex: 9),
                CanvasElement(name: "F3 Body", payload: .text(TextContent(text: "Generate lossless vector PDFs and clean SVG assets ready for professional letterpress, offset printing, and mobile development.", fontFamily: "Georgia", fontSize: 16, alignment: .left, textColor: CodableColor(hex: "#FED7AA"), lineSpacing: 6)), x: 1315, y: 340, width: 450, height: 200, zIndex: 10)
            ]
        )

        // Slide 5: The Call to Action & Conclusion
        let slide5 = CanvasPage(
            name: "Slide 5: The Next Chapter",
            width: 1920, height: 1080,
            background: FillStyle.solid(CodableColor(hex: "#C2410C")),
            elements: [
                CanvasElement(name: "Tag", payload: .text(TextContent(text: "STRATEGIC HORIZONS • THE NEXT CHAPTER", fontFamily: "Inter", fontSize: 14, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#FED7AA"), letterSpacing: 3)), x: 120, y: 100, width: 600, height: 25, zIndex: 0),
                CanvasElement(name: "Title", payload: .text(TextContent(text: "Join Us in Building the Native Craft Era", fontFamily: "Playfair Display", fontSize: 54, fontWeight: 900, alignment: .left, textColor: .white)), x: 120, y: 135, width: 1400, height: 70, zIndex: 1),
                // Closing Callout Card
                CanvasElement(name: "Card", payload: .shape(ShapeContent(kind: .roundedRectangle, cornerRadius: 12, fill: FillStyle.solid(CodableColor(hex: "#9A3412")))), x: 120, y: 250, width: 1680, height: 440, zIndex: 2),
                CanvasElement(name: "Card Headline", payload: .text(TextContent(text: "“When creation software becomes instantaneous, the distance between human imagination and the canvas disappears entirely.”", fontFamily: "Playfair Display", fontSize: 32, fontWeight: 700, isItalic: true, alignment: .center, textColor: .white, lineSpacing: 10)), x: 180, y: 320, width: 1560, height: 150, zIndex: 3),
                CanvasElement(name: "Card Sub", payload: .text(TextContent(text: "GET STARTED TODAY • TECHNIART.APP • OPEN SOURCE CORE", fontFamily: "Inter", fontSize: 16, fontWeight: 900, alignment: .center, textColor: CodableColor(hex: "#FED7AA"), letterSpacing: 3)), x: 180, y: 520, width: 1560, height: 30, zIndex: 4),
                // Thank you
                CanvasElement(name: "Thank You", payload: .text(TextContent(text: "THANK YOU • alexander@techniart.app", fontFamily: "SF Mono", fontSize: 14, fontWeight: 700, alignment: .center, textColor: .white, letterSpacing: 2)), x: 120, y: 740, width: 1680, height: 25, zIndex: 5)
            ]
        )

        return CanvasTemplate(
            id: "product_vision",
            title: "Product Vision Keynote (5 Slides)",
            category: "Presentations & Screens",
            docType: .presentation,
            themeName: "Terracotta Modern",
            preset: CanvasPreset.presets[7],
            pages: [slide1, slide2, slide3, slide4, slide5],
            previewColorHex: "#C2410C"
        )
    }

    // =========================================================================
    // MARK: - 2. MULTI-PAGE A4 TEMPLATES
    // =========================================================================

    public static func createRetroNewspaperTemplate() -> CanvasTemplate {
        let page1 = CanvasPage(
            name: "Page 1: Front Page",
            width: 1240, height: 1754,
            background: FillStyle(type: .newsprint, solidColor: CodableColor(hex: "#F5F2EB")),
            elements: [
                CanvasElement(name: "Top Rule", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(.inkBlack))), x: 60, y: 50, width: 1120, height: 4, zIndex: 0),
                CanvasElement(name: "Top Thin Rule", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(.inkBlack))), x: 60, y: 58, width: 1120, height: 1.5, zIndex: 1),
                CanvasElement(name: "Ear Left", payload: .text(TextContent(text: "VOL. CVI • NO. 38,419\nWEATHER: CRISP & FAST", fontFamily: "Georgia", fontSize: 11, fontWeight: 700, alignment: .left, textColor: .inkBlack, lineSpacing: 2)), x: 60, y: 68, width: 240, height: 32, zIndex: 2),
                CanvasElement(name: "Ear Right", payload: .text(TextContent(text: "PRICE FIVE CENTS\nPAY NO MORE", fontFamily: "Georgia", fontSize: 11, fontWeight: 700, alignment: .right, textColor: .inkBlack, lineSpacing: 2)), x: 940, y: 68, width: 240, height: 32, zIndex: 3),
                CanvasElement(name: "Masthead Title", payload: .text(TextContent(text: "THE DAILY DISPATCH", fontFamily: "Playfair Display", fontSize: 84, fontWeight: 900, alignment: .center, textColor: .inkBlack, letterSpacing: 4.0)), x: 60, y: 105, width: 1120, height: 95, zIndex: 4),
                CanvasElement(name: "Masthead Subtitle", payload: .text(TextContent(text: "THE INDEPENDENT JOURNAL OF GRAPHICS & CRAFTSMANSHIP • ESTABLISHED 1924", fontFamily: "Georgia", fontSize: 11, fontWeight: 700, alignment: .center, textColor: .inkBlack, letterSpacing: 2.0)), x: 60, y: 205, width: 1120, height: 20, zIndex: 5),
                CanvasElement(name: "Banner Rule", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(.inkBlack))), x: 60, y: 230, width: 1120, height: 2.5, zIndex: 6),
                CanvasElement(name: "Lead Headline", payload: .text(TextContent(text: "HIGH-SPEED NATIVE ENGINE REVOLUTIONIZES CRAFT", fontFamily: "Playfair Display", fontSize: 48, fontWeight: 900, alignment: .center, textColor: .inkBlack, lineSpacing: 3.0)), x: 60, y: 250, width: 1120, height: 115, zIndex: 7),
                CanvasElement(name: "Headline Deck", payload: .text(TextContent(text: "Ultra-Lightweight 40MB Memory Subsystem Leaves Web Browsers Stunned Across The Globe", fontFamily: "Georgia", fontSize: 17, fontWeight: 500, isItalic: true, alignment: .center, textColor: CodableColor(hex: "#44403C"))), x: 120, y: 370, width: 1000, height: 35, zIndex: 8),
                CanvasElement(name: "Col 1 Body", payload: .text(TextContent(text: "SAN FRANCISCO — Today marks the dawn of a new generation in digital creation tools. In an era where modern applications consume immense memory, Pluma proves that uncompromising speed and tactile beauty can coexist seamlessly.\n\nEvery stroke renders with sub-millisecond latency directly to Apple Silicon hardware, ensuring smooth 120 FPS ProMotion fidelity without a single dropped frame.", fontFamily: "Georgia", fontSize: 14.0, alignment: .left, textColor: .inkBlack, lineSpacing: 5.5)), x: 60, y: 430, width: 540, height: 260, zIndex: 9),
                CanvasElement(name: "Col Divider", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#D6D3CD")))), x: 620, y: 430, width: 1.0, height: 380, zIndex: 10),
                CanvasElement(name: "Col 2 Body", payload: .text(TextContent(text: "TACTILE CRAFTSMANSHIP\n\nUnlike virtualized browsers, every typography element and vector path utilizes native AppKit CoreText rendering.\n\nFrom antique woodblock press posters to modern multi-page documents, the artisan tactile grain brings physical paper warmth to your screen.", fontFamily: "Georgia", fontSize: 14.0, alignment: .left, textColor: .inkBlack, lineSpacing: 5.5)), x: 640, y: 430, width: 540, height: 260, zIndex: 11)
            ]
        )

        let page2 = CanvasPage(
            name: "Page 2: Editorial & Arts",
            width: 1240, height: 1754,
            background: FillStyle(type: .newsprint, solidColor: CodableColor(hex: "#F5F2EB")),
            elements: [
                CanvasElement(name: "Page Header Rule", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(.inkBlack))), x: 60, y: 50, width: 1120, height: 2, zIndex: 0),
                CanvasElement(name: "Page 2 Header", payload: .text(TextContent(text: "SECTION TWO • ARTS, TYPOGRAPHY & ESSAYS • PAGE 2", fontFamily: "Georgia", fontSize: 11, fontWeight: 700, alignment: .center, textColor: .inkBlack, letterSpacing: 2.5)), x: 60, y: 58, width: 1120, height: 20, zIndex: 1),
                CanvasElement(name: "Section Headline", payload: .text(TextContent(text: "THE ANATOMY OF TACTILE DIGITAL SURFACES", fontFamily: "Playfair Display", fontSize: 42, fontWeight: 900, alignment: .left, textColor: .inkBlack)), x: 60, y: 110, width: 1120, height: 60, zIndex: 2)
            ]
        )

        let page3 = CanvasPage(
            name: "Page 3: Market & Classifieds",
            width: 1240, height: 1754,
            background: FillStyle(type: .newsprint, solidColor: CodableColor(hex: "#F5F2EB")),
            elements: [
                CanvasElement(name: "Page Header Rule", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(.inkBlack))), x: 60, y: 50, width: 1120, height: 2, zIndex: 0),
                CanvasElement(name: "Page 3 Header", payload: .text(TextContent(text: "SECTION THREE • FINANCIAL DISPATCH & CLASSIFIED DIRECTORY", fontFamily: "Georgia", fontSize: 11, fontWeight: 700, alignment: .center, textColor: .inkBlack, letterSpacing: 2.5)), x: 60, y: 58, width: 1120, height: 20, zIndex: 1)
            ]
        )

        return CanvasTemplate(
            id: "retro_newspaper",
            title: "The Daily Chronicle (3 Pages)",
            category: "Print & Documents",
            docType: .a4,
            themeName: "Vintage Paper",
            preset: CanvasPreset.presets[10],
            pages: [page1, page2, page3],
            previewColorHex: "#D97706"
        )
    }

    public static func createMetropolitanBroadsheetTemplate() -> CanvasTemplate {
        let page1 = CanvasPage(
            name: "Page 1: Front Page",
            width: 1240, height: 1754,
            background: FillStyle(type: .newsprint, solidColor: CodableColor(hex: "#F4F0E8")),
            elements: [
                CanvasElement(name: "Top Thick Rule", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(.inkBlack))), x: 60, y: 45, width: 1120, height: 4, zIndex: 0),
                CanvasElement(name: "Top Thin Rule", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(.inkBlack))), x: 60, y: 53, width: 1120, height: 1, zIndex: 1),
                CanvasElement(name: "Left Weather Box", payload: .text(TextContent(text: "EDITION: NATIVE ALPHA\nTEMP: 68°F • CLEAR SKIES", fontFamily: "Georgia", fontSize: 10, fontWeight: 700, alignment: .left, textColor: .inkBlack, lineSpacing: 2)), x: 60, y: 64, width: 240, height: 32, zIndex: 2),
                CanvasElement(name: "Right Price Box", payload: .text(TextContent(text: "CIRCULATION 250,000\nPRICE: 10 CENTS", fontFamily: "Georgia", fontSize: 10, fontWeight: 700, alignment: .right, textColor: .inkBlack, lineSpacing: 2)), x: 940, y: 64, width: 240, height: 32, zIndex: 3),
                CanvasElement(name: "Masthead Title", payload: .text(TextContent(text: "THE METROPOLITAN HERALD", fontFamily: "Playfair Display", fontSize: 76, fontWeight: 900, alignment: .center, textColor: .inkBlack, letterSpacing: 3)), x: 60, y: 96, width: 1120, height: 90, zIndex: 4),
                CanvasElement(name: "Lead Headline", payload: .text(TextContent(text: "HARDWARE REVOLUTION:\nTHE RETURN OF INSTANT SPEED", fontFamily: "Playfair Display", fontSize: 54, fontWeight: 900, alignment: .left, textColor: .inkBlack, lineSpacing: 2)), x: 60, y: 240, width: 780, height: 130, zIndex: 5)
            ]
        )

        let page2 = CanvasPage(
            name: "Page 2: Deep Dive",
            width: 1240, height: 1754,
            background: FillStyle(type: .newsprint, solidColor: CodableColor(hex: "#F4F0E8")),
            elements: [
                CanvasElement(name: "Header Rule", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(.inkBlack))), x: 60, y: 50, width: 1120, height: 2, zIndex: 0),
                CanvasElement(name: "Page 2 Header", payload: .text(TextContent(text: "SECTION TWO • SYSTEMS ARCHITECTURE & GRAPHICS BENCHMARKS", fontFamily: "Georgia", fontSize: 11, fontWeight: 700, alignment: .center, textColor: .inkBlack, letterSpacing: 2)), x: 60, y: 58, width: 1120, height: 20, zIndex: 1)
            ]
        )

        let page3 = CanvasPage(
            name: "Page 3: Colophon",
            width: 1240, height: 1754,
            background: FillStyle(type: .newsprint, solidColor: CodableColor(hex: "#F4F0E8")),
            elements: [
                CanvasElement(name: "Colophon Header", payload: .text(TextContent(text: "METROPOLITAN HERALD ARCHIVE • EST. 1924", fontFamily: "Georgia", fontSize: 14, fontWeight: 800, alignment: .center, textColor: .inkBlack, letterSpacing: 3)), x: 60, y: 80, width: 1120, height: 30, zIndex: 0)
            ]
        )

        return CanvasTemplate(
            id: "metropolitan_broadsheet",
            title: "The Metropolitan Broadsheet (3 Pages)",
            category: "Print & Documents",
            docType: .a4,
            themeName: "Vintage Paper",
            preset: CanvasPreset.presets[10],
            pages: [page1, page2, page3],
            previewColorHex: "#D97706"
        )
    }

    public static func createHauteCoutureLookbookTemplate() -> CanvasTemplate {
        let page1 = CanvasPage(
            name: "Page 1: Cover",
            width: 1240, height: 1754,
            background: FillStyle(type: .vintageParchment, solidColor: CodableColor(hex: "#FAF8F5")),
            elements: [
                CanvasElement(name: "Outer Border", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(.clear), stroke: StrokeStyle(isEnabled: true, color: CodableColor(hex: "#C2410C"), lineWidth: 1.5))), x: 50, y: 50, width: 1140, height: 1654, zIndex: 0),
                CanvasElement(name: "Headline", payload: .text(TextContent(text: "L’ÉLÉGANCE DU CRAFT", fontFamily: "Playfair Display", fontSize: 68, fontWeight: 800, alignment: .center, textColor: .inkBlack, letterSpacing: 6)), x: 100, y: 140, width: 1040, height: 85, zIndex: 1)
            ]
        )

        let page2 = CanvasPage(
            name: "Page 2: Mood & Manifesto",
            width: 1240, height: 1754,
            background: FillStyle(type: .vintageParchment, solidColor: CodableColor(hex: "#FAF8F5")),
            elements: [
                CanvasElement(name: "Manifesto Title", payload: .text(TextContent(text: "THE MANIFESTO OF PROPORTION", fontFamily: "Playfair Display", fontSize: 38, fontWeight: 800, alignment: .center, textColor: .inkBlack, letterSpacing: 3)), x: 100, y: 120, width: 1040, height: 50, zIndex: 0)
            ]
        )

        let page3 = CanvasPage(
            name: "Page 3: Collection Index",
            width: 1240, height: 1754,
            background: FillStyle(type: .vintageParchment, solidColor: CodableColor(hex: "#FAF8F5")),
            elements: [
                CanvasElement(name: "Index Title", payload: .text(TextContent(text: "GARMENT INDEX • AUTUMN 2026", fontFamily: "Inter", fontSize: 14, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#C2410C"), letterSpacing: 3)), x: 100, y: 100, width: 800, height: 30, zIndex: 0)
            ]
        )

        let page4 = CanvasPage(
            name: "Page 4: Colophon",
            width: 1240, height: 1754,
            background: FillStyle(type: .vintageParchment, solidColor: CodableColor(hex: "#FAF8F5")),
            elements: [
                CanvasElement(name: "Colophon", payload: .text(TextContent(text: "ATELIER TECHNIART • PARIS / SAN FRANCISCO", fontFamily: "Inter", fontSize: 12, fontWeight: 700, alignment: .center, textColor: .inkBlack, letterSpacing: 4)), x: 100, y: 800, width: 1040, height: 30, zIndex: 0)
            ]
        )

        return CanvasTemplate(
            id: "haute_couture_lookbook",
            title: "Haute Couture Editorial (4 Pages)",
            category: "Print & Documents",
            docType: .a4,
            themeName: "Artisan Paper",
            preset: CanvasPreset.presets[10],
            pages: [page1, page2, page3, page4],
            previewColorHex: "#C2410C"
        )
    }

    public static func createVCInvestmentMemoTemplate() -> CanvasTemplate {
        let page1 = CanvasPage(
            name: "Page 1: Executive Summary",
            width: 1240, height: 1754,
            background: FillStyle.solid(CodableColor(hex: "#09090B")),
            elements: [
                CanvasElement(name: "Confidential Pill", payload: .shape(ShapeContent(kind: .roundedRectangle, cornerRadius: 4, fill: FillStyle.solid(CodableColor(hex: "#D97706", opacity: 0.2)))), x: 80, y: 80, width: 220, height: 30, zIndex: 0),
                CanvasElement(name: "Confidential Text", payload: .text(TextContent(text: "STRICTLY CONFIDENTIAL", fontFamily: "SF Mono", fontSize: 10.5, fontWeight: 800, alignment: .center, textColor: CodableColor(hex: "#F59E0B"), letterSpacing: 1.5)), x: 80, y: 87, width: 220, height: 18, zIndex: 1),
                CanvasElement(name: "Memo Title", payload: .text(TextContent(text: "Series A: Pluma Engine", fontFamily: "Inter", fontSize: 44, fontWeight: 900, alignment: .left, textColor: .white)), x: 80, y: 130, width: 1080, height: 55, zIndex: 2),
                CanvasElement(name: "Card 1", payload: .shape(ShapeContent(kind: .roundedRectangle, cornerRadius: 8, fill: FillStyle.solid(CodableColor(hex: "#18181B")), stroke: StrokeStyle(isEnabled: true, color: CodableColor(hex: "#27272A"), lineWidth: 1))), x: 80, y: 240, width: 340, height: 130, zIndex: 3),
                CanvasElement(name: "Val 1", payload: .text(TextContent(text: "$18.0M", fontFamily: "Inter", fontSize: 34, fontWeight: 900, alignment: .left, textColor: CodableColor(hex: "#38BDF8"))), x: 105, y: 260, width: 290, height: 40, zIndex: 4),
                CanvasElement(name: "Card 2", payload: .shape(ShapeContent(kind: .roundedRectangle, cornerRadius: 8, fill: FillStyle.solid(CodableColor(hex: "#18181B")), stroke: StrokeStyle(isEnabled: true, color: CodableColor(hex: "#27272A"), lineWidth: 1))), x: 450, y: 240, width: 340, height: 130, zIndex: 5),
                CanvasElement(name: "Val 2", payload: .text(TextContent(text: "$95M", fontFamily: "Inter", fontSize: 34, fontWeight: 900, alignment: .left, textColor: CodableColor(hex: "#34D399"))), x: 475, y: 260, width: 290, height: 40, zIndex: 6),
                CanvasElement(name: "Card 3", payload: .shape(ShapeContent(kind: .roundedRectangle, cornerRadius: 8, fill: FillStyle.solid(CodableColor(hex: "#18181B")), stroke: StrokeStyle(isEnabled: true, color: CodableColor(hex: "#27272A"), lineWidth: 1))), x: 820, y: 240, width: 340, height: 130, zIndex: 7),
                CanvasElement(name: "Val 3", payload: .text(TextContent(text: "420% YoY", fontFamily: "Inter", fontSize: 34, fontWeight: 900, alignment: .left, textColor: CodableColor(hex: "#F472B6"))), x: 845, y: 260, width: 290, height: 40, zIndex: 8)
            ]
        )

        let page2 = CanvasPage(
            name: "Page 2: Technology Moat",
            width: 1240, height: 1754,
            background: FillStyle.solid(CodableColor(hex: "#09090B")),
            elements: [
                CanvasElement(name: "Moat Header", payload: .text(TextContent(text: "2. TECHNICAL MOAT & BENCHMARKS", fontFamily: "SF Mono", fontSize: 13, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#38BDF8"), letterSpacing: 1.5)), x: 80, y: 80, width: 800, height: 25, zIndex: 0)
            ]
        )

        let page3 = CanvasPage(
            name: "Page 3: Cap Table",
            width: 1240, height: 1754,
            background: FillStyle.solid(CodableColor(hex: "#09090B")),
            elements: [
                CanvasElement(name: "Funds Header", payload: .text(TextContent(text: "3. USE OF FUNDS & MILESTONES", fontFamily: "SF Mono", fontSize: 13, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#38BDF8"), letterSpacing: 1.5)), x: 80, y: 80, width: 800, height: 25, zIndex: 0)
            ]
        )

        return CanvasTemplate(
            id: "vc_investment_memo",
            title: "VC Investment Memo (3 Pages)",
            category: "Print & Documents",
            docType: .a4,
            themeName: "Dark Studio",
            preset: CanvasPreset.presets[10],
            pages: [page1, page2, page3],
            previewColorHex: "#09090B"
        )
    }

    public static func createBauhausReviewTemplate() -> CanvasTemplate {
        let page1 = CanvasPage(
            name: "Page 1: Cover",
            width: 1240, height: 1754,
            background: FillStyle.solid(CodableColor(hex: "#FDFBF7")),
            elements: [
                CanvasElement(name: "Top Block", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#C2410C")))), x: 60, y: 60, width: 1120, height: 240, zIndex: 0),
                CanvasElement(name: "Bauhaus Number", payload: .text(TextContent(text: "01", fontFamily: "Impact", fontSize: 120, fontWeight: 900, alignment: .left, textColor: CodableColor(hex: "#FED7AA"))), x: 90, y: 90, width: 200, height: 140, zIndex: 1),
                CanvasElement(name: "Bauhaus Title", payload: .text(TextContent(text: "FORM FOLLOWS\nFUNCTION & SPEED", fontFamily: "Playfair Display", fontSize: 48, fontWeight: 900, alignment: .left, textColor: .white, lineSpacing: 2)), x: 290, y: 105, width: 850, height: 130, zIndex: 2)
            ]
        )

        let page2 = CanvasPage(
            name: "Page 2: Spatial Theory",
            width: 1240, height: 1754,
            background: FillStyle.solid(CodableColor(hex: "#FDFBF7")),
            elements: [
                CanvasElement(name: "Theory Title", payload: .text(TextContent(text: "SPATIAL PROPORTIONS & GRID MATRICES", fontFamily: "Playfair Display", fontSize: 36, fontWeight: 900, alignment: .left, textColor: .inkBlack)), x: 60, y: 80, width: 1120, height: 50, zIndex: 0)
            ]
        )

        let page3 = CanvasPage(
            name: "Page 3: Colophon",
            width: 1240, height: 1754,
            background: FillStyle.solid(CodableColor(hex: "#FDFBF7")),
            elements: [
                CanvasElement(name: "Colophon", payload: .text(TextContent(text: "BAUHAUS DESIGN ARCHIVE • 2026 EDITION", fontFamily: "Inter", fontSize: 13, fontWeight: 800, alignment: .center, textColor: CodableColor(hex: "#C2410C"), letterSpacing: 3)), x: 60, y: 800, width: 1120, height: 30, zIndex: 0)
            ]
        )

        return CanvasTemplate(
            id: "bauhaus_review",
            title: "Bauhaus Design Review (3 Pages)",
            category: "Print & Documents",
            docType: .a4,
            themeName: "Terracotta Modern",
            preset: CanvasPreset.presets[10],
            pages: [page1, page2, page3],
            previewColorHex: "#C2410C"
        )
    }

    public static func createLetterpressPosterTemplate() -> CanvasTemplate {
        let page = CanvasPage(
            name: "Artisan Letterpress Broadside",
            width: 1240, height: 1754,
            background: FillStyle(type: .vintageParchment, solidColor: CodableColor(hex: "#FAF7F0")),
            elements: [
                CanvasElement(name: "Outer Border", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(.clear), stroke: StrokeStyle(isEnabled: true, color: .inkBlack, lineWidth: 6))), x: 40, y: 40, width: 1160, height: 1674, zIndex: 0),
                CanvasElement(name: "Inner Thin Border", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(.clear), stroke: StrokeStyle(isEnabled: true, color: .inkBlack, lineWidth: 1.5))), x: 52, y: 52, width: 1136, height: 1650, zIndex: 1),
                CanvasElement(name: "Header Top", payload: .text(TextContent(text: "ESTABLISHED MCMXXIV • HAND-PULLED PRINTS", fontFamily: "Georgia", fontSize: 14, fontWeight: 700, alignment: .center, textColor: CodableColor(hex: "#C2410C"), letterSpacing: 4.0)), x: 100, y: 100, width: 1040, height: 30, zIndex: 2),
                CanvasElement(name: "Main Woodcut Title", payload: .text(TextContent(text: "CRAFT\nOVER\nBLOAT", fontFamily: "Playfair Display", fontSize: 130, fontWeight: 900, alignment: .center, textColor: .inkBlack, letterSpacing: 6.0, lineSpacing: -10.0)), x: 100, y: 180, width: 1040, height: 420, zIndex: 3),
                CanvasElement(name: "Wax Seal Badge", payload: .shape(ShapeContent(kind: .circle, fill: FillStyle.solid(CodableColor(hex: "#C2410C")), stroke: StrokeStyle(isEnabled: true, color: .white, lineWidth: 2))), x: 560, y: 640, width: 120, height: 120, shadow: ShadowEffect.elevated, zIndex: 4),
                CanvasElement(name: "Seal Text", payload: .text(TextContent(text: "120\nFPS", fontFamily: "Playfair Display", fontSize: 22, fontWeight: 900, alignment: .center, textColor: .white)), x: 570, y: 672, width: 100, height: 60, zIndex: 5),
                CanvasElement(name: "Manifesto Text", payload: .text(TextContent(text: "When every pixel is drawn with intention rather than rendered through layers of virtualized browsers, software feels like artisan craftsmanship once again.", fontFamily: "Georgia", fontSize: 22, fontWeight: 400, isItalic: true, alignment: .center, textColor: CodableColor(hex: "#292524"), lineSpacing: 8.0)), x: 180, y: 840, width: 880, height: 160, zIndex: 6)
            ]
        )

        return CanvasTemplate(
            id: "letterpress_poster",
            title: "Artisan Broadside Poster",
            category: "Print & Documents",
            docType: .a4,
            themeName: "Artisan Paper",
            preset: CanvasPreset.presets[10],
            page: page,
            previewColorHex: "#C2410C"
        )
    }

    public static func createMinimalistResumeTemplate() -> CanvasTemplate {
        let page = CanvasPage(
            name: "Minimalist Tech Résumé",
            width: 1240, height: 1754,
            background: FillStyle.solid(CodableColor(hex: "#FFFFFF")),
            elements: [
                CanvasElement(name: "Full Name", payload: .text(TextContent(text: "ALEXANDER CHEN", fontFamily: "Playfair Display", fontSize: 42, fontWeight: 800, alignment: .left, textColor: .inkBlack, letterSpacing: 2)), x: 100, y: 100, width: 700, height: 60, zIndex: 0),
                CanvasElement(name: "Title Subheader", payload: .text(TextContent(text: "STAFF SOFTWARE ARCHITECT • SYSTEMS & GRAPHICS", fontFamily: "Inter", fontSize: 13, fontWeight: 600, alignment: .left, textColor: CodableColor(hex: "#C2410C"), letterSpacing: 1.5)), x: 100, y: 165, width: 800, height: 25, zIndex: 1),
                CanvasElement(name: "Header Line", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#E5E7EB")))), x: 100, y: 205, width: 1040, height: 1.5, zIndex: 2),
                CanvasElement(name: "Summary Header", payload: .text(TextContent(text: "EXPERIENCE", fontFamily: "Inter", fontSize: 14, fontWeight: 800, alignment: .left, textColor: .inkBlack, letterSpacing: 1)), x: 100, y: 240, width: 300, height: 30, zIndex: 3),
                CanvasElement(name: "Job 1 Title", payload: .text(TextContent(text: "Lead Graphics Engineer — Pluma Studios", fontFamily: "Inter", fontSize: 16, fontWeight: 700, alignment: .left, textColor: .inkBlack)), x: 100, y: 280, width: 600, height: 25, zIndex: 4),
                CanvasElement(name: "Job 1 Date", payload: .text(TextContent(text: "2023 — PRESENT • SAN FRANCISCO, CA", fontFamily: "Inter", fontSize: 11, fontWeight: 500, alignment: .left, textColor: CodableColor(hex: "#6B7280"))), x: 100, y: 310, width: 400, height: 20, zIndex: 5),
                CanvasElement(name: "Job 1 Bullets", payload: .text(TextContent(text: "• Architected high-performance 120 FPS Metal canvas rendering engine with <40MB RAM footprint.\n• Built zero-jump in-place WYSIWYG typography editor using unified AppKit CoreText subsystem.\n• Implemented offline machine-learning background segmentation using Apple Vision framework.", fontFamily: "Inter", fontSize: 13, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#374151"), lineSpacing: 6)), x: 100, y: 340, width: 1040, height: 100, zIndex: 6)
            ]
        )

        return CanvasTemplate(
            id: "minimalist_resume",
            title: "Minimalist Tech Résumé",
            category: "Print & Documents",
            docType: .a4,
            themeName: "Modern Clean",
            preset: CanvasPreset.presets[10],
            page: page,
            previewColorHex: "#FFFFFF"
        )
    }

    public static func createNordicInvoiceTemplate() -> CanvasTemplate {
        let page = CanvasPage(
            name: "Nordic Studio Invoice",
            width: 1240, height: 1754,
            background: FillStyle.solid(CodableColor(hex: "#F8FAFC")),
            elements: [
                CanvasElement(name: "Invoice Header", payload: .text(TextContent(text: "INVOICE", fontFamily: "Inter", fontSize: 36, fontWeight: 900, alignment: .left, textColor: CodableColor(hex: "#0F172A"), letterSpacing: 2)), x: 80, y: 80, width: 400, height: 50, zIndex: 0),
                CanvasElement(name: "Invoice Number", payload: .text(TextContent(text: "INV-2026-089 • DUE UPON RECEIPT", fontFamily: "Inter", fontSize: 12, fontWeight: 600, alignment: .left, textColor: CodableColor(hex: "#64748B"))), x: 80, y: 135, width: 400, height: 25, zIndex: 1),
                CanvasElement(name: "Total Card", payload: .shape(ShapeContent(kind: .roundedRectangle, cornerRadius: 8, fill: FillStyle.solid(CodableColor(hex: "#0F172A")))), x: 860, y: 80, width: 300, height: 100, zIndex: 2),
                CanvasElement(name: "Total Label", payload: .text(TextContent(text: "TOTAL DUE", fontFamily: "Inter", fontSize: 11, fontWeight: 700, alignment: .center, textColor: CodableColor(hex: "#94A3B8"), letterSpacing: 1.5)), x: 860, y: 95, width: 300, height: 20, zIndex: 3),
                CanvasElement(name: "Total Amount", payload: .text(TextContent(text: "$8,500.00", fontFamily: "Inter", fontSize: 32, fontWeight: 900, alignment: .center, textColor: .white)), x: 860, y: 125, width: 300, height: 45, zIndex: 4)
            ]
        )

        return CanvasTemplate(
            id: "nordic_invoice",
            title: "Nordic Studio Invoice",
            category: "Print & Documents",
            docType: .a4,
            themeName: "Nordic Frost",
            preset: CanvasPreset.presets[10],
            page: page,
            previewColorHex: "#0F172A"
        )
    }

    // =========================================================================
    // MARK: - 3. INSTAGRAM / SQUARE TEMPLATES
    // =========================================================================

    public static func createPaperCollageTemplate() -> CanvasTemplate {
        let page = CanvasPage(
            name: "Tactile Paper Scrapbook",
            width: 1080, height: 1080,
            background: FillStyle(type: .vintageParchment, solidColor: CodableColor(hex: "#FAF7F0")),
            elements: [
                CanvasElement(name: "Washi Tape Top Left", payload: .shape(ShapeContent(kind: .washiTape, fill: FillStyle.solid(CodableColor(hex: "#FB923C")))), x: 80, y: 80, width: 220, height: 36, rotation: -12, zIndex: 3),
                CanvasElement(name: "Paper Card Center", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(.white), stroke: StrokeStyle(isEnabled: true, color: CodableColor(hex: "#D6D3CD"), lineWidth: 1))), x: 140, y: 140, width: 800, height: 800, rotation: 2.0, shadow: ShadowEffect.elevated, zIndex: 0),
                CanvasElement(name: "Title Quote", payload: .text(TextContent(text: "Quiet Moments & Tactile Craft", fontFamily: "Playfair Display", fontSize: 48, fontWeight: 800, alignment: .center, textColor: .inkBlack)), x: 200, y: 240, width: 680, height: 130, rotation: 2.0, zIndex: 1),
                CanvasElement(name: "Postage Stamp", payload: .shape(ShapeContent(kind: .postageStamp, fill: FillStyle.solid(CodableColor(hex: "#C2410C")))), x: 740, y: 180, width: 140, height: 180, rotation: 8.0, zIndex: 2)
            ]
        )

        return CanvasTemplate(
            id: "paper_collage",
            title: "Tactile Paper Scrapbook",
            category: "Social Media",
            docType: .square,
            themeName: "Vintage Paper",
            preset: CanvasPreset.presets[0],
            page: page,
            previewColorHex: "#D97706"
        )
    }

    public static func createVintageZineTemplate() -> CanvasTemplate {
        let page = CanvasPage(
            name: "Vintage Zine Cover",
            width: 1080, height: 1080,
            background: FillStyle(type: .newsprint, solidColor: CodableColor(hex: "#F5F2EB")),
            elements: [
                CanvasElement(name: "Issue Pill", payload: .shape(ShapeContent(kind: .roundedRectangle, cornerRadius: 16, fill: FillStyle.solid(.inkBlack))), x: 80, y: 80, width: 200, height: 40, zIndex: 0),
                CanvasElement(name: "Issue Text", payload: .text(TextContent(text: "ISSUE NO. 04", fontFamily: "Inter", fontSize: 13, fontWeight: 800, alignment: .center, textColor: .white, letterSpacing: 2)), x: 80, y: 88, width: 200, height: 24, zIndex: 1),
                CanvasElement(name: "Zine Title", payload: .text(TextContent(text: "THE\nMODERN\nARTISAN", fontFamily: "Playfair Display", fontSize: 92, fontWeight: 900, alignment: .left, textColor: .inkBlack, lineSpacing: -10)), x: 80, y: 160, width: 800, height: 320, zIndex: 2)
            ]
        )

        return CanvasTemplate(
            id: "vintage_zine",
            title: "Vintage Editorial Zine",
            category: "Social Media",
            docType: .square,
            themeName: "Artisan Paper",
            preset: CanvasPreset.presets[0],
            page: page,
            previewColorHex: "#292524"
        )
    }

    public static func createFlashSaleTemplate() -> CanvasTemplate {
        let page = CanvasPage(
            name: "Flash Sale Promo",
            width: 1080, height: 1080,
            background: FillStyle.solid(CodableColor(hex: "#C2410C")),
            elements: [
                CanvasElement(name: "Sale Header", payload: .text(TextContent(text: "LIMITED TIME DROP", fontFamily: "Inter", fontSize: 16, fontWeight: 800, alignment: .center, textColor: CodableColor(hex: "#FED7AA"), letterSpacing: 3)), x: 100, y: 120, width: 880, height: 30, zIndex: 0),
                CanvasElement(name: "Main Discount", payload: .text(TextContent(text: "50% OFF", fontFamily: "Impact", fontSize: 140, fontWeight: 900, alignment: .center, textColor: .white)), x: 100, y: 170, width: 880, height: 160, zIndex: 1),
                CanvasElement(name: "Coupon Box", payload: .shape(ShapeContent(kind: .roundedRectangle, cornerRadius: 12, fill: FillStyle.solid(.white), stroke: StrokeStyle(isEnabled: true, color: .inkBlack, lineWidth: 2))), x: 240, y: 380, width: 600, height: 80, zIndex: 2),
                CanvasElement(name: "Coupon Text", payload: .text(TextContent(text: "USE CODE: CRAFT50", fontFamily: "SF Mono", fontSize: 24, fontWeight: 900, alignment: .center, textColor: CodableColor(hex: "#C2410C"))), x: 240, y: 405, width: 600, height: 35, zIndex: 3)
            ]
        )

        return CanvasTemplate(
            id: "flash_sale",
            title: "Flash Sale Promo",
            category: "Social Media",
            docType: .square,
            themeName: "Terracotta Modern",
            preset: CanvasPreset.presets[0],
            page: page,
            previewColorHex: "#C2410C"
        )
    }

    public static func createThoughtLeadershipQuoteTemplate() -> CanvasTemplate {
        let page = CanvasPage(
            name: "Thought Leadership Quote",
            width: 1080, height: 1080,
            background: FillStyle.solid(CodableColor(hex: "#FAF7F0")),
            elements: [
                CanvasElement(name: "Quote Mark", payload: .text(TextContent(text: "“", fontFamily: "Playfair Display", fontSize: 180, fontWeight: 900, alignment: .left, textColor: CodableColor(hex: "#C2410C"))), x: 100, y: 80, width: 200, height: 160, zIndex: 0),
                CanvasElement(name: "Quote Body", payload: .text(TextContent(text: "Simplicity is not the absence of clutter, that's a consequence of simplicity. Simplicity is somehow essentially describing the purpose and place of an object.", fontFamily: "Playfair Display", fontSize: 34, fontWeight: 700, isItalic: true, alignment: .left, textColor: .inkBlack, lineSpacing: 8)), x: 100, y: 250, width: 880, height: 260, zIndex: 1),
                CanvasElement(name: "Author Name", payload: .text(TextContent(text: "— JONY IVE", fontFamily: "Inter", fontSize: 16, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#C2410C"), letterSpacing: 3)), x: 100, y: 560, width: 500, height: 30, zIndex: 2)
            ]
        )

        return CanvasTemplate(
            id: "thought_quote",
            title: "Thought Leadership Quote",
            category: "Social Media",
            docType: .square,
            themeName: "Terracotta Modern",
            preset: CanvasPreset.presets[0],
            page: page,
            previewColorHex: "#FAF7F0"
        )
    }

    public static func createNordicEventPassTemplate() -> CanvasTemplate {
        let page = CanvasPage(
            name: "Nordic Tech Pass",
            width: 1080, height: 1080,
            background: FillStyle.solid(CodableColor(hex: "#0F172A")),
            elements: [
                CanvasElement(name: "Event Tag", payload: .text(TextContent(text: "NATIVE ARCHITECTURE SUMMIT • 2026", fontFamily: "Inter", fontSize: 13, fontWeight: 800, alignment: .center, textColor: CodableColor(hex: "#38BDF8"), letterSpacing: 2)), x: 100, y: 100, width: 880, height: 25, zIndex: 0),
                CanvasElement(name: "Event Title", payload: .text(TextContent(text: "The High-Performance\nDeveloper Conference", fontFamily: "Playfair Display", fontSize: 54, fontWeight: 900, alignment: .center, textColor: .white, lineSpacing: 6)), x: 100, y: 150, width: 880, height: 160, zIndex: 1)
            ]
        )

        return CanvasTemplate(
            id: "nordic_pass",
            title: "Nordic Event Pass",
            category: "Social Media",
            docType: .square,
            themeName: "Nordic Frost",
            preset: CanvasPreset.presets[0],
            page: page,
            previewColorHex: "#0F172A"
        )
    }

    // =========================================================================
    // MARK: - 4. STORY / VERTICAL (9:16) TEMPLATES
    // =========================================================================

    public static func createScrapbookStoryTemplate() -> CanvasTemplate {
        let page = CanvasPage(
            name: "Scrapbook Mood Story",
            width: 1080, height: 1920,
            background: FillStyle(type: .vintageParchment, solidColor: CodableColor(hex: "#FAF7F0")),
            elements: [
                CanvasElement(name: "Washi Tape Top", payload: .shape(ShapeContent(kind: .washiTape, fill: FillStyle.solid(CodableColor(hex: "#FB923C")))), x: 100, y: 120, width: 280, height: 42, rotation: -6, zIndex: 0),
                CanvasElement(name: "Story Headline", payload: .text(TextContent(text: "Daily Mood &\nCraft Notes", fontFamily: "Playfair Display", fontSize: 64, fontWeight: 900, alignment: .center, textColor: .inkBlack)), x: 100, y: 220, width: 880, height: 180, zIndex: 1)
            ]
        )

        return CanvasTemplate(
            id: "scrapbook_story",
            title: "Scrapbook Daily Story",
            category: "Social Media",
            docType: .story,
            themeName: "Vintage Paper",
            preset: CanvasPreset.presets[2],
            page: page,
            previewColorHex: "#D97706"
        )
    }

    public static func createFlashCountdownStoryTemplate() -> CanvasTemplate {
        let page = CanvasPage(
            name: "Flash Drop Story",
            width: 1080, height: 1920,
            background: FillStyle.solid(CodableColor(hex: "#C2410C")),
            elements: [
                CanvasElement(name: "Drop Headline", payload: .text(TextContent(text: "NEW DROP\nLIVE NOW", fontFamily: "Impact", fontSize: 96, fontWeight: 900, alignment: .center, textColor: .white)), x: 100, y: 280, width: 880, height: 260, zIndex: 0)
            ]
        )

        return CanvasTemplate(
            id: "flash_drop_story",
            title: "Flash Drop Story",
            category: "Social Media",
            docType: .story,
            themeName: "Terracotta Modern",
            preset: CanvasPreset.presets[2],
            page: page,
            previewColorHex: "#C2410C"
        )
    }

    public static func createTechTipStoryTemplate() -> CanvasTemplate {
        let page = CanvasPage(
            name: "Tech Tip Story",
            width: 1080, height: 1920,
            background: FillStyle.solid(CodableColor(hex: "#0F172A")),
            elements: [
                CanvasElement(name: "Tip Tag", payload: .text(TextContent(text: "SWIFTUI PRO TIP #42", fontFamily: "SF Mono", fontSize: 14, fontWeight: 800, alignment: .center, textColor: CodableColor(hex: "#38BDF8"), letterSpacing: 2)), x: 100, y: 180, width: 880, height: 30, zIndex: 0)
            ]
        )

        return CanvasTemplate(
            id: "tech_tip_story",
            title: "Tech Tip Story",
            category: "Social Media",
            docType: .story,
            themeName: "Nordic Frost",
            preset: CanvasPreset.presets[2],
            page: page,
            previewColorHex: "#0F172A"
        )
    }

    // =========================================================================
    // MARK: - 5. YOUTUBE THUMBNAIL (16:9 - 1280 × 720) TEMPLATES
    // =========================================================================

    public static func createRetroDocThumbnailTemplate() -> CanvasTemplate {
        let page = CanvasPage(
            name: "Retro Doc Thumbnail",
            width: 1280, height: 720,
            background: FillStyle(type: .newsprint, solidColor: CodableColor(hex: "#F5F2EB")),
            elements: [
                CanvasElement(name: "Badge", payload: .text(TextContent(text: "DECLASSIFIED ARCHIVE", fontFamily: "Georgia", fontSize: 16, fontWeight: 900, alignment: .left, textColor: CodableColor(hex: "#C2410C"))), x: 80, y: 80, width: 600, height: 30, zIndex: 0),
                CanvasElement(name: "Headline", payload: .text(TextContent(text: "THE LOST ART OF\nSPEED IN SOFTWARE", fontFamily: "Playfair Display", fontSize: 64, fontWeight: 900, alignment: .left, textColor: .inkBlack)), x: 80, y: 130, width: 1000, height: 180, zIndex: 1)
            ]
        )

        return CanvasTemplate(
            id: "retro_doc_thumb",
            title: "Retro Documentary Thumbnail",
            category: "Social Media",
            docType: .thumbnail,
            themeName: "Vintage Paper",
            preset: CanvasPreset.presets[3],
            page: page,
            previewColorHex: "#F5F2EB"
        )
    }

    public static func createDesignSecretsThumbnailTemplate() -> CanvasTemplate {
        let page = CanvasPage(
            name: "Design Secrets Thumbnail",
            width: 1280, height: 720,
            background: FillStyle.solid(CodableColor(hex: "#C2410C")),
            elements: [
                CanvasElement(name: "Headline", payload: .text(TextContent(text: "10 NATIVE DESIGN\nSECRETS YOU MISSED", fontFamily: "Impact", fontSize: 68, fontWeight: 900, alignment: .left, textColor: .white)), x: 80, y: 100, width: 1000, height: 180, zIndex: 0)
            ]
        )

        return CanvasTemplate(
            id: "design_secrets_thumb",
            title: "Design Secrets Video",
            category: "Social Media",
            docType: .thumbnail,
            themeName: "Terracotta Modern",
            preset: CanvasPreset.presets[3],
            page: page,
            previewColorHex: "#C2410C"
        )
    }

    // =========================================================================
    // MARK: - 6. BUSINESS CARDS (1050 × 600) TEMPLATES
    // =========================================================================

    public static func createBusinessCardTemplate() -> CanvasTemplate {
        let page = CanvasPage(
            name: "Embossed Letterpress Card",
            width: 1050, height: 600,
            background: FillStyle(type: .vintageParchment, solidColor: CodableColor(hex: "#FAF7F0")),
            elements: [
                CanvasElement(name: "Border", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(.clear), stroke: StrokeStyle(isEnabled: true, color: .inkBlack, lineWidth: 2))), x: 30, y: 30, width: 990, height: 540, zIndex: 0),
                CanvasElement(name: "Name", payload: .text(TextContent(text: "ELIZABETH VANCE", fontFamily: "Playfair Display", fontSize: 32, fontWeight: 800, alignment: .left, textColor: .inkBlack, letterSpacing: 3)), x: 80, y: 120, width: 700, height: 45, zIndex: 1),
                CanvasElement(name: "Title", payload: .text(TextContent(text: "MASTER TYPOGRAPHER & PRINTMAKER", fontFamily: "Georgia", fontSize: 11, fontWeight: 700, alignment: .left, textColor: CodableColor(hex: "#C2410C"), letterSpacing: 2)), x: 80, y: 170, width: 600, height: 25, zIndex: 2)
            ]
        )

        return CanvasTemplate(
            id: "business_card",
            title: "Letterpress Business Card",
            category: "Print & Documents",
            docType: .businessCard,
            themeName: "Vintage Paper",
            preset: CanvasPreset.presets[12],
            page: page,
            previewColorHex: "#FAF7F0"
        )
    }

    public static func createStudioDirectorCardTemplate() -> CanvasTemplate {
        let page = CanvasPage(
            name: "Studio Director Card",
            width: 1050, height: 600,
            background: FillStyle.solid(CodableColor(hex: "#C2410C")),
            elements: [
                CanvasElement(name: "Director Name", payload: .text(TextContent(text: "MAYA LIN", fontFamily: "Playfair Display", fontSize: 34, fontWeight: 900, alignment: .left, textColor: .white, letterSpacing: 3)), x: 80, y: 120, width: 700, height: 45, zIndex: 0),
                CanvasElement(name: "Director Title", payload: .text(TextContent(text: "CREATIVE DIRECTOR • STUDIO CRAFT", fontFamily: "Inter", fontSize: 11, fontWeight: 700, alignment: .left, textColor: CodableColor(hex: "#FED7AA"), letterSpacing: 2)), x: 80, y: 170, width: 600, height: 25, zIndex: 1)
            ]
        )

        return CanvasTemplate(
            id: "studio_director_card",
            title: "Studio Director Card",
            category: "Print & Documents",
            docType: .businessCard,
            themeName: "Terracotta Modern",
            preset: CanvasPreset.presets[12],
            page: page,
            previewColorHex: "#C2410C"
        )
    }
}
