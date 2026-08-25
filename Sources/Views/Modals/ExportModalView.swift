import SwiftUI
import AppKit

public struct ExportModalView: View {
    @ObservedObject var viewModel: CanvasDocumentViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab: String = "universal" // universal, figma, canva
    @State private var selectedFormat: ExportFormat = .png
    @State private var exportScale: Double = 2.0
    @State private var jpegQuality: Double = 0.9

    // Light "Studio Newsprint" palette — matches the rest of the app
    private let paper = Color(hex: "#FAF7F0")
    private let ink = Color(hex: "#1C1917")
    private let inkSoft = Color(hex: "#57534E")
    private let inkFaint = Color(hex: "#A8A29E")
    private let accent = Color(hex: "#C2410C")
    private let accentSoft = Color(hex: "#FEEEDF")
    private let hairline = Color(hex: "#E7E0D2")

    public var body: some View {
        VStack(spacing: 18) {
            // Header
            HStack {
                Image(systemName: "square.and.arrow.up.fill")
                    .font(.system(size: 18))
                    .foregroundColor(accent)

                Text("PRINT & EXPORT STUDIO")
                    .font(.system(size: 15, weight: .bold, design: .serif))
                    .foregroundColor(ink)
                    .tracking(1.0)

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(inkFaint)
                }
                .buttonStyle(.plain)
            }

            // Export Destination Tabs
            HStack(spacing: 8) {
                destinationTabButton(id: "universal", title: "Universal Formats", icon: "doc.fill")
                destinationTabButton(id: "figma", title: "Figma Vector", icon: "paintpalette.fill")
                destinationTabButton(id: "canva", title: "Canva Ready", icon: "sparkles")
            }

            Divider().background(hairline)

            // Tab Content
            if selectedTab == "universal" {
                universalExportView
            } else if selectedTab == "figma" {
                figmaExportView
            } else if selectedTab == "canva" {
                canvaExportView
            }
        }
        .padding(22)
        .frame(width: 500)
        .background(paper)
    }

    // MARK: - Destination Tab Button

    private func destinationTabButton(id: String, title: String, icon: String) -> some View {
        Button(action: { selectedTab = id }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(title)
                    .font(.system(size: 11.5, weight: selectedTab == id ? .bold : .medium, design: .serif))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(selectedTab == id ? accent : Color(hex: "#F0EADF"))
            )
            .foregroundColor(selectedTab == id ? .white : inkSoft)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 1. Universal Export View

    private var universalExportView: some View {
        VStack(spacing: 16) {
            // Format Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("FILE FORMAT")
                    .font(.system(size: 10.5, weight: .bold, design: .serif))
                    .foregroundColor(accent)

                Picker("Format", selection: $selectedFormat) {
                    ForEach(ExportFormat.allCases) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .pickerStyle(.menu)
            }

            // Resolution
            if selectedFormat == .png || selectedFormat == .jpeg {
                VStack(alignment: .leading, spacing: 8) {
                    Text("PRESS RESOLUTION & SUPERSAMPLING")
                        .font(.system(size: 10.5, weight: .bold, design: .serif))
                        .foregroundColor(accent)

                    Picker("Scale", selection: $exportScale) {
                        Text("1x Standard (\(Int(viewModel.currentPage.width)) × \(Int(viewModel.currentPage.height)) px)").tag(1.0)
                        Text("2x High-DPI (\(Int(viewModel.currentPage.width * 2)) × \(Int(viewModel.currentPage.height * 2)) px)").tag(2.0)
                        Text("3x Fine Art (\(Int(viewModel.currentPage.width * 3)) × \(Int(viewModel.currentPage.height * 3)) px)").tag(3.0)
                        Text("4x Ultra Print (\(Int(viewModel.currentPage.width * 4)) × \(Int(viewModel.currentPage.height * 4)) px)").tag(4.0)
                    }
                    .pickerStyle(.menu)
                }
            }

            // Quality
            if selectedFormat == .jpeg {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("JPEG Quality")
                            .font(.system(size: 11, design: .serif))
                            .foregroundColor(inkSoft)
                        Spacer()
                        Text("\(Int(jpegQuality * 100))%")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(ink)
                    }
                    Slider(value: $jpegQuality, in: 0.5...1.0, step: 0.05)
                }
            }

            // Info
            HStack(spacing: 8) {
                Image(systemName: "bolt.fill")
                    .foregroundColor(Color(hex: "#059669"))
                Text("Vector rasterization rendered at native Apple Silicon Metal speeds")
                    .font(.system(size: 11, design: .serif))
                    .foregroundColor(Color(hex: "#065F46"))
                Spacer()
            }
            .padding(10)
            .background(Color(hex: "#059669").opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(hex: "#059669").opacity(0.25), lineWidth: 0.8))

            Divider().background(hairline)

            // Actions
            HStack(spacing: 12) {
                Button(action: { dismiss() }) {
                    Text("Cancel")
                        .font(.system(size: 12, design: .serif))
                        .foregroundColor(inkSoft)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(hairline, lineWidth: 1)
                        )
                }
                .keyboardShortcut(.cancelAction)
                .buttonStyle(.plain)

                Button(action: { performExport(format: selectedFormat) }) {
                    Text("Save to Disk...")
                        .font(.system(size: 12, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(accent)
                        )
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.defaultAction)
            }

            // Bulk export — all pages as numbered PNGs into a folder
            if viewModel.project.pages.count > 1 {
                Divider()
                Button(action: exportAllPagesAsPNGs) {
                    HStack(spacing: 6) {
                        Image(systemName: "photo.stack")
                            .font(.system(size: 12))
                        Text("Export ALL \(viewModel.project.pages.count) Pages as Numbered PNGs…")
                            .font(.system(size: 11.5, weight: .semibold, design: .serif))
                        Spacer()
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(Color(hex: "#C2410C"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .buttonStyle(HoverPillButtonStyle(cornerRadius: 6, tint: Color(hex: "#C2410C")))
                .help("Choose a folder — every page is saved as a 2× PNG (PageName_01.png …)")
            }
        }
    }

    /// Saves every page of the project as a numbered PNG into a chosen folder.
    private func exportAllPagesAsPNGs() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.message = "Choose a folder for the exported PNG pages"
        panel.prompt = "Export \(viewModel.project.pages.count) Pages"
        guard panel.runModal() == .OK, let folder = panel.url else { return }

        let safeName = viewModel.project.name
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        var saved = 0
        for (idx, page) in viewModel.project.pages.enumerated() {
            guard let data = ExportEngine.exportPNG(page: page, scale: 2.0) else { continue }
            let pageLabel = page.name
                .replacingOccurrences(of: "/", with: "-")
                .replacingOccurrences(of: ":", with: "-")
                .trimmingCharacters(in: .whitespaces)
            let fileName = "\(safeName)_\(pageLabel)_\(String(format: "%02d", idx + 1)).png"
            do {
                try data.write(to: folder.appendingPathComponent(fileName))
                saved += 1
            } catch {
                continue
            }
        }
        dismiss()
        viewModel.showTemporaryToast("✅ Exported \(saved) page\(saved > 1 ? "s" : "") to \(folder.lastPathComponent)")
        NSWorkspace.shared.selectFile(folder.appendingPathComponent(".").path, inFileViewerRootedAtPath: folder.path)
    }

    // MARK: - 2. Figma Export Hub

    private var figmaExportView: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "paintpalette.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: "#7C3AED"))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Export for Figma")
                        .font(.system(size: 13.5, weight: .bold, design: .serif))
                        .foregroundColor(ink)
                    Text("Lossless vector layers, shapes, typography & colors")
                        .font(.system(size: 11, design: .serif))
                        .foregroundColor(inkSoft)
                }
            }
            .padding(10)
            .background(Color(hex: "#7C3AED").opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 8) {
                Text("QUICK WORKFLOW")
                    .font(.system(size: 10.5, weight: .bold, design: .serif))
                    .foregroundColor(accent)

                HStack(spacing: 10) {
                    Button(action: {
                        viewModel.copySVGForFigma()
                        dismiss()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "doc.on.clipboard.fill")
                            Text("Copy SVG for Figma (⌘C)")
                                .font(.system(size: 12, weight: .bold, design: .serif))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(hex: "#7C3AED"))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        performExport(format: .svg)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.down.doc.fill")
                            Text("Save .svg File")
                                .font(.system(size: 12, weight: .bold, design: .serif))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(hex: "#F0EADF"))
                        .foregroundColor(ink)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }

                Text("💡 Tip: After copying, open any Figma file and press ⌘V. All vector layers, groups, and typography will paste automatically into Figma frames.")
                    .font(.system(size: 11, design: .serif))
                    .foregroundColor(inkSoft)
                    .padding(.top, 4)
            }
        }
    }

    // MARK: - 3. Canva Export Hub

    private var canvaExportView: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: "#0891B2"))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Export for Canva")
                        .font(.system(size: 13.5, weight: .bold, design: .serif))
                        .foregroundColor(ink)
                    Text("Multi-page PDF & Presentation formats supported by Canva")
                        .font(.system(size: 11, design: .serif))
                        .foregroundColor(inkSoft)
                }
            }
            .padding(10)
            .background(Color(hex: "#0891B2").opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 8) {
                Text("CHOOSE CANVA FORMAT")
                    .font(.system(size: 10.5, weight: .bold, design: .serif))
                    .foregroundColor(accent)

                // Option 1: Multi-Page PDF (Best for Documents & Resumes)
                Button(action: {
                    performExport(format: .pdf)
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "doc.richtext.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "#0891B2"))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Canva Multi-Page PDF (.pdf)")
                                .font(.system(size: 12, weight: .bold, design: .serif))
                                .foregroundColor(ink)
                            Text("Best for A4 Documents, Resumes, Newsletters & Posters")
                                .font(.system(size: 10.5, design: .serif))
                                .foregroundColor(inkSoft)
                        }
                        Spacer()
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(Color(hex: "#0891B2"))
                    }
                    .padding(10)
                    .background(Color(hex: "#F0EADF"))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)

                // Option 2: PowerPoint (.pptx) (Best for Presentations)
                Button(action: {
                    performExport(format: .pptx)
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "tv.fill")
                            .font(.system(size: 16))
                            .foregroundColor(accent)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Canva Presentation Deck (.pptx)")
                                .font(.system(size: 12, weight: .bold, design: .serif))
                                .foregroundColor(ink)
                            Text("Best for 16:9 Pitch Decks & Slide Presentations")
                                .font(.system(size: 10.5, design: .serif))
                                .foregroundColor(inkSoft)
                        }
                        Spacer()
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(accent)
                    }
                    .padding(10)
                    .background(Color(hex: "#F0EADF"))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)

                // Option 3: SVG Vectors
                Button(action: {
                    performExport(format: .svg)
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "bezierpath")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "#059669"))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Canva Vector Graphic (.svg)")
                                .font(.system(size: 12, weight: .bold, design: .serif))
                                .foregroundColor(ink)
                            Text("Best for Logos, Illustrations & Badges")
                                .font(.system(size: 10.5, design: .serif))
                                .foregroundColor(inkSoft)
                        }
                        Spacer()
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(Color(hex: "#059669"))
                    }
                    .padding(10)
                    .background(Color(hex: "#F0EADF"))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)

                Text("✨ How to use in Canva: Go to canva.com, click 'Upload' at the top right, and select your exported PDF or PPTX. Canva will automatically convert all pages into fully editable Canva designs.")
                    .font(.system(size: 11, design: .serif))
                    .foregroundColor(inkSoft)
                    .padding(.top, 4)
            }
        }
    }

    // MARK: - Save File Helper

    private func performExport(format: ExportFormat) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [format.utType]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        savePanel.title = "Export \(viewModel.project.name)"
        savePanel.nameFieldStringValue = "\(viewModel.project.name).\(format.fileExtension)"

        if savePanel.runModal() == .OK, let url = savePanel.url {
            switch format {
            case .png:
                if let data = ExportEngine.exportPNG(page: viewModel.currentPage, scale: exportScale) {
                    try? data.write(to: url)
                    viewModel.showTemporaryToast("✅ Exported PNG Successfully!")
                }
            case .jpeg:
                if let data = ExportEngine.exportJPEG(page: viewModel.currentPage, scale: exportScale, quality: jpegQuality) {
                    try? data.write(to: url)
                    viewModel.showTemporaryToast("✅ Exported JPEG Successfully!")
                }
            case .pdf:
                if let data = ExportEngine.exportPDF(page: viewModel.currentPage) {
                    try? data.write(to: url)
                    viewModel.showTemporaryToast("✅ Exported Multi-Page PDF Successfully!")
                }
            case .pptx:
                if let data = ExportEngine.exportPPTX(project: viewModel.project) {
                    try? data.write(to: url)
                    viewModel.showTemporaryToast("✅ Exported Presentation (.pptx) Successfully!")
                }
            case .svg:
                let svg = ExportEngine.exportSVG(page: viewModel.currentPage)
                if let data = svg.data(using: .utf8) {
                    try? data.write(to: url)
                    viewModel.showTemporaryToast("✅ Exported SVG Vector Successfully!")
                }
            case .project:
                if let data = try? viewModel.project.encodeToData() {
                    try? data.write(to: url)
                    viewModel.showTemporaryToast("✅ Saved Project File!")
                }
            }
            dismiss()
        }
    }
}
