import SwiftUI

public struct DrawingTabView: View {
    @ObservedObject var viewModel: CanvasDocumentViewModel

    private let inkColors: [CodableColor] = [
        .inkBlack, CodableColor.terracotta, CodableColor.vintageForest, CodableColor.agedBrass,
        CodableColor.waxSealRed, CodableColor(hex: "#1D4ED8"), CodableColor(hex: "#57534E"), .white
    ]

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("INK & FREEHAND")
                .font(.system(size: 12, weight: .bold, design: .serif))
                .foregroundColor(.primary)
                .tracking(0.5)
                .padding(.horizontal, 14)
                .padding(.top, 12)

            VStack(alignment: .leading, spacing: 12) {
                Button(action: {
                    viewModel.activeTool = (viewModel.activeTool == .draw) ? .select : .draw
                }) {
                    HStack {
                        Image(systemName: "pencil.tip")
                        Text(viewModel.activeTool == .draw ? "Inking Mode: ACTIVE" : "Start Inking")
                            .font(.system(size: 12, weight: .bold, design: .serif))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(viewModel.activeTool == .draw ? Color(hex: "#C2410C") : Color.secondary.opacity(0.08))
                    .foregroundColor(viewModel.activeTool == .draw ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.16), lineWidth: 0.8))
                }
                .buttonStyle(.plain)
                .hoverHighlight()

                Text("Nib Width: \(Int(viewModel.drawingLineWidth)) px")
                    .font(.system(size: 11, weight: .medium, design: .serif))
                    .foregroundColor(.secondary)

                Slider(value: $viewModel.drawingLineWidth, in: 1...25, step: 1)

                Text("Ink Well")
                    .font(.system(size: 11, weight: .bold, design: .serif))
                    .foregroundColor(Color(hex: "#C2410C"))
                    .tracking(0.3)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(inkColors, id: \.self) { color in
                        Button(action: {
                            viewModel.drawingColor = color
                        }) {
                            Circle()
                                .fill(color.color)
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(viewModel.drawingColor == color ? Color(hex: "#C2410C") : Color.secondary.opacity(0.25), lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                .hoverHighlight()
                    }
                }
            }
            .padding(.horizontal, 14)

            Spacer()
        }
    }
}
