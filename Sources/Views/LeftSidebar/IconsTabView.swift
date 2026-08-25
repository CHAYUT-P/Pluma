import SwiftUI

public struct IconsTabView: View {
    @ObservedObject var viewModel: CanvasDocumentViewModel
    @State private var searchText: String = ""
    @State private var selectedCategory: String = "All"

    struct MulticolorIconPreset: Identifiable {
        let id = UUID()
        let name: String
        let symbol: String
        let primary: CodableColor
        let secondary: CodableColor
        let tertiary: CodableColor

        init(_ name: String, _ symbol: String, _ primaryHex: String, _ secondaryHex: String, _ tertiaryHex: String = "#F59E0B") {
            self.name = name
            self.symbol = symbol
            self.primary = CodableColor(hex: primaryHex)
            self.secondary = CodableColor(hex: secondaryHex)
            self.tertiary = CodableColor(hex: tertiaryHex)
        }
    }

    private let multicolorPresets: [MulticolorIconPreset] = [
        MulticolorIconPreset("Sunny Day", "cloud.sun.fill", "#38BDF8", "#F59E0B"),
        MulticolorIconPreset("Verified Seal", "checkmark.seal.fill", "#10B981", "#FFFFFF"),
        MulticolorIconPreset("Champion Trophy", "trophy.fill", "#D97706", "#C2410C"),
        MulticolorIconPreset("Royal Crown", "crown.fill", "#D97706", "#E11D48"),
        MulticolorIconPreset("Love Badge", "heart.circle.fill", "#E11D48", "#FFFFFF"),
        MulticolorIconPreset("Blazing Fire", "flame.fill", "#DC2626", "#F97316"),
        MulticolorIconPreset("Eco Leaf", "leaf.fill", "#15803D", "#84CC16"),
        MulticolorIconPreset("Camera Lens", "camera.badge.ellipsis", "#334155", "#2563EB"),
        MulticolorIconPreset("Price Tag", "tag.fill", "#C2410C", "#F59E0B"),
        MulticolorIconPreset("Pro Laptop", "laptopcomputer.and.iphone", "#1E293B", "#0284C7"),
        MulticolorIconPreset("System Folder", "folder.badge.gearshape", "#D97706", "#475569"),
        MulticolorIconPreset("Turbo Lightning", "bolt.circle.fill", "#F59E0B", "#1C1917"),
        MulticolorIconPreset("Growth Chart", "chart.line.uptrend.xyaxis.circle.fill", "#4F46E5", "#10B981"),
        MulticolorIconPreset("Artist Palette", "swatchpalette.fill", "#C2410C", "#0D9488", "#F59E0B"),
        MulticolorIconPreset("Classic Books", "books.vertical.fill", "#881337", "#D97706"),
        MulticolorIconPreset("World Globe", "globe.americas.fill", "#0284C7", "#16A34A")
    ]

    private let categories: [(name: String, symbols: [String])] = [
        ("Design & Craft", [
            "paintbrush.pointed.fill", "pencil.tip", "paintbrush.fill", "eyedropper.halffull", "crop", "wand.and.stars",
            "sparkles", "seal.fill", "rosette", "swatchpalette.fill", "square.2.layers.3d.top.filled", "circle.dashed",
            "square.dashed", "ruler.fill", "scissors", "highlighter", "eraser.fill", "scribble.variable", "compass.drawing",
            "circle.grid.cross.fill", "circle.hexagongrid.fill", "paintpalette.fill", "lasso"
        ]),
        ("Tech & Code", [
            "chevron.left.forwardslash.chevron.right", "cpu.fill", "memorychip.fill", "terminal.fill", "network", "server.rack",
            "laptopcomputer", "desktopcomputer", "macbook", "ipad", "iphone", "applewatch", "keyboard.fill",
            "point.3.connected.trianglepath.dotted", "externaldrive.fill", "bolt.fill", "wifi", "antenna.radiowaves.left.and.right",
            "curlybraces", "hammer.fill", "wrench.and.screwdriver.fill", "shippingbox.and.arrow.backward.fill"
        ]),
        ("UI & Navigation", [
            "cursorarrow.rays", "hand.point.up.left.fill", "magnifyingglass", "slider.horizontal.3", "switch.2", "gearshape.fill",
            "bell.fill", "bookmark.fill", "star.fill", "heart.fill", "flag.fill", "pin.fill", "paperclip", "link",
            "checkmark.circle.fill", "xmark.circle.fill", "plus.circle.fill", "minus.circle.fill", "arrow.clockwise",
            "ellipsis.circle.fill", "line.3.horizontal", "square.and.arrow.up.fill"
        ]),
        ("Media & Capture", [
            "camera.fill", "photo.fill", "photo.on.rectangle.angled", "film.fill", "video.fill", "mic.fill", "waveform",
            "speaker.wave.3.fill", "play.fill", "pause.fill", "backward.fill", "forward.fill", "opticaldisc.fill", "music.note",
            "music.mic", "guitars.fill", "theatermasks.fill", "tv.fill"
        ]),
        ("Stationery & Mail", [
            "envelope.fill", "paperplane.fill", "doc.plaintext.fill", "doc.text.fill", "books.vertical.fill", "newspaper.fill",
            "folder.fill", "archivebox.fill", "tray.full.fill", "tag.fill", "shippingbox.fill", "gift.fill", "cart.fill",
            "creditcard.fill", "banknote.fill", "calendar", "clock.fill", "printer.fill"
        ]),
        ("Nature & Weather", [
            "sun.max.fill", "moon.stars.fill", "cloud.sun.fill", "sparkle", "flame.fill", "drop.fill", "leaf.fill",
            "tree.fill", "globe.americas.fill", "globe.europe.africa.fill", "globe.asia.australia.fill", "wind", "snowflake",
            "tornado", "thermometer.sun.fill", "mountain.2.fill"
        ]),
        ("Commerce & Finance", [
            "creditcard.fill", "banknote.fill", "chart.xyaxis.line", "chart.bar.xaxis", "chart.pie.fill", "arrow.up.right.circle.fill",
            "arrow.down.right.circle.fill", "percent", "dollarsign.circle.fill", "eurosign.circle.fill", "sterlingsign.circle.fill",
            "bag.fill", "cart.badge.plus", "barcode.viewfinder"
        ]),
        ("Security & Badges", [
            "lock.fill", "lock.open.fill", "key.fill", "shield.checkered", "shield.fill", "checkmark.seal.fill",
            "crown.fill", "medal.fill", "trophy.fill", "person.badge.shield.checkmark.fill", "eye.fill", "hand.raised.fill"
        ])
    ]

    private var allSymbols: [String] {
        if selectedCategory == "All" || selectedCategory == "Multicolor" {
            let combined = categories.flatMap { $0.symbols }
            if searchText.isEmpty { return combined }
            return combined.filter { $0.localizedCaseInsensitiveContains(searchText) }
        } else {
            guard let cat = categories.first(where: { $0.name == selectedCategory }) else { return [] }
            if searchText.isEmpty { return cat.symbols }
            return cat.symbols.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SYMBOLS & ICONS")
                .font(.system(size: 12, weight: .bold, design: .serif))
                .foregroundColor(.primary)
                .tracking(0.5)
                .padding(.horizontal, 14)
                .padding(.top, 12)

            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search 200+ SF Symbols...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11))
            }
            .padding(6)
            .background(Color.secondary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .padding(.horizontal, 14)

            // Category Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 5) {
                    filterChip("All")
                    filterChip("Multicolor")
                    ForEach(categories, id: \.name) { cat in
                        filterChip(cat.name)
                    }
                }
                .padding(.horizontal, 14)
            }

            // Icons Grid
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    // Multicolor Preset Showcase
                    if selectedCategory == "All" || selectedCategory == "Multicolor" {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("MULTICOLOR & DUOTONE")
                                .font(.system(size: 11, weight: .bold, design: .serif))
                                .foregroundColor(Color(hex: "#C2410C"))
                                .tracking(0.3)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(multicolorPresets) { preset in
                                    Button(action: {
                                        viewModel.addMulticolorIcon(
                                            preset.symbol,
                                            primary: preset.primary,
                                            secondary: preset.secondary,
                                            tertiary: preset.tertiary
                                        )
                                    }) {
                                        VStack(spacing: 3) {
                                            Image(systemName: preset.symbol)
                                                .font(.system(size: 18))
                                                .symbolRenderingMode(.palette)
                                                .foregroundStyle(preset.primary.color, preset.secondary.color, preset.tertiary.color)
                                                .frame(width: 44, height: 38)

                                            Text(preset.name)
                                                .font(.system(size: 8, weight: .medium))
                                                .foregroundColor(.primary)
                                                .lineLimit(1)
                                        }
                                        .padding(.vertical, 4)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.secondary.opacity(0.06))
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.12), lineWidth: 1))
                                    }
                                    .buttonStyle(.plain)
                .hoverHighlight()
                                    .help("\(preset.name) (Multicolor)")
                                }
                            }
                        }
                    }

                    if selectedCategory != "Multicolor" {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(selectedCategory == "All" ? "STANDARD ICONS" : selectedCategory.uppercased())
                                .font(.system(size: 11, weight: .bold, design: .serif))
                                .foregroundColor(Color(hex: "#C2410C"))
                                .tracking(0.3)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(allSymbols, id: \.self) { symbol in
                                    Button(action: {
                                        viewModel.addIcon(symbol, color: .inkBlack)
                                    }) {
                                        Image(systemName: symbol)
                                            .font(.system(size: 17))
                                            .foregroundColor(.primary)
                                            .frame(width: 44, height: 44)
                                            .background(Color.secondary.opacity(0.06))
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.12), lineWidth: 1))
                                    }
                                    .buttonStyle(.plain)
                .hoverHighlight()
                                    .help(symbol)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 20)
            }
        }
    }

    private func filterChip(_ name: String) -> some View {
        let isSel = (selectedCategory == name)
        return Button(action: { selectedCategory = name }) {
            Text(name)
                .font(.system(size: 10, weight: isSel ? .bold : .medium, design: .serif))
                .padding(.horizontal, 8)
                .padding(.vertical, 3.5)
                .background(isSel ? Color(hex: "#C2410C") : Color.secondary.opacity(0.08))
                .foregroundColor(isSel ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
                .hoverHighlight()
    }
}
