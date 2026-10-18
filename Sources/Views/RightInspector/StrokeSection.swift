import SwiftUI

public struct StrokeSection: View {
    @ObservedObject var viewModel: CanvasDocumentViewModel

    public var body: some View {
        if let element = viewModel.primarySelectedElement,
           case .shape(let shape) = element.payload {
            InspectorSection("Border", accessory: {
                    Toggle("", isOn: Binding(
                        get: { shape.stroke.isEnabled },
                        set: { val in
                            viewModel.updateSelectedElement { elem in
                                if case .shape(var s) = elem.payload {
                                    s.stroke.isEnabled = val
                                    elem.payload = .shape(s)
                                }
                            }
                        }
                    ))
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .labelsHidden()
            }) {
                if shape.stroke.isEnabled {
                    HStack {
                        Text("Color")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Spacer()
                        CanvaColorButton(
                            color: Binding(
                                get: { shape.stroke.color },
                                set: { newCol in
                                    viewModel.updateSelectedElement { elem in
                                        if case .shape(var s) = elem.payload {
                                            s.stroke.color = newCol
                                            elem.payload = .shape(s)
                                        }
                                    }
                                }
                            ),
                            size: 22
                        )
                    }

                    HStack {
                        Text("Weight")
                            .font(.system(size: 11))
                            .foregroundColor(Color.secondary)
                        Slider(value: Binding(
                            get: { shape.stroke.lineWidth },
                            set: { val in
                                viewModel.updateSelectedElement { elem in
                                    if case .shape(var s) = elem.payload {
                                        s.stroke.lineWidth = val
                                        elem.payload = .shape(s)
                                    }
                                }
                            }
                        ), in: 0.5...20, step: 0.5)
                        Text(String(format: "%.1f pt", shape.stroke.lineWidth))
                            .font(.system(size: 10.5, design: .monospaced))
                            .foregroundColor(Color.primary)
                            .frame(width: 40)
                    }

                    Picker("Style", selection: Binding(
                        get: { shape.stroke.dashPattern },
                        set: { val in
                            viewModel.updateSelectedElement { elem in
                                if case .shape(var s) = elem.payload {
                                    s.stroke.dashPattern = val
                                    elem.payload = .shape(s)
                                }
                            }
                        }
                    )) {
                        ForEach(DashPattern.allCases, id: \.self) { pat in
                            Text(pat.rawValue).tag(pat)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
    }
}
