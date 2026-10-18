import SwiftUI

public struct TransformSection: View {
    @ObservedObject var viewModel: CanvasDocumentViewModel

    private var isMulti: Bool { viewModel.selectedElementIds.count > 1 }

    public var body: some View {
        if let element = viewModel.primarySelectedElement {
            // Multi-selection edits the collective bounds (X/Y move everything by
            // the same delta) — typing X used to stack every element on one spot.
            let bounds = isMulti ? viewModel.selectionBounds : CGRect(x: element.x, y: element.y, width: element.width, height: element.height)

            InspectorSection(isMulti ? "Align" : "Position", key: "position") {

                HStack(spacing: 2) {
                    alignButton(icon: "align.horizontal.left", help: "Align left") { viewModel.alignSelected(.left) }
                    alignButton(icon: "align.horizontal.center", help: "Align horizontal centers") { viewModel.alignSelected(.centerHorizontal) }
                    alignButton(icon: "align.horizontal.right", help: "Align right") { viewModel.alignSelected(.right) }
                    Rectangle().fill(PlumaTheme.hairline).frame(width: 1, height: 14)
                    alignButton(icon: "align.vertical.top", help: "Align top") { viewModel.alignSelected(.top) }
                    alignButton(icon: "align.vertical.center", help: "Align vertical centers") { viewModel.alignSelected(.centerVertical) }
                    alignButton(icon: "align.vertical.bottom", help: "Align bottom") { viewModel.alignSelected(.bottom) }
                }
                .padding(2)
                .background(RoundedRectangle(cornerRadius: 7).fill(PlumaTheme.control))

                Grid(horizontalSpacing: 6, verticalSpacing: 6) {
                    GridRow {
                        numberInput(label: "X", value: Binding(
                            get: { bounds.minX },
                            set: { val in moveSelection(dx: val - bounds.minX, dy: 0) }
                        ))
                        numberInput(label: "Y", value: Binding(
                            get: { bounds.minY },
                            set: { val in moveSelection(dx: 0, dy: val - bounds.minY) }
                        ))
                    }
                    if !isMulti {
                        GridRow {
                            numberInput(label: "W", value: Binding(
                                get: { element.width },
                                set: { val in
                                    viewModel.updateSelectedElement { $0.width = max(5, val) }
                                    // Canva parity: width edits reflow text, height follows.
                                    viewModel.refitSelectedTextHeights()
                                    viewModel.syncConnectors(touching: viewModel.selectedElementIds)
                                }
                            ))
                            numberInput(label: "H", value: Binding(
                                get: { element.height },
                                set: { val in
                                    viewModel.updateSelectedElement { $0.height = max(5, val) }
                                    viewModel.syncConnectors(touching: viewModel.selectedElementIds)
                                }
                            ))
                        }
                    }
                }

                if !isMulti {
                    HStack(spacing: 8) {
                        Image(systemName: "rotate.right")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .help("Rotation")
                        Slider(value: Binding(
                            get: { element.rotation },
                            set: { val in viewModel.updateSelectedElement { $0.rotation = val } }
                        ), in: 0...360, step: 1)
                        .controlSize(.small)
                        Text("\(Int(element.rotation))°")
                            .font(PlumaTheme.numeric(11))
                            .frame(width: 34, alignment: .trailing)
                    }
                }

                HStack(spacing: 6) {
                    flipButton(title: "Flip H", icon: "arrow.left.and.right", isOn: !isMulti && element.isFlippedH) {
                        viewModel.flipSelected(horizontal: true)
                    }
                    flipButton(title: "Flip V", icon: "arrow.up.and.down", isOn: !isMulti && element.isFlippedV) {
                        viewModel.flipSelected(horizontal: false)
                    }
                }
            }
        }
    }

    private func moveSelection(dx: Double, dy: Double) {
        guard dx != 0 || dy != 0 else { return }
        viewModel.updateSelectedElement { el in
            el.x += dx
            el.y += dy
        }
        viewModel.syncConnectors(touching: viewModel.selectedElementIds)
    }

    private func flipButton(title: String, icon: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 10, weight: .medium))
                Text(title).font(PlumaTheme.label(11))
            }
            .foregroundColor(isOn ? PlumaTheme.accentOnSoft : .primary)
            .frame(maxWidth: .infinity, minHeight: 26)
            .background(RoundedRectangle(cornerRadius: 6).fill(isOn ? PlumaTheme.accentSoft : PlumaTheme.control))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .hoverHighlight(cornerRadius: 6, opacity: 0.06)
    }

    private func alignButton(icon: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, minHeight: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .hoverHighlight(cornerRadius: 5)
        .help(help)
    }

    private func numberInput(label: String, value: Binding<Double>) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(PlumaTheme.label(10, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(width: 12)

            TextField("", value: value, format: .number.precision(.fractionLength(0...1)).grouping(.never))
                .textFieldStyle(.plain)
                .font(PlumaTheme.numeric(12))
                .padding(.horizontal, 6)
                .frame(height: 24)
                .background(RoundedRectangle(cornerRadius: 5).fill(PlumaTheme.field))
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(PlumaTheme.hairline, lineWidth: 1))
        }
    }
}
