import SwiftUI
import AppKit

public struct CanvaColorPickerView: View {
    @Binding var selectedColor: CodableColor
    var documentColors: [CodableColor] = []
    var onColorChanged: ((CodableColor) -> Void)? = nil

    @State private var hue: Double = 0.0
    @State private var saturation: Double = 1.0
    @State private var brightness: Double = 1.0
    @State private var opacity: Double = 1.0
    @State private var hexInput: String = ""
    @State private var isCopiedHex: Bool = false

    // Curated Canva Color Swatch Categories
    private let defaultNeutrals: [CodableColor] = [
        .white, CodableColor(hex: "#F3F4F6"), CodableColor(hex: "#E5E7EB"),
        CodableColor(hex: "#9CA3AF"), CodableColor(hex: "#4B5563"), CodableColor(hex: "#1F2937"),
        .inkBlack
    ]

    private let vibrantPalette: [CodableColor] = [
        CodableColor(hex: "#EF4444"), // Red
        CodableColor(hex: "#F97316"), // Orange
        CodableColor(hex: "#F59E0B"), // Amber
        CodableColor(hex: "#10B981"), // Emerald
        CodableColor(hex: "#06B6D4"), // Cyan
        CodableColor(hex: "#3B82F6"), // Blue
        CodableColor(hex: "#6366F1"), // Indigo
        CodableColor(hex: "#8B5CF6"), // Purple
        CodableColor(hex: "#EC4899"), // Pink
        CodableColor(hex: "#C2410C")  // Terracotta
    ]

    private let pastelPalette: [CodableColor] = [
        CodableColor(hex: "#FEE2E2"), CodableColor(hex: "#FFEDD5"), CodableColor(hex: "#FEF3C7"),
        CodableColor(hex: "#D1FAE5"), CodableColor(hex: "#CFFAFE"), CodableColor(hex: "#DBEAFE"),
        CodableColor(hex: "#E0E7FF"), CodableColor(hex: "#EDE9FE"), CodableColor(hex: "#FCE7F3")
    ]

    public init(
        selectedColor: Binding<CodableColor>,
        documentColors: [CodableColor] = [],
        onColorChanged: ((CodableColor) -> Void)? = nil
    ) {
        self._selectedColor = selectedColor
        self.documentColors = documentColors
        self.onColorChanged = onColorChanged
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Preview Swatch + Hex Input + Copy
            HStack(spacing: 8) {
                // Color Preview Box with Checkerboard Backdrop
                ZStack {
                    TransparencyCheckerboard()
                        .frame(width: 32, height: 32)
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    RoundedRectangle(cornerRadius: 6)
                        .fill(selectedColor.color)
                        .frame(width: 32, height: 32)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                }

                // Hex Code Text Field
                HStack(spacing: 4) {
                    Text("#")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)

                    TextField("HEX", text: $hexInput)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .frame(width: 65)
                        .onSubmit {
                            applyHexInput()
                        }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.secondary.opacity(0.15), lineWidth: 1))

                Spacer()

                // Copy Hex Button
                Button(action: {
                    let pb = NSPasteboard.general
                    pb.clearContents()
                    pb.setString("#\(hexInput.uppercased())", forType: .string)
                    isCopiedHex = true
                    Task {
                        try? await Task.sleep(nanoseconds: 1_500_000_000)
                        isCopiedHex = false
                    }
                }) {
                    Image(systemName: isCopiedHex ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 10))
                        .foregroundColor(isCopiedHex ? Color(hex: "#10B981") : .secondary)
                        .frame(width: 26, height: 26)
                        .background(Color.secondary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Copy HEX Code")
            }

            // 2D Saturation & Brightness Drag Spectrum Box
            saturationBrightnessPicker
                .frame(height: 110)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2), lineWidth: 1))

            // Hue Spectrum Rainbow Slider
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Hue")
                        .font(.system(size: 10, weight: .medium, design: .serif))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(hue * 360))°")
                        .font(.system(size: 9.5, design: .monospaced))
                        .foregroundColor(.secondary)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hue: 0.0, saturation: 1.0, brightness: 1.0),
                                Color(hue: 0.17, saturation: 1.0, brightness: 1.0),
                                Color(hue: 0.33, saturation: 1.0, brightness: 1.0),
                                Color(hue: 0.5, saturation: 1.0, brightness: 1.0),
                                Color(hue: 0.67, saturation: 1.0, brightness: 1.0),
                                Color(hue: 0.83, saturation: 1.0, brightness: 1.0),
                                Color(hue: 1.0, saturation: 1.0, brightness: 1.0)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(height: 12)
                        .clipShape(Capsule())

                        // Indicator Thumb
                        Circle()
                            .fill(Color.white)
                            .frame(width: 16, height: 16)
                            .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 1)
                            .overlay(Circle().stroke(Color.black.opacity(0.2), lineWidth: 1))
                            .offset(x: max(0, min(geo.size.width - 16, CGFloat(hue) * (geo.size.width - 16))))
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let fraction = max(0, min(1, value.location.x / geo.size.width))
                                hue = fraction
                                updateColorFromHSB()
                            }
                    )
                }
                .frame(height: 16)
            }

            // Opacity Slider
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Opacity")
                        .font(.system(size: 10, weight: .medium, design: .serif))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(opacity * 100))%")
                        .font(.system(size: 9.5, design: .monospaced))
                        .foregroundColor(.secondary)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        TransparencyCheckerboard()
                            .frame(height: 12)
                            .clipShape(Capsule())

                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hue: hue, saturation: saturation, brightness: brightness).opacity(0),
                                Color(hue: hue, saturation: saturation, brightness: brightness).opacity(1)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(height: 12)
                        .clipShape(Capsule())

                        // Indicator Thumb
                        Circle()
                            .fill(Color.white)
                            .frame(width: 16, height: 16)
                            .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 1)
                            .overlay(Circle().stroke(Color.black.opacity(0.2), lineWidth: 1))
                            .offset(x: max(0, min(geo.size.width - 16, CGFloat(opacity) * (geo.size.width - 16))))
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let fraction = max(0, min(1, value.location.x / geo.size.width))
                                opacity = fraction
                                updateColorFromHSB()
                            }
                    )
                }
                .frame(height: 16)
            }

            Divider()

            // Document Used Colors (if available)
            if !documentColors.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Document Colors")
                        .font(.system(size: 10, weight: .bold, design: .serif))
                        .foregroundColor(.secondary)

                    paletteGrid(colors: Array(Set(documentColors)).prefix(14).map { $0 })
                }
            }

            // Default Material & Vibrant Swatches
            VStack(alignment: .leading, spacing: 5) {
                Text("Default Palette")
                    .font(.system(size: 10, weight: .bold, design: .serif))
                    .foregroundColor(.secondary)

                paletteGrid(colors: defaultNeutrals)
                paletteGrid(colors: vibrantPalette)
                paletteGrid(colors: pastelPalette)
            }
        }
        .padding(14)
        .frame(width: 250)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            syncStateFromColor(selectedColor)
        }
        .onChange(of: selectedColor) { oldCol, newCol in
            if hexInput.isEmpty || hexInput.uppercased() != newCol.hexString.replacingOccurrences(of: "#", with: "").uppercased() {
                syncStateFromColor(newCol)
            }
        }
    }

    // MARK: - 2D Saturation / Brightness Spectrum

    private var saturationBrightnessPicker: some View {
        GeometryReader { geo in
            ZStack {
                // Base Hue Color
                Color(hue: hue, saturation: 1.0, brightness: 1.0)

                // Horizontal White Gradient (Saturation)
                LinearGradient(
                    gradient: Gradient(colors: [.white, .clear]),
                    startPoint: .leading,
                    endPoint: .trailing
                )

                // Vertical Black Gradient (Brightness)
                LinearGradient(
                    gradient: Gradient(colors: [.clear, .black]),
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Selection Ring
                Circle()
                    .stroke(Color.white, lineWidth: 2)
                    .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
                    .frame(width: 14, height: 14)
                    .position(
                        x: CGFloat(saturation) * geo.size.width,
                        y: (1.0 - CGFloat(brightness)) * geo.size.height
                    )
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let sat = max(0, min(1, value.location.x / geo.size.width))
                        let br = max(0, min(1, 1.0 - (value.location.y / geo.size.height)))
                        self.saturation = Double(sat)
                        self.brightness = Double(br)
                        updateColorFromHSB()
                    }
            )
        }
    }

    // MARK: - Palette Grid Swatches

    private func paletteGrid(colors: [CodableColor]) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 7), spacing: 5) {
            ForEach(colors, id: \.self) { c in
                Button(action: {
                    selectPresetColor(c)
                }) {
                    ZStack {
                        Circle()
                            .fill(c.color)
                            .frame(width: 22, height: 22)
                            .overlay(
                                Circle()
                                    .stroke(selectedColor == c ? Color(hex: "#C2410C") : Color.secondary.opacity(0.2), lineWidth: selectedColor == c ? 2 : 0.8)
                            )
                            .contentShape(Circle())

                        if selectedColor == c {
                            Image(systemName: "checkmark")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(c.red * 0.299 + c.green * 0.587 + c.blue * 0.114 > 0.6 ? .black : .white)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - State Sync Helpers

    private func selectPresetColor(_ c: CodableColor) {
        selectedColor = c
        syncStateFromColor(c)
        onColorChanged?(c)
    }

    private func applyHexInput() {
        var cleanHex = hexInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanHex.hasPrefix("#") { cleanHex = "#" + cleanHex }
        let newCol = CodableColor(hex: cleanHex, opacity: opacity)
        selectedColor = newCol
        syncStateFromColor(newCol)
        onColorChanged?(newCol)
    }

    private func updateColorFromHSB() {
        let nsColor = NSColor(hue: CGFloat(hue), saturation: CGFloat(saturation), brightness: CGFloat(brightness), alpha: CGFloat(opacity))
        let newCol = CodableColor(
            red: Double(nsColor.redComponent),
            green: Double(nsColor.greenComponent),
            blue: Double(nsColor.blueComponent),
            opacity: opacity
        )
        selectedColor = newCol
        hexInput = newCol.hexString.replacingOccurrences(of: "#", with: "")
        onColorChanged?(newCol)
    }

    private func syncStateFromColor(_ color: CodableColor) {
        let nsColor = color.nsColor.usingColorSpace(.sRGB) ?? color.nsColor
        self.hue = Double(nsColor.hueComponent)
        self.saturation = Double(nsColor.saturationComponent)
        self.brightness = Double(nsColor.brightnessComponent)
        self.opacity = color.opacity
        self.hexInput = color.hexString.replacingOccurrences(of: "#", with: "")
    }
}

// MARK: - Reusable Canva Color Swatch Button with Native Popover

public struct CanvaColorButton: View {
    @Binding var color: CodableColor
    var documentColors: [CodableColor] = []
    var size: CGFloat = 24
    var onColorChanged: ((CodableColor) -> Void)? = nil

    @State private var isShowingPopover: Bool = false
    @State private var isHovered: Bool = false

    public init(
        color: Binding<CodableColor>,
        documentColors: [CodableColor] = [],
        size: CGFloat = 24,
        onColorChanged: ((CodableColor) -> Void)? = nil
    ) {
        self._color = color
        self.documentColors = documentColors
        self.size = size
        self.onColorChanged = onColorChanged
    }

    public var body: some View {
        Button(action: {
            isShowingPopover.toggle()
        }) {
            ZStack {
                // Background shadow / hover
                Circle()
                    .fill(Color.secondary.opacity(isHovered ? 0.2 : 0.08))
                    .frame(width: size + 6, height: size + 6)

                // Swatch Circle
                Circle()
                    .fill(color.color)
                    .frame(width: size, height: size)
                    .overlay(
                        Circle()
                            .stroke(Color.secondary.opacity(0.35), lineWidth: 1)
                    )
            }
            .frame(width: size + 8, height: size + 8)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .popover(isPresented: $isShowingPopover, arrowEdge: .bottom) {
            CanvaColorPickerView(
                selectedColor: $color,
                documentColors: documentColors,
                onColorChanged: onColorChanged
            )
        }
    }
}
