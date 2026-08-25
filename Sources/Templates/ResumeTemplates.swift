import Foundation
import SwiftUI

public enum ResumeTemplates {
    public static func allResumeTemplates() -> [CanvasTemplate] {
        return [
            createTechLeadResumeTemplate(),
            createExecutiveLeadershipResumeTemplate(),
            createCreativeDirectorResumeTemplate(),
            createIvyLeagueAcademicResumeTemplate(),
            createGrowthMarketingResumeTemplate(),
            createTwoColumnMinimalResumeTemplate(),
            createBoldImpactResumeTemplate(),
            createHealthcareResumeTemplate(),
            createStudentInternshipResumeTemplate(),
            createSalesManagerResumeTemplate()
        ]
    }

    // =========================================================================
    // 1. MODERN TECH & AI LEAD RESUME (A4 - 1240 × 1754)
    // =========================================================================
    public static func createTechLeadResumeTemplate() -> CanvasTemplate {
        let page = CanvasPage(
            name: "Modern Tech Resume",
            width: 1240, height: 1754,
            background: FillStyle(type: .solid, solidColor: CodableColor(hex: "#FFFFFF")),
            elements: [
                // Top Header Background Accent Band
                CanvasElement(name: "Header Accent", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#18181B")))), x: 0, y: 0, width: 1240, height: 210, zIndex: 0),
                
                // Name & Role Title
                CanvasElement(name: "Candidate Name", payload: .text(TextContent(text: "ALEXANDER CHEN", fontFamily: "Inter", fontSize: 34, fontWeight: 900, alignment: .left, textColor: .white, letterSpacing: 2)), x: 70, y: 45, width: 750, height: 45, zIndex: 1),
                CanvasElement(name: "Role Title", payload: .text(TextContent(text: "Staff Systems Engineer & AI Architect", fontFamily: "Inter", fontSize: 18, fontWeight: 600, alignment: .left, textColor: CodableColor(hex: "#C2410C"))), x: 70, y: 95, width: 750, height: 28, zIndex: 2),
                
                // Contact Details Bar
                CanvasElement(name: "Contact Bar", payload: .text(TextContent(text: "San Francisco, CA • alex.chen@platform.dev • +1 (415) 890-2341 • github.com/alexchen • linkedin.com/in/alexchen", fontFamily: "SF Mono", fontSize: 11, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#A1A1AA"))), x: 70, y: 135, width: 1050, height: 22, zIndex: 3),

                // QR Code to Live GitHub / Tech Portfolio
                CanvasElement(name: "Portfolio QR", payload: .image(ImageContent(
                    imageBase64: QRCodeGenerator.generateBase64(from: "https://github.com", darkColor: CodableColor(hex: "#FFFFFF"), lightColor: CodableColor(hex: "#27272A")) ?? "",
                    cornerRadius: 6
                )), x: 1080, y: 35, width: 90, height: 90, zIndex: 4),
                CanvasElement(name: "QR Caption", payload: .text(TextContent(text: "SCAN PORTFOLIO", fontFamily: "SF Mono", fontSize: 8, fontWeight: 700, alignment: .center, textColor: CodableColor(hex: "#A1A1AA"), letterSpacing: 1)), x: 1060, y: 130, width: 130, height: 16, zIndex: 5),

                // ── LEFT COLUMN: WORK EXPERIENCE (Width: 680px) ──
                CanvasElement(name: "Exp Section Title", payload: .text(TextContent(text: "WORK EXPERIENCE", fontFamily: "Inter", fontSize: 14, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#18181B"), letterSpacing: 2)), x: 70, y: 250, width: 680, height: 24, zIndex: 6),
                CanvasElement(name: "Exp Rule", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#C2410C")))), x: 70, y: 278, width: 680, height: 2, zIndex: 7),

                // Job 1
                CanvasElement(name: "Job 1 Header", payload: .text(TextContent(text: "Staff Platform Engineer • Stripe", fontFamily: "Inter", fontSize: 16, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#18181B"))), x: 70, y: 295, width: 450, height: 24, zIndex: 8),
                CanvasElement(name: "Job 1 Dates", payload: .text(TextContent(text: "2022 — PRESENT • SAN FRANCISCO, CA", fontFamily: "SF Mono", fontSize: 10, fontWeight: 600, alignment: .left, textColor: CodableColor(hex: "#71717A"))), x: 70, y: 322, width: 450, height: 18, zIndex: 9),
                CanvasElement(name: "Job 1 Bullets", payload: .text(TextContent(text: "• Architected high-throughput ledger service processing $4.2B daily volume with 99.999% uptime and sub-15ms p99 latency.\n• Led engineering migration of core runtime to Rust/Metal GPU compute, reducing cloud infrastructure spend by $1.8M annually.\n• Mentored 14 senior engineers across distributed systems, concurrency pipelines, and observability telemetry.", fontFamily: "Inter", fontSize: 12, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#27272A"), lineSpacing: 5)), x: 70, y: 345, width: 680, height: 95, zIndex: 10),

                // Job 2
                CanvasElement(name: "Job 2 Header", payload: .text(TextContent(text: "Senior Systems Engineer • Vercel", fontFamily: "Inter", fontSize: 16, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#18181B"))), x: 70, y: 460, width: 450, height: 24, zIndex: 11),
                CanvasElement(name: "Job 2 Dates", payload: .text(TextContent(text: "2019 — 2022 • SAN FRANCISCO, CA", fontFamily: "SF Mono", fontSize: 10, fontWeight: 600, alignment: .left, textColor: CodableColor(hex: "#71717A"))), x: 70, y: 487, width: 450, height: 18, zIndex: 12),
                CanvasElement(name: "Job 2 Bullets", payload: .text(TextContent(text: "• Designed edge compilation pipeline executing serverless functions across 300+ global PoPs in <8ms.\n• Authored open-source AST parser adopted by 2.4M weekly developers with zero breaking regressions across 4 major releases.\n• Collaborated with product leadership to specify developer CLI ergonomics, driving 140% developer adoption growth.", fontFamily: "Inter", fontSize: 12, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#27272A"), lineSpacing: 5)), x: 70, y: 510, width: 680, height: 95, zIndex: 13),

                // Job 3
                CanvasElement(name: "Job 3 Header", payload: .text(TextContent(text: "Software Engineer • Apple", fontFamily: "Inter", fontSize: 16, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#18181B"))), x: 70, y: 625, width: 450, height: 24, zIndex: 14),
                CanvasElement(name: "Job 3 Dates", payload: .text(TextContent(text: "2017 — 2019 • CUPERTINO, CA", fontFamily: "SF Mono", fontSize: 10, fontWeight: 600, alignment: .left, textColor: CodableColor(hex: "#71717A"))), x: 70, y: 652, width: 450, height: 18, zIndex: 15),
                CanvasElement(name: "Job 3 Bullets", payload: .text(TextContent(text: "• Implemented Metal 2 GPU shader passes for CoreAnimation rendering engine on macOS and iOS.\n• Reduced frame hitch rate by 34% in ProMotion 120Hz display modes through asynchronous texture caching.", fontFamily: "Inter", fontSize: 12, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#27272A"), lineSpacing: 5)), x: 70, y: 675, width: 680, height: 65, zIndex: 16),

                // Featured Technical Projects
                CanvasElement(name: "Proj Section Title", payload: .text(TextContent(text: "KEY PROJECTS & OPEN SOURCE", fontFamily: "Inter", fontSize: 14, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#18181B"), letterSpacing: 2)), x: 70, y: 770, width: 680, height: 24, zIndex: 17),
                CanvasElement(name: "Proj Rule", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#C2410C")))), x: 70, y: 798, width: 680, height: 2, zIndex: 18),
                CanvasElement(name: "Proj 1", payload: .text(TextContent(text: "• HyperVector (GitHub: 8.4k stars) — Ultra-fast SIMD-accelerated embedded vector database written in Swift & C++.\n• LLM-Canvas-Bridge — Local neural engine integration streaming token diffs to Canvas viewports at 120 FPS.", fontFamily: "Inter", fontSize: 12, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#27272A"), lineSpacing: 5)), x: 70, y: 815, width: 680, height: 65, zIndex: 19),

                // ── RIGHT COLUMN: SKILLS, EDUCATION & PATENTS (Width: 380px) ──
                // Tech Stack Tags
                CanvasElement(name: "Skills Section Title", payload: .text(TextContent(text: "CORE COMPETENCIES", fontFamily: "Inter", fontSize: 14, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#18181B"), letterSpacing: 2)), x: 790, y: 250, width: 380, height: 24, zIndex: 20),
                CanvasElement(name: "Skills Rule", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#18181B")))), x: 790, y: 278, width: 380, height: 2, zIndex: 21),
                
                CanvasElement(name: "Skill Group 1", payload: .text(TextContent(text: "LANGUAGES & SYSTEMS\nSwift, Rust, C++, Python, TypeScript, SQL, Metal Shaders, WASM, POSIX Threads", fontFamily: "SF Mono", fontSize: 11, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#27272A"), lineSpacing: 4)), x: 790, y: 295, width: 380, height: 50, zIndex: 22),
                CanvasElement(name: "Skill Group 2", payload: .text(TextContent(text: "ARCHITECTURE & CLOUD\nDistributed Consensus, Raft, Kafka, gRPC, Docker, Kubernetes, AWS, Cloudflare Workers", fontFamily: "SF Mono", fontSize: 11, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#27272A"), lineSpacing: 4)), x: 790, y: 360, width: 380, height: 50, zIndex: 23),
                CanvasElement(name: "Skill Group 3", payload: .text(TextContent(text: "AI & GRAPHICS\nCoreML, Apple Neural Engine, PyTorch, SIMD, CoreGraphics, Vision Framework, ONNX", fontFamily: "SF Mono", fontSize: 11, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#27272A"), lineSpacing: 4)), x: 790, y: 425, width: 380, height: 50, zIndex: 24),

                // Education
                CanvasElement(name: "Edu Section Title", payload: .text(TextContent(text: "EDUCATION", fontFamily: "Inter", fontSize: 14, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#18181B"), letterSpacing: 2)), x: 790, y: 510, width: 380, height: 24, zIndex: 25),
                CanvasElement(name: "Edu Rule", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#18181B")))), x: 790, y: 538, width: 380, height: 2, zIndex: 26),
                CanvasElement(name: "Edu Degree", payload: .text(TextContent(text: "B.S. in Computer Science & AI\nUniversity of California, Berkeley", fontFamily: "Inter", fontSize: 13, fontWeight: 700, alignment: .left, textColor: CodableColor(hex: "#18181B"), lineSpacing: 3)), x: 790, y: 555, width: 380, height: 40, zIndex: 27),
                CanvasElement(name: "Edu Details", payload: .text(TextContent(text: "GPA: 3.94 • Regents and Chancellor's Scholar\nFocus: Distributed Concurrency & Hardware Synthesis", fontFamily: "Inter", fontSize: 11, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#71717A"), lineSpacing: 3)), x: 790, y: 600, width: 380, height: 35, zIndex: 28),

                // Patents & Certifications
                CanvasElement(name: "Cert Section Title", payload: .text(TextContent(text: "PATENTS & AWARDS", fontFamily: "Inter", fontSize: 14, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#18181B"), letterSpacing: 2)), x: 790, y: 660, width: 380, height: 24, zIndex: 29),
                CanvasElement(name: "Cert Rule", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#18181B")))), x: 790, y: 688, width: 380, height: 2, zIndex: 30),
                CanvasElement(name: "Cert Details", payload: .text(TextContent(text: "• US Patent 11,489,201: Asynchronous Vector Quantization in SIMD Cache.\n• Apple WWDC Apple Design Award Winner 2021.\n• Certified AWS Solutions Architect (Professional).", fontFamily: "Inter", fontSize: 11, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#27272A"), lineSpacing: 4)), x: 790, y: 705, width: 380, height: 75, zIndex: 31)
            ]
        )

        return CanvasTemplate(
            id: "resume_tech_lead",
            title: "Modern Tech & AI Lead Resume",
            category: "Resumes & CVs",
            docType: .a4,
            themeName: "Tech & Engineering",
            preset: .a4(),
            pages: [page],
            previewColorHex: "#18181B"
        )
    }

    // =========================================================================
    // 2. EXECUTIVE & LEADERSHIP MINIMALIST RESUME (A4 - 1240 × 1754)
    // =========================================================================
    public static func createExecutiveLeadershipResumeTemplate() -> CanvasTemplate {
        let page = CanvasPage(
            name: "Executive Leadership Resume",
            width: 1240, height: 1754,
            background: FillStyle(type: .solid, solidColor: CodableColor(hex: "#FAFAF9")),
            elements: [
                // Top Editorial Header
                CanvasElement(name: "Top Border Line", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#1C1917")))), x: 80, y: 60, width: 1080, height: 3, zIndex: 0),
                CanvasElement(name: "Executive Name", payload: .text(TextContent(text: "VICTORIA STERLING", fontFamily: "Playfair Display", fontSize: 38, fontWeight: 900, alignment: .center, textColor: CodableColor(hex: "#1C1917"), letterSpacing: 4)), x: 80, y: 80, width: 1080, height: 50, zIndex: 1),
                CanvasElement(name: "Executive Subtitle", payload: .text(TextContent(text: "CHIEF EXECUTIVE OFFICER • BOARD DIRECTOR • B2B SAAS SCALEUP", fontFamily: "Inter", fontSize: 11, fontWeight: 800, alignment: .center, textColor: CodableColor(hex: "#C2410C"), letterSpacing: 3)), x: 80, y: 135, width: 1080, height: 22, zIndex: 2),
                CanvasElement(name: "Executive Contact", payload: .text(TextContent(text: "New York, NY • v.sterling@executive.com • +1 (212) 555-0198 • linkedin.com/in/vsterling", fontFamily: "Georgia", fontSize: 12, fontWeight: 400, isItalic: true, alignment: .center, textColor: CodableColor(hex: "#57534E"))), x: 80, y: 160, width: 1080, height: 22, zIndex: 3),
                CanvasElement(name: "Header Divider", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#D6D3D1")))), x: 80, y: 195, width: 1080, height: 1, zIndex: 4),

                // Executive Summary
                CanvasElement(name: "Summary Title", payload: .text(TextContent(text: "EXECUTIVE PROFILE & VALUE PROPOSITION", fontFamily: "Playfair Display", fontSize: 15, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#1C1917"), letterSpacing: 2)), x: 80, y: 220, width: 1080, height: 25, zIndex: 5),
                CanvasElement(name: "Summary Text", payload: .text(TextContent(text: "Transformational CEO with 16+ years scaling enterprise software corporations from early commercialization to global profitability ($15M to $210M ARR). Proven expertise leading cross-functional organizations of 600+ personnel across North America, EMEA, and APAC. Track record includes 2 successful public listings (NYSE) and 3 private equity exits delivering >5.4x MOIC to investors.", fontFamily: "Georgia", fontSize: 13, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#292524"), lineSpacing: 5)), x: 80, y: 250, width: 1080, height: 60, zIndex: 6),

                // Key Performance Metric Badges (3 Column Highlight Cards)
                CanvasElement(name: "Metric 1 Box", payload: .shape(ShapeContent(kind: .roundedRectangle, cornerRadius: 4, fill: FillStyle.solid(CodableColor(hex: "#F5F5F4")), stroke: StrokeStyle(isEnabled: true, color: CodableColor(hex: "#E7E5E4"), lineWidth: 1))), x: 80, y: 330, width: 340, height: 80, zIndex: 7),
                CanvasElement(name: "Metric 1 Num", payload: .text(TextContent(text: "$210M ARR", fontFamily: "Playfair Display", fontSize: 24, fontWeight: 900, alignment: .center, textColor: CodableColor(hex: "#C2410C"))), x: 90, y: 342, width: 320, height: 30, zIndex: 8),
                CanvasElement(name: "Metric 1 Label", payload: .text(TextContent(text: "Scaled Revenue from $15M", fontFamily: "Inter", fontSize: 10, fontWeight: 700, alignment: .center, textColor: CodableColor(hex: "#57534E"))), x: 90, y: 375, width: 320, height: 18, zIndex: 9),

                CanvasElement(name: "Metric 2 Box", payload: .shape(ShapeContent(kind: .roundedRectangle, cornerRadius: 4, fill: FillStyle.solid(CodableColor(hex: "#F5F5F4")), stroke: StrokeStyle(isEnabled: true, color: CodableColor(hex: "#E7E5E4"), lineWidth: 1))), x: 450, y: 330, width: 340, height: 80, zIndex: 10),
                CanvasElement(name: "Metric 2 Num", payload: .text(TextContent(text: "3 M&A Exits", fontFamily: "Playfair Display", fontSize: 24, fontWeight: 900, alignment: .center, textColor: CodableColor(hex: "#1C1917"))), x: 460, y: 342, width: 320, height: 30, zIndex: 11),
                CanvasElement(name: "Metric 2 Label", payload: .text(TextContent(text: "Delivered 5.4x Capital Return", fontFamily: "Inter", fontSize: 10, fontWeight: 700, alignment: .center, textColor: CodableColor(hex: "#57534E"))), x: 460, y: 375, width: 320, height: 18, zIndex: 12),

                CanvasElement(name: "Metric 3 Box", payload: .shape(ShapeContent(kind: .roundedRectangle, cornerRadius: 4, fill: FillStyle.solid(CodableColor(hex: "#F5F5F4")), stroke: StrokeStyle(isEnabled: true, color: CodableColor(hex: "#E7E5E4"), lineWidth: 1))), x: 820, y: 330, width: 340, height: 80, zIndex: 13),
                CanvasElement(name: "Metric 3 Num", payload: .text(TextContent(text: "600+ Global", fontFamily: "Playfair Display", fontSize: 24, fontWeight: 900, alignment: .center, textColor: CodableColor(hex: "#1C1917"))), x: 830, y: 342, width: 320, height: 30, zIndex: 14),
                CanvasElement(name: "Metric 3 Label", payload: .text(TextContent(text: "Employee Organization Led", fontFamily: "Inter", fontSize: 10, fontWeight: 700, alignment: .center, textColor: CodableColor(hex: "#57534E"))), x: 830, y: 375, width: 320, height: 18, zIndex: 15),

                // Career History
                CanvasElement(name: "Exp Header", payload: .text(TextContent(text: "EXECUTIVE LEADERSHIP & CAREER MILESTONES", fontFamily: "Playfair Display", fontSize: 15, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#1C1917"), letterSpacing: 2)), x: 80, y: 440, width: 1080, height: 25, zIndex: 16),
                CanvasElement(name: "Exp Divider", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#1C1917")))), x: 80, y: 468, width: 1080, height: 1.5, zIndex: 17),

                // Exec Job 1
                CanvasElement(name: "Exec 1 Title", payload: .text(TextContent(text: "Chief Executive Officer • Apex Technologies Inc. (NYSE: APX)", fontFamily: "Playfair Display", fontSize: 17, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#1C1917"))), x: 80, y: 485, width: 750, height: 25, zIndex: 18),
                CanvasElement(name: "Exec 1 Dates", payload: .text(TextContent(text: "2019 — 2025 • NEW YORK, NY", fontFamily: "Inter", fontSize: 10.5, fontWeight: 700, alignment: .right, textColor: CodableColor(hex: "#78716C"))), x: 850, y: 488, width: 310, height: 20, zIndex: 19),
                CanvasElement(name: "Exec 1 Bullets", payload: .text(TextContent(text: "• Led corporate turnaround, pivoting product portfolio to AI-assisted enterprise workflow suite and expanding gross margins from 64% to 81%.\n• Scaled annual recurring revenue from $42M to $210M within 5 years while sustaining 28% adjusted EBITDA profitability.\n• Successfully executed initial public offering on the New York Stock Exchange raising $340M in primary equity capital.\n• Maintained 94% executive retention and established award-winning employee culture recognized by Fortune Best Workplaces.", fontFamily: "Georgia", fontSize: 12.5, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#292524"), lineSpacing: 5)), x: 80, y: 515, width: 1080, height: 85, zIndex: 20),

                // Exec Job 2
                CanvasElement(name: "Exec 2 Title", payload: .text(TextContent(text: "President & Chief Operating Officer • Nexus Cloud Systems", fontFamily: "Playfair Display", fontSize: 17, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#1C1917"))), x: 80, y: 620, width: 750, height: 25, zIndex: 21),
                CanvasElement(name: "Exec 2 Dates", payload: .text(TextContent(text: "2014 — 2019 • BOSTON, MA", fontFamily: "Inter", fontSize: 10.5, fontWeight: 700, alignment: .right, textColor: CodableColor(hex: "#78716C"))), x: 850, y: 623, width: 310, height: 20, zIndex: 22),
                CanvasElement(name: "Exec 2 Bullets", payload: .text(TextContent(text: "• Oversaw global sales, engineering, customer success, and legal operations across 12 worldwide field offices.\n• Re-architected GTM engine, driving 165% net revenue retention (NRR) and reducing customer acquisition payback to 8.2 months.\n• Orchestrated strategic $1.2B acquisition by Oracle Corporation, representing an 8.6x revenue multiple for seed investors.", fontFamily: "Georgia", fontSize: 12.5, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#292524"), lineSpacing: 5)), x: 80, y: 650, width: 1080, height: 65, zIndex: 23),

                // Board Directorships & Governance
                CanvasElement(name: "Board Header", payload: .text(TextContent(text: "BOARD APPOINTMENTS & GOVERNANCE", fontFamily: "Playfair Display", fontSize: 15, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#1C1917"), letterSpacing: 2)), x: 80, y: 745, width: 1080, height: 25, zIndex: 24),
                CanvasElement(name: "Board Divider", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#1C1917")))), x: 80, y: 773, width: 1080, height: 1.5, zIndex: 25),
                CanvasElement(name: "Board Bullets", payload: .text(TextContent(text: "• Independent Board Director & Audit Committee Chair • Lumina Biosystems (NASDAQ: LMNA) • 2021 — Present\n• Board Advisor • Harvard Business School Rock Center for Entrepreneurship • 2018 — Present\n• Member • National Association of Corporate Directors (NACD Directorship Certified)", fontFamily: "Georgia", fontSize: 12.5, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#292524"), lineSpacing: 5)), x: 80, y: 790, width: 1080, height: 65, zIndex: 26),

                // Education & Credentials
                CanvasElement(name: "Exec Edu Header", payload: .text(TextContent(text: "EDUCATION & CREDENTIALS", fontFamily: "Playfair Display", fontSize: 15, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#1C1917"), letterSpacing: 2)), x: 80, y: 885, width: 1080, height: 25, zIndex: 27),
                CanvasElement(name: "Exec Edu Divider", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#1C1917")))), x: 80, y: 913, width: 1080, height: 1.5, zIndex: 28),
                CanvasElement(name: "Exec Edu Content", payload: .text(TextContent(text: "Master of Business Administration (MBA) • Harvard Business School (Baker Scholar, High Distinction)\nBachelor of Arts in Economics & Public Policy • Stanford University (Summa Cum Laude, Phi Beta Kappa)", fontFamily: "Georgia", fontSize: 12.5, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#292524"), lineSpacing: 4)), x: 80, y: 930, width: 1080, height: 45, zIndex: 29)
            ]
        )

        return CanvasTemplate(
            id: "resume_executive_leadership",
            title: "Executive & Board Director Resume",
            category: "Resumes & CVs",
            docType: .a4,
            themeName: "Executive & Leadership",
            preset: .a4(),
            pages: [page],
            previewColorHex: "#C2410C"
        )
    }

    // =========================================================================
    // 3. CREATIVE DIRECTOR & UI/UX LEAD RESUME (A4 - 1240 × 1754)
    // =========================================================================
    public static func createCreativeDirectorResumeTemplate() -> CanvasTemplate {
        let page = CanvasPage(
            name: "Creative Director Resume",
            width: 1240, height: 1754,
            background: FillStyle(type: .solid, solidColor: CodableColor(hex: "#FFFFFF")),
            elements: [
                // Left Column Dark Terracotta / Slate Canvas Sidebar (Width: 400px)
                CanvasElement(name: "Sidebar Bg", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#1F1D1B")))), x: 0, y: 0, width: 400, height: 1754, zIndex: 0),

                // Avatar / Profile Frame
                CanvasElement(name: "Avatar Frame", payload: .image(ImageContent(
                    imageBase64: ImageUtils.generatePlaceholder(width: 400, height: 400, text: "PORTRAIT", colorHex: "#3F3F46"),
                    cornerRadius: 16,
                    frameKind: .arch
                )), x: 120, y: 60, width: 160, height: 200, zIndex: 1),

                // Sidebar Name & Info
                CanvasElement(name: "Side Name", payload: .text(TextContent(text: "MARCUS STERLING", fontFamily: "Avenir Next", fontSize: 22, fontWeight: 900, alignment: .center, textColor: .white, letterSpacing: 2)), x: 30, y: 280, width: 340, height: 30, zIndex: 2),
                CanvasElement(name: "Side Role", payload: .text(TextContent(text: "CREATIVE DIRECTOR & BRAND ARCHITECT", fontFamily: "Avenir Next", fontSize: 11, fontWeight: 700, alignment: .center, textColor: CodableColor(hex: "#C2410C"), letterSpacing: 2)), x: 30, y: 315, width: 340, height: 20, zIndex: 3),

                // Live Portfolio QR Code
                CanvasElement(name: "Side QR", payload: .image(ImageContent(
                    imageBase64: QRCodeGenerator.generateBase64(from: "https://behance.net", darkColor: CodableColor(hex: "#FFFFFF"), lightColor: CodableColor(hex: "#27272A")) ?? "",
                    cornerRadius: 6
                )), x: 145, y: 360, width: 110, height: 110, zIndex: 4),
                CanvasElement(name: "Side QR Label", payload: .text(TextContent(text: "SCAN DIGITAL PORTFOLIO", fontFamily: "Avenir Next", fontSize: 9, fontWeight: 800, alignment: .center, textColor: CodableColor(hex: "#A1A1AA"), letterSpacing: 1.5)), x: 30, y: 480, width: 340, height: 16, zIndex: 5),

                // Contact Details
                CanvasElement(name: "Side Contact Title", payload: .text(TextContent(text: "CONTACT", fontFamily: "Avenir Next", fontSize: 12, fontWeight: 800, alignment: .left, textColor: .white, letterSpacing: 2)), x: 50, y: 530, width: 300, height: 20, zIndex: 6),
                CanvasElement(name: "Side Contact Line", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#C2410C")))), x: 50, y: 555, width: 300, height: 1.5, zIndex: 7),
                CanvasElement(name: "Side Contact Info", payload: .text(TextContent(text: "marcus@studio-sterling.design\n+1 (310) 902-8812\nLos Angeles & London\ninstagram.com/marcus.design\nbehance.net/marcussterling", fontFamily: "Avenir Next", fontSize: 11, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#D4D4D8"), lineSpacing: 5)), x: 50, y: 568, width: 300, height: 110, zIndex: 8),

                // Design Disciplines
                CanvasElement(name: "Side Disc Title", payload: .text(TextContent(text: "CORE DISCIPLINES", fontFamily: "Avenir Next", fontSize: 12, fontWeight: 800, alignment: .left, textColor: .white, letterSpacing: 2)), x: 50, y: 700, width: 300, height: 20, zIndex: 9),
                CanvasElement(name: "Side Disc Line", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#C2410C")))), x: 50, y: 725, width: 300, height: 1.5, zIndex: 10),
                CanvasElement(name: "Side Disc List", payload: .text(TextContent(text: "• Creative & Art Direction\n• Brand Identity & Systems\n• UI/UX & Design Systems\n• 3D Motion & Kinetic Type\n• Spatial Computing (visionOS)\n• Editorial & Printmaking", fontFamily: "Avenir Next", fontSize: 11.5, fontWeight: 500, alignment: .left, textColor: CodableColor(hex: "#E4E4E7"), lineSpacing: 5)), x: 50, y: 738, width: 300, height: 140, zIndex: 11),

                // ── RIGHT MAIN CANVAS CONTENT (Width: 760px) ──
                // Executive Bio
                CanvasElement(name: "Bio Title", payload: .text(TextContent(text: "CREATIVE PROFILE", fontFamily: "Avenir Next", fontSize: 14, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#1F1D1B"), letterSpacing: 2)), x: 450, y: 60, width: 720, height: 22, zIndex: 12),
                CanvasElement(name: "Bio Line", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#1F1D1B")))), x: 450, y: 88, width: 720, height: 2, zIndex: 13),
                CanvasElement(name: "Bio Text", payload: .text(TextContent(text: "Multi-disciplinary Creative Director with 12+ years defining visual culture for global luxury brands, high-growth technology flagships, and cultural institutions. Blending tactile typography with cutting-edge digital interactions to produce unforgettable brand experiences.", fontFamily: "Avenir Next", fontSize: 13, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#3F3F46"), lineSpacing: 5)), x: 450, y: 100, width: 720, height: 60, zIndex: 14),

                // Experience
                CanvasElement(name: "Exp Title", payload: .text(TextContent(text: "LEADERSHIP EXPERIENCE", fontFamily: "Avenir Next", fontSize: 14, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#1F1D1B"), letterSpacing: 2)), x: 450, y: 190, width: 720, height: 22, zIndex: 15),
                CanvasElement(name: "Exp Line", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#1F1D1B")))), x: 450, y: 218, width: 720, height: 2, zIndex: 16),

                // Creative Job 1
                CanvasElement(name: "CJob 1 Header", payload: .text(TextContent(text: "Head of Brand & Product Design • Linear App", fontFamily: "Avenir Next", fontSize: 16, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#1F1D1B"))), x: 450, y: 235, width: 500, height: 24, zIndex: 17),
                CanvasElement(name: "CJob 1 Dates", payload: .text(TextContent(text: "2021 — PRESENT • SAN FRANCISCO & REMOTE", fontFamily: "SF Mono", fontSize: 10, fontWeight: 600, alignment: .left, textColor: CodableColor(hex: "#71717A"))), x: 450, y: 262, width: 500, height: 18, zIndex: 18),
                CanvasElement(name: "CJob 1 Bullets", payload: .text(TextContent(text: "• Directed the comprehensive global rebrand and design system redesign spanning web, desktop, and mobile products.\n• Established high-precision 120 FPS micro-interaction standards celebrated across the global design community.\n• Scaled in-house design organization from 3 to 18 product designers, brand motion artists, and design engineers.", fontFamily: "Avenir Next", fontSize: 12, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#3F3F46"), lineSpacing: 5)), x: 450, y: 285, width: 720, height: 80, zIndex: 19),

                // Creative Job 2
                CanvasElement(name: "CJob 2 Header", payload: .text(TextContent(text: "Creative Director • Pentagram Design", fontFamily: "Avenir Next", fontSize: 16, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#1F1D1B"))), x: 450, y: 390, width: 500, height: 24, zIndex: 20),
                CanvasElement(name: "CJob 2 Dates", payload: .text(TextContent(text: "2016 — 2021 • NEW YORK & LONDON", fontFamily: "SF Mono", fontSize: 10, fontWeight: 600, alignment: .left, textColor: CodableColor(hex: "#71717A"))), x: 450, y: 417, width: 500, height: 18, zIndex: 21),
                CanvasElement(name: "CJob 2 Bullets", payload: .text(TextContent(text: "• Led multi-million-dollar identity engagements for MoMA, Warner Bros, and Nike Special Projects.\n• Awarded 3 D&AD Yellow Pencils, 2 Cannes Lions (Design Grand Prix), and Tokyo TDC Annual Book selection.\n• Managed multidisciplinary team of 12 art directors, type designers, and interactive 3D developers.", fontFamily: "Avenir Next", fontSize: 12, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#3F3F46"), lineSpacing: 5)), x: 450, y: 440, width: 720, height: 80, zIndex: 22),

                // Selected Case Studies
                CanvasElement(name: "Case Title", payload: .text(TextContent(text: "SELECTED AWARDS & RECOGNITION", fontFamily: "Avenir Next", fontSize: 14, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#1F1D1B"), letterSpacing: 2)), x: 450, y: 550, width: 720, height: 22, zIndex: 23),
                CanvasElement(name: "Case Line", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#1F1D1B")))), x: 450, y: 578, width: 720, height: 2, zIndex: 24),
                CanvasElement(name: "Case List", payload: .text(TextContent(text: "• Apple Design Award (Interaction Design) — 2023\n• D&AD Yellow Pencil (Branding & Spatial Design) — 2022\n• Cannes Lions Gold Lion (Digital Craft) — 2021\n• AIGA 50 Books | 50 Covers Award — 2019", fontFamily: "Avenir Next", fontSize: 12, fontWeight: 500, alignment: .left, textColor: CodableColor(hex: "#27272A"), lineSpacing: 6)), x: 450, y: 595, width: 720, height: 85, zIndex: 25),

                // Education
                CanvasElement(name: "Edu Title", payload: .text(TextContent(text: "ACADEMIC BACKGROUND", fontFamily: "Avenir Next", fontSize: 14, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#1F1D1B"), letterSpacing: 2)), x: 450, y: 710, width: 720, height: 22, zIndex: 26),
                CanvasElement(name: "Edu Line", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#1F1D1B")))), x: 450, y: 738, width: 720, height: 2, zIndex: 27),
                CanvasElement(name: "Edu Info", payload: .text(TextContent(text: "Master of Fine Arts (MFA) in Graphic & Interactive Design • Yale School of Art (2016)\nBachelor of Fine Arts (BFA) • Rhode Island School of Design (RISD, Honors, 2014)", fontFamily: "Avenir Next", fontSize: 12, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#3F3F46"), lineSpacing: 4)), x: 450, y: 755, width: 720, height: 45, zIndex: 28)
            ]
        )

        return CanvasTemplate(
            id: "resume_creative_director",
            title: "Creative Director & UI/UX Lead Resume",
            category: "Resumes & CVs",
            docType: .a4,
            themeName: "Creative & Design",
            preset: .a4(),
            pages: [page],
            previewColorHex: "#1F1D1B"
        )
    }

    // =========================================================================
    // 4. HARVARD / IVY LEAGUE MINIMALIST ACADEMIC & CONSULTANT RESUME (A4)
    // =========================================================================
    public static func createIvyLeagueAcademicResumeTemplate() -> CanvasTemplate {
        let page = CanvasPage(
            name: "Ivy League Minimalist Resume",
            width: 1240, height: 1754,
            background: FillStyle(type: .solid, solidColor: CodableColor(hex: "#FFFFFF")),
            elements: [
                // Header (Single Column Ultra-Clean ATS Compliant)
                CanvasElement(name: "Candidate Name", payload: .text(TextContent(text: "BENJAMIN H. MONTGOMERY", fontFamily: "Baskerville", fontSize: 32, fontWeight: 800, alignment: .center, textColor: CodableColor(hex: "#111827"), letterSpacing: 3)), x: 100, y: 70, width: 1040, height: 40, zIndex: 0),
                CanvasElement(name: "Contact Details", payload: .text(TextContent(text: "Cambridge, MA • b.montgomery@alumni.harvard.edu • +1 (617) 495-1000 • linkedin.com/in/bmontgomery", fontFamily: "Baskerville", fontSize: 12, fontWeight: 400, alignment: .center, textColor: CodableColor(hex: "#374151"))), x: 100, y: 115, width: 1040, height: 20, zIndex: 1),
                CanvasElement(name: "Header Line", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#111827")))), x: 100, y: 145, width: 1040, height: 1.5, zIndex: 2),

                // ── EDUCATION SECTION ──
                CanvasElement(name: "Edu Sec Title", payload: .text(TextContent(text: "EDUCATION", fontFamily: "Baskerville", fontSize: 14, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#111827"), letterSpacing: 2)), x: 100, y: 170, width: 1040, height: 20, zIndex: 3),
                CanvasElement(name: "Edu Sec Rule", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#9CA3AF")))), x: 100, y: 195, width: 1040, height: 1, zIndex: 4),

                CanvasElement(name: "Edu 1 School", payload: .text(TextContent(text: "HARVARD UNIVERSITY, GRADUATE SCHOOL OF BUSINESS", fontFamily: "Baskerville", fontSize: 14, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#111827"))), x: 100, y: 210, width: 750, height: 20, zIndex: 5),
                CanvasElement(name: "Edu 1 Dates", payload: .text(TextContent(text: "Boston, MA • May 2021", fontFamily: "Baskerville", fontSize: 12, fontWeight: 400, isItalic: true, alignment: .right, textColor: CodableColor(hex: "#4B5563"))), x: 800, y: 210, width: 340, height: 20, zIndex: 6),
                CanvasElement(name: "Edu 1 Degree", payload: .text(TextContent(text: "Master in Business Administration (MBA). George F. Baker Scholar (Top 5% of class). Co-President of Private Equity Club.", fontFamily: "Baskerville", fontSize: 12.5, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#1F2937"))), x: 100, y: 232, width: 1040, height: 20, zIndex: 7),

                CanvasElement(name: "Edu 2 School", payload: .text(TextContent(text: "MASSACHUSETTS INSTITUTE OF TECHNOLOGY (MIT)", fontFamily: "Baskerville", fontSize: 14, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#111827"))), x: 100, y: 265, width: 750, height: 20, zIndex: 8),
                CanvasElement(name: "Edu 2 Dates", payload: .text(TextContent(text: "Cambridge, MA • June 2017", fontFamily: "Baskerville", fontSize: 12, fontWeight: 400, isItalic: true, alignment: .right, textColor: CodableColor(hex: "#4B5563"))), x: 800, y: 265, width: 340, height: 20, zIndex: 9),
                CanvasElement(name: "Edu 2 Degree", payload: .text(TextContent(text: "Bachelor of Science in Mathematics and Computer Science. GPA: 3.98/4.00. Phi Beta Kappa, Tau Beta Pi Honor Societies.", fontFamily: "Baskerville", fontSize: 12.5, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#1F2937"))), x: 100, y: 287, width: 1040, height: 20, zIndex: 10),

                // ── PROFESSIONAL EXPERIENCE ──
                CanvasElement(name: "Exp Sec Title", payload: .text(TextContent(text: "PROFESSIONAL EXPERIENCE", fontFamily: "Baskerville", fontSize: 14, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#111827"), letterSpacing: 2)), x: 100, y: 330, width: 1040, height: 20, zIndex: 11),
                CanvasElement(name: "Exp Sec Rule", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#9CA3AF")))), x: 100, y: 355, width: 1040, height: 1, zIndex: 12),

                // Job 1
                CanvasElement(name: "McKinsey Title", payload: .text(TextContent(text: "MCKINSEY & COMPANY — Engagement Manager (Strategy & Technology)", fontFamily: "Baskerville", fontSize: 14, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#111827"))), x: 100, y: 370, width: 750, height: 20, zIndex: 13),
                CanvasElement(name: "McKinsey Dates", payload: .text(TextContent(text: "New York, NY • 2021 — Present", fontFamily: "Baskerville", fontSize: 12, fontWeight: 400, isItalic: true, alignment: .right, textColor: CodableColor(hex: "#4B5563"))), x: 800, y: 370, width: 340, height: 20, zIndex: 14),
                CanvasElement(name: "McKinsey Bullets", payload: .text(TextContent(text: "• Advised Fortune 50 semiconductor and cloud computing executives on multi-billion dollar capital allocation and M&A integration.\n• Formulated automated pricing engine for $14B industrial distributor, generating $140M in incremental operating EBIT in year one.\n• Managed 6 associate consultants and data scientists; received highest client satisfaction rating across Northeast practice.", fontFamily: "Baskerville", fontSize: 12.5, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#1F2937"), lineSpacing: 4)), x: 100, y: 395, width: 1040, height: 65, zIndex: 15),

                // Job 2
                CanvasElement(name: "Goldman Title", payload: .text(TextContent(text: "GOLDMAN SACHS & CO. — Investment Banking Analyst (Technology, Media & Telecom)", fontFamily: "Baskerville", fontSize: 14, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#111827"))), x: 100, y: 480, width: 750, height: 20, zIndex: 16),
                CanvasElement(name: "Goldman Dates", payload: .text(TextContent(text: "San Francisco, CA • 2017 — 2019", fontFamily: "Baskerville", fontSize: 12, fontWeight: 400, isItalic: true, alignment: .right, textColor: CodableColor(hex: "#4B5563"))), x: 800, y: 480, width: 340, height: 20, zIndex: 17),
                CanvasElement(name: "Goldman Bullets", payload: .text(TextContent(text: "• Built dynamic LBO and DCF valuation models for 7 announced M&A transactions totaling over $18.5B in aggregate enterprise value.\n• Spearheaded financial due diligence for IPO roadshows, authoring comprehensive S-1 registration statement documentation.\n• Ranked in top tier analyst cohort; awarded direct promotion to Senior Associate track.", fontFamily: "Baskerville", fontSize: 12.5, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#1F2937"), lineSpacing: 4)), x: 100, y: 505, width: 1040, height: 65, zIndex: 18),

                // ── PUBLICATIONS & FELLOWSHIPS ──
                CanvasElement(name: "Pub Sec Title", payload: .text(TextContent(text: "PUBLICATIONS & ACADEMIC HONORS", fontFamily: "Baskerville", fontSize: 14, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#111827"), letterSpacing: 2)), x: 100, y: 590, width: 1040, height: 20, zIndex: 19),
                CanvasElement(name: "Pub Sec Rule", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#9CA3AF")))), x: 100, y: 615, width: 1040, height: 1, zIndex: 20),
                CanvasElement(name: "Pub Bullets", payload: .text(TextContent(text: "• Montgomery, B. & Thorne, E. (2020). \"Algorithmic Capital Allocation in Asymmetric Private Markets.\" Harvard Business Review.\n• National Science Foundation (NSF) Graduate Research Fellow in Computational Game Theory (2017 — 2019).\n• Putnam Mathematical Competition — Ranked in Top 50 nationally across North American universities (2016).", fontFamily: "Baskerville", fontSize: 12.5, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#1F2937"), lineSpacing: 5)), x: 100, y: 628, width: 1040, height: 65, zIndex: 21),

                // ── SKILLS & PERSONAL ──
                CanvasElement(name: "Skills Sec Title", payload: .text(TextContent(text: "ADDITIONAL INFORMATION", fontFamily: "Baskerville", fontSize: 14, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#111827"), letterSpacing: 2)), x: 100, y: 715, width: 1040, height: 20, zIndex: 22),
                CanvasElement(name: "Skills Sec Rule", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#9CA3AF")))), x: 100, y: 740, width: 1040, height: 1, zIndex: 23),
                CanvasElement(name: "Skills Info", payload: .text(TextContent(text: "Technical: Python, R, SQL, Financial Modeling, Statistical Hypothesis Testing, LaTeX, Bloomberg Terminal, Capital IQ.\nLanguages: English (Native), French (Fluent / C1 Professional), Mandarin Chinese (Conversational).\nInterests: Marathon runner (Boston Marathon Qualifier: 2:48), Classical Cello (Boston Philharmonic Youth Orchestra).", fontFamily: "Baskerville", fontSize: 12.5, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#1F2937"), lineSpacing: 4)), x: 100, y: 755, width: 1040, height: 65, zIndex: 24)
            ]
        )

        return CanvasTemplate(
            id: "resume_ivy_league",
            title: "Ivy League & Academic Minimalist CV",
            category: "Resumes & CVs",
            docType: .a4,
            themeName: "Academic & Corporate",
            preset: .a4(),
            pages: [page],
            previewColorHex: "#111827"
        )
    }

    // =========================================================================
    // 5. STARTUP GROWTH & MARKETING LEAD RESUME (A4 - 1240 × 1754)
    // =========================================================================
    public static func createGrowthMarketingResumeTemplate() -> CanvasTemplate {
        let page = CanvasPage(
            name: "Growth Marketing Resume",
            width: 1240, height: 1754,
            background: FillStyle(type: .solid, solidColor: CodableColor(hex: "#FFFFFF")),
            elements: [
                // Top Header with Terracotta Banner
                CanvasElement(name: "Top Banner", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#C2410C")))), x: 0, y: 0, width: 1240, height: 170, zIndex: 0),
                CanvasElement(name: "Candidate Name", payload: .text(TextContent(text: "EMILY WATSON", fontFamily: "Inter", fontSize: 36, fontWeight: 900, alignment: .left, textColor: .white, letterSpacing: 2)), x: 70, y: 40, width: 750, height: 45, zIndex: 1),
                CanvasElement(name: "Role Title", payload: .text(TextContent(text: "VP OF GROWTH & LIFECYCLE MARKETING", fontFamily: "Inter", fontSize: 14, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#FDE047"), letterSpacing: 2)), x: 70, y: 88, width: 750, height: 22, zIndex: 2),
                CanvasElement(name: "Contact Bar", payload: .text(TextContent(text: "Austin, TX • emily.watson@growthlead.io • +1 (512) 809-4412 • linkedin.com/in/emilywatson", fontFamily: "Inter", fontSize: 11, fontWeight: 500, alignment: .left, textColor: .white)), x: 70, y: 120, width: 750, height: 20, zIndex: 3),

                // Top Right Metrics Card
                CanvasElement(name: "Metric Card", payload: .shape(ShapeContent(kind: .roundedRectangle, cornerRadius: 8, fill: FillStyle.solid(CodableColor(hex: "#FFFFFF")), stroke: StrokeStyle(isEnabled: true, color: CodableColor(hex: "#E5E7EB"), lineWidth: 1))), x: 880, y: 35, width: 290, height: 105, zIndex: 4),
                CanvasElement(name: "Metric Card Num", payload: .text(TextContent(text: "+240% ARR", fontFamily: "Inter", fontSize: 24, fontWeight: 900, alignment: .center, textColor: CodableColor(hex: "#C2410C"))), x: 890, y: 50, width: 270, height: 30, zIndex: 5),
                CanvasElement(name: "Metric Card Label", payload: .text(TextContent(text: "Top Quartile Growth Rate Scaled", fontFamily: "Inter", fontSize: 10, fontWeight: 600, alignment: .center, textColor: CodableColor(hex: "#6B7280"))), x: 890, y: 85, width: 270, height: 18, zIndex: 6),

                // ── LEFT COLUMN: WORK EXPERIENCE & CAMPAIGNS (Width: 680px) ──
                CanvasElement(name: "Exp Header", payload: .text(TextContent(text: "PROVEN TRACK RECORD & EXPERIENCE", fontFamily: "Inter", fontSize: 13, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#111827"), letterSpacing: 2)), x: 70, y: 210, width: 680, height: 20, zIndex: 7),
                CanvasElement(name: "Exp Line", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#C2410C")))), x: 70, y: 235, width: 680, height: 2, zIndex: 8),

                // Job 1
                CanvasElement(name: "GJob 1 Title", payload: .text(TextContent(text: "VP of Growth • Ramp Financial", fontFamily: "Inter", fontSize: 16, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#111827"))), x: 70, y: 250, width: 450, height: 24, zIndex: 9),
                CanvasElement(name: "GJob 1 Dates", payload: .text(TextContent(text: "2022 — PRESENT • AUSTIN, TX", fontFamily: "SF Mono", fontSize: 10, fontWeight: 600, alignment: .left, textColor: CodableColor(hex: "#6B7280"))), x: 70, y: 277, width: 450, height: 18, zIndex: 10),
                CanvasElement(name: "GJob 1 Bullets", payload: .text(TextContent(text: "• Built user acquisition loop scaling corporate cardholders from 24,000 to 180,000 active businesses.\n• Reduced blended Customer Acquisition Cost (CAC) by 41% while increasing 90-day retention to 88%.\n• Managed $18M annual paid performance budget across Google Search, Meta, LinkedIn, and influencer partnerships.\n• Built and led team of 16 growth product managers, lifecycle marketers, and data engineers.", fontFamily: "Inter", fontSize: 12, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#374151"), lineSpacing: 5)), x: 70, y: 300, width: 680, height: 95, zIndex: 11),

                // Job 2
                CanvasElement(name: "GJob 2 Title", payload: .text(TextContent(text: "Head of Demand Generation • Notion", fontFamily: "Inter", fontSize: 16, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#111827"))), x: 70, y: 415, width: 450, height: 24, zIndex: 12),
                CanvasElement(name: "GJob 2 Dates", payload: .text(TextContent(text: "2019 — 2022 • SAN FRANCISCO, CA", fontFamily: "SF Mono", fontSize: 10, fontWeight: 600, alignment: .left, textColor: CodableColor(hex: "#6B7280"))), x: 70, y: 442, width: 450, height: 18, zIndex: 13),
                CanvasElement(name: "GJob 2 Bullets", payload: .text(TextContent(text: "• Championed product-led growth (PLG) viral loops generating 4.8M organic signups via community template directory.\n• Orchestrated enterprise self-serve conversion pipeline increasing workspace expansions by 210% YoY.\n• Designed and automated multi-touch lifecycle email onboarding sequence engaging 12M monthly active users.", fontFamily: "Inter", fontSize: 12, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#374151"), lineSpacing: 5)), x: 70, y: 465, width: 680, height: 80, zIndex: 14),

                // Job 3
                CanvasElement(name: "GJob 3 Title", payload: .text(TextContent(text: "Senior Growth Manager • Webflow", fontFamily: "Inter", fontSize: 16, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#111827"))), x: 70, y: 565, width: 450, height: 24, zIndex: 15),
                CanvasElement(name: "GJob 3 Dates", payload: .text(TextContent(text: "2017 — 2019 • SAN FRANCISCO, CA", fontFamily: "SF Mono", fontSize: 10, fontWeight: 600, alignment: .left, textColor: CodableColor(hex: "#6B7280"))), x: 70, y: 592, width: 450, height: 18, zIndex: 16),
                CanvasElement(name: "GJob 3 Bullets", payload: .text(TextContent(text: "• Executed 120+ A/B conversion experiments on high-traffic landing pages improving signup conversion rate by 28%.\n• Pioneered SEO programmatic hub architecture ranking #1 for 4,500+ design and web development keywords.", fontFamily: "Inter", fontSize: 12, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#374151"), lineSpacing: 5)), x: 70, y: 615, width: 680, height: 60, zIndex: 17),

                // ── RIGHT COLUMN: SKILLS, TOOLING & EDUCATION (Width: 380px) ──
                CanvasElement(name: "Growth Stack Title", payload: .text(TextContent(text: "GROWTH STACK & TOOLING", fontFamily: "Inter", fontSize: 13, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#111827"), letterSpacing: 2)), x: 790, y: 210, width: 380, height: 20, zIndex: 18),
                CanvasElement(name: "Growth Stack Line", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#111827")))), x: 790, y: 235, width: 380, height: 2, zIndex: 19),

                CanvasElement(name: "Tool Group 1", payload: .text(TextContent(text: "ANALYTICS & EXPERIMENTATION\nMixpanel, Amplitude, PostHog, SQL, dbt, Statsig, Optimizely, Segment", fontFamily: "SF Mono", fontSize: 11, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#1F2937"), lineSpacing: 4)), x: 790, y: 250, width: 380, height: 50, zIndex: 20),
                CanvasElement(name: "Tool Group 2", payload: .text(TextContent(text: "ACQUISITION & CHANNELS\nGoogle Ads, Meta Ads Manager, LinkedIn Campaign Manager, App Store Optimization", fontFamily: "SF Mono", fontSize: 11, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#1F2937"), lineSpacing: 4)), x: 790, y: 315, width: 380, height: 50, zIndex: 21),
                CanvasElement(name: "Tool Group 3", payload: .text(TextContent(text: "LIFECYCLE & AUTOMATION\nCustomer.io, Braze, HubSpot, Zapier, Webflow, Figma, Clearbit", fontFamily: "SF Mono", fontSize: 11, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#1F2937"), lineSpacing: 4)), x: 790, y: 380, width: 380, height: 50, zIndex: 22),

                // Education
                CanvasElement(name: "Edu Header", payload: .text(TextContent(text: "EDUCATION", fontFamily: "Inter", fontSize: 13, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#111827"), letterSpacing: 2)), x: 790, y: 460, width: 380, height: 20, zIndex: 23),
                CanvasElement(name: "Edu Line", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#111827")))), x: 790, y: 485, width: 380, height: 2, zIndex: 24),
                CanvasElement(name: "Edu Degree", payload: .text(TextContent(text: "B.A. in Economics & Data Science\nUniversity of Texas at Austin (Honors, 2017)", fontFamily: "Inter", fontSize: 12.5, fontWeight: 700, alignment: .left, textColor: CodableColor(hex: "#111827"), lineSpacing: 3)), x: 790, y: 500, width: 380, height: 40, zIndex: 25)
            ]
        )

        return CanvasTemplate(
            id: "resume_growth_marketing",
            title: "Startup Growth & Marketing Lead Resume",
            category: "Resumes & CVs",
            docType: .a4,
            themeName: "Marketing & Growth",
            preset: .a4(),
            pages: [page],
            previewColorHex: "#C2410C"
        )
    }

    // =========================================================================
    // 6. CLEAN TWO-COLUMN MINIMAL RESUME (Teal Accent — Universal/ATS Friendly)
    // =========================================================================
    public static func createTwoColumnMinimalResumeTemplate() -> CanvasTemplate {
        let page = CanvasPage(
            name: "Two-Column Minimal Resume",
            width: 1240, height: 1754,
            background: FillStyle(type: .solid, solidColor: CodableColor(hex: "#FFFFFF")),
            elements: [
                // Left sidebar (soft gray)
                CanvasElement(name: "Sidebar BG", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#F0FDFA")))), x: 0, y: 0, width: 420, height: 1754, zIndex: 0),
                CanvasElement(name: "Sidebar Edge", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#0D9488")))), x: 420, y: 0, width: 5, height: 1754, zIndex: 1),

                // Header
                CanvasElement(name: "Name", payload: .text(TextContent(text: "SARAH KIM", fontFamily: "Inter", fontSize: 40, fontWeight: 900, alignment: .left, textColor: CodableColor(hex: "#134E4A"), letterSpacing: 3)), x: 60, y: 106, width: 340, height: 50, zIndex: 2),
                CanvasElement(name: "Role", payload: .text(TextContent(text: "Full-Stack Developer", fontFamily: "Inter", fontSize: 17, fontWeight: 600, alignment: .left, textColor: CodableColor(hex: "#0D9488"))), x: 60, y: 190, width: 340, height: 26, zIndex: 3),

                // Contact block
                CanvasElement(name: "Contact Title", payload: .text(TextContent(text: "CONTACT", fontFamily: "Inter", fontSize: 12, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#134E4A"), letterSpacing: 2)), x: 60, y: 319, width: 300, height: 20, zIndex: 4),
                CanvasElement(name: "Contact Rule", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#0D9488")))), x: 60, y: 359, width: 60, height: 3, zIndex: 5),
                CanvasElement(name: "Contact Info", payload: .text(TextContent(text: "sarah.kim@dev.io\n+1 (206) 555-0177\nSeattle, WA\nsarahkim.dev\ngithub.com/sarahkim\nlinkedin.com/in/sarahkim", fontFamily: "Inter", fontSize: 12, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#3F3F46"), lineSpacing: 7)), x: 60, y: 383, width: 320, height: 130, zIndex: 6),

                // Skills
                CanvasElement(name: "Skills Title", payload: .text(TextContent(text: "SKILLS", fontFamily: "Inter", fontSize: 12, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#134E4A"), letterSpacing: 2)), x: 60, y: 638, width: 300, height: 20, zIndex: 7),
                CanvasElement(name: "Skills Rule", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#0D9488")))), x: 60, y: 678, width: 60, height: 3, zIndex: 8),
                CanvasElement(name: "Skills List", payload: .text(TextContent(text: "• TypeScript / JavaScript\n• React, Next.js, Vue\n• Node.js, GraphQL\n• PostgreSQL, Redis\n• AWS, Docker, CI/CD\n• Swift & SwiftUI\n• Figma, Design Systems\n• Agile / Scrum", fontFamily: "Inter", fontSize: 12, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#3F3F46"), lineSpacing: 7)), x: 60, y: 702, width: 320, height: 180, zIndex: 9),

                // Languages
                CanvasElement(name: "Lang Title", payload: .text(TextContent(text: "LANGUAGES", fontFamily: "Inter", fontSize: 12, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#134E4A"), letterSpacing: 2)), x: 60, y: 1034, width: 300, height: 20, zIndex: 10),
                CanvasElement(name: "Lang Rule", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#0D9488")))), x: 60, y: 1073, width: 60, height: 3, zIndex: 11),
                CanvasElement(name: "Lang List", payload: .text(TextContent(text: "English — Native\nKorean — Fluent\nJapanese — Conversational", fontFamily: "Inter", fontSize: 12, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#3F3F46"), lineSpacing: 7)), x: 60, y: 1097, width: 320, height: 80, zIndex: 12),

                // Certifications
                CanvasElement(name: "Cert Title", payload: .text(TextContent(text: "CERTIFICATIONS", fontFamily: "Inter", fontSize: 12, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#134E4A"), letterSpacing: 2)), x: 60, y: 1277, width: 300, height: 20, zIndex: 13),
                CanvasElement(name: "Cert Rule", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#0D9488")))), x: 60, y: 1316, width: 60, height: 3, zIndex: 14),
                CanvasElement(name: "Cert List", payload: .text(TextContent(text: "• AWS Solutions Architect\n• Google Cloud Professional\n• CKA (Kubernetes Admin)", fontFamily: "Inter", fontSize: 12, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#3F3F46"), lineSpacing: 7)), x: 60, y: 1341, width: 320, height: 80, zIndex: 15),

                // ── RIGHT COLUMN ──
                CanvasElement(name: "Summary Title", payload: .text(TextContent(text: "PROFILE", fontFamily: "Inter", fontSize: 13, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#134E4A"), letterSpacing: 2)), x: 480, y: 106, width: 690, height: 22, zIndex: 16),
                CanvasElement(name: "Summary Rule", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#0D9488")))), x: 480, y: 146, width: 690, height: 2.5, zIndex: 17),
                CanvasElement(name: "Summary Text", payload: .text(TextContent(text: "Full-stack developer with 7 years of experience building performant web applications used by millions. Passionate about developer experience, design systems, and shipping products that feel effortless. Proven record of leading cross-functional teams and mentoring junior engineers.", fontFamily: "Inter", fontSize: 12.5, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#27272A"), lineSpacing: 5)), x: 480, y: 167, width: 690, height: 70, zIndex: 18),

                CanvasElement(name: "Exp Title", payload: .text(TextContent(text: "EXPERIENCE", fontFamily: "Inter", fontSize: 13, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#134E4A"), letterSpacing: 2)), x: 480, y: 319, width: 690, height: 22, zIndex: 19),
                CanvasElement(name: "Exp Rule", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#0D9488")))), x: 480, y: 359, width: 690, height: 2.5, zIndex: 20),

                CanvasElement(name: "Job1 Head", payload: .text(TextContent(text: "Senior Software Engineer • Shopify", fontFamily: "Inter", fontSize: 15, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#18181B"))), x: 480, y: 383, width: 480, height: 22, zIndex: 21),
                CanvasElement(name: "Job1 Dates", payload: .text(TextContent(text: "2021 — Present", fontFamily: "Inter", fontSize: 11, fontWeight: 600, alignment: .right, textColor: CodableColor(hex: "#0D9488"))), x: 980, y: 386, width: 190, height: 20, zIndex: 22),
                CanvasElement(name: "Job1 Bullets", payload: .text(TextContent(text: "• Led checkout performance initiative, cutting Time-to-Interactive by 42% across 2M+ storefronts.\n• Designed and shipped GraphQL federation layer unifying 14 backend services.\n• Mentor to 5 engineers; run the frontend guild and interview loop.", fontFamily: "Inter", fontSize: 12, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#27272A"), lineSpacing: 5)), x: 480, y: 423, width: 690, height: 80, zIndex: 23),

                CanvasElement(name: "Job2 Head", payload: .text(TextContent(text: "Software Engineer • Airbnb", fontFamily: "Inter", fontSize: 15, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#18181B"))), x: 480, y: 578, width: 480, height: 22, zIndex: 24),
                CanvasElement(name: "Job2 Dates", payload: .text(TextContent(text: "2018 — 2021", fontFamily: "Inter", fontSize: 11, fontWeight: 600, alignment: .right, textColor: CodableColor(hex: "#0D9488"))), x: 980, y: 581, width: 190, height: 20, zIndex: 25),
                CanvasElement(name: "Job2 Bullets", payload: .text(TextContent(text: "• Built host earnings dashboard adopted by 4M hosts; 98% task-completion satisfaction.\n• Migrated legacy Rails views to React Server Components, halving page weight.\n• Won internal hackathon with accessibility linter now standard across the codebase.", fontFamily: "Inter", fontSize: 12, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#27272A"), lineSpacing: 5)), x: 480, y: 617, width: 690, height: 80, zIndex: 26),

                CanvasElement(name: "Job3 Head", payload: .text(TextContent(text: "Frontend Developer • Zoom (Contract)", fontFamily: "Inter", fontSize: 15, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#18181B"))), x: 480, y: 772, width: 480, height: 22, zIndex: 27),
                CanvasElement(name: "Job3 Dates", payload: .text(TextContent(text: "2017 — 2018", fontFamily: "Inter", fontSize: 11, fontWeight: 600, alignment: .right, textColor: CodableColor(hex: "#0D9488"))), x: 980, y: 775, width: 190, height: 20, zIndex: 28),
                CanvasElement(name: "Job3 Bullets", payload: .text(TextContent(text: "• Shipped webinar registration flows handling 300K concurrent registrations.\n• Established component library with Storybook used by 40+ engineers.", fontFamily: "Inter", fontSize: 12, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#27272A"), lineSpacing: 5)), x: 480, y: 812, width: 690, height: 55, zIndex: 29),

                CanvasElement(name: "Edu Title", payload: .text(TextContent(text: "EDUCATION", fontFamily: "Inter", fontSize: 13, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#134E4A"), letterSpacing: 2)), x: 480, y: 942, width: 690, height: 22, zIndex: 30),
                CanvasElement(name: "Edu Rule", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#0D9488")))), x: 480, y: 982, width: 690, height: 2.5, zIndex: 31),
                CanvasElement(name: "Edu 1", payload: .text(TextContent(text: "B.S. Computer Science • University of Washington — 2017\nCum Laude • Dean's List (8 quarters) • Teaching Assistant for Data Structures", fontFamily: "Inter", fontSize: 12.5, fontWeight: 500, alignment: .left, textColor: CodableColor(hex: "#27272A"), lineSpacing: 5)), x: 480, y: 1006, width: 690, height: 45, zIndex: 32),

                CanvasElement(name: "Proj Title", payload: .text(TextContent(text: "SELECTED PROJECTS", fontFamily: "Inter", fontSize: 13, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#134E4A"), letterSpacing: 2)), x: 480, y: 1125, width: 690, height: 22, zIndex: 33),
                CanvasElement(name: "Proj Rule", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#0D9488")))), x: 480, y: 1164, width: 690, height: 2.5, zIndex: 34),
                CanvasElement(name: "Proj List", payload: .text(TextContent(text: "• DevLens (12k GitHub stars) — Open-source code review analytics dashboard.\n• Ferry Tracker — Real-time Seattle ferry PWA with offline support, 40k MAU.\n• A11y Audit Kit — CLI accessibility scanner integrated into 200+ repos.", fontFamily: "Inter", fontSize: 12, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#27272A"), lineSpacing: 5)), x: 480, y: 1189, width: 690, height: 70, zIndex: 35)
            ]
        )

        return CanvasTemplate(
            id: "resume_two_column_minimal",
            title: "Clean Two-Column Developer Resume",
            category: "Resumes & CVs",
            docType: .a4,
            themeName: "Minimal & Modern",
            preset: .a4(),
            pages: [page],
            previewColorHex: "#0D9488"
        )
    }

    // =========================================================================
    // 7. BOLD IMPACT CREATIVE RESUME (Violet — Designers, Creators, Media)
    // =========================================================================
    public static func createBoldImpactResumeTemplate() -> CanvasTemplate {
        let page = CanvasPage(
            name: "Bold Impact Resume",
            width: 1240, height: 1754,
            background: FillStyle(type: .solid, solidColor: CodableColor(hex: "#1E1B4B")),
            elements: [
                CanvasElement(name: "Accent Blob", payload: .shape(ShapeContent(kind: .circle, fill: FillStyle(type: .radialGradient, solidColor: CodableColor(hex: "#8B5CF6"), gradientStops: [GradientStop(color: CodableColor(hex: "#8B5CF6"), location: 0), GradientStop(color: CodableColor(hex: "#1E1B4B"), location: 1)]))), x: 850, y: -180, width: 620, height: 620, zIndex: 0),
                CanvasElement(name: "Accent Blob 2", payload: .shape(ShapeContent(kind: .circle, fill: FillStyle(type: .radialGradient, solidColor: CodableColor(hex: "#EC4899"), gradientStops: [GradientStop(color: CodableColor(hex: "#EC4899"), location: 0), GradientStop(color: CodableColor(hex: "#1E1B4B"), location: 1)]))), x: -220, y: 2052, width: 560, height: 560, zIndex: 0),

                CanvasElement(name: "Name", payload: .text(TextContent(text: "ZOE MARTINEZ", fontFamily: "Inter", fontSize: 52, fontWeight: 900, alignment: .left, textColor: .white, letterSpacing: 1)), x: 80, y: 137, width: 900, height: 62, zIndex: 2),
                CanvasElement(name: "Role", payload: .text(TextContent(text: "PRODUCT DESIGNER & ART DIRECTOR", fontFamily: "Inter", fontSize: 16, fontWeight: 700, alignment: .left, textColor: CodableColor(hex: "#C4B5FD"), letterSpacing: 4)), x: 82, y: 240, width: 800, height: 24, zIndex: 3),
                CanvasElement(name: "Contact", payload: .text(TextContent(text: "zoe@martinez.design   •   +1 (917) 555-0142   •   martinez.design   •   @zoemakes", fontFamily: "Inter", fontSize: 12, fontWeight: 500, alignment: .left, textColor: CodableColor(hex: "#A5B4FC"))), x: 82, y: 292, width: 900, height: 20, zIndex: 4),

                CanvasElement(name: "Summary Card", payload: .shape(ShapeContent(kind: .roundedRectangle, cornerRadius: 16, fill: FillStyle.solid(CodableColor(hex: "#312E81", opacity: 1)))), x: 80, y: 380, width: 1080, height: 110, zIndex: 5),
                CanvasElement(name: "Summary Text", payload: .text(TextContent(text: "Award-winning product designer blending bold visual systems with rigorous UX research. 9 years shipping delightful products for fintech, social, and creator-economy brands. My work has reached 80M+ users and been featured by App of the Day three times.", fontFamily: "Inter", fontSize: 13.5, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#E0E7FF"), lineSpacing: 6)), x: 110, y: 413, width: 1020, height: 70, zIndex: 6),

                CanvasElement(name: "Exp Label", payload: .text(TextContent(text: "EXPERIENCE", fontFamily: "Inter", fontSize: 14, fontWeight: 900, alignment: .left, textColor: CodableColor(hex: "#C4B5FD"), letterSpacing: 3)), x: 80, y: 608, width: 400, height: 24, zIndex: 7),
                CanvasElement(name: "Exp Rule", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#8B5CF6")))), x: 80, y: 654, width: 1080, height: 3, zIndex: 8),

                CanvasElement(name: "J1 Title", payload: .text(TextContent(text: "Lead Product Designer • Spotify", fontFamily: "Inter", fontSize: 17, fontWeight: 800, alignment: .left, textColor: .white)), x: 80, y: 687, width: 700, height: 26, zIndex: 9),
                CanvasElement(name: "J1 Dates", payload: .text(TextContent(text: "2022 — NOW", fontFamily: "Inter", fontSize: 11, fontWeight: 800, alignment: .right, textColor: CodableColor(hex: "#EC4899"))), x: 940, y: 693, width: 220, height: 20, zIndex: 10),
                CanvasElement(name: "J1 Bullets", payload: .text(TextContent(text: "• Own end-to-end design for playlist creation used by 60M monthly creators.\n• Built the motion language for Wrapped 2024 — 425M shares in one week.\n• Lead crits and design sprints for a squad of 9 designers and researchers.", fontFamily: "Inter", fontSize: 12.5, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#C7D2FE"), lineSpacing: 6)), x: 80, y: 736, width: 1080, height: 80, zIndex: 11),

                CanvasElement(name: "J2 Title", payload: .text(TextContent(text: "Senior Product Designer • Cash App", fontFamily: "Inter", fontSize: 17, fontWeight: 800, alignment: .left, textColor: .white)), x: 80, y: 889, width: 700, height: 26, zIndex: 12),
                CanvasElement(name: "J2 Dates", payload: .text(TextContent(text: "2019 — 2022", fontFamily: "Inter", fontSize: 11, fontWeight: 800, alignment: .right, textColor: CodableColor(hex: "#EC4899"))), x: 940, y: 895, width: 220, height: 20, zIndex: 13),
                CanvasElement(name: "J2 Bullets", payload: .text(TextContent(text: "• Redesigned onboarding, lifting activation 31% and cutting support tickets in half.\n• Created the Boost design system — 120+ components adopted by 8 product teams.\n• Shipped the physical Cash Card unboxing experience with 2.1M first-year orders.", fontFamily: "Inter", fontSize: 12.5, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#C7D2FE"), lineSpacing: 6)), x: 80, y: 938, width: 1080, height: 80, zIndex: 14),

                CanvasElement(name: "J3 Title", payload: .text(TextContent(text: "Product Designer • VICE Media", fontFamily: "Inter", fontSize: 17, fontWeight: 800, alignment: .left, textColor: .white)), x: 80, y: 1091, width: 700, height: 26, zIndex: 15),
                CanvasElement(name: "J3 Dates", payload: .text(TextContent(text: "2016 — 2019", fontFamily: "Inter", fontSize: 11, fontWeight: 800, alignment: .right, textColor: CodableColor(hex: "#EC4899"))), x: 940, y: 1097, width: 220, height: 20, zIndex: 16),
                CanvasElement(name: "J3 Bullets", payload: .text(TextContent(text: "• Designed editorial experiences for a 30M-audience across web and apps.\n• Art-directed 40+ interactive longform stories, 3 Webby honorees.", fontFamily: "Inter", fontSize: 12.5, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#C7D2FE"), lineSpacing: 6)), x: 80, y: 1140, width: 1080, height: 55, zIndex: 17),

                // Skills chips
                CanvasElement(name: "Skills Label", payload: .text(TextContent(text: "SUPERPOWERS", fontFamily: "Inter", fontSize: 14, fontWeight: 900, alignment: .left, textColor: CodableColor(hex: "#C4B5FD"), letterSpacing: 3)), x: 80, y: 1284, width: 400, height: 24, zIndex: 18),
                CanvasElement(name: "Skills Rule", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#8B5CF6")))), x: 80, y: 1330, width: 1080, height: 3, zIndex: 19),
                CanvasElement(name: "Skills Col 1", payload: .text(TextContent(text: "• Product Strategy & Vision\n• Design Systems (Figma)\n• Motion & Prototyping\n• User Research & Testing", fontFamily: "Inter", fontSize: 12.5, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#E0E7FF"), lineSpacing: 7)), x: 80, y: 1360, width: 340, height: 110, zIndex: 20),
                CanvasElement(name: "Skills Col 2", payload: .text(TextContent(text: "• Figma, Principle, Rive\n• After Effects, Cinema 4D\n• HTML/CSS, Swift (basic)\n• Workshop Facilitation", fontFamily: "Inter", fontSize: 12.5, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#E0E7FF"), lineSpacing: 7)), x: 450, y: 1360, width: 340, height: 110, zIndex: 21),
                CanvasElement(name: "Skills Col 3", payload: .text(TextContent(text: "• Awwwards SOTD (2×)\n• ADC Young Guns 19\n• App of the Day (3×)\n• Fast Company Innovation", fontFamily: "Inter", fontSize: 12.5, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#E0E7FF"), lineSpacing: 7)), x: 820, y: 1360, width: 340, height: 110, zIndex: 22),

                // Education
                CanvasElement(name: "Edu Label", payload: .text(TextContent(text: "EDUCATION", fontFamily: "Inter", fontSize: 14, fontWeight: 900, alignment: .left, textColor: CodableColor(hex: "#C4B5FD"), letterSpacing: 3)), x: 80, y: 1581, width: 400, height: 24, zIndex: 23),
                CanvasElement(name: "Edu Rule", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#8B5CF6")))), x: 80, y: 1626, width: 1080, height: 3, zIndex: 24),
                CanvasElement(name: "Edu Text", payload: .text(TextContent(text: "BFA Communication Design • Parsons School of Design — 2016\nInteraction Design Specialization • Copenhagen Institute of Interaction Design (CIID) — 2017", fontFamily: "Inter", fontSize: 12.5, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#C7D2FE"), lineSpacing: 6)), x: 80, y: 1657, width: 1080, height: 50, zIndex: 25)
            ]
        )

        return CanvasTemplate(
            id: "resume_bold_impact",
            title: "Bold Impact Creative Resume",
            category: "Resumes & CVs",
            docType: .a4,
            themeName: "Bold & Creative",
            preset: .a4(),
            pages: [page],
            previewColorHex: "#8B5CF6"
        )
    }

    // =========================================================================
    // 8. HEALTHCARE & CLINICAL RESUME (Calm Blue — Nurses, Med Techs, Care)
    // =========================================================================
    public static func createHealthcareResumeTemplate() -> CanvasTemplate {
        let page = CanvasPage(
            name: "Healthcare Resume",
            width: 1240, height: 1754,
            background: FillStyle(type: .solid, solidColor: CodableColor(hex: "#FFFFFF")),
            elements: [
                CanvasElement(name: "Header Band", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#0369A1")))), x: 0, y: 0, width: 1240, height: 200, zIndex: 0),
                CanvasElement(name: "Header Accent", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#22D3EE")))), x: 0, y: 304, width: 1240, height: 6, zIndex: 1),

                CanvasElement(name: "Name", payload: .text(TextContent(text: "RACHEL OSEI, RN, BSN", fontFamily: "Inter", fontSize: 36, fontWeight: 900, alignment: .left, textColor: .white, letterSpacing: 1)), x: 70, y: 73, width: 800, height: 46, zIndex: 2),
                CanvasElement(name: "Role", payload: .text(TextContent(text: "Critical Care Registered Nurse • ICU / ER", fontFamily: "Inter", fontSize: 17, fontWeight: 600, alignment: .left, textColor: CodableColor(hex: "#BAE6FD"))), x: 70, y: 152, width: 700, height: 26, zIndex: 3),
                CanvasElement(name: "Contact", payload: .text(TextContent(text: "Chicago, IL • rachel.osei@caremail.com • +1 (312) 555-0186 • RN License #IL-428-9912 • BLS/ACLS Certified", fontFamily: "Inter", fontSize: 12, fontWeight: 500, alignment: .left, textColor: CodableColor(hex: "#E0F2FE"))), x: 70, y: 207, width: 1100, height: 22, zIndex: 4),

                CanvasElement(name: "Summary Title", payload: .text(TextContent(text: "PROFESSIONAL SUMMARY", fontFamily: "Inter", fontSize: 14, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#0369A1"), letterSpacing: 2)), x: 70, y: 365, width: 1100, height: 22, zIndex: 5),
                CanvasElement(name: "Summary Rule", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#22D3EE")))), x: 70, y: 404, width: 1100, height: 2.5, zIndex: 6),
                CanvasElement(name: "Summary Text", payload: .text(TextContent(text: "Compassionate critical-care RN with 8+ years across ICU and emergency settings. Expert in hemodynamic monitoring, ventilator management, and rapid-response leadership. Recognized with two DAISY Awards for extraordinary nursing; preceptor to 20+ new graduates.", fontFamily: "Inter", fontSize: 12.5, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#27272A"), lineSpacing: 5)), x: 70, y: 426, width: 1100, height: 60, zIndex: 7),

                CanvasElement(name: "Exp Title", payload: .text(TextContent(text: "CLINICAL EXPERIENCE", fontFamily: "Inter", fontSize: 14, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#0369A1"), letterSpacing: 2)), x: 70, y: 562, width: 1100, height: 22, zIndex: 8),
                CanvasElement(name: "Exp Rule", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#22D3EE")))), x: 70, y: 602, width: 1100, height: 2.5, zIndex: 9),

                CanvasElement(name: "J1 Head", payload: .text(TextContent(text: "Charge Nurse, Medical ICU • Northwestern Memorial Hospital", fontFamily: "Inter", fontSize: 15, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#18181B"))), x: 70, y: 629, width: 850, height: 22, zIndex: 10),
                CanvasElement(name: "J1 Dates", payload: .text(TextContent(text: "2019 — Present", fontFamily: "Inter", fontSize: 11, fontWeight: 700, alignment: .right, textColor: CodableColor(hex: "#0369A1"))), x: 950, y: 632, width: 220, height: 20, zIndex: 11),
                CanvasElement(name: "J1 Bullets", payload: .text(TextContent(text: "• Lead a 24-bed medical ICU; coordinate staffing, assignments, and escalation for 40 nurses per shift.\n• Reduced central-line infections 38% by championing a bundle-compliance program and bedside audits.\n• Precept 20+ new graduates and nursing students; developed the unit's structured orientation curriculum.\n• Respond as member of the hospital rapid-response and code-blue teams.", fontFamily: "Inter", fontSize: 12, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#27272A"), lineSpacing: 5)), x: 70, y: 669, width: 1100, height: 100, zIndex: 12),

                CanvasElement(name: "J2 Head", payload: .text(TextContent(text: "ICU Staff Nurse • Rush University Medical Center", fontFamily: "Inter", fontSize: 15, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#18181B"))), x: 70, y: 851, width: 850, height: 22, zIndex: 13),
                CanvasElement(name: "J2 Dates", payload: .text(TextContent(text: "2016 — 2019", fontFamily: "Inter", fontSize: 11, fontWeight: 700, alignment: .right, textColor: CodableColor(hex: "#0369A1"))), x: 950, y: 854, width: 220, height: 20, zIndex: 14),
                CanvasElement(name: "J2 Bullets", payload: .text(TextContent(text: "• Managed care for 4–6 high-acuity patients including CRRT, ECMO, and mechanical circulatory support.\n• Served on the hospital-wide sepsis bundle task force, improving 3-hour bundle compliance from 74% to 96%.\n• DAISY Award recipient (2021, 2023) for compassionate, extraordinary patient care.", fontFamily: "Inter", fontSize: 12, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#27272A"), lineSpacing: 5)), x: 70, y: 891, width: 1100, height: 80, zIndex: 15),

                CanvasElement(name: "J3 Head", payload: .text(TextContent(text: "Emergency Department Nurse • Cook County Health", fontFamily: "Inter", fontSize: 15, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#18181B"))), x: 70, y: 1043, width: 850, height: 22, zIndex: 16),
                CanvasElement(name: "J3 Dates", payload: .text(TextContent(text: "2014 — 2016", fontFamily: "Inter", fontSize: 11, fontWeight: 700, alignment: .right, textColor: CodableColor(hex: "#0369A1"))), x: 950, y: 1046, width: 220, height: 20, zIndex: 17),
                CanvasElement(name: "J3 Bullets", payload: .text(TextContent(text: "• Triage and stabilized 60+ patients per shift in a Level 1 trauma center.\n• Cross-trained in disaster response; deployed for city-wide mass-casualty drills.", fontFamily: "Inter", fontSize: 12, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#27272A"), lineSpacing: 5)), x: 70, y: 1082, width: 1100, height: 55, zIndex: 18),

                CanvasElement(name: "Edu Title", payload: .text(TextContent(text: "EDUCATION & LICENSURE", fontFamily: "Inter", fontSize: 14, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#0369A1"), letterSpacing: 2)), x: 70, y: 1216, width: 1100, height: 22, zIndex: 19),
                CanvasElement(name: "Edu Rule", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#22D3EE")))), x: 70, y: 1256, width: 1100, height: 2.5, zIndex: 20),
                CanvasElement(name: "Edu Text", payload: .text(TextContent(text: "Bachelor of Science in Nursing (BSN) • Loyola University Chicago — 2014, Magna Cum Laude\nIllinois RN License #IL-428-9912 • CCRN (Critical Care RN) Certification — 2020\nCertifications: BLS • ACLS • PALS • TNCC (Trauma Nursing Core Course)", fontFamily: "Inter", fontSize: 12, fontWeight: 500, alignment: .left, textColor: CodableColor(hex: "#27272A"), lineSpacing: 6)), x: 70, y: 1280, width: 1100, height: 70, zIndex: 21),

                CanvasElement(name: "Skill Title", payload: .text(TextContent(text: "CORE COMPETENCIES", fontFamily: "Inter", fontSize: 14, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#0369A1"), letterSpacing: 2)), x: 70, y: 1429, width: 1100, height: 22, zIndex: 22),
                CanvasElement(name: "Skill Rule", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#22D3EE")))), x: 70, y: 1468, width: 1100, height: 2.5, zIndex: 23),
                CanvasElement(name: "Skill Col 1", payload: .text(TextContent(text: "• Hemodynamic Monitoring\n• Ventilator Management\n• CRRT / ECMO Care\n• Sepsis Bundle Protocols", fontFamily: "Inter", fontSize: 12, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#27272A"), lineSpacing: 7)), x: 70, y: 1493, width: 350, height: 100, zIndex: 24),
                CanvasElement(name: "Skill Col 2", payload: .text(TextContent(text: "• Epic & Cerner EHR Systems\n• Rapid Response Leadership\n• Patient & Family Education\n• Cross-Cultural Care", fontFamily: "Inter", fontSize: 12, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#27272A"), lineSpacing: 7)), x: 450, y: 1493, width: 350, height: 100, zIndex: 25),
                CanvasElement(name: "Skill Col 3", payload: .text(TextContent(text: "• Preceptorship & Mentoring\n• Quality Improvement\n• Code Blue Team\n• English (Native), French (Medical)", fontFamily: "Inter", fontSize: 12, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#27272A"), lineSpacing: 7)), x: 830, y: 1493, width: 350, height: 100, zIndex: 26)
            ]
        )

        return CanvasTemplate(
            id: "resume_healthcare",
            title: "Healthcare & Clinical Resume",
            category: "Resumes & CVs",
            docType: .a4,
            themeName: "Healthcare",
            preset: .a4(),
            pages: [page],
            previewColorHex: "#0369A1"
        )
    }

    // =========================================================================
    // 9. STUDENT / NEW-GRAD INTERNSHIP RESUME (Fresh, Clean, One Page)
    // =========================================================================
    public static func createStudentInternshipResumeTemplate() -> CanvasTemplate {
        let page = CanvasPage(
            name: "Student Internship Resume",
            width: 1240, height: 1754,
            background: FillStyle(type: .solid, solidColor: CodableColor(hex: "#FFFFFF")),
            elements: [
                CanvasElement(name: "Name", payload: .text(TextContent(text: "ALEX RIVERA", fontFamily: "Inter", fontSize: 34, fontWeight: 900, alignment: .center, textColor: CodableColor(hex: "#111827"), letterSpacing: 3)), x: 100, y: 91, width: 1040, height: 44, zIndex: 0),
                CanvasElement(name: "Tagline", payload: .text(TextContent(text: "COMPUTER SCIENCE STUDENT • CLASS OF 2026 • SEEKING SUMMER 2025 SOFTWARE INTERNSHIP", fontFamily: "Inter", fontSize: 11.5, fontWeight: 700, alignment: .center, textColor: CodableColor(hex: "#2563EB"), letterSpacing: 1)), x: 100, y: 164, width: 1040, height: 20, zIndex: 1),
                CanvasElement(name: "Contact", payload: .text(TextContent(text: "Berkeley, CA • alex.rivera@berkeley.edu • +1 (510) 555-0139 • github.com/alexr • alexrivera.dev", fontFamily: "Inter", fontSize: 12, fontWeight: 400, alignment: .center, textColor: CodableColor(hex: "#374151"))), x: 100, y: 204, width: 1040, height: 20, zIndex: 2),
                CanvasElement(name: "Header Rule", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#2563EB")))), x: 470, y: 252, width: 300, height: 3, zIndex: 3),

                CanvasElement(name: "Edu Title", payload: .text(TextContent(text: "EDUCATION", fontFamily: "Inter", fontSize: 13, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#111827"), letterSpacing: 2)), x: 100, y: 304, width: 1040, height: 20, zIndex: 4),
                CanvasElement(name: "Edu Rule", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#2563EB")))), x: 100, y: 340, width: 1040, height: 2, zIndex: 5),
                CanvasElement(name: "Edu School", payload: .text(TextContent(text: "UC BERKELEY — B.S. Computer Science (Expected May 2026)", fontFamily: "Inter", fontSize: 13.5, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#111827"))), x: 100, y: 362, width: 760, height: 20, zIndex: 6),
                CanvasElement(name: "Edu GPA", payload: .text(TextContent(text: "GPA: 3.86 / 4.00", fontFamily: "Inter", fontSize: 12.5, fontWeight: 700, alignment: .right, textColor: CodableColor(hex: "#2563EB"))), x: 880, y: 362, width: 260, height: 20, zIndex: 7),
                CanvasElement(name: "Edu Detail", payload: .text(TextContent(text: "Coursework: Data Structures, Algorithms, Computer Architecture, Databases, Operating Systems, Machine Learning\nHonors: EECS Departmental Scholar • Regents' and Chancellor's Scholar • Dean's List (4 semesters)", fontFamily: "Inter", fontSize: 12, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#374151"), lineSpacing: 5)), x: 100, y: 398, width: 1040, height: 40, zIndex: 8),

                CanvasElement(name: "Exp Title", payload: .text(TextContent(text: "EXPERIENCE & PROJECTS", fontFamily: "Inter", fontSize: 13, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#111827"), letterSpacing: 2)), x: 100, y: 502, width: 1040, height: 20, zIndex: 9),
                CanvasElement(name: "Exp Rule", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#2563EB")))), x: 100, y: 538, width: 1040, height: 2, zIndex: 10),

                CanvasElement(name: "P1 Head", payload: .text(TextContent(text: "Undergraduate Research Assistant • Berkeley Artificial Intelligence Research (BAIR)", fontFamily: "Inter", fontSize: 13, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#111827"))), x: 100, y: 562, width: 800, height: 20, zIndex: 11),
                CanvasElement(name: "P1 Dates", payload: .text(TextContent(text: "2023 — Present", fontFamily: "Inter", fontSize: 11, fontWeight: 700, alignment: .right, textColor: CodableColor(hex: "#2563EB"))), x: 920, y: 564, width: 220, height: 20, zIndex: 12),
                CanvasElement(name: "P1 Bullets", payload: .text(TextContent(text: "• Built data pipelines processing 2M+ labeled images for embodied-AI navigation research (CoRL submission).\n• Wrote PyTorch training utilities adopted by 12 lab members; cut experiment setup time by 60%.\n• Co-authored workshop paper on sample-efficient imitation learning.", fontFamily: "Inter", fontSize: 12, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#374151"), lineSpacing: 5)), x: 100, y: 599, width: 1040, height: 65, zIndex: 13),

                CanvasElement(name: "P2 Head", payload: .text(TextContent(text: "Software Engineering Intern • Blue Origin (Summer 2024)", fontFamily: "Inter", fontSize: 13, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#111827"))), x: 100, y: 727, width: 800, height: 20, zIndex: 14),
                CanvasElement(name: "P2 Dates", payload: .text(TextContent(text: "Jun — Aug 2024", fontFamily: "Inter", fontSize: 11, fontWeight: 700, alignment: .right, textColor: CodableColor(hex: "#2563EB"))), x: 920, y: 728, width: 220, height: 20, zIndex: 15),
                CanvasElement(name: "P2 Bullets", payload: .text(TextContent(text: "• Developed internal telemetry dashboard (React + Go) monitoring 400+ engine sensors in real time.\n• Automated regression test suite, reducing CI runtime from 48 to 11 minutes.\n• Presented capstone project to VP of Engineering; received return-offer for 2025.", fontFamily: "Inter", fontSize: 12, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#374151"), lineSpacing: 5)), x: 100, y: 763, width: 1040, height: 65, zIndex: 16),

                CanvasElement(name: "P3 Head", payload: .text(TextContent(text: "CampusMobile App — Hackathon Winner (1st / 120 teams)", fontFamily: "Inter", fontSize: 13, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#111827"))), x: 100, y: 891, width: 800, height: 20, zIndex: 17),
                CanvasElement(name: "P3 Dates", payload: .text(TextContent(text: "2024", fontFamily: "Inter", fontSize: 11, fontWeight: 700, alignment: .right, textColor: CodableColor(hex: "#2563EB"))), x: 920, y: 892, width: 220, height: 20, zIndex: 18),
                CanvasElement(name: "P3 Bullets", payload: .text(TextContent(text: "• Led a 4-person team building a SwiftUI study-group matcher with Firebase realtime sync.\n• 800+ weekly active student users within one month of campus launch.", fontFamily: "Inter", fontSize: 12, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#374151"), lineSpacing: 5)), x: 100, y: 927, width: 1040, height: 45, zIndex: 19),

                CanvasElement(name: "Skill Title", payload: .text(TextContent(text: "TECHNICAL SKILLS", fontFamily: "Inter", fontSize: 13, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#111827"), letterSpacing: 2)), x: 100, y: 1037, width: 1040, height: 20, zIndex: 20),
                CanvasElement(name: "Skill Rule", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#2563EB")))), x: 100, y: 1073, width: 1040, height: 2, zIndex: 21),
                CanvasElement(name: "Skill Text", payload: .text(TextContent(text: "Languages: Python, Swift, TypeScript, Go, Java, SQL, C\nFrameworks & Tools: React, Node.js, PyTorch, Firebase, Docker, Git, PostgreSQL, AWS (basics)", fontFamily: "Inter", fontSize: 12, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#374151"), lineSpacing: 5)), x: 100, y: 1097, width: 1040, height: 40, zIndex: 22),

                CanvasElement(name: "Lead Title", payload: .text(TextContent(text: "LEADERSHIP & ACTIVITIES", fontFamily: "Inter", fontSize: 13, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#111827"), letterSpacing: 2)), x: 100, y: 1201, width: 1040, height: 20, zIndex: 23),
                CanvasElement(name: "Lead Rule", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#2563EB")))), x: 100, y: 1237, width: 1040, height: 2, zIndex: 24),
                CanvasElement(name: "Lead Text", payload: .text(TextContent(text: "• Technical Vice President, Berkeley Code Society — organize weekly workshops for 300+ members.\n• Mentor, Berkeley CS Scholars — guide 10 first-generation students through intro CS sequence.\n• Intramural Soccer Captain • Piano (Level 8 ABRSM) • Food-coop volunteer cook", fontFamily: "Inter", fontSize: 12, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#374151"), lineSpacing: 5)), x: 100, y: 1262, width: 1040, height: 65, zIndex: 25)
            ]
        )

        return CanvasTemplate(
            id: "resume_student_internship",
            title: "Student & Internship Resume",
            category: "Resumes & CVs",
            docType: .a4,
            themeName: "Student & Early Career",
            preset: .a4(),
            pages: [page],
            previewColorHex: "#2563EB"
        )
    }

    // =========================================================================
    // 10. SALES & BUSINESS DEVELOPMENT RESUME (Navy/Gold — Quota Crushers)
    // =========================================================================
    public static func createSalesManagerResumeTemplate() -> CanvasTemplate {
        let page = CanvasPage(
            name: "Sales Manager Resume",
            width: 1240, height: 1754,
            background: FillStyle(type: .solid, solidColor: CodableColor(hex: "#FFFFFF")),
            elements: [
                CanvasElement(name: "Left Band", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#1E3A5F")))), x: 0, y: 0, width: 30, height: 1754, zIndex: 0),
                CanvasElement(name: "Gold Band", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#D4A017")))), x: 30, y: 0, width: 6, height: 1754, zIndex: 1),

                CanvasElement(name: "Name", payload: .text(TextContent(text: "MARCUS JOHNSON", fontFamily: "Inter", fontSize: 40, fontWeight: 900, alignment: .left, textColor: CodableColor(hex: "#1E3A5F"), letterSpacing: 2)), x: 80, y: 106, width: 800, height: 50, zIndex: 2),
                CanvasElement(name: "Role", payload: .text(TextContent(text: "REGIONAL SALES MANAGER • ENTERPRISE SAAS", fontFamily: "Inter", fontSize: 15, fontWeight: 700, alignment: .left, textColor: CodableColor(hex: "#D4A017"), letterSpacing: 3)), x: 80, y: 192, width: 800, height: 24, zIndex: 3),
                CanvasElement(name: "Contact", payload: .text(TextContent(text: "Dallas, TX • marcus.johnson@salespro.com • +1 (214) 555-0165 • linkedin.com/in/marcusjohnson", fontFamily: "Inter", fontSize: 12, fontWeight: 500, alignment: .left, textColor: CodableColor(hex: "#4B5563"))), x: 80, y: 240, width: 900, height: 20, zIndex: 4),

                // KPI band
                CanvasElement(name: "KPI Band BG", payload: .shape(ShapeContent(kind: .roundedRectangle, cornerRadius: 10, fill: FillStyle.solid(CodableColor(hex: "#1E3A5F")))), x: 80, y: 319, width: 1080, height: 92, zIndex: 5),
                CanvasElement(name: "KPI 1", payload: .text(TextContent(text: "247%\nOF QUOTA", fontFamily: "Inter", fontSize: 17, fontWeight: 900, alignment: .center, textColor: CodableColor(hex: "#D4A017"), lineSpacing: 2)), x: 100, y: 347, width: 250, height: 56, zIndex: 6),
                CanvasElement(name: "KPI 2", payload: .text(TextContent(text: "$38.2M\nBOOKED 2024", fontFamily: "Inter", fontSize: 17, fontWeight: 900, alignment: .center, textColor: .white, lineSpacing: 2)), x: 370, y: 347, width: 250, height: 56, zIndex: 7),
                CanvasElement(name: "KPI 3", payload: .text(TextContent(text: "134%\nTEAM ATTAINMENT", fontFamily: "Inter", fontSize: 17, fontWeight: 900, alignment: .center, textColor: .white, lineSpacing: 2)), x: 640, y: 347, width: 250, height: 56, zIndex: 8),
                CanvasElement(name: "KPI 4", payload: .text(TextContent(text: "12\nREPS LED", fontFamily: "Inter", fontSize: 17, fontWeight: 900, alignment: .center, textColor: .white, lineSpacing: 2)), x: 910, y: 347, width: 230, height: 56, zIndex: 9),

                CanvasElement(name: "Exp Title", payload: .text(TextContent(text: "SALES LEADERSHIP EXPERIENCE", fontFamily: "Inter", fontSize: 14, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#1E3A5F"), letterSpacing: 2)), x: 80, y: 517, width: 1080, height: 22, zIndex: 10),
                CanvasElement(name: "Exp Rule", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#D4A017")))), x: 80, y: 556, width: 1080, height: 2.5, zIndex: 11),

                CanvasElement(name: "J1 Head", payload: .text(TextContent(text: "Regional Sales Manager, Enterprise • Salesforce", fontFamily: "Inter", fontSize: 16, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#111827"))), x: 80, y: 584, width: 800, height: 24, zIndex: 12),
                CanvasElement(name: "J1 Dates", payload: .text(TextContent(text: "2020 — Present • DALLAS, TX", fontFamily: "Inter", fontSize: 10.5, fontWeight: 700, alignment: .right, textColor: CodableColor(hex: "#6B7280"))), x: 900, y: 590, width: 260, height: 20, zIndex: 13),
                CanvasElement(name: "J1 Bullets", payload: .text(TextContent(text: "• Lead a 12-rep enterprise team covering south-central US; booked $38.2M ARR in FY24 (134% of plan).\n• Rebuilt territory coverage model, lifting pipeline coverage from 2.1× to 4.3× within two quarters.\n• Coached 6 reps to President's Club; team ramp time cut from 9 to 5.5 months via playbook redesign.\n• Closed 3 of the region's top-10 deals ever, including a $4.8M multi-year platform consolidation.", fontFamily: "Inter", fontSize: 12, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#374151"), lineSpacing: 5)), x: 80, y: 626, width: 1080, height: 100, zIndex: 14),

                CanvasElement(name: "J2 Head", payload: .text(TextContent(text: "Senior Account Executive, Mid-Market • HubSpot", fontFamily: "Inter", fontSize: 16, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#111827"))), x: 80, y: 809, width: 800, height: 24, zIndex: 15),
                CanvasElement(name: "J2 Dates", payload: .text(TextContent(text: "2017 — 2020 • AUSTIN, TX", fontFamily: "Inter", fontSize: 10.5, fontWeight: 700, alignment: .right, textColor: CodableColor(hex: "#6B7280"))), x: 900, y: 815, width: 260, height: 20, zIndex: 16),
                CanvasElement(name: "J2 Bullets", payload: .text(TextContent(text: "• Ranked #2 of 140 AEs globally in FY19 with 212% quota attainment ($6.4M closed-won).\n• Maintained 118% average annual attainment across all 3 years; zero missed quarters.\n• Piloted the value-engineering motion now standard for deals above $100K.", fontFamily: "Inter", fontSize: 12, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#374151"), lineSpacing: 5)), x: 80, y: 851, width: 1080, height: 80, zIndex: 17),

                CanvasElement(name: "J3 Head", payload: .text(TextContent(text: "Account Executive • Paycom", fontFamily: "Inter", fontSize: 16, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#111827"))), x: 80, y: 1003, width: 800, height: 24, zIndex: 18),
                CanvasElement(name: "J3 Dates", payload: .text(TextContent(text: "2015 — 2017 • OKLAHOMA CITY, OK", fontFamily: "Inter", fontSize: 10.5, fontWeight: 700, alignment: .right, textColor: CodableColor(hex: "#6B7280"))), x: 900, y: 1009, width: 260, height: 20, zIndex: 19),
                CanvasElement(name: "J3 Bullets", payload: .text(TextContent(text: "• President's Club (2016) — 156% of annual quota in first full year.\n• Built book of business from 12 to 90+ active accounts in the Oklahoma territory.", fontFamily: "Inter", fontSize: 12, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#374151"), lineSpacing: 5)), x: 80, y: 1046, width: 1080, height: 55, zIndex: 20),

                CanvasElement(name: "Skill Title", payload: .text(TextContent(text: "SALES EXPERTISE", fontFamily: "Inter", fontSize: 14, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#1E3A5F"), letterSpacing: 2)), x: 80, y: 1178, width: 1080, height: 22, zIndex: 21),
                CanvasElement(name: "Skill Rule", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#D4A017")))), x: 80, y: 1218, width: 1080, height: 2.5, zIndex: 22),
                CanvasElement(name: "Skill Col 1", payload: .text(TextContent(text: "• MEDDIC / MEDDPICC Qualification\n• Challenger & Sandler Methods\n• Enterprise Negotiation\n• Multi-Year Contract Structuring", fontFamily: "Inter", fontSize: 12, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#374151"), lineSpacing: 7)), x: 80, y: 1243, width: 350, height: 100, zIndex: 23),
                CanvasElement(name: "Skill Col 2", payload: .text(TextContent(text: "• Salesforce, Gong, Outreach\n• Forecasting & Pipeline Hygiene\n• Territory & Capacity Planning\n• Executive Business Reviews", fontFamily: "Inter", fontSize: 12, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#374151"), lineSpacing: 7)), x: 460, y: 1243, width: 350, height: 100, zIndex: 24),
                CanvasElement(name: "Skill Col 3", payload: .text(TextContent(text: "• Team Hiring & Ramp Programs\n• Deal Desk & Pricing Strategy\n• Partner / Channel Co-Selling\n• Cross-Functional Leadership", fontFamily: "Inter", fontSize: 12, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#374151"), lineSpacing: 7)), x: 840, y: 1243, width: 320, height: 100, zIndex: 25),

                CanvasElement(name: "Edu Title", payload: .text(TextContent(text: "EDUCATION & AWARDS", fontFamily: "Inter", fontSize: 14, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#1E3A5F"), letterSpacing: 2)), x: 80, y: 1444, width: 1080, height: 22, zIndex: 26),
                CanvasElement(name: "Edu Rule", payload: .shape(ShapeContent(kind: .rectangle, fill: FillStyle.solid(CodableColor(hex: "#D4A017")))), x: 80, y: 1484, width: 1080, height: 2.5, zIndex: 27),
                CanvasElement(name: "Edu Text", payload: .text(TextContent(text: "B.B.A. Marketing • Baylor University — 2015 • Hankamer School of Business Dean's List\nAwards: Salesforce Summit Club (2023) • HubSpot Global Top-10 AE (2019) • Paycom President's Club (2016)", fontFamily: "Inter", fontSize: 12, fontWeight: 500, alignment: .left, textColor: CodableColor(hex: "#374151"), lineSpacing: 6)), x: 80, y: 1508, width: 1080, height: 50, zIndex: 28)
            ]
        )

        return CanvasTemplate(
            id: "resume_sales_manager",
            title: "Sales & Business Development Resume",
            category: "Resumes & CVs",
            docType: .a4,
            themeName: "Sales & Business",
            preset: .a4(),
            pages: [page],
            previewColorHex: "#1E3A5F"
        )
    }
}
