import SwiftUI

public struct ElementsTabView: View {
    @ObservedObject var viewModel: CanvasDocumentViewModel

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SHAPES & CRAFT")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.primary)
                .tracking(0.5)
                .padding(.horizontal, 14)
                .padding(.top, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    // Whiteboard, Mindmap & Sticky Notes
                    sectionHeader("🧠 Mindmap & Sticky Notes")
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        stickyNoteButton(title: "Sticky Yellow", color: CodableColor(hex: "#FEF08A"), textColor: CodableColor(hex: "#854D0E"), borderColor: CodableColor(hex: "#FDE047"))
                        stickyNoteButton(title: "Sticky Mint", color: CodableColor(hex: "#D1FAE5"), textColor: CodableColor(hex: "#065F46"), borderColor: CodableColor(hex: "#6EE7B7"))
                        stickyNoteButton(title: "Sticky Sky", color: CodableColor(hex: "#E0F2FE"), textColor: CodableColor(hex: "#0369A1"), borderColor: CodableColor(hex: "#7DD3FC"))
                        stickyNoteButton(title: "Sticky Rose", color: CodableColor(hex: "#FFE4E6"), textColor: CodableColor(hex: "#9F1239"), borderColor: CodableColor(hex: "#FDA4AF"))
                        craftButton(title: "Mindmap Node", kind: .pill, icon: "capsule.portrait.fill", fill: .solid(CodableColor(hex: "#C2410C")))
                        craftButton(title: "Flowchart Card", kind: .roundedRectangle, icon: "app.fill", fill: .solid(CodableColor(hex: "#FFFFFF")))
                    }

                    // Tactile Paper & Press Elements
                    sectionHeader("Tactile Stationery & Seals")
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        craftButton(title: "Washi Tape", kind: .washiTape, icon: "bookmark.fill", fill: .solid(CodableColor.washiTerracotta.withAlphaComponent(0.85)))
                        craftButton(title: "Postage Stamp", kind: .postageStamp, icon: "envelope.fill", fill: .solid(CodableColor(hex: "#FAF5E9")))
                        craftButton(title: "Wax Seal", kind: .waxSeal, icon: "seal.fill", fill: .solid(.waxSealRed))
                        craftButton(title: "Torn Paper", kind: .tornPaper, icon: "doc.plaintext.fill", fill: .solid(CodableColor(hex: "#FAF7F0")))
                        craftButton(title: "Price Tag", kind: .tag, icon: "tag.fill", fill: .solid(CodableColor(hex: "#EFE8DA")))
                        craftButton(title: "Ticket Coupon", kind: .ticket, icon: "ticket.fill", fill: .solid(CodableColor(hex: "#F5F2EB")))
                    }

                    // Newspaper & Editorial Rules
                    sectionHeader("Editorial Rules & Badges")
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        craftButton(title: "Oxford Rule", kind: .oxfordBorder, icon: "rectangle.inset.filled", fill: .solid(.inkBlack))
                        craftButton(title: "Hairline Rule", kind: .line, icon: "line.diagonal", fill: .solid(.inkBlack))
                        craftButton(title: "Embossed Seal", kind: .badge, icon: "rosette", fill: .solid(.terracotta))
                        craftButton(title: "Speech Bubble", kind: .speechBubble, icon: "bubble.left.fill", fill: .solid(.newsprint))
                        craftButton(title: "Quote Callout", kind: .quoteBubble, icon: "quote.bubble.fill", fill: .solid(CodableColor(hex: "#FAF7F0")))
                        craftButton(title: "Ribbon Banner", kind: .bannerRibbon, icon: "flag.fill", fill: .solid(.terracotta))
                        craftButton(title: "Bookmark Notch", kind: .bookmark, icon: "bookmark.fill", fill: .solid(.vintageForest))
                        craftButton(title: "Shield Badge", kind: .shield, icon: "shield.fill", fill: .solid(.vintageForest))
                    }

                    // Special Decorative Emblems & Flourishes
                    sectionHeader("Special Emblems & Flourishes")
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        miniShapeButton(title: "Sparkle 4pt", kind: .sparkleStar, icon: "sparkle")
                        miniShapeButton(title: "Sunburst", kind: .starburst, icon: "sun.max.fill")
                        miniShapeButton(title: "Petal Flower", kind: .flower, icon: "camera.macro")
                        miniShapeButton(title: "Crescent", kind: .crescentMoon, icon: "moon.stars.fill")
                        miniShapeButton(title: "Lightning", kind: .lightning, icon: "bolt.fill")
                        miniShapeButton(title: "Cloud", kind: .cloud, icon: "cloud.fill")
                        miniShapeButton(title: "Donut Ring", kind: .donut, icon: "circle.circle")
                        miniShapeButton(title: "Cross", kind: .cross, icon: "plus")
                        miniShapeButton(title: "Heart", kind: .heart, icon: "heart.fill")
                    }

                    // Standard Geometric Shapes
                    sectionHeader("Geometrics & Polygons")
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        miniShapeButton(title: "Database", kind: .database, icon: "cylinder.fill")
                        miniShapeButton(title: "Rectangle", kind: .rectangle, icon: "square.fill")
                        miniShapeButton(title: "Card", kind: .roundedRectangle, icon: "app.fill")
                        miniShapeButton(title: "Capsule", kind: .pill, icon: "capsule.fill")
                        miniShapeButton(title: "Circle", kind: .circle, icon: "circle.fill")
                        miniShapeButton(title: "Triangle", kind: .triangle, icon: "triangle.fill")
                        miniShapeButton(title: "Diamond", kind: .diamond, icon: "diamond.fill")
                        miniShapeButton(title: "Star 5pt", kind: .star, icon: "star.fill")
                        miniShapeButton(title: "Hexagon", kind: .polygon, icon: "hexagon.fill")
                        miniShapeButton(title: "Parallelogram", kind: .parallelogram, icon: "skew")
                        miniShapeButton(title: "Trapezoid", kind: .trapezoid, icon: "trapezoid.and.line.vertical")
                        miniShapeButton(title: "Arch", kind: .arch, icon: "door.left.hand.closed")
                        miniShapeButton(title: "Arrow", kind: .arrow, icon: "arrow.right")
                        miniShapeButton(title: "Chevron", kind: .chevron, icon: "chevron.right.2")
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 20)
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(Color(hex: "#C2410C"))
            .tracking(0.3)
            .padding(.top, 4)
    }

    private func craftButton(title: String, kind: ShapeKind, icon: String, fill: FillStyle) -> some View {
        Button(action: {
            viewModel.addShape(kind, fill: fill)
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#C2410C"))

                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.secondary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.16), lineWidth: 0.8))
        }
        .buttonStyle(.plain)
                .hoverHighlight()
    }

    private func miniShapeButton(title: String, kind: ShapeKind, icon: String) -> some View {
        Button(action: {
            viewModel.addShape(kind, fill: .solid(.inkBlack))
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "#C2410C"))

                Text(title)
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.secondary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.16), lineWidth: 0.8))
        }
        .buttonStyle(.plain)
                .hoverHighlight()
    }

    private func stickyNoteButton(title: String, color: CodableColor, textColor: CodableColor, borderColor: CodableColor) -> some View {
        Button(action: {
            viewModel.addStickyNote(color: color, textColor: textColor, borderColor: borderColor)
        }) {
            HStack(spacing: 8) {
                Image(systemName: "note.text")
                    .font(.system(size: 13))
                    .foregroundColor(textColor.color)

                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    // Sticky fills are fixed pastels — use the note's own ink, not
                    // .primary (white-on-pastel in dark mode).
                    .foregroundColor(textColor.color)

                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(color.color)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(borderColor.color, lineWidth: 1))
        }
        .buttonStyle(.plain)
                .hoverHighlight()
    }
}
