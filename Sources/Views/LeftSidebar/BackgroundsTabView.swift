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
            Text("CANVAS & TEXTURES")
                .font(.system(size: 12, weight: .bold, design: .serif))
                .foregroundColor(.primary)
                .tracking(0.5)
                .padding(.horizontal, 14)
                .padding(.top, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    // Transparent Sheet Toggle
                    Toggle("Transparent Background", isOn: $viewModel.currentPage.isTransparent)
                        .font(.system(size: 11, weight: .medium, design: .serif))
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
                                        .background(selectedCategory == cat ? Color(hex: "#C2410C") : Color.secondary.opacity(0.08))
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
                                    .font(.system(size: 10, weight: .semibold, design: .serif))
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

                    Text("EDITORIAL INK COLORS")
                        .font(.system(size: 11, weight: .bold, design: .serif))
                        .foregroundColor(Color(hex: "#C2410C"))
                        .tracking(0.3)
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
                }
                .padding(.bottom, 20)
            }
        }
    }
}
