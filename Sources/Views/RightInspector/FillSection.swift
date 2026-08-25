import SwiftUI

public struct FillSection: View {
    @ObservedObject var viewModel: CanvasDocumentViewModel

    private let swatches: [CodableColor] = [
        .newsprint, .parchment, .kraftPaper, .inkBlack,
        CodableColor(hex: "#C2410C"), CodableColor(hex: "#2D4A3E"), CodableColor(hex: "#881337"),
        CodableColor(hex: "#B45309"), CodableColor.washiSage, CodableColor.washiTerracotta, .white
    ]

    public var body: some View {
        if let element = viewModel.primarySelectedElement,
           case .shape(let shape) = element.payload {
            VStack(alignment: .leading, spacing: 10) {
                Text("FILL & TEXTURE")
                    .font(.system(size: 10, weight: .bold, design: .serif))
                    .foregroundColor(Color(hex: "#D97706"))

                Picker("Texture Stock", selection: Binding(
                    get: { shape.fill.type },
                    set: { newType in
                        viewModel.updateSelectedElement { elem in
                            if case .shape(var s) = elem.payload {
                                s.fill.type = newType
                                elem.payload = .shape(s)
                            }
                        }
                    }
                )) {
                    ForEach(FillType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.menu)

                // Color Picker (Custom Canva Popover)
                HStack {
                    Text("Base Tint")
                        .font(.system(size: 11, design: .serif))
                        .foregroundColor(.secondary)
                    Spacer()
                    CanvaColorButton(
                        color: Binding(
                            get: { shape.fill.solidColor },
                            set: { newCol in
                                viewModel.updateSelectedElement { elem in
                                    if case .shape(var s) = elem.payload {
                                        s.fill.solidColor = newCol
                                        elem.payload = .shape(s)
                                    }
                                }
                            }
                        ),
                        size: 22
                    )
                    Text(shape.fill.solidColor.hexString)
                        .font(.system(size: 10.5, design: .monospaced))
                        .foregroundColor(.secondary)
                }

                // Swatches
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 5) {
                        ForEach(swatches, id: \.self) { swatch in
                            Button(action: {
                                viewModel.updateSelectedElement { elem in
                                    if case .shape(var s) = elem.payload {
                                        s.fill.solidColor = swatch
                                        elem.payload = .shape(s)
                                    }
                                }
                            }) {
                                Circle()
                                    .fill(swatch.color)
                                    .frame(width: 18, height: 18)
                                    .overlay(Circle().stroke(Color(hex: "#3D3833"), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Corner Radius
                if shape.kind == .roundedRectangle || shape.kind == .rectangle {
                    HStack {
                        Text("Corner Deckle")
                            .font(.system(size: 11, design: .serif))
                            .foregroundColor(Color(hex: "#8C827A"))
                        Slider(value: Binding(
                            get: { shape.cornerRadius },
                            set: { val in
                                viewModel.updateSelectedElement { elem in
                                    if case .shape(var s) = elem.payload {
                                        s.cornerRadius = val
                                        elem.payload = .shape(s)
                                    }
                                }
                            }
                        ), in: 0...60, step: 1)
                        Text("\(Int(shape.cornerRadius))")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(Color(hex: "#FAF7F0"))
                            .frame(width: 24)
                    }
                }
            }
        }
    }
}
