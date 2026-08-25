import SwiftUI

public struct EffectsSection: View {
    @ObservedObject var viewModel: CanvasDocumentViewModel

    public var body: some View {
        if let element = viewModel.primarySelectedElement {
            VStack(alignment: .leading, spacing: 10) {
                Text("TACTILE SHADOW & OPACITY")
                    .font(.system(size: 10, weight: .bold, design: .serif))
                    .foregroundColor(Color(hex: "#D97706"))

                // Opacity Slider
                HStack {
                    Text("Ink Density")
                        .font(.system(size: 11, design: .serif))
                        .foregroundColor(Color(hex: "#8C827A"))
                    Slider(value: Binding(
                        get: { element.opacity },
                        set: { val in viewModel.updateSelectedElement { $0.opacity = val } }
                    ), in: 0...1.0)
                    Text("\(Int(element.opacity * 100))%")
                        .font(.system(size: 10.5, design: .monospaced))
                        .foregroundColor(Color(hex: "#FAF7F0"))
                        .frame(width: 32)
                }

                // Drop Shadow
                HStack {
                    Text("Paper Cast Shadow")
                        .font(.system(size: 11, design: .serif))
                        .foregroundColor(Color(hex: "#8C827A"))
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { element.shadow.isEnabled },
                        set: { val in viewModel.updateSelectedElement { $0.shadow.isEnabled = val } }
                    ))
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                }

                if element.shadow.isEnabled {
                    ColorPicker("Shadow Tint", selection: Binding(
                        get: { element.shadow.color.color },
                        set: { col in viewModel.updateSelectedElement { $0.shadow.color = CodableColor(color: col) } }
                    ))

                    HStack {
                        Text("Softness")
                            .font(.system(size: 11, design: .serif))
                            .foregroundColor(Color(hex: "#8C827A"))
                        Slider(value: Binding(
                            get: { element.shadow.radius },
                            set: { val in viewModel.updateSelectedElement { $0.shadow.radius = val } }
                        ), in: 0...40)
                        Text("\(Int(element.shadow.radius))")
                            .font(.system(size: 10.5, design: .monospaced))
                            .foregroundColor(Color(hex: "#FAF7F0"))
                            .frame(width: 24)
                    }
                }

                Divider().background(Color(hex: "#2D2A26"))

                // Arrange
                Text("PRINT DEPTH (LAYERS)")
                    .font(.system(size: 10, weight: .bold, design: .serif))
                    .foregroundColor(Color(hex: "#D97706"))

                HStack(spacing: 4) {
                    arrangeButton(icon: "square.2.layers.3d.top.filled", label: "Top") { viewModel.bringToFront() }
                    arrangeButton(icon: "arrow.up", label: "Up") { viewModel.bringForward() }
                    arrangeButton(icon: "arrow.down", label: "Down") { viewModel.sendBackward() }
                    arrangeButton(icon: "square.2.layers.3d.bottom.filled", label: "Base") { viewModel.sendToBack() }
                }
            }
        }
    }

    private func arrangeButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 10.5))
                Text(label)
                    .font(.system(size: 9, design: .serif))
            }
            .frame(maxWidth: .infinity, minHeight: 28)
            .background(Color(hex: "#262422"))
            .foregroundColor(Color(hex: "#D6D3CD"))
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color(hex: "#3D3833"), lineWidth: 0.8))
        }
        .buttonStyle(.plain)
    }
}
