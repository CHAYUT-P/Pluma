import SwiftUI

/// Opacity + drop shadow. Layer order lives in the selection bar and the
/// Arrange menu, so it is not repeated here.
public struct EffectsSection: View {
    @ObservedObject var viewModel: CanvasDocumentViewModel

    public var body: some View {
        if let element = viewModel.primarySelectedElement {
            InspectorSection("Opacity & Shadow", key: "effects") {
                // Opacity Slider
                HStack {
                    Text("Opacity")
                        .font(.system(size: 11))
                        .foregroundColor(Color.secondary)
                    Slider(value: Binding(
                        get: { element.opacity },
                        set: { val in viewModel.updateSelectedElement { $0.opacity = val } }
                    ), in: 0...1.0)
                    Text("\(Int(element.opacity * 100))%")
                        .font(PlumaTheme.numeric(10.5))
                        .foregroundColor(Color.primary)
                        .frame(width: 32)
                }

                // Drop Shadow
                HStack {
                    Text("Drop shadow")
                        .font(.system(size: 11))
                        .foregroundColor(Color.secondary)
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { element.shadow.isEnabled },
                        set: { val in viewModel.updateSelectedElement { $0.shadow.isEnabled = val } }
                    ))
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .labelsHidden()
                }

                if element.shadow.isEnabled {
                    HStack {
                        Text("Color")
                            .font(.system(size: 11))
                            .foregroundColor(Color.secondary)
                        Spacer()
                        // updateSelectedElement coalesces a drag into one undo step.
                        CanvaColorButton(
                            color: Binding(
                                get: { element.shadow.color },
                                set: { col in viewModel.updateSelectedElement { $0.shadow.color = col } }
                            ),
                            size: 22
                        )
                    }

                    HStack {
                        Text("Blur")
                            .font(.system(size: 11))
                            .foregroundColor(Color.secondary)
                        Slider(value: Binding(
                            get: { element.shadow.radius },
                            set: { val in viewModel.updateSelectedElement { $0.shadow.radius = val } }
                        ), in: 0...40)
                        Text("\(Int(element.shadow.radius))")
                            .font(PlumaTheme.numeric(10.5))
                            .foregroundColor(Color.primary)
                            .frame(width: 24)
                    }
                }
            }
        }
    }
}
