import SwiftUI

public struct StrokeSection: View {
    @ObservedObject var viewModel: CanvasDocumentViewModel

    public var body: some View {
        if let element = viewModel.primarySelectedElement,
           case .shape(let shape) = element.payload {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("INK BORDER & RULE")
                        .font(.system(size: 10, weight: .bold, design: .serif))
                        .foregroundColor(Color(hex: "#D97706"))
                    Spacer()
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
                }

                if shape.stroke.isEnabled {
                    HStack {
                        Text("Rule Inking")
                            .font(.system(size: 11, design: .serif))
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
                            .font(.system(size: 11, design: .serif))
                            .foregroundColor(Color(hex: "#8C827A"))
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
                            .foregroundColor(Color(hex: "#FAF7F0"))
                            .frame(width: 40)
                    }

                    Picker("Rule Style", selection: Binding(
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
