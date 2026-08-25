import SwiftUI

public struct InspectorView: View {
    @ObservedObject var viewModel: CanvasDocumentViewModel

    public var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if let element = viewModel.primarySelectedElement {
                        // Element Header (Name & Delete)
                        HStack {
                            Text(element.name.uppercased())
                                .font(.system(size: 11, weight: .bold, design: .serif))
                                .foregroundColor(.primary)
                                .lineLimit(1)

                            Spacer()

                            Button(action: {
                                viewModel.toggleLockSelected()
                            }) {
                                Image(systemName: element.isLocked ? "lock.fill" : "lock.open")
                                    .font(.system(size: 11))
                                    .foregroundColor(element.isLocked ? Color(hex: "#D97706") : .secondary)
                            }
                            .buttonStyle(.plain)
                            .help(element.isLocked ? "Unlock Element" : "Lock Element")

                            Button(action: {
                                viewModel.deleteSelected()
                            }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(hex: "#EF4444"))
                            }
                            .buttonStyle(.plain)
                            .help("Delete Element")
                        }

                        Divider()

                        // Transform & Geometry (X, Y, W, H, Rotation, Align)
                        TransformSection(viewModel: viewModel)

                        Divider()

                        // Contextual Sections based on payload type
                        switch element.payload {
                        case .shape:
                            FillSection(viewModel: viewModel)
                            Divider()
                            StrokeSection(viewModel: viewModel)
                            Divider()
                            EffectsSection(viewModel: viewModel)

                        case .text:
                            TypographySection(viewModel: viewModel)
                            Divider()
                            EffectsSection(viewModel: viewModel)

                        case .code:
                            CodeSection(viewModel: viewModel)
                            Divider()
                            EffectsSection(viewModel: viewModel)

                        case .image:
                            ImageFiltersSection(viewModel: viewModel)
                            Divider()
                            EffectsSection(viewModel: viewModel)

                        case .icon(let icon):
                            VStack(alignment: .leading, spacing: 8) {
                                Text("EMBLEM COLOR")
                                    .font(.system(size: 10, weight: .bold, design: .serif))
                                    .foregroundColor(Color(hex: "#D97706"))

                                ColorPicker("Primary Color", selection: Binding(
                                    get: { icon.primaryColor.color },
                                    set: { col in
                                        viewModel.updateSelectedElement { elem in
                                            if case .icon(var ic) = elem.payload {
                                                ic.primaryColor = CodableColor(color: col)
                                                elem.payload = .icon(ic)
                                            }
                                        }
                                    }
                                ))
                            }
                            Divider()
                            EffectsSection(viewModel: viewModel)

                        case .drawing:
                            EffectsSection(viewModel: viewModel)
                        }
                    } else {
                        // Nothing selected: Show Sheet & Page Settings
                        PageSettingsSection(viewModel: viewModel)
                    }
                }
                .padding(14)
            }
        }
        .frame(width: 270)
        .background(Color(NSColor.windowBackgroundColor))
    }
}
