import SwiftUI
import AppKit

public struct TypographySection: View {
    @ObservedObject var viewModel: CanvasDocumentViewModel
    @State private var showFontPopover: Bool = false

    private let availableFonts: [String] = [
        "Playfair Display", "Georgia", "Didot", "Bodoni 72", "Times New Roman", "Baskerville", "Palatino", "Charter", "Hoefler Text",
        "Inter", "Helvetica Neue", "SF Pro", "Avenir Next", "Futura", "Optima", "Gill Sans", "Trebuchet MS",
        "Impact", "Copperplate", "Phosphate", "SF Mono", "Menlo", "Courier New", "Monaco", "Snell Roundhand", "Zapfino"
    ]

    public var body: some View {
        if let element = viewModel.primarySelectedElement,
           case .text(let text) = element.payload {
            InspectorSection("Typography") {

                // Text Content
                TextField("Text", text: Binding(
                    get: { text.text },
                    set: { newText in
                        viewModel.updateSelectedElement { elem in
                            if case .text(var t) = elem.payload {
                                t.text = newText
                                elem.payload = .text(t)
                            }
                        }
                        viewModel.refitSelectedTextHeights()
                    }
                ), axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(3...6)
                .font(.system(size: 12))
                .foregroundColor(.primary)
                .padding(6)
                .background(Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.secondary.opacity(0.15), lineWidth: 1))

                // Font Family with Visual Font Picker Popover
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Typeface")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                        Spacer()
                        if let currentFont = FontCatalog.allFonts.first(where: { $0.name == text.fontFamily }) {
                            HStack(spacing: 3) {
                                Image(systemName: currentFont.license.badgeIcon)
                                    .font(.system(size: 9))
                                Text(currentFont.license.badgeLabel)
                                    .font(.system(size: 8.5, weight: .bold))
                            }
                            .foregroundColor(currentFont.license == .commercial ? Color(hex: "#10B981") : PlumaTheme.sectionHeader)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(currentFont.license == .commercial ? Color(hex: "#10B981").opacity(0.12) : PlumaTheme.sectionHeader.opacity(0.12))
                            .clipShape(Capsule())
                        }
                    }

                    Button(action: { showFontPopover = true }) {
                        HStack {
                            Text(text.fontFamily)
                                .font(.custom(text.fontFamily, size: 14))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color.secondary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.secondary.opacity(0.15), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showFontPopover, arrowEdge: .trailing) {
                        VisualFontPickerPopover(viewModel: viewModel, selectedFont: text.fontFamily)
                    }
                }

                // Font Size & Weight
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Text("Size")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                        TextField("", value: Binding(
                            get: { text.fontSize },
                            set: { val in
                                viewModel.updateSelectedElement { elem in
                                    if case .text(var t) = elem.payload {
                                        t.fontSize = max(6, val)
                                        elem.payload = .text(t)
                                    }
                                }
                                viewModel.refitSelectedTextHeights()
                            }
                        ), format: .number)
                        .textFieldStyle(.plain)
                        .font(PlumaTheme.numeric(12))
                        .frame(width: 52)
                        .padding(4)
                        .background(Color.secondary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.secondary.opacity(0.15), lineWidth: 1))
                    }

                    Picker("Weight", selection: Binding(
                        get: { text.fontWeight },
                        set: { w in
                            viewModel.updateSelectedElement { elem in
                                if case .text(var t) = elem.payload {
                                    t.fontWeight = w
                                    elem.payload = .text(t)
                                }
                            }
                            // Heavier weights are wider — re-wrap and refit the box.
                            viewModel.refitSelectedTextHeights()
                        }
                    )) {
                        Text("Light").tag(300.0)
                        Text("Regular").tag(400.0)
                        Text("Medium").tag(500.0)
                        Text("Semibold").tag(600.0)
                        Text("Bold").tag(700.0)
                        Text("Black").tag(900.0)
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                    .help("Font weight")
                }

                // Text Color & Gradient
                HStack {
                    Text("Color")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Spacer()
                    // updateSelectedElement coalesces a drag into one undo step.
                    CanvaColorButton(
                        color: Binding(
                            get: { text.textColor },
                            set: { newCol in
                                viewModel.updateSelectedElement { elem in
                                    if case .text(var t) = elem.payload {
                                        t.textColor = newCol
                                        elem.payload = .text(t)
                                    }
                                }
                            }
                        ),
                        size: 22
                    )
                }

                // Text Effect
                VStack(alignment: .leading, spacing: 6) {
                    Picker("Effect", selection: Binding(
                        get: { text.effectKind },
                        set: { eff in
                            viewModel.updateSelectedElement { elem in
                                if case .text(var t) = elem.payload {
                                    t.effectKind = eff
                                    elem.payload = .text(t)
                                }
                            }
                        }
                    )) {
                        ForEach(TextEffectKind.allCases, id: \.self) { eff in
                            Text(eff.rawValue).tag(eff)
                        }
                    }
                    .pickerStyle(.menu)

                    if text.effectKind == .outline {
                        HStack {
                            Text("Outline color").font(.system(size: 10)).foregroundColor(.secondary)
                            Spacer()
                            CanvaColorButton(
                                color: Binding(
                                    get: { text.outlineColor },
                                    set: { col in
                                        viewModel.updateSelectedElement { elem in
                                            if case .text(var t) = elem.payload {
                                                t.outlineColor = col
                                                elem.payload = .text(t)
                                            }
                                        }
                                    }
                                ),
                                size: 20
                            )
                        }
                        HStack {
                            Text("Width").font(.system(size: 10)).foregroundColor(.secondary)
                            Slider(value: Binding(
                                get: { text.outlineWidth },
                                set: { w in
                                    viewModel.updateSelectedElement { elem in
                                        if case .text(var t) = elem.payload {
                                            t.outlineWidth = w
                                            elem.payload = .text(t)
                                        }
                                    }
                                }
                            ), in: 0.5...8, step: 0.5)
                            Text("\(Int(text.outlineWidth))px").font(.system(size: 10, design: .monospaced)).frame(width: 32)
                        }
                    } else if text.effectKind == .neon || text.effectKind == .shadow || text.effectKind == .backgroundPill {
                        HStack {
                            Text("Glow color").font(.system(size: 10)).foregroundColor(.secondary)
                            Spacer()
                            CanvaColorButton(
                                color: Binding(
                                    get: { text.effectColor },
                                    set: { col in
                                        viewModel.updateSelectedElement { elem in
                                            if case .text(var t) = elem.payload {
                                                t.effectColor = col
                                                elem.payload = .text(t)
                                            }
                                        }
                                    }
                                ),
                                size: 20
                            )
                        }
                        HStack {
                            Text("Intensity").font(.system(size: 10)).foregroundColor(.secondary)
                            Slider(value: Binding(
                                get: { text.effectWidth },
                                set: { w in
                                    viewModel.updateSelectedElement { elem in
                                        if case .text(var t) = elem.payload {
                                            t.effectWidth = w
                                            elem.payload = .text(t)
                                        }
                                    }
                                }
                            ), in: 1...15, step: 1)
                            Text("\(Int(text.effectWidth))").font(.system(size: 10, design: .monospaced)).frame(width: 24)
                        }
                    }
                }

                // Alignment Toolbar
                HStack(spacing: 2) {
                    alignFormatButton(icon: "text.alignleft", isSelected: text.alignment == .left) { updateAlign(.left) }
                    alignFormatButton(icon: "text.aligncenter", isSelected: text.alignment == .center) { updateAlign(.center) }
                    alignFormatButton(icon: "text.alignright", isSelected: text.alignment == .right) { updateAlign(.right) }
                    alignFormatButton(icon: "text.justify", isSelected: text.alignment == .justified) { updateAlign(.justified) }

                    Divider().frame(height: 14)

                    alignFormatButton(icon: "italic", isSelected: text.isItalic) {
                        viewModel.updateSelectedElement { elem in
                            if case .text(var t) = elem.payload {
                                t.isItalic.toggle()
                                elem.payload = .text(t)
                            }
                        }
                    }
                    alignFormatButton(icon: "underline", isSelected: text.isUnderlined) {
                        viewModel.updateSelectedElement { elem in
                            if case .text(var t) = elem.payload {
                                t.isUnderlined.toggle()
                                elem.payload = .text(t)
                            }
                        }
                    }
                }
                .padding(3)
                .background(Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.secondary.opacity(0.15), lineWidth: 1))

                // Tracking / Kerning
                HStack {
                    Text("Letter spacing")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Slider(value: Binding(
                        get: { text.letterSpacing },
                        set: { val in
                            viewModel.updateSelectedElement { elem in
                                if case .text(var t) = elem.payload {
                                    t.letterSpacing = val
                                    elem.payload = .text(t)
                                }
                            }
                            viewModel.refitSelectedTextHeights()
                        }
                    ), in: -2...15, step: 0.5)
                    Text(String(format: "%.1f", text.letterSpacing))
                        .font(.system(size: 10.5, design: .monospaced))
                        .frame(width: 28)
                }

                // Line Height / Leading
                HStack {
                    Text("Line height")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Slider(value: Binding(
                        get: { text.lineSpacing },
                        set: { val in
                            viewModel.updateSelectedElement { elem in
                                if case .text(var t) = elem.payload {
                                    t.lineSpacing = val
                                    elem.payload = .text(t)
                                }
                            }
                            viewModel.refitSelectedTextHeights()
                        }
                    ), in: -5...30, step: 1)
                    Text("\(Int(text.lineSpacing))")
                        .font(.system(size: 10.5, design: .monospaced))
                        .frame(width: 24)
                }

                // Curved / Arc Text
                VStack(alignment: .leading, spacing: 6) {
                    Toggle(isOn: Binding(
                        get: { text.isCurved },
                        set: { val in
                            viewModel.updateSelectedElement { elem in
                                if case .text(var t) = elem.payload {
                                    t.isCurved = val
                                    elem.payload = .text(t)
                                }
                            }
                        }
                    )) {
                        HStack(spacing: 4) {
                            Image(systemName: "circle.circle")
                            Text("Curved text")
                                .font(.system(size: 11))
                        }
                    }
                    .toggleStyle(.checkbox)

                    if text.isCurved {
                        HStack {
                            Text("Angle")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            Slider(value: Binding(
                                get: { text.curveAngle },
                                set: { val in
                                    viewModel.updateSelectedElement { elem in
                                        if case .text(var t) = elem.payload {
                                            t.curveAngle = val
                                            elem.payload = .text(t)
                                        }
                                    }
                                }
                            ), in: 30...360, step: 5)
                            Text("\(Int(text.curveAngle))°")
                                .font(.system(size: 10, design: .monospaced))
                                .frame(width: 32)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    private func updateAlign(_ align: TextAlignmentKind) {
        viewModel.updateSelectedElement { elem in
            if case .text(var t) = elem.payload {
                t.alignment = align
                elem.payload = .text(t)
            }
        }
    }

    private func alignFormatButton(icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 10.5, weight: isSelected ? .bold : .regular))
                .frame(maxWidth: .infinity, minHeight: 20)
                .background(isSelected ? PlumaTheme.accent.opacity(0.25) : Color.clear)
                .foregroundColor(isSelected ? PlumaTheme.accent : .secondary)
                .clipShape(RoundedRectangle(cornerRadius: 3))
        }
        .buttonStyle(.plain)
    }
}
