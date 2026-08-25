import SwiftUI

public struct ImageFiltersSection: View {
    @ObservedObject var viewModel: CanvasDocumentViewModel

    public var body: some View {
        if let element = viewModel.primarySelectedElement,
           case .image(let imageContent) = element.payload {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Image Adjustments")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Reset") {
                        viewModel.updateSelectedElement { elem in
                            if case .image(var img) = elem.payload {
                                img.filter = .default
                                elem.payload = .image(img)
                            }
                        }
                    }
                    .font(.system(size: 10))
                }

                // 1-Click Smart Tools
                VStack(spacing: 8) {
                    Button(action: {
                        viewModel.removeBackgroundFromSelectedImage()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .foregroundColor(Color(hex: "#D97706"))
                            Text("Remove Background (Apple Vision)")
                                .font(.system(size: 11, weight: .bold, design: .serif))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(Color(hex: "#C2410C").opacity(0.12))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(hex: "#C2410C").opacity(0.3), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        if let img = ImageUtils.nsImage(from: imageContent.imageBase64) {
                            let palette = ColorPaletteGenerator.shared.extractPalette(from: img)
                            viewModel.showTemporaryToast("Extracted \(palette.count) colors from image!")
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "paintpalette.fill")
                                .foregroundColor(Color(hex: "#C2410C"))
                            Text("Extract Color Palette")
                                .font(.system(size: 11, weight: .medium, design: .serif))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.secondary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 4)

                // Brightness
                filterSlider(label: "Brightness", value: Binding(
                    get: { imageContent.filter.brightness },
                    set: { val in
                        viewModel.updateSelectedElement { elem in
                            if case .image(var img) = elem.payload {
                                img.filter.brightness = val
                                elem.payload = .image(img)
                            }
                        }
                    }
                ), range: -0.8...0.8)

                // Contrast
                filterSlider(label: "Contrast", value: Binding(
                    get: { imageContent.filter.contrast },
                    set: { val in
                        viewModel.updateSelectedElement { elem in
                            if case .image(var img) = elem.payload {
                                img.filter.contrast = val
                                elem.payload = .image(img)
                            }
                        }
                    }
                ), range: 0.2...2.0)

                // Saturation
                filterSlider(label: "Saturation", value: Binding(
                    get: { imageContent.filter.saturation },
                    set: { val in
                        viewModel.updateSelectedElement { elem in
                            if case .image(var img) = elem.payload {
                                img.filter.saturation = val
                                elem.payload = .image(img)
                            }
                        }
                    }
                ), range: 0.0...2.0)

                // Blur
                filterSlider(label: "Blur", value: Binding(
                    get: { imageContent.filter.blur },
                    set: { val in
                        viewModel.updateSelectedElement { elem in
                            if case .image(var img) = elem.payload {
                                img.filter.blur = val
                                elem.payload = .image(img)
                            }
                        }
                    }
                ), range: 0.0...20.0)

                // Sepia
                filterSlider(label: "Sepia", value: Binding(
                    get: { imageContent.filter.sepia },
                    set: { val in
                        viewModel.updateSelectedElement { elem in
                            if case .image(var img) = elem.payload {
                                img.filter.sepia = val
                                elem.payload = .image(img)
                            }
                        }
                    }
                ), range: 0.0...1.0)
            }
        }
    }

    private func filterSlider(label: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .frame(width: 65, alignment: .leading)
            Slider(value: value, in: range)
            Text(String(format: "%.1f", value.wrappedValue))
                .font(.system(size: 11, design: .monospaced))
                .frame(width: 28)
        }
    }
}
