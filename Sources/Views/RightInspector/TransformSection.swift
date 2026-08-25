import SwiftUI

public struct TransformSection: View {
    @ObservedObject var viewModel: CanvasDocumentViewModel

    public var body: some View {
        if let element = viewModel.primarySelectedElement {
            VStack(alignment: .leading, spacing: 10) {
                Text("TRANSFORM & ALIGN")
                    .font(.system(size: 10, weight: .bold, design: .serif))
                    .foregroundColor(Color(hex: "#D97706"))

                // Alignments
                HStack(spacing: 2) {
                    alignButton(icon: "align.horizontal.left", help: "Align Left") { viewModel.alignSelected(.left) }
                    alignButton(icon: "align.horizontal.center", help: "Align Center (H)") { viewModel.alignSelected(.centerHorizontal) }
                    alignButton(icon: "align.horizontal.right", help: "Align Right") { viewModel.alignSelected(.right) }
                    Divider().frame(height: 14).background(Color(hex: "#3D3833"))
                    alignButton(icon: "align.vertical.top", help: "Align Top") { viewModel.alignSelected(.top) }
                    alignButton(icon: "align.vertical.center", help: "Align Center (V)") { viewModel.alignSelected(.centerVertical) }
                    alignButton(icon: "align.vertical.bottom", help: "Align Bottom") { viewModel.alignSelected(.bottom) }
                }
                .padding(3)
                .background(Color(hex: "#262422"))
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color(hex: "#3D3833"), lineWidth: 0.8))

                // X, Y, W, H Numerical Inputs
                Grid(horizontalSpacing: 6, verticalSpacing: 6) {
                    GridRow {
                        numberInput(label: "X", value: Binding(
                            get: { element.x },
                            set: { val in viewModel.updateSelectedElement { $0.x = val } }
                        ))
                        numberInput(label: "Y", value: Binding(
                            get: { element.y },
                            set: { val in viewModel.updateSelectedElement { $0.y = val } }
                        ))
                    }
                    GridRow {
                        numberInput(label: "W", value: Binding(
                            get: { element.width },
                            set: { val in viewModel.updateSelectedElement { $0.width = max(5, val) } }
                        ))
                        numberInput(label: "H", value: Binding(
                            get: { element.height },
                            set: { val in viewModel.updateSelectedElement { $0.height = max(5, val) } }
                        ))
                    }
                }

                // Rotation Angle Slider & Input
                HStack {
                    Text("Angle")
                        .font(.system(size: 11, design: .serif))
                        .foregroundColor(Color(hex: "#8C827A"))
                    Slider(value: Binding(
                        get: { element.rotation },
                        set: { val in viewModel.updateSelectedElement { $0.rotation = val } }
                    ), in: 0...360, step: 1)
                    Text("\(Int(element.rotation))°")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(Color(hex: "#FAF7F0"))
                        .frame(width: 32)
                }

                // Mirror Flips
                HStack(spacing: 8) {
                    Text("Flip")
                        .font(.system(size: 11, design: .serif))
                        .foregroundColor(Color(hex: "#8C827A"))
                    Button(action: { viewModel.flipSelected(horizontal: true) }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.left.and.right.righttriangle.left.righttriangle.right")
                                .font(.system(size: 10))
                            Text("Horizontal")
                                .font(.system(size: 10.5, weight: element.isFlippedH ? .bold : .medium))
                        }
                        .foregroundColor(element.isFlippedH ? .white : Color(hex: "#D6D3CD"))
                        .frame(maxWidth: .infinity, minHeight: 22)
                    }
                    .buttonStyle(HoverPillButtonStyle(cornerRadius: 5, tint: Color(hex: "#C2410C")))
                    .help("Flip Horizontally")

                    Button(action: { viewModel.flipSelected(horizontal: false) }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.and.down.righttriangle.up.righttriangle.down")
                                .font(.system(size: 10))
                            Text("Vertical")
                                .font(.system(size: 10.5, weight: element.isFlippedV ? .bold : .medium))
                        }
                        .foregroundColor(element.isFlippedV ? .white : Color(hex: "#D6D3CD"))
                        .frame(maxWidth: .infinity, minHeight: 22)
                    }
                    .buttonStyle(HoverPillButtonStyle(cornerRadius: 5, tint: Color(hex: "#C2410C")))
                    .help("Flip Vertically")
                }
            }
        }
    }

    private func alignButton(icon: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 10.5))
                .foregroundColor(Color(hex: "#D6D3CD"))
                .frame(maxWidth: .infinity, minHeight: 20)
        }
        .buttonStyle(.plain)
        .help(help)
    }

    private func numberInput(label: String, value: Binding<Double>) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .serif))
                .foregroundColor(Color(hex: "#8C827A"))
                .frame(width: 14)

            TextField("", value: value, format: .number)
                .textFieldStyle(.plain)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(Color(hex: "#FAF7F0"))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color(hex: "#262422"))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color(hex: "#3D3833"), lineWidth: 0.8))
        }
    }
}
