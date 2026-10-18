import SwiftUI

public struct BackgroundsTabView: View {
    @ObservedObject var viewModel: CanvasDocumentViewModel
    @State private var selectedCategory: TextureCategory = .paper

    private let editorialInkColors: [CodableColor] = [
        .newsprint, .parchment, .kraftPaper, .inkBlack,
        CodableColor(hex: "#C2410C"), CodableColor(hex: "#2D4A3E"), CodableColor(hex: "#881337"), CodableColor(hex: "#B45309")
    ]

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SidebarPanelHeader("Background")

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    // Transparent Sheet Toggle
                    Toggle("Transparent Background", isOn: $viewModel.currentPage.isTransparent)
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 14)

                    Divider().padding(.horizontal, 14)

                    // Texture Category Filter Tabs
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(TextureCategory.allCases) { cat in
                                Button(action: { selectedCategory = cat }) {
                                    Text(cat.rawValue)
                                        .font(.system(size: 10, weight: selectedCategory == cat ? .bold : .regular))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(selectedCategory == cat ? PlumaTheme.accent : PlumaTheme.control)
                                        .foregroundColor(selectedCategory == cat ? .white : .primary)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                .hoverHighlight()
                            }
                        }
                        .padding(.horizontal, 14)
                    }

                    // Textures Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(TextureCatalog.allTextures.filter { $0.category == selectedCategory }) { texture in
                            VStack(alignment: .leading, spacing: 4) {
                                ZStack(alignment: .bottomTrailing) {
                                    // 1. Thumbnail Image Button (Applies as Page Background)
                                    Button(action: {
                                        viewModel.applyTextureBackground(preset: texture)
                                    }) {
                                        Group {
                                            if let nsImg = texture.nsImage {
                                                Image(nsImage: nsImg)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(height: 68)
                                                    .clipped()
                                            } else {
                                                RoundedRectangle(cornerRadius: 6)
                                                    .fill(Color.secondary.opacity(0.1))
                                                    .frame(height: 68)
                                            }
                                        }
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                        )
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                .hoverHighlight()

                                    // 2. Add as Overlay Layer Button (Separate sibling button)
                                    Button(action: {
                                        viewModel.addTextureOverlay(preset: texture)
                                    }) {
                                        HStack(spacing: 2) {
                                            Image(systemName: "plus.square.on.square")
                                                .font(.system(size: 9))
                                            Text("Layer")
                                                .font(.system(size: 8, weight: .bold))
                                        }
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 3)
                                        .background(Color.black.opacity(0.85))
                                        .foregroundColor(.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                        .padding(4)
                                    }
                                    .buttonStyle(.plain)
                .hoverHighlight()
                                    .help("Add as adjustable texture overlay layer")
                                }

                                Text(texture.name)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)

                                Text(texture.description)
                                    .font(.system(size: 8.5))
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                    .padding(.horizontal, 14)

                    Divider().padding(.horizontal, 14)

                    SidebarSectionHeader("Page Colors")
                        .padding(.horizontal, 14)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(editorialInkColors, id: \.self) { color in
                            Button(action: {
                                viewModel.saveHistoryState()
                                viewModel.currentPage.isTransparent = false
                                viewModel.currentPage.background = .solid(color)
                            }) {
                                Circle()
                                    .fill(color.color)
                                    .frame(width: 32, height: 32)
                                    .overlay(Circle().stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                .hoverHighlight()
                        }
                    }
                    .padding(.horizontal, 14)

                    Divider().padding(.horizontal, 14)

                    // Image textures (moved here from Media) — placed as image
                    // layers rather than applied as the page background.
                    SidebarSectionHeader("Engravings & Textures")
                        .padding(.horizontal, 14)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        stockButton(title: "Press Room", hex: "#292524")
                        stockButton(title: "Cotton Linters", hex: "#EFE8DA")
                        stockButton(title: "Parchment Map", hex: "#D97706")
                        stockButton(title: "Type Case", hex: "#1C1917")
                    }
                    .padding(.horizontal, 14)
                }
                .padding(.bottom, 20)
            }
        }
    }

    private func stockButton(title: String, hex: String) -> some View {
        Button(action: {
            let base64 = ImageUtils.generatePlaceholder(width: 800, height: 600, text: title, colorHex: hex)
            let elem = CanvasElement(
                name: title,
                payload: .image(ImageContent(imageBase64: base64, cornerRadius: 4)),
                x: 100, y: 100, width: 360, height: 260
            )
            viewModel.placeNewElement(elem)
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(hex: hex))
                    .frame(height: 56)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(PlumaTheme.hairline, lineWidth: 1))

                Text(title)
                    .font(PlumaTheme.label(10.5, weight: .semibold))
                    .foregroundColor(.white)
                    .shadow(radius: 2)
            }
        }
        .buttonStyle(.plain)
        .hoverHighlight()
        .help("Add as an image layer")
    }
}
