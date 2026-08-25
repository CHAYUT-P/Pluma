import SwiftUI

public struct PageSettingsSection: View {
    @ObservedObject var viewModel: CanvasDocumentViewModel

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("SHEET SPECIFICATIONS")
                .font(.system(size: 12, weight: .bold, design: .serif))
                .foregroundColor(Color(hex: "#FAF7F0"))
                .tracking(1.0)

            // Sheet Dimensions
            VStack(alignment: .leading, spacing: 6) {
                Text("Dimensions")
                    .font(.system(size: 10, weight: .bold, design: .serif))
                    .foregroundColor(Color(hex: "#D97706"))

                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Text("W")
                            .font(.system(size: 10, weight: .bold, design: .serif))
                            .foregroundColor(Color(hex: "#8C827A"))
                        TextField("", value: $viewModel.currentPage.width, format: .number)
                            .textFieldStyle(.plain)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(Color(hex: "#FAF7F0"))
                            .padding(4)
                            .background(Color(hex: "#262422"))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color(hex: "#3D3833"), lineWidth: 0.8))
                    }

                    HStack(spacing: 4) {
                        Text("H")
                            .font(.system(size: 10, weight: .bold, design: .serif))
                            .foregroundColor(Color(hex: "#8C827A"))
                        TextField("", value: $viewModel.currentPage.height, format: .number)
                            .textFieldStyle(.plain)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(Color(hex: "#FAF7F0"))
                            .padding(4)
                            .background(Color(hex: "#262422"))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color(hex: "#3D3833"), lineWidth: 0.8))
                    }
                }
            }

            Divider().background(Color(hex: "#2D2A26"))

            // Snapping & Grid Options
            VStack(alignment: .leading, spacing: 8) {
                Text("Drafting Alignment")
                    .font(.system(size: 10, weight: .bold, design: .serif))
                    .foregroundColor(Color(hex: "#D97706"))

                Toggle("Smart Snapping Lines", isOn: $viewModel.enableSnapping)
                    .font(.system(size: 11, design: .serif))

                Toggle("Show Drafting Millimeter Grid", isOn: $viewModel.showGridOverlay)
                    .font(.system(size: 11, design: .serif))
            }

            Divider().background(Color(hex: "#2D2A26"))

            // Background Fill
            VStack(alignment: .leading, spacing: 8) {
                Text("Sheet Stock Fill")
                    .font(.system(size: 10, weight: .bold, design: .serif))
                    .foregroundColor(Color(hex: "#D97706"))

                Toggle("Transparent Background", isOn: $viewModel.currentPage.isTransparent)
                    .font(.system(size: 11, design: .serif))

                if !viewModel.currentPage.isTransparent {
                    ColorPicker("Stock Tint", selection: Binding(
                        get: { viewModel.currentPage.background.solidColor.color },
                        set: { col in
                            viewModel.saveHistoryState()
                            viewModel.currentPage.background = .solid(CodableColor(color: col))
                        }
                    ))
                }
            }

            Divider().background(Color(hex: "#2D2A26"))

            // Document Summary
            VStack(alignment: .leading, spacing: 6) {
                Text("STUDIO PERFORMANCE")
                    .font(.system(size: 10, weight: .bold, design: .serif))
                    .foregroundColor(Color(hex: "#D97706"))

                HStack {
                    Text("Total Sheets:")
                        .font(.system(size: 11, design: .serif))
                        .foregroundColor(Color(hex: "#8C827A"))
                    Spacer()
                    Text("\(viewModel.project.pages.count)")
                        .font(.system(size: 11, weight: .semibold, design: .serif))
                        .foregroundColor(Color(hex: "#FAF7F0"))
                }

                HStack {
                    Text("Elements on Sheet:")
                        .font(.system(size: 11, design: .serif))
                        .foregroundColor(Color(hex: "#8C827A"))
                    Spacer()
                    Text("\(viewModel.currentPage.elements.count)")
                        .font(.system(size: 11, weight: .semibold, design: .serif))
                        .foregroundColor(Color(hex: "#FAF7F0"))
                }
            }
        }
    }
}
