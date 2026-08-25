import SwiftUI

public struct BrandKitTabView: View {
    @ObservedObject var viewModel: CanvasDocumentViewModel
    @State private var brandKits: [BrandKit] = BrandKit.defaults

    public init(viewModel: CanvasDocumentViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("BRAND KIT")
                        .font(.system(size: 11, weight: .bold, design: .serif))
                        .foregroundColor(Color(hex: "#D97706"))
                        .tracking(1.0)

                    Text("Apply your brand colors & typography to any element with 1-click")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                // Brand Kits
                ForEach(brandKits) { kit in
                    brandKitCard(kit)
                }
            }
            .padding(16)
        }
    }

    private func brandKitCard(_ kit: BrandKit) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(kit.name)
                    .font(.system(size: 12, weight: .bold, design: .serif))
                    .foregroundColor(.primary)

                Spacer()

                Button("Apply Palette") {
                    applyPalette(kit)
                }
                .font(.system(size: 10, weight: .semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color(hex: "#C2410C").opacity(0.12))
                .foregroundColor(Color(hex: "#C2410C"))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .buttonStyle(.plain)
                .hoverHighlight()
            }

            // Colors Swatches
            HStack(spacing: 8) {
                ForEach(kit.colors, id: \.self) { col in
                    colorSwatchButton(col)
                }
            }

            // Fonts
            HStack(spacing: 8) {
                fontBadge(title: "Heading", font: kit.headingFontName) {
                    applyFontToSelection(kit.headingFontName)
                }
                fontBadge(title: "Body", font: kit.bodyFontName) {
                    applyFontToSelection(kit.bodyFontName)
                }
            }
        }
        .padding(12)
        .background(Color.secondary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.12), lineWidth: 1))
    }

    private func colorSwatchButton(_ col: CodableColor) -> some View {
        Button(action: {
            applyColorToSelection(col)
        }) {
            Circle()
                .fill(col.color)
                .frame(width: 32, height: 32)
                .overlay(Circle().stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
                .hoverHighlight()
        .help("Click to apply \(col.hexString) to selected element")
    }

    private func fontBadge(title: String, font: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 9, design: .serif))
                    .foregroundColor(.secondary)
                Text(font)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.secondary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
                .hoverHighlight()
        .help("Click to apply \(font) to selected text")
    }

    private func applyColorToSelection(_ col: CodableColor) {
        viewModel.saveHistoryState()
        viewModel.updateSelectedElement { elem in
            switch elem.payload {
            case .shape(var s):
                s.fill = .solid(col)
                elem.payload = .shape(s)
            case .text(var t):
                t.textColor = col
                elem.payload = .text(t)
            case .icon(var i):
                i.primaryColor = col
                elem.payload = .icon(i)
            default:
                break
            }
        }
        viewModel.showTemporaryToast("Applied \(col.hexString)")
    }

    private func applyFontToSelection(_ fontName: String) {
        viewModel.saveHistoryState()
        viewModel.updateSelectedElement { elem in
            if case .text(var t) = elem.payload {
                t.fontFamily = fontName
                elem.payload = .text(t)
            }
        }
        viewModel.showTemporaryToast("Applied font \(fontName)")
    }

    private func applyPalette(_ kit: BrandKit) {
        viewModel.saveHistoryState()
        if let firstCol = kit.colors.first {
            viewModel.currentPage.background = .solid(firstCol)
        }
        viewModel.showTemporaryToast("Applied \(kit.name) Theme!")
    }
}
