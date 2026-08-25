import SwiftUI
import AppKit
import UniformTypeIdentifiers

public struct MediaTabView: View {
    @ObservedObject var viewModel: CanvasDocumentViewModel
    @State private var qrText: String = "https://pluma.design"
    @State private var qrDarkColor: Color = .black
    @State private var qrLightColor: Color = .white

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("MEDIA & QR CODES")
                .font(.system(size: 12, weight: .bold, design: .serif))
                .foregroundColor(.primary)
                .tracking(0.5)
                .padding(.horizontal, 14)
                .padding(.top, 12)

            VStack(spacing: 6) {
                Button(action: openImagePicker) {
                    HStack(spacing: 6) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 13))
                        Text("Add Image to Canvas...")
                            .font(.system(size: 11, weight: .semibold, design: .serif))
                    }
                    .padding(.vertical, 7)
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: "#C2410C"))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .hoverHighlight()

                Button(action: openCanvaImport) {
                    HStack(spacing: 5) {
                        Image(systemName: "square.and.arrow.down.on.square")
                            .font(.system(size: 12))
                        Text("Import PPTX / Canva PDF / SVG...")
                            .font(.system(size: 10.5, weight: .medium, design: .serif))
                    }
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
                    .background(Color.secondary.opacity(0.12))
                    .foregroundColor(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.18), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .hoverHighlight()
            }
            .padding(.horizontal, 14)

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    // QR Code Generator Card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "qrcode")
                                .foregroundColor(Color(hex: "#C2410C"))
                            Text("VECTOR QR GENERATOR")
                                .font(.system(size: 10.5, weight: .bold, design: .serif))
                                .foregroundColor(Color(hex: "#C2410C"))
                        }

                        TextField("https://...", text: $qrText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 11, design: .monospaced))
                            .padding(6)
                            .background(Color.secondary.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.secondary.opacity(0.15), lineWidth: 1))

                        HStack {
                            Text("Colors").font(.system(size: 10, design: .serif)).foregroundColor(.secondary)
                            Spacer()
                            ColorPicker("Dark", selection: $qrDarkColor).labelsHidden()
                            ColorPicker("Light", selection: $qrLightColor).labelsHidden()
                        }

                        Button(action: {
                            viewModel.addQRCode(
                                url: qrText.isEmpty ? "https://pluma.design" : qrText,
                                darkColor: CodableColor(color: qrDarkColor),
                                lightColor: CodableColor(color: qrLightColor)
                            )
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                Text("Insert QR Code")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity, minHeight: 24)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        .buttonStyle(.plain)
                .hoverHighlight()
                    }
                    .padding(10)
                    .background(Color.secondary.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.1), lineWidth: 1))

                    // Photo Frames Section
                    Text("PHOTO SHAPE FRAMES")
                        .font(.system(size: 10.5, weight: .bold, design: .serif))
                        .foregroundColor(Color(hex: "#C2410C"))
                        .tracking(0.3)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        frameButton(title: "Circle Frame", frame: .circle, icon: "circle")
                        frameButton(title: "Arch Doorway", frame: .arch, icon: "door.left.hand.closed")
                        frameButton(title: "Heart Frame", frame: .heart, icon: "heart")
                        frameButton(title: "Postage Stamp", frame: .postageStamp, icon: "envelope")
                        frameButton(title: "Star Badge", frame: .star, icon: "star")
                        frameButton(title: "Price Tag", frame: .tag, icon: "tag")
                    }

                    // Stock Textures
                    Text("ENGRAVINGS & TEXTURES")
                        .font(.system(size: 10.5, weight: .bold, design: .serif))
                        .foregroundColor(Color(hex: "#C2410C"))
                        .tracking(0.3)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        stockButton(title: "Press Room", hex: "#292524")
                        stockButton(title: "Cotton Linters", hex: "#EFE8DA")
                        stockButton(title: "Parchment Map", hex: "#D97706")
                        stockButton(title: "Type Case", hex: "#1C1917")
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 20)
            }
        }
    }

    private func frameButton(title: String, frame: ShapeKind, icon: String) -> some View {
        Button(action: {
            let base64 = ImageUtils.generatePlaceholder(width: 600, height: 600, text: title, colorHex: "#3F3F46")
            let elem = CanvasElement(
                name: title,
                payload: .image(ImageContent(imageBase64: base64, cornerRadius: 12, frameKind: frame)),
                x: 100, y: 100, width: 260, height: 260
            )
            viewModel.saveHistoryState()
            viewModel.currentPage.elements.append(elem)
            viewModel.selectedElementIds = [elem.id]
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "#C2410C"))
                Text(title)
                    .font(.system(size: 9.5, weight: .semibold, design: .serif))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(Color.secondary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.12), lineWidth: 1))
        }
        .buttonStyle(.plain)
                .hoverHighlight()
    }

    private func stockButton(title: String, hex: String) -> some View {
        Button(action: {
            let base64 = ImageUtils.generatePlaceholder(width: 800, height: 600, text: title, colorHex: hex)
            let elem = CanvasElement(
                name: title,
                payload: .image(ImageContent(imageBase64: base64, cornerRadius: 4)),
                x: 100, y: 100, width: 360, height: 260
            )
            viewModel.saveHistoryState()
            viewModel.currentPage.elements.append(elem)
            viewModel.selectedElementIds = [elem.id]
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(hex: hex))
                    .frame(height: 70)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(hex: "#3D3833"), lineWidth: 1))

                Text(title)
                    .font(.system(size: 10.5, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                    .shadow(radius: 2)
            }
        }
        .buttonStyle(.plain)
                .hoverHighlight()
    }

    private func openImagePicker() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image, .png, .jpeg, .tiff, .heic, .webP]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url, let nsImage = NSImage(contentsOf: url) {
            viewModel.addImage(from: nsImage)
        }
    }

    private func openCanvaImport() {
        let panel = NSOpenPanel()
        var types: [UTType] = [
            UTType.pdf,
            UTType.svg,
            UTType.image,
            UTType.png,
            UTType.jpeg,
            UTType.zip,
            UTType.json
        ]
        if let pptxType = UTType(filenameExtension: "pptx") { types.append(pptxType) }
        panel.allowedContentTypes = types
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = "Select a PowerPoint (.pptx), Canva PDF, SVG, ZIP, or Image file to import"

        if panel.runModal() == .OK, let url = panel.url {
            if let importedProject = CanvaDocumentImporter.importDocument(from: url) {
                viewModel.project = importedProject
                viewModel.selectedElementIds.removeAll()
                ProjectStorage.shared.saveProject(importedProject)
                viewModel.showTemporaryToast("✨ Imported \(importedProject.name)")
            } else {
                let alert = NSAlert()
                alert.alertStyle = .warning
                alert.messageText = "Import Failed"
                alert.informativeText = "\"\(url.lastPathComponent)\" could not be read.\n\nSupported formats: PowerPoint (.pptx), PDF, SVG, ZIP of images, PNG / JPEG / WebP / HEIC, and Pluma project files (.json)."
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
        }
    }
}
