import SwiftUI

public struct InspectorView: View {
    @ObservedObject var viewModel: CanvasDocumentViewModel

    public var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if let element = viewModel.primarySelectedElement {
                        header(for: element)

                        Divider()

                        // Content first (what the element looks like), geometry after —
                        // the order designers reach for most often.
                        if viewModel.selectedElementIds.count == 1 {
                            switch element.payload {
                            case .shape:
                                FillSection(viewModel: viewModel)
                                Divider()
                                StrokeSection(viewModel: viewModel)
                            case .text:
                                TypographySection(viewModel: viewModel)
                            case .code:
                                CodeSection(viewModel: viewModel)
                            case .image:
                                ImageFiltersSection(viewModel: viewModel)
                            case .icon(let icon):
                                iconColorSection(icon)
                            case .drawing(let drawing):
                                drawingSection(drawing)
                            }
                            Divider()
                        }

                        TransformSection(viewModel: viewModel)

                        Divider()

                        EffectsSection(viewModel: viewModel)
                    } else {
                        PageSettingsSection(viewModel: viewModel)
                    }
                }
                .padding(14)
            }
        }
        .frame(width: 270)
        .background(PlumaTheme.chrome)
        .overlay(alignment: .leading) { Rectangle().fill(PlumaTheme.hairline).frame(width: 1) }
    }

    // MARK: - Header

    private func header(for element: CanvasElement) -> some View {
        let count = viewModel.selectedElementIds.count
        let anyLocked = viewModel.selectedElements.contains(where: \.isLocked)
        return HStack(spacing: 4) {
            VStack(alignment: .leading, spacing: 1) {
                Text(count > 1 ? "\(count) elements" : (element.name.isEmpty ? kindName(element) : element.name))
                    .font(PlumaTheme.label(13, weight: .semibold))
                    .lineLimit(1)
                if count == 1 && !element.name.isEmpty && element.name != kindName(element) {
                    Text(kindName(element))
                        .font(PlumaTheme.label(11, weight: .regular))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            headerButton(icon: anyLocked ? "lock.fill" : "lock.open",
                         tint: anyLocked ? PlumaTheme.accentWarm : .secondary,
                         help: anyLocked ? "Unlock (⌘L)" : "Lock (⌘L)") {
                viewModel.toggleLockSelected()
            }
            headerButton(icon: "plus.square.on.square", tint: .secondary, help: "Duplicate (⌘D)") {
                viewModel.duplicateSelected()
            }
            headerButton(icon: "trash", tint: PlumaTheme.danger, help: "Delete (⌫)") {
                viewModel.deleteSelected()
            }
        }
    }

    private func headerButton(icon: String, tint: Color, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(tint)
                .frame(width: 26, height: 26)
        }
        .buttonStyle(HoverIconButtonStyle(side: 26))
        .help(help)
    }

    private func kindName(_ element: CanvasElement) -> String {
        switch element.payload {
        case .shape: return "Shape"
        case .text: return "Text"
        case .code: return "Code block"
        case .image: return "Image"
        case .icon: return "Icon"
        case .drawing: return "Drawing"
        }
    }

    // MARK: - Icon

    private func iconColorSection(_ icon: IconContent) -> some View {
        InspectorSection("Color", key: "icon.color") {
            HStack(spacing: 8) {
                CanvaColorButton(
                    color: Binding(
                        get: { icon.primaryColor },
                        set: { col in
                            viewModel.updateSelectedElement { elem in
                                if case .icon(var ic) = elem.payload {
                                    ic.primaryColor = col
                                    elem.payload = .icon(ic)
                                }
                            }
                        }
                    ),
                    size: 22
                )
                Text(icon.primaryColor.hexString)
                    .font(PlumaTheme.numeric(11))
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Drawing (pen strokes previously had no stroke controls at all)

    private func drawingSection(_ drawing: DrawingContent) -> some View {
        InspectorSection("Stroke", key: "drawing.stroke") {
            HStack(spacing: 8) {
                CanvaColorButton(
                    color: Binding(
                        get: { drawing.strokeColor },
                        set: { col in updateDrawing { $0.strokeColor = col } }
                    ),
                    size: 22
                )
                Slider(value: Binding(
                    get: { drawing.lineWidth },
                    set: { w in updateDrawing { $0.lineWidth = w } }
                ), in: 1...40)
                .controlSize(.small)
                Text("\(Int(drawing.lineWidth)) pt")
                    .font(PlumaTheme.numeric(11))
                    .frame(width: 36, alignment: .trailing)
            }
            Toggle("Smooth curve", isOn: Binding(
                get: { drawing.isSmooth },
                set: { v in updateDrawing { $0.isSmooth = v } }
            ))
            .font(PlumaTheme.label(12, weight: .regular))
        }
    }

    private func updateDrawing(_ modify: @escaping (inout DrawingContent) -> Void) {
        viewModel.updateSelectedElement { elem in
            if case .drawing(var d) = elem.payload {
                modify(&d)
                elem.payload = .drawing(d)
            }
        }
    }
}
