import Foundation
import SwiftUI

public enum WhiteboardTemplates {
    public static func allWhiteboardTemplates() -> [CanvasTemplate] {
        return [
            createProductStrategyMindmapTemplate(),
            createSystemArchitectureFlowchartTemplate(),
            createAgileStickyNoteBoardTemplate(),
            createKanbanDeliveryBoardTemplate(),
            createSWOTAnalysisTemplate(),
            createUserJourneyMapTemplate()
        ]
    }

    // =========================================================================
    // 1. PRODUCT STRATEGY & INNOVATION MINDMAP (Boundless 3200 × 2000)
    // =========================================================================
    public static func createProductStrategyMindmapTemplate() -> CanvasTemplate {
        let page = CanvasPage(
            name: "Product Strategy Mindmap",
            width: 3200, height: 2000,
            background: FillStyle(type: .graphPaper, solidColor: CodableColor(hex: "#FAFAF9")),
            elements: [
                // Central Main Topic Node (Deep Terracotta)
                CanvasElement(name: "Central Topic Bubble", payload: .shape(ShapeContent(kind: .roundedRectangle, cornerRadius: 28, fill: FillStyle.solid(CodableColor(hex: "#C2410C")), stroke: StrokeStyle(isEnabled: false))), x: 1300, y: 880, width: 600, height: 240, shadow: ShadowEffect.elevated, zIndex: 10),
                CanvasElement(name: "Central Tag", payload: .text(TextContent(text: "CORE VISION 2026", fontFamily: "SF Mono", fontSize: 13, fontWeight: 700, alignment: .center, textColor: CodableColor(hex: "#FED7AA"), letterSpacing: 2)), x: 1320, y: 920, width: 560, height: 24, zIndex: 11),
                CanvasElement(name: "Central Title", payload: .text(TextContent(text: "PLUMA CREATIVE\nSTUDIO SUITE", fontFamily: "Playfair Display", fontSize: 32, fontWeight: 900, alignment: .center, textColor: .white, lineSpacing: 4)), x: 1320, y: 955, width: 560, height: 110, zIndex: 12),

                // ── BRANCH 1: NATIVE DESKTOP PERFORMANCE (TOP LEFT) ──
                CanvasElement(name: "Branch 1 Connector", payload: .shape(ShapeContent(kind: .line, fill: FillStyle.solid(.clear), stroke: StrokeStyle(isEnabled: true, color: CodableColor(hex: "#EA580C"), lineWidth: 3))), x: 950, y: 550, width: 400, height: 350, zIndex: 2),
                CanvasElement(name: "Branch 1 Card", payload: .shape(ShapeContent(kind: .roundedRectangle, cornerRadius: 18, fill: FillStyle.solid(.white), stroke: StrokeStyle(isEnabled: true, color: CodableColor(hex: "#EA580C"), lineWidth: 2))), x: 650, y: 380, width: 420, height: 190, shadow: ShadowEffect.subtle, zIndex: 5),
                CanvasElement(name: "Branch 1 Header", payload: .text(TextContent(text: "⚡ 120 FPS NATIVE ENGINE", fontFamily: "Inter", fontSize: 16, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#EA580C"), letterSpacing: 1)), x: 680, y: 410, width: 360, height: 24, zIndex: 6),
                CanvasElement(name: "Branch 1 Body", payload: .text(TextContent(text: "• Metal GPU hardware rendering\n• 40MB idle RAM footprint\n• Instant vector rasterization\n• Zero electron overhead", fontFamily: "Inter", fontSize: 13, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#27272A"), lineSpacing: 5)), x: 680, y: 445, width: 360, height: 100, zIndex: 7),

                // Sticky Note 1 (Mint) - Unified Element
                CanvasElement(
                    name: "Sticky Note Mint",
                    payload: .text(TextContent(
                        text: "Benchmark Target:\n< 8ms input latency on ProMotion 120Hz Displays 🚀",
                        fontFamily: "Indie Flower",
                        fontSize: 15,
                        fontWeight: 700,
                        alignment: .left,
                        textColor: CodableColor(hex: "#065F46"),
                        lineSpacing: 4,
                        cardBackground: CodableColor(hex: "#D1FAE5"),
                        cardBorderColor: CodableColor(hex: "#6EE7B7"),
                        cardBorderWidth: 1,
                        cardCornerRadius: 10,
                        cardPadding: 16
                    )),
                    x: 380, y: 460, width: 220, height: 200, rotation: -3, shadow: ShadowEffect.subtle, zIndex: 8
                ),

                // ── BRANCH 2: UNIVERSAL INTEROP (TOP RIGHT) ──
                CanvasElement(name: "Branch 2 Connector", payload: .shape(ShapeContent(kind: .line, fill: FillStyle.solid(.clear), stroke: StrokeStyle(isEnabled: true, color: CodableColor(hex: "#2563EB"), lineWidth: 3))), x: 1850, y: 550, width: 400, height: 350, zIndex: 2),
                CanvasElement(name: "Branch 2 Card", payload: .shape(ShapeContent(kind: .roundedRectangle, cornerRadius: 18, fill: FillStyle.solid(.white), stroke: StrokeStyle(isEnabled: true, color: CodableColor(hex: "#2563EB"), lineWidth: 2))), x: 2150, y: 380, width: 420, height: 190, shadow: ShadowEffect.subtle, zIndex: 5),
                CanvasElement(name: "Branch 2 Header", payload: .text(TextContent(text: "🌐 SEAMLESS FIGMA & CANVA INTEROP", fontFamily: "Inter", fontSize: 16, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#2563EB"), letterSpacing: 1)), x: 2180, y: 410, width: 360, height: 24, zIndex: 6),
                CanvasElement(name: "Branch 2 Body", payload: .text(TextContent(text: "• 1-Click SVG Vector Copy for Figma\n• Multi-Page PDF & PPTX for Canva\n• Vector preserve typography\n• Lossless asset extraction", fontFamily: "Inter", fontSize: 13, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#27272A"), lineSpacing: 5)), x: 2180, y: 445, width: 360, height: 100, zIndex: 7),

                // Sticky Note 2 (Sky Blue) - Unified Element
                CanvasElement(
                    name: "Sticky Note Blue",
                    payload: .text(TextContent(
                        text: "⌥⌘C in Pluma -> ⌘V in Figma = Instant Vector Layers! 🎉",
                        fontFamily: "Indie Flower",
                        fontSize: 15,
                        fontWeight: 700,
                        alignment: .left,
                        textColor: CodableColor(hex: "#0369A1"),
                        lineSpacing: 4,
                        cardBackground: CodableColor(hex: "#E0F2FE"),
                        cardBorderColor: CodableColor(hex: "#7DD3FC"),
                        cardBorderWidth: 1,
                        cardCornerRadius: 10,
                        cardPadding: 16
                    )),
                    x: 2620, y: 440, width: 220, height: 200, rotation: 4, shadow: ShadowEffect.subtle, zIndex: 8
                ),

                // ── BRANCH 3: FREEFORM WHITEBOARD & MINDMAPS (BOTTOM LEFT) ──
                CanvasElement(name: "Branch 3 Card", payload: .shape(ShapeContent(kind: .roundedRectangle, cornerRadius: 18, fill: FillStyle.solid(.white), stroke: StrokeStyle(isEnabled: true, color: CodableColor(hex: "#059669"), lineWidth: 2))), x: 650, y: 1350, width: 420, height: 190, shadow: ShadowEffect.subtle, zIndex: 5),
                CanvasElement(name: "Branch 3 Header", payload: .text(TextContent(text: "🧠 BOUNDLESS FREEFORM CANVAS", fontFamily: "Inter", fontSize: 16, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#059669"), letterSpacing: 1)), x: 680, y: 1380, width: 360, height: 24, zIndex: 6),
                CanvasElement(name: "Branch 3 Body", payload: .text(TextContent(text: "• Infinite drafting area\n• Pastel sticky notes & thought cards\n• Continuous multi-page documents\n• Two-finger smooth pan & zoom", fontFamily: "Inter", fontSize: 13, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#27272A"), lineSpacing: 5)), x: 680, y: 1415, width: 360, height: 100, zIndex: 7),

                // Sticky Note 3 (Yellow) - Unified Element
                CanvasElement(
                    name: "Sticky Note Yellow",
                    payload: .text(TextContent(
                        text: "No fixed boundaries! Think freely & organize thoughts effortlessly 💡",
                        fontFamily: "Indie Flower",
                        fontSize: 15,
                        fontWeight: 700,
                        alignment: .left,
                        textColor: CodableColor(hex: "#854D0E"),
                        lineSpacing: 4,
                        cardBackground: CodableColor(hex: "#FEF08A"),
                        cardBorderColor: CodableColor(hex: "#FDE047"),
                        cardBorderWidth: 1,
                        cardCornerRadius: 10,
                        cardPadding: 16
                    )),
                    x: 380, y: 1380, width: 220, height: 200, rotation: 2, shadow: ShadowEffect.subtle, zIndex: 8
                ),

                // ── BRANCH 4: AI PAIR DESIGNER (BOTTOM RIGHT) ──
                CanvasElement(name: "Branch 4 Card", payload: .shape(ShapeContent(kind: .roundedRectangle, cornerRadius: 18, fill: FillStyle.solid(.white), stroke: StrokeStyle(isEnabled: true, color: CodableColor(hex: "#7C3AED"), lineWidth: 2))), x: 2150, y: 1350, width: 420, height: 190, shadow: ShadowEffect.subtle, zIndex: 5),
                CanvasElement(name: "Branch 4 Header", payload: .text(TextContent(text: "🤖 AI DESIGN AGENT & MCP TOOLS", fontFamily: "Inter", fontSize: 16, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#7C3AED"), letterSpacing: 1)), x: 2180, y: 1380, width: 360, height: 24, zIndex: 6),
                CanvasElement(name: "Branch 4 Body", payload: .text(TextContent(text: "• MCP Server automation tools\n• CLI & Subagent design generators\n• Autonomous typography refinement\n• Direct canvas layout synthesis", fontFamily: "Inter", fontSize: 13, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#27272A"), lineSpacing: 5)), x: 2180, y: 1415, width: 360, height: 100, zIndex: 7),

                // Sticky Note 4 (Peach / Rose) - Unified Element
                CanvasElement(
                    name: "Sticky Note Rose",
                    payload: .text(TextContent(
                        text: "Ask AI to generate templates, palettes & mindmaps in seconds! 🔮",
                        fontFamily: "Indie Flower",
                        fontSize: 15,
                        fontWeight: 700,
                        alignment: .left,
                        textColor: CodableColor(hex: "#9F1239"),
                        lineSpacing: 4,
                        cardBackground: CodableColor(hex: "#FFE4E6"),
                        cardBorderColor: CodableColor(hex: "#FDA4AF"),
                        cardBorderWidth: 1,
                        cardCornerRadius: 10,
                        cardPadding: 16
                    )),
                    x: 2620, y: 1380, width: 220, height: 200, rotation: -4, shadow: ShadowEffect.subtle, zIndex: 8
                )
            ]
        )

        return CanvasTemplate(
            id: "mindmap_product_strategy",
            title: "Product Strategy & Mindmap",
            category: "Whiteboard & Mindmap",
            docType: .whiteboard,
            themeName: "Mindmap & Freeform",
            preset: CanvasPreset(name: "Infinite Whiteboard", category: .whiteboard, width: 3200, height: 2000, iconName: "brain.head.profile", description: "Boundless canvas"),
            page: page,
            previewColorHex: "#C2410C"
        )
    }

    // =========================================================================
    // 2. SYSTEM ARCHITECTURE & DIAGRAM FLOWCHART (3200 × 2000)
    // =========================================================================
    public static func createSystemArchitectureFlowchartTemplate() -> CanvasTemplate {
        let page = CanvasPage(
            name: "System Architecture Flowchart",
            width: 3200, height: 2000,
            background: FillStyle(type: .graphPaper, solidColor: CodableColor(hex: "#0F172A")),
            elements: [
                // Header Banner
                CanvasElement(name: "Title", payload: .text(TextContent(text: "DISTRIBUTED SYSTEM ARCHITECTURE", fontFamily: "SF Mono", fontSize: 26, fontWeight: 800, alignment: .left, textColor: .white, letterSpacing: 3)), x: 120, y: 80, width: 900, height: 35, zIndex: 1),
                CanvasElement(name: "Subtitle", payload: .text(TextContent(text: "High-Throughput Streaming Event Pipeline • Multi-Region Resiliency", fontFamily: "Inter", fontSize: 13, fontWeight: 500, alignment: .left, textColor: CodableColor(hex: "#94A3B8"))), x: 120, y: 125, width: 900, height: 22, zIndex: 2),

                // Node 1: API Gateway (Blue Card)
                CanvasElement(name: "API Gateway Node", payload: .shape(ShapeContent(kind: .roundedRectangle, cornerRadius: 14, fill: FillStyle.solid(CodableColor(hex: "#1E293B")), stroke: StrokeStyle(isEnabled: true, color: CodableColor(hex: "#38BDF8"), lineWidth: 2))), x: 200, y: 500, width: 380, height: 220, zIndex: 5),
                CanvasElement(name: "Node 1 Title", payload: .text(TextContent(text: "🌐 EDGE API GATEWAY", fontFamily: "Inter", fontSize: 15, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#38BDF8"))), x: 230, y: 530, width: 320, height: 22, zIndex: 6),
                CanvasElement(name: "Node 1 Specs", payload: .text(TextContent(text: "• Cloudflare Workers Edge PoPs\n• mTLS Token Validation\n• Rate Limiting & Geo-Routing\n• < 4ms TLS Handshake", fontFamily: "SF Mono", fontSize: 11, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#CBD5E1"), lineSpacing: 5)), x: 230, y: 565, width: 320, height: 120, zIndex: 7),

                // Node 2: Streaming Ingestion (Purple Card)
                CanvasElement(name: "Ingestion Node", payload: .shape(ShapeContent(kind: .roundedRectangle, cornerRadius: 14, fill: FillStyle.solid(CodableColor(hex: "#1E293B")), stroke: StrokeStyle(isEnabled: true, color: CodableColor(hex: "#A855F7"), lineWidth: 2))), x: 800, y: 500, width: 380, height: 220, zIndex: 5),
                CanvasElement(name: "Node 2 Title", payload: .text(TextContent(text: "⚡ APACHE KAFKA BROKER", fontFamily: "Inter", fontSize: 15, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#A855F7"))), x: 830, y: 530, width: 320, height: 22, zIndex: 6),
                CanvasElement(name: "Node 2 Specs", payload: .text(TextContent(text: "• 64 Partition Raft Cluster\n• 2.4M msgs/sec Ingestion\n• Zero-Copy Kernel Sockets\n• LZ4 Compression", fontFamily: "SF Mono", fontSize: 11, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#CBD5E1"), lineSpacing: 5)), x: 830, y: 565, width: 320, height: 120, zIndex: 7),

                // Node 3: SIMD Compute Engine (Emerald Card)
                CanvasElement(name: "Compute Node", payload: .shape(ShapeContent(kind: .roundedRectangle, cornerRadius: 14, fill: FillStyle.solid(CodableColor(hex: "#1E293B")), stroke: StrokeStyle(isEnabled: true, color: CodableColor(hex: "#34D399"), lineWidth: 2))), x: 1400, y: 500, width: 380, height: 220, zIndex: 5),
                CanvasElement(name: "Node 3 Title", payload: .text(TextContent(text: "🚀 VECTOR COMPUTE WORKER", fontFamily: "Inter", fontSize: 15, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#34D399"))), x: 1430, y: 530, width: 320, height: 22, zIndex: 6),
                CanvasElement(name: "Node 3 Specs", payload: .text(TextContent(text: "• Rust / Metal Compute Shaders\n• AVX-512 SIMD Acceleration\n• Sub-10ms Batch Aggregation\n• High Availability Hot Standby", fontFamily: "SF Mono", fontSize: 11, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#CBD5E1"), lineSpacing: 5)), x: 1430, y: 565, width: 320, height: 120, zIndex: 7),

                // Node 4: Sharded Storage (Amber Card)
                CanvasElement(name: "Storage Node", payload: .shape(ShapeContent(kind: .roundedRectangle, cornerRadius: 14, fill: FillStyle.solid(CodableColor(hex: "#1E293B")), stroke: StrokeStyle(isEnabled: true, color: CodableColor(hex: "#FBBF24"), lineWidth: 2))), x: 2000, y: 500, width: 380, height: 220, zIndex: 5),
                CanvasElement(name: "Node 4 Title", payload: .text(TextContent(text: "💾 SHARDED NVME STORAGE", fontFamily: "Inter", fontSize: 15, fontWeight: 800, alignment: .left, textColor: CodableColor(hex: "#FBBF24"))), x: 2030, y: 530, width: 320, height: 22, zIndex: 6),
                CanvasElement(name: "Node 4 Specs", payload: .text(TextContent(text: "• ScyllaDB Multi-AZ Cluster\n• Write-Ahead WAL Logging\n• Point-in-Time Recovery\n• 99.999% Durability SLA", fontFamily: "SF Mono", fontSize: 11, fontWeight: 400, alignment: .left, textColor: CodableColor(hex: "#CBD5E1"), lineSpacing: 5)), x: 2030, y: 565, width: 320, height: 120, zIndex: 7)
            ]
        )

        return CanvasTemplate(
            id: "system_architecture_flowchart",
            title: "System Architecture Flowchart",
            category: "Whiteboard & Mindmap",
            docType: .whiteboard,
            themeName: "Diagram & Flowchart",
            preset: CanvasPreset(name: "Infinite Whiteboard", category: .whiteboard, width: 3200, height: 2000, iconName: "point.topleft.down.curvedto.point.bottomright.up", description: "Boundless canvas"),
            page: page,
            previewColorHex: "#0F172A"
        )
    }

    // =========================================================================
    // 3. AGILE SPRINT & STICKY NOTE BOARD (3200 × 2000)
    // =========================================================================
    public static func createAgileStickyNoteBoardTemplate() -> CanvasTemplate {
        let page = CanvasPage(
            name: "Agile Sticky Note Board",
            width: 3200, height: 2000,
            background: FillStyle(type: .newsprint, solidColor: CodableColor(hex: "#F5F5F4")),
            elements: [
                // Column 1: Backlog
                CanvasElement(name: "Col 1 Box", payload: .shape(ShapeContent(kind: .roundedRectangle, cornerRadius: 16, fill: FillStyle.solid(CodableColor(hex: "#E7E5E4")), stroke: StrokeStyle(isEnabled: false))), x: 120, y: 150, width: 680, height: 1700, zIndex: 0),
                CanvasElement(name: "Col 1 Title", payload: .text(TextContent(text: "📋 PRODUCT BACKLOG", fontFamily: "Inter", fontSize: 18, fontWeight: 900, alignment: .left, textColor: CodableColor(hex: "#44403C"), letterSpacing: 1.5)), x: 160, y: 180, width: 400, height: 26, zIndex: 1),

                // Sticky Note 1 - Unified Element
                CanvasElement(
                    name: "Sticky 1",
                    payload: .text(TextContent(
                        text: "Feature: Infinite Canvas Pan & 2-Finger Trackpad\nImplement smooth 120 FPS coordinate transform and local mouse boundary checks.",
                        fontFamily: "Indie Flower",
                        fontSize: 16,
                        fontWeight: 700,
                        alignment: .left,
                        textColor: CodableColor(hex: "#854D0E"),
                        lineSpacing: 4,
                        cardBackground: CodableColor(hex: "#FEF08A"),
                        cardCornerRadius: 10,
                        cardPadding: 16
                    )),
                    x: 160, y: 240, width: 600, height: 180, shadow: ShadowEffect.subtle, zIndex: 5
                ),

                // Column 2: In Progress
                CanvasElement(name: "Col 2 Box", payload: .shape(ShapeContent(kind: .roundedRectangle, cornerRadius: 16, fill: FillStyle.solid(CodableColor(hex: "#E7E5E4")), stroke: StrokeStyle(isEnabled: false))), x: 860, y: 150, width: 680, height: 1700, zIndex: 0),
                CanvasElement(name: "Col 2 Title", payload: .text(TextContent(text: "⚡ IN PROGRESS (SPRINT 42)", fontFamily: "Inter", fontSize: 18, fontWeight: 900, alignment: .left, textColor: CodableColor(hex: "#EA580C"), letterSpacing: 1.5)), x: 900, y: 180, width: 400, height: 26, zIndex: 1),

                // Sticky Note 2 - Unified Element
                CanvasElement(
                    name: "Sticky 2",
                    payload: .text(TextContent(
                        text: "Design: Figma & Canva Lossless Export\nAdd 1-click 'Copy as SVG for Figma' and native multi-page PDF for Canva.",
                        fontFamily: "Indie Flower",
                        fontSize: 16,
                        fontWeight: 700,
                        alignment: .left,
                        textColor: CodableColor(hex: "#065F46"),
                        lineSpacing: 4,
                        cardBackground: CodableColor(hex: "#D1FAE5"),
                        cardCornerRadius: 10,
                        cardPadding: 16
                    )),
                    x: 900, y: 240, width: 600, height: 180, shadow: ShadowEffect.subtle, zIndex: 5
                ),

                // Column 3: Quality Assurance
                CanvasElement(name: "Col 3 Box", payload: .shape(ShapeContent(kind: .roundedRectangle, cornerRadius: 16, fill: FillStyle.solid(CodableColor(hex: "#E7E5E4")), stroke: StrokeStyle(isEnabled: false))), x: 1600, y: 150, width: 680, height: 1700, zIndex: 0),
                CanvasElement(name: "Col 3 Title", payload: .text(TextContent(text: "🧪 QA & PERFORMANCE AUDIT", fontFamily: "Inter", fontSize: 18, fontWeight: 900, alignment: .left, textColor: CodableColor(hex: "#2563EB"), letterSpacing: 1.5)), x: 1640, y: 180, width: 400, height: 26, zIndex: 1),

                // Column 4: Done & Shipped
                CanvasElement(name: "Col 4 Box", payload: .shape(ShapeContent(kind: .roundedRectangle, cornerRadius: 16, fill: FillStyle.solid(CodableColor(hex: "#E7E5E4")), stroke: StrokeStyle(isEnabled: false))), x: 2340, y: 150, width: 680, height: 1700, zIndex: 0),
                CanvasElement(name: "Col 4 Title", payload: .text(TextContent(text: "🚀 SHIPPED TO PRODUCTION", fontFamily: "Inter", fontSize: 18, fontWeight: 900, alignment: .left, textColor: CodableColor(hex: "#059669"), letterSpacing: 1.5)), x: 2380, y: 180, width: 400, height: 26, zIndex: 1)
            ]
        )

        return CanvasTemplate(
            id: "agile_sticky_board",
            title: "Agile Sprint & Sticky Note Board",
            category: "Whiteboard & Mindmap",
            docType: .whiteboard,
            themeName: "Kanban & Sprint",
            preset: CanvasPreset(name: "Infinite Whiteboard", category: .whiteboard, width: 3200, height: 2000, iconName: "square.grid.3x3.fill", description: "Boundless canvas"),
            page: page,
            previewColorHex: "#F5F5F4"
        )
    }

    // =========================================================================
    // 4. KANBAN DELIVERY BOARD (Clean 3600 × 2000, 5 Columns)
    // =========================================================================
    public static func createKanbanDeliveryBoardTemplate() -> CanvasTemplate {
        let page = CanvasPage(
            name: "Kanban Delivery Board",
            width: 3600, height: 2000,
            background: FillStyle(type: .solid, solidColor: CodableColor(hex: "#F8FAFC")),
            elements: [
                CanvasElement(name: "Board Title", payload: .text(TextContent(text: "🚚 DELIVERY KANBAN — Q3", fontFamily: "Inter", fontSize: 26, fontWeight: 900, alignment: .left, textColor: CodableColor(hex: "#0F172A"), letterSpacing: 1)), x: 120, y: 60, width: 900, height: 36, zIndex: 1),

                // Column factory data: (x, title, color, stickies[(y, color, text)])
                // Col 1 — To Do
                CanvasElement(name: "Col1 BG", payload: .shape(ShapeContent(kind: .roundedRectangle, cornerRadius: 18, fill: FillStyle.solid(CodableColor(hex: "#EEF2F7")))), x: 120, y: 140, width: 640, height: 1720, zIndex: 0),
                CanvasElement(name: "Col1 Title", payload: .text(TextContent(text: "TO DO", fontFamily: "Inter", fontSize: 16, fontWeight: 900, alignment: .left, textColor: CodableColor(hex: "#475569"), letterSpacing: 2)), x: 160, y: 170, width: 400, height: 24, zIndex: 1),
                CanvasElement(name: "C1 Sticky 1", payload: .text(TextContent(text: "API rate limiting\nToken bucket algorithm, 429 responses, per-key quotas.", fontFamily: "Indie Flower", fontSize: 16, fontWeight: 700, alignment: .left, textColor: CodableColor(hex: "#1E40AF"), lineSpacing: 4, cardBackground: CodableColor(hex: "#DBEAFE"), cardCornerRadius: 10, cardPadding: 16)), x: 160, y: 220, width: 560, height: 170, shadow: ShadowEffect.subtle, zIndex: 2),
                CanvasElement(name: "C1 Sticky 2", payload: .text(TextContent(text: "Dark mode audit\nContrast pass on all marketing pages.", fontFamily: "Indie Flower", fontSize: 16, fontWeight: 700, alignment: .left, textColor: CodableColor(hex: "#1E40AF"), lineSpacing: 4, cardBackground: CodableColor(hex: "#DBEAFE"), cardCornerRadius: 10, cardPadding: 16)), x: 160, y: 410, width: 560, height: 140, shadow: ShadowEffect.subtle, zIndex: 2),

                // Col 2 — Design
                CanvasElement(name: "Col2 BG", payload: .shape(ShapeContent(kind: .roundedRectangle, cornerRadius: 18, fill: FillStyle.solid(CodableColor(hex: "#F5F3FF")))), x: 800, y: 140, width: 640, height: 1720, zIndex: 0),
                CanvasElement(name: "Col2 Title", payload: .text(TextContent(text: "🎨 DESIGN", fontFamily: "Inter", fontSize: 16, fontWeight: 900, alignment: .left, textColor: CodableColor(hex: "#7C3AED"), letterSpacing: 2)), x: 840, y: 170, width: 400, height: 24, zIndex: 1),
                CanvasElement(name: "C2 Sticky 1", payload: .text(TextContent(text: "Onboarding v3 flows\nReduce steps 5 → 3. Test with 8 users.", fontFamily: "Indie Flower", fontSize: 16, fontWeight: 700, alignment: .left, textColor: CodableColor(hex: "#5B21B6"), lineSpacing: 4, cardBackground: CodableColor(hex: "#EDE9FE"), cardCornerRadius: 10, cardPadding: 16)), x: 840, y: 220, width: 560, height: 150, shadow: ShadowEffect.subtle, zIndex: 2),

                // Col 3 — In Progress
                CanvasElement(name: "Col3 BG", payload: .shape(ShapeContent(kind: .roundedRectangle, cornerRadius: 18, fill: FillStyle.solid(CodableColor(hex: "#FFFBEB")))), x: 1480, y: 140, width: 640, height: 1720, zIndex: 0),
                CanvasElement(name: "Col3 Title", payload: .text(TextContent(text: "⚙️ IN PROGRESS", fontFamily: "Inter", fontSize: 16, fontWeight: 900, alignment: .left, textColor: CodableColor(hex: "#B45309"), letterSpacing: 2)), x: 1520, y: 170, width: 400, height: 24, zIndex: 1),
                CanvasElement(name: "C3 Sticky 1", payload: .text(TextContent(text: "Billing migration\nStripe → in-house ledger. Cutover planned Aug 12.", fontFamily: "Indie Flower", fontSize: 16, fontWeight: 700, alignment: .left, textColor: CodableColor(hex: "#92400E"), lineSpacing: 4, cardBackground: CodableColor(hex: "#FEF3C7"), cardCornerRadius: 10, cardPadding: 16)), x: 1520, y: 220, width: 560, height: 160, shadow: ShadowEffect.subtle, zIndex: 2),
                CanvasElement(name: "C3 Sticky 2", payload: .text(TextContent(text: "Search relevance v2\nBM25 + embeddings hybrid. A/B at 10%.", fontFamily: "Indie Flower", fontSize: 16, fontWeight: 700, alignment: .left, textColor: CodableColor(hex: "#92400E"), lineSpacing: 4, cardBackground: CodableColor(hex: "#FEF08A"), cardCornerRadius: 10, cardPadding: 16)), x: 1520, y: 400, width: 560, height: 150, shadow: ShadowEffect.subtle, zIndex: 2),

                // Col 4 — Review
                CanvasElement(name: "Col4 BG", payload: .shape(ShapeContent(kind: .roundedRectangle, cornerRadius: 18, fill: FillStyle.solid(CodableColor(hex: "#ECFDF5")))), x: 2160, y: 140, width: 640, height: 1720, zIndex: 0),
                CanvasElement(name: "Col4 Title", payload: .text(TextContent(text: "👀 IN REVIEW", fontFamily: "Inter", fontSize: 16, fontWeight: 900, alignment: .left, textColor: CodableColor(hex: "#047857"), letterSpacing: 2)), x: 2200, y: 170, width: 400, height: 24, zIndex: 1),
                CanvasElement(name: "C4 Sticky 1", payload: .text(TextContent(text: "SSO (SAML) PR\nWaiting on security review — Priya.", fontFamily: "Indie Flower", fontSize: 16, fontWeight: 700, alignment: .left, textColor: CodableColor(hex: "#065F46"), lineSpacing: 4, cardBackground: CodableColor(hex: "#D1FAE5"), cardCornerRadius: 10, cardPadding: 16)), x: 2200, y: 220, width: 560, height: 130, shadow: ShadowEffect.subtle, zIndex: 2),

                // Col 5 — Done
                CanvasElement(name: "Col5 BG", payload: .shape(ShapeContent(kind: .roundedRectangle, cornerRadius: 18, fill: FillStyle.solid(CodableColor(hex: "#F0F9FF")))), x: 2840, y: 140, width: 640, height: 1720, zIndex: 0),
                CanvasElement(name: "Col5 Title", payload: .text(TextContent(text: "✅ DONE — JULY", fontFamily: "Inter", fontSize: 16, fontWeight: 900, alignment: .left, textColor: CodableColor(hex: "#0369A1"), letterSpacing: 2)), x: 2880, y: 170, width: 400, height: 24, zIndex: 1),
                CanvasElement(name: "C5 Sticky 1", payload: .text(TextContent(text: "Webhook retries\nExponential backoff shipped 7/18 ✓", fontFamily: "Indie Flower", fontSize: 16, fontWeight: 700, alignment: .left, textColor: CodableColor(hex: "#0C4A6E"), lineSpacing: 4, cardBackground: CodableColor(hex: "#E0F2FE"), cardCornerRadius: 10, cardPadding: 16)), x: 2880, y: 220, width: 560, height: 130, shadow: ShadowEffect.subtle, zIndex: 2),
                CanvasElement(name: "C5 Sticky 2", payload: .text(TextContent(text: "Perf: TTI −38%\nRoute-level code splitting ✓", fontFamily: "Indie Flower", fontSize: 16, fontWeight: 700, alignment: .left, textColor: CodableColor(hex: "#0C4A6E"), lineSpacing: 4, cardBackground: CodableColor(hex: "#E0F2FE"), cardCornerRadius: 10, cardPadding: 16)), x: 2880, y: 370, width: 560, height: 130, shadow: ShadowEffect.subtle, zIndex: 2)
            ]
        )

        return CanvasTemplate(
            id: "kanban_delivery_board",
            title: "Kanban Delivery Board",
            category: "Whiteboard & Mindmap",
            docType: .whiteboard,
            themeName: "Kanban & Sprint",
            preset: CanvasPreset(name: "Infinite Whiteboard", category: .whiteboard, width: 3600, height: 2000, iconName: "square.grid.3x3.fill", description: "Boundless canvas"),
            page: page,
            previewColorHex: "#F8FAFC"
        )
    }

    // =========================================================================
    // 5. SWOT ANALYSIS BOARD (2×2 Quadrant Grid, 3200 × 2000)
    // =========================================================================
    public static func createSWOTAnalysisTemplate() -> CanvasTemplate {
        func quadrant(x: Double, y: Double, bg: String, label: String, labelColor: String, items: [String], stickyColor: String, textColor: String) -> [CanvasElement] {
            var els: [CanvasElement] = []
            els.append(CanvasElement(name: "Quad BG", payload: .shape(ShapeContent(kind: .roundedRectangle, cornerRadius: 20, fill: FillStyle.solid(CodableColor(hex: bg)))), x: x, y: y, width: 1400, height: 800, zIndex: 0))
            els.append(CanvasElement(name: "Quad Label", payload: .text(TextContent(text: label, fontFamily: "Inter", fontSize: 24, fontWeight: 900, alignment: .left, textColor: CodableColor(hex: labelColor), letterSpacing: 3)), x: x + 50, y: y + 36, width: 800, height: 32, zIndex: 1))
            for (i, item) in items.enumerated() {
                let col = i % 2
                let row = i / 2
                els.append(CanvasElement(
                    name: "Item \(i + 1)",
                    payload: .text(TextContent(
                        text: item,
                        fontFamily: "Indie Flower", fontSize: 16, fontWeight: 700,
                        alignment: .left, textColor: CodableColor(hex: textColor), lineSpacing: 4,
                        cardBackground: CodableColor(hex: stickyColor), cardCornerRadius: 10, cardPadding: 16
                    )),
                    x: x + 50 + Double(col) * 680, y: y + 100 + Double(row) * 330,
                    width: 640, height: 300, shadow: ShadowEffect.subtle, zIndex: 2
                ))
            }
            return els
        }

        var swotElements: [CanvasElement] = []
        swotElements += quadrant(x: 120, y: 140, bg: "#DCFCE7", label: "💪 STRENGTHS", labelColor: "#166534", items: [
            "Own the full stack — hardware to services.", "NPS of 72, highest in category.", "40% gross margin headroom.", "Legendary support team, <2h response."], stickyColor: "#BBF7D0", textColor: "#14532D")
        swotElements += quadrant(x: 1680, y: 140, bg: "#FEE2E2", label: "⚠️ WEAKNESSES", labelColor: "#991B1B", items: [
            "Legacy billing blocks self-serve.", "Mobile ratings stuck at 3.6★.", "Enterprise sales cycle: 9 months.", "Key-person risk in platform team."], stickyColor: "#FECACA", textColor: "#7F1D1D")
        swotElements += quadrant(x: 120, y: 1040, bg: "#DBEAFE", label: "🚀 OPPORTUNITIES", labelColor: "#1E40AF", items: [
            "EU expansion — 3 competitors left.", "API platform & developer ecosystem.", "AI-assisted workflows (top request).", "Partnership with big-4 consultancies."], stickyColor: "#BFDBFE", textColor: "#1E3A8A")
        swotElements += quadrant(x: 1680, y: 1040, bg: "#FEF3C7", label: "🛑 THREATS", labelColor: "#92400E", items: [
            "Well-funded entrant at ½ our price.", "Platform policy changes pending.", "Open-source alternative gaining stars.", "Talent war inflating comp 20%/yr."], stickyColor: "#FDE68A", textColor: "#78350F")
        swotElements.append(CanvasElement(name: "Title", payload: .text(TextContent(text: "SWOT — STRATEGIC PLANNING OFFSITE", fontFamily: "Inter", fontSize: 30, fontWeight: 900, alignment: .left, textColor: CodableColor(hex: "#1C1917"), letterSpacing: 1)), x: 120, y: 50, width: 1400, height: 40, zIndex: 5))

        let page = CanvasPage(
            name: "SWOT Analysis",
            width: 3200, height: 2000,
            background: FillStyle(type: .solid, solidColor: CodableColor(hex: "#FAFAF9")),
            elements: swotElements
        )

        return CanvasTemplate(
            id: "swot_analysis_board",
            title: "SWOT Analysis Board",
            category: "Whiteboard & Mindmap",
            docType: .whiteboard,
            themeName: "Strategy",
            preset: CanvasPreset(name: "Infinite Whiteboard", category: .whiteboard, width: 3200, height: 2000, iconName: "square.grid.3x3.fill", description: "Boundless canvas"),
            page: page,
            previewColorHex: "#FAFAF9"
        )
    }

    // =========================================================================
    // 6. USER JOURNEY MAP (Stages × Emotions, 3600 × 1800)
    // =========================================================================
    public static func createUserJourneyMapTemplate() -> CanvasTemplate {
        let stages = ["DISCOVER", "EVALUATE", "SIGN UP", "FIRST USE", "ADVOCATE"]
        let stageColors = ["#EDE9FE", "#DBEAFE", "#DCFCE7", "#FEF3C7", "#FCE7F3"]
        let stageTextColors = ["#5B21B6", "#1E40AF", "#166534", "#92400E", "#9D174D"]

        var els: [CanvasElement] = [
            CanvasElement(name: "Title", payload: .text(TextContent(text: "USER JOURNEY MAP — NEW CUSTOMER", fontFamily: "Inter", fontSize: 28, fontWeight: 900, alignment: .left, textColor: CodableColor(hex: "#111827"), letterSpacing: 1)), x: 100, y: 60, width: 1200, height: 38, zIndex: 9),
            CanvasElement(name: "Persona", payload: .text(TextContent(text: "Persona: 'Startup Sam' — technical founder, 2–20 person team, values speed over polish.", fontFamily: "Inter", fontSize: 14, fontWeight: 500, alignment: .left, textColor: CodableColor(hex: "#6B7280"))), x: 100, y: 104, width: 1600, height: 22, zIndex: 9)
        ]

        for (i, stage) in stages.enumerated() {
            let x = 100.0 + Double(i) * 700.0
            els.append(CanvasElement(name: "Stage BG", payload: .shape(ShapeContent(kind: .roundedRectangle, cornerRadius: 18, fill: FillStyle.solid(CodableColor(hex: stageColors[i])))), x: x, y: 160, width: 660, height: 1400, zIndex: 0))
            els.append(CanvasElement(name: "Stage Title", payload: .text(TextContent(text: "\(i + 1). \(stage)", fontFamily: "Inter", fontSize: 18, fontWeight: 900, alignment: .left, textColor: CodableColor(hex: stageTextColors[i]), letterSpacing: 2)), x: x + 36, y: 190, width: 560, height: 26, zIndex: 1))

            let actions = [
                "• Hears about us on X / HN\n• Lands on pricing page",
                "• Compares 3 tools\n• Reads docs & changelog",
                "• Creates account\n• Invites 1 teammate",
                "• Completes first project\n• Hits one blocker",
                "• Tweets about launch\n• Refers 2 founders"
            ]
            let thoughts = [
                "\"Is this fast enough\nfor my use case?\"",
                "\"Can I trust this with\nmy data?\"",
                "\"Why do I need a credit\ncard already?\"",
                "\"This import actually\nworked?!\"",
                "\"My whole team needs\nto see this.\""
            ]
            els.append(CanvasElement(name: "Actions", payload: .text(TextContent(text: actions[i], fontFamily: "Inter", fontSize: 14, fontWeight: 500, alignment: .left, textColor: CodableColor(hex: stageTextColors[i]), lineSpacing: 6, cardBackground: .white, cardCornerRadius: 10, cardPadding: 16)), x: x + 36, y: 240, width: 588, height: 150, shadow: ShadowEffect.subtle, zIndex: 2))
            els.append(CanvasElement(name: "Thoughts", payload: .text(TextContent(text: thoughts[i], fontFamily: "Indie Flower", fontSize: 17, fontWeight: 700, alignment: .left, textColor: CodableColor(hex: stageTextColors[i]), lineSpacing: 5, cardBackground: CodableColor(hex: stageColors[i]), cardCornerRadius: 10, cardPadding: 16)), x: x + 36, y: 420, width: 588, height: 140, shadow: ShadowEffect.subtle, zIndex: 2))
            let emotions = ["🤔 Curious", "🧐 Evaluating", "😬 Friction", "😃 Delighted", "🤩 Champion"]
            els.append(CanvasElement(name: "Emotion", payload: .text(TextContent(text: emotions[i], fontFamily: "Inter", fontSize: 16, fontWeight: 800, alignment: .center, textColor: CodableColor(hex: stageTextColors[i]))), x: x + 36, y: 590, width: 588, height: 40, zIndex: 2))
        }

        let page = CanvasPage(
            name: "User Journey Map",
            width: 3600, height: 1800,
            background: FillStyle(type: .solid, solidColor: CodableColor(hex: "#FFFFFF")),
            elements: els
        )

        return CanvasTemplate(
            id: "user_journey_map",
            title: "User Journey Map",
            category: "Whiteboard & Mindmap",
            docType: .whiteboard,
            themeName: "UX & Research",
            preset: CanvasPreset(name: "Infinite Whiteboard", category: .whiteboard, width: 3600, height: 1800, iconName: "square.grid.3x3.fill", description: "Boundless canvas"),
            page: page,
            previewColorHex: "#FFFFFF"
        )
    }
}
