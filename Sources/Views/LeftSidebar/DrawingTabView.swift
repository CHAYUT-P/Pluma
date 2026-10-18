import SwiftUI

/// Pen settings — nib width and ink — shown in a popover from the toolbar Pen
/// button (formerly the left rail's Draw tab).
public struct PenSettingsPopover: View {
    @ObservedObject var viewModel: CanvasDocumentViewModel

    private let inkColors: [CodableColor] = [
        .inkBlack, CodableColor.terracotta, CodableColor.vintageForest, CodableColor.agedBrass,
        CodableColor.waxSealRed, CodableColor(hex: "#1D4ED8"), CodableColor(hex: "#57534E"), .white
    ]

    public init(viewModel: CanvasDocumentViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Pen")
                    .font(PlumaTheme.label(13, weight: .semibold))
                Spacer()
                Toggle("Drawing", isOn: Binding(
                    get: { viewModel.activeTool == .draw },
                    set: { viewModel.activeTool = $0 ? .draw : .select }
                ))
                .toggleStyle(.switch)
                .controlSize(.mini)
                .font(PlumaTheme.label(11, weight: .regular))
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    sectionTitle("Width")
                    Spacer()
                    Text("\(Int(viewModel.drawingLineWidth)) pt")
                        .font(PlumaTheme.numeric(11))
                        .foregroundColor(.secondary)
                }
                Slider(value: $viewModel.drawingLineWidth, in: 1...25, step: 1)
                    .controlSize(.small)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    sectionTitle("Ink")
                    Spacer()
                    Text("Custom")
                        .font(PlumaTheme.label(11, weight: .regular))
                        .foregroundColor(.secondary)
                    CanvaColorButton(color: $viewModel.drawingColor, size: 16)
                        .help("Custom ink color")
                }
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(28), spacing: 8), count: 4), alignment: .leading, spacing: 8) {
                    ForEach(inkColors, id: \.self) { color in
                        Button(action: { viewModel.drawingColor = color }) {
                            Circle()
                                .fill(color.color)
                                .frame(width: 22, height: 22)
                                .overlay(Circle().stroke(PlumaTheme.hairline, lineWidth: 1))
                                .padding(2)
                                .overlay(
                                    Circle().stroke(viewModel.drawingColor == color ? PlumaTheme.accent : .clear, lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                        .help(color.hexString)
                    }
                }
            }
        }
        .padding(14)
        .frame(width: 230)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title.uppercased())
            .font(PlumaTheme.label(10, weight: .semibold))
            .tracking(0.6)
            .foregroundColor(.secondary)
    }
}
