import SwiftUI
import AppKit

public struct PresetPickerModal: View {
    @ObservedObject var viewModel: CanvasDocumentViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var customWidth: Double = 1080
    @State private var customHeight: Double = 1080
    @State private var isLockAspectRatio: Bool = false
    @State private var selectedCategory: PresetCategory = .social
    @State private var hoveredPresetId: String? = nil

    public init(viewModel: CanvasDocumentViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 20) {
            // Modal Header
            HStack(alignment: .top) {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: "#C2410C").opacity(0.12))
                            .frame(width: 36, height: 36)

                        Image(systemName: "aspectratio")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(hex: "#C2410C"))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Page Dimensions & Formats")
                            .font(.system(size: 16, weight: .bold, design: .serif))
                            .foregroundColor(.primary)

                        Text("Current Canvas: \(Int(viewModel.currentPage.width)) × \(Int(viewModel.currentPage.height)) px")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary.opacity(0.7))
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Close (Esc)")
            }

            // Custom Dimensions Input Card
            VStack(alignment: .leading, spacing: 10) {
                Text("CUSTOM DIMENSIONS")
                    .font(.system(size: 10.5, weight: .bold, design: .serif))
                    .foregroundColor(.secondary)
                    .tracking(0.8)

                HStack(spacing: 12) {
                    // Width input
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Width (px)")
                            .font(.system(size: 10, design: .serif))
                            .foregroundColor(.secondary)

                        HStack {
                            TextField("Width", value: $customWidth, format: .number)
                                .textFieldStyle(.plain)
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .frame(width: 70)
                            Text("px")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color.secondary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.15), lineWidth: 1))
                    }

                    // Lock Aspect Ratio & Orientation Buttons
                    HStack(spacing: 4) {
                        Button(action: {
                            isLockAspectRatio.toggle()
                        }) {
                            Image(systemName: isLockAspectRatio ? "lock.fill" : "lock.open")
                                .font(.system(size: 11))
                                .foregroundColor(isLockAspectRatio ? Color(hex: "#C2410C") : .secondary)
                                .frame(width: 26, height: 26)
                                .background(Color.secondary.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .help(isLockAspectRatio ? "Unlock Aspect Ratio" : "Lock Aspect Ratio")

                        Button(action: {
                            // Flip orientation
                            let temp = customWidth
                            customWidth = customHeight
                            customHeight = temp
                        }) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .frame(width: 26, height: 26)
                                .background(Color.secondary.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .help("Swap Width and Height (Flip Orientation)")
                    }
                    .padding(.top, 14)

                    // Height input
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Height (px)")
                            .font(.system(size: 10, design: .serif))
                            .foregroundColor(.secondary)

                        HStack {
                            TextField("Height", value: $customHeight, format: .number)
                                .textFieldStyle(.plain)
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .frame(width: 70)
                            Text("px")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color.secondary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.15), lineWidth: 1))
                    }

                    Spacer()

                    // Apply Button
                    Button(action: {
                        viewModel.saveHistoryState()
                        viewModel.currentPage.width = max(100, customWidth)
                        viewModel.currentPage.height = max(100, customHeight)
                        dismiss()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                            Text("Apply Size")
                                .font(.system(size: 12, weight: .semibold, design: .serif))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color(hex: "#C2410C"))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 14)
                }
            }
            .padding(14)
            .background(Color.secondary.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.12), lineWidth: 1))

            // Elegant Custom Category Pill Bar (Replaces ugly blue Segmented Picker)
            HStack(spacing: 8) {
                categoryTabPill(category: .social, title: "Social Media", icon: "camera.fill")
                categoryTabPill(category: .presentation, title: "Screens & Slides", icon: "tv.fill")
                categoryTabPill(category: .print, title: "Print & Documents", icon: "doc.text.fill")
                categoryTabPill(category: .marketing, title: "Design & Marketing", icon: "paintpalette.fill")
            }

            // Preset Cards Grid with True Aspect-Ratio Previews
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(CanvasPreset.presets.filter { $0.category == selectedCategory }) { preset in
                        presetGridCard(preset)
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(maxHeight: 280)
        }
        .padding(24)
        .frame(width: 580)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            self.customWidth = viewModel.currentPage.width
            self.customHeight = viewModel.currentPage.height
        }
    }

    // MARK: - Category Pill Button

    private func categoryTabPill(category: PresetCategory, title: String, icon: String) -> some View {
        let isSelected = selectedCategory == category

        return Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedCategory = category
            }
        }) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .bold : .medium, design: .serif))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color(hex: "#C2410C").opacity(0.15) : Color.secondary.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Color(hex: "#C2410C").opacity(0.5) : Color.clear, lineWidth: 1)
            )
            .foregroundColor(isSelected ? Color(hex: "#C2410C") : .secondary)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Preset Grid Card with Visual Aspect-Ratio Page Thumbnail

    private func presetGridCard(_ preset: CanvasPreset) -> some View {
        let isHovered = hoveredPresetId == preset.id

        return Button(action: {
            viewModel.applyPreset(preset)
            dismiss()
        }) {
            HStack(spacing: 12) {
                // True Aspect Ratio Mini Page Thumbnail
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.secondary.opacity(0.1))
                        .frame(width: 44, height: 44)

                    // Scaled Aspect Ratio Page
                    let (thumbW, thumbH) = computeThumbnailDimensions(width: preset.width, height: preset.height, maxSide: 30)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white)
                        .frame(width: thumbW, height: thumbH)
                        .shadow(color: .black.opacity(0.18), radius: 2, x: 0, y: 1)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(Color.secondary.opacity(0.25), lineWidth: 0.8)
                        )
                }

                // Preset Name & Details
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(preset.name)
                            .font(.system(size: 12, weight: .bold, design: .serif))
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        Spacer()

                        Text(preset.aspectRatioFormatted)
                            .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                            .foregroundColor(Color(hex: "#C2410C"))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(Color(hex: "#C2410C").opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }

                    Text("\(Int(preset.width)) × \(Int(preset.height)) px")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? Color.secondary.opacity(0.1) : Color.secondary.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isHovered ? Color(hex: "#C2410C").opacity(0.4) : Color.secondary.opacity(0.12), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                hoveredPresetId = hovering ? preset.id : nil
            }
        }
    }

    private func computeThumbnailDimensions(width: Double, height: Double, maxSide: CGFloat) -> (CGFloat, CGFloat) {
        let aspect = width / height
        if aspect >= 1.0 {
            let w = maxSide
            let h = max(10, maxSide / CGFloat(aspect))
            return (w, h)
        } else {
            let h = maxSide
            let w = max(10, maxSide * CGFloat(aspect))
            return (w, h)
        }
    }
}
