import SwiftUI
import AppKit
import UniformTypeIdentifiers

public struct CanvasToolbarView: View {
    @ObservedObject var viewModel: CanvasDocumentViewModel
    var onReturnHome: (() -> Void)?

    public init(viewModel: CanvasDocumentViewModel, onReturnHome: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onReturnHome = onReturnHome
    }

    public var body: some View {
        HStack(spacing: 10) {
            // Home / Projects Back Button
            if let onReturnHome = onReturnHome {
                Button(action: onReturnHome) {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .semibold))
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 12))
                        Text("Projects")
                            .font(.system(size: 12, weight: .medium, design: .serif))
                    }
                }
                .buttonStyle(HoverPillButtonStyle(tint: .secondary))
                .help("Return to Projects Dashboard")
            }

            // Left Sidebar Toggle
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.isLeftSidebarVisible.toggle()
                }
            }) {
                Image(systemName: "sidebar.left")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(viewModel.isLeftSidebarVisible ? Color(hex: "#C2410C") : .secondary)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(HoverIconButtonStyle(side: 28, isSelected: viewModel.isLeftSidebarVisible))
            .help("Toggle Left Sidebar (⌘1)")

            Divider().frame(height: 18)

            // Project Title
            HStack(spacing: 6) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#D97706"))

                TextField("Untitled Project", text: $viewModel.project.name)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: .bold, design: .serif))
                    .frame(maxWidth: 160)
            }

            // Dimensions / Sheet Presets
            Button(action: {
                viewModel.showPresetPickerModal = true
            }) {
                HStack(spacing: 5) {
                    Text("\(Int(viewModel.currentPage.width)) × \(Int(viewModel.currentPage.height))")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
            }
            .buttonStyle(HoverPillButtonStyle(tint: .secondary))
            .help("Change Canvas Dimensions (⌘K)")

            // Undo / Redo
            HStack(spacing: 2) {
                Button(action: { viewModel.undo() }) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(viewModel.historyManager.canUndo ? .primary : .secondary.opacity(0.4))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(HoverIconButtonStyle(side: 28))
                .disabled(!viewModel.historyManager.canUndo)
                .help("Undo (⌘Z)")

                Button(action: { viewModel.redo() }) {
                    Image(systemName: "arrow.uturn.forward")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(viewModel.historyManager.canRedo ? .primary : .secondary.opacity(0.4))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(HoverIconButtonStyle(side: 28))
                .disabled(!viewModel.historyManager.canRedo)
                .help("Redo (⇧⌘Z)")
            }

            Spacer()

            // Center Quick Tools
            HStack(spacing: 2) {
                toolButton(tool: .select, icon: "cursorarrow.rays", label: "Select (V)")
                toolButton(tool: .hand, icon: "hand.raised.fill", label: "Hand Pan Tool (H / Space)")
                toolButton(tool: .text, icon: "textformat", label: "Type (T)", action: {
                    viewModel.addText()
                })
                toolButton(tool: .shape(.roundedRectangle), icon: "chevron.left.forwardslash.chevron.right", label: "Code Block (C)", action: {
                    viewModel.addCodeBlock()
                })
                toolButton(tool: .shape(.washiTape), icon: "seal.fill", label: "Stamp & Tape (R)", action: {
                    viewModel.addShape(.washiTape)
                })
                toolButton(tool: .draw, icon: "pencil.tip", label: "Pen (P)", action: {
                    viewModel.activeTool = (viewModel.activeTool == .draw) ? .select : .draw
                })
            }
            .padding(3)
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 7))

            Divider().frame(height: 18)

            // Canvas Layout Mode Menu (Doc Flow, Single Slide, Infinite Whiteboard)
            Menu {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.pageLayoutMode = .infiniteWhiteboard
                    }
                    viewModel.showTemporaryToast("🧠 Infinite Whiteboard (Figma Style)")
                }) {
                    Label("Infinite Whiteboard (Figma Style)", systemImage: "brain.head.profile")
                }

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.pageLayoutMode = .continuousVertical
                    }
                    viewModel.showTemporaryToast("📄 Continuous Document Flow")
                }) {
                    Label("Continuous Document Flow (A4 / Docs)", systemImage: "scroll.fill")
                }

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.pageLayoutMode = .singleSlide
                    }
                    viewModel.showTemporaryToast("📺 Single Slide / Artboard")
                }) {
                    Label("Single Slide / Artboard", systemImage: "rectangle.split.1x2.fill")
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: viewModel.pageLayoutMode == .infiniteWhiteboard ? "brain.head.profile" : (viewModel.pageLayoutMode == .continuousVertical ? "scroll.fill" : "rectangle.split.1x2.fill"))
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "#C2410C"))
                    Text(viewModel.pageLayoutMode == .infiniteWhiteboard ? "Whiteboard" : (viewModel.pageLayoutMode == .continuousVertical ? "Doc Flow" : "Single Slide"))
                        .font(.system(size: 11, weight: .semibold, design: .serif))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            .menuStyle(.borderlessButton)
            .help("Switch Canvas Mode: Infinite Whiteboard vs Document Flow vs Single Slide")

            Divider().frame(height: 18)

            // Zoom Controls
            HStack(spacing: 4) {
                Button(action: { viewModel.zoomOut() }) {
                    Image(systemName: "minus")
                        .font(.system(size: 11, weight: .medium))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(HoverIconButtonStyle(side: 24, cornerRadius: 6))
                .help("Zoom Out")

                Text("\(Int(viewModel.zoomScale * 100))%")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .frame(width: 42)

                Button(action: { viewModel.zoomIn() }) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .medium))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(HoverIconButtonStyle(side: 24, cornerRadius: 6))
                .help("Zoom In")

                Button(action: { viewModel.zoomTo100() }) {
                    Text("100%")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 4)
                }
                .buttonStyle(HoverPillButtonStyle(cornerRadius: 5, tint: .secondary))
                .help("Reset Zoom to 100%")
            }

            Spacer()

            // Quick Copy SVG for Figma (Option+Cmd+C)
            Button(action: {
                viewModel.copySVGForFigma()
            }) {
                HStack(spacing: 3) {
                    Image(systemName: "paintpalette.fill")
                        .font(.system(size: 9))
                    Text("Figma")
                        .font(.system(size: 10, weight: .bold, design: .serif))
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 5)
                .foregroundColor(Color(hex: "#7C3AED"))
            }
            .buttonStyle(HoverPillButtonStyle(tint: Color(hex: "#7C3AED")))
            .help("Copy SVG Layers for Figma (⌥⌘C) - Paste directly with ⌘V into Figma")

            // Quick Copy HD Image (Cmd+Shift+C)
            Button(action: {
                viewModel.copyPageImageToClipboard()
            }) {
                Image(systemName: "doc.on.clipboard")
                    .font(.system(size: 12, weight: .medium))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(HoverIconButtonStyle(side: 28))
            .help("Copy HD Image to Clipboard (⇧⌘C)")

            // AI Bridge Indicator (MCP) — click to copy the MCP client config
            Button(action: {
                let scriptPath = Bundle.main.resourcePath.map { $0 + "/pluma_mcp_server.py" } ?? "~/project/canvas/scripts/pluma_mcp_server.py"
                let config = "{\"mcpServers\":{\"pluma\":{\"command\":\"python3\",\"args\":[\"\(scriptPath)\"]}}}"
                let pb = NSPasteboard.general
                pb.clearContents()
                pb.setString(config, forType: .string)
                viewModel.showTemporaryToast("🤖 MCP config copied — paste into Claude Desktop / Cursor settings")
            }) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(PlumaBridgeServer.shared.isRunning ? Color(hex: "#10B981") : Color.secondary.opacity(0.4))
                        .frame(width: 6, height: 6)
                    Image(systemName: "sparkles")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color(hex: "#7C3AED"))
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 5)
            }
            .buttonStyle(HoverPillButtonStyle(cornerRadius: 6, tint: Color(hex: "#7C3AED")))
            .help("AI Bridge active on 127.0.0.1:\(PlumaBridgeServer.shared.port) — click to copy MCP setup config for Claude Desktop / Cursor")

            // Import Button (PowerPoint / Canva / PDF / SVG)
            Button(action: {
                openImportPanel()
            }) {
                HStack(spacing: 5) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Import")
                        .font(.system(size: 11, weight: .bold, design: .serif))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Color(hex: "#C2410C").opacity(0.1))
                .foregroundColor(Color(hex: "#C2410C"))
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color(hex: "#C2410C").opacity(0.45), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .help("Import PowerPoint (.pptx), Canva PDF, SVG, ZIP, or Image")

            // Export Button
            Button(action: {
                viewModel.showExportModal = true
            }) {
                HStack(spacing: 5) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Export")
                        .font(.system(size: 11, weight: .bold, design: .serif))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .foregroundColor(.white)
            }
            .buttonStyle(HoverPillButtonStyle(filled: true))
            .help("Export PNG, JPEG, PDF, SVG, PPTX (⌘E)")

            Divider().frame(height: 18)

            // Right Inspector Toggle
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.isRightInspectorVisible.toggle()
                }
            }) {
                Image(systemName: "sidebar.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(viewModel.isRightInspectorVisible ? Color(hex: "#C2410C") : .secondary)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(HoverIconButtonStyle(side: 28, isSelected: viewModel.isRightInspectorVisible))
            .help("Toggle Right Inspector (⌘2)")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Color(NSColor.windowBackgroundColor))
        .overlay(Divider(), alignment: .bottom)
    }

    private func toolButton(tool: CanvasTool, icon: String, label: String, action: (() -> Void)? = nil) -> some View {
        let isSelected = (viewModel.activeTool == tool)

        return Button(action: {
            if let action = action {
                action()
            } else {
                viewModel.activeTool = tool
            }
        }) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 5.5)
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(ToolToggleButtonStyle(isSelected: isSelected))
        .help(label)
    }

    private func openImportPanel() {
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
                importFailureAlert(file: url.lastPathComponent)
            }
        }
    }

    /// Visible failure feedback — never leave the user wondering whether the import worked.
    private func importFailureAlert(file: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Import Failed"
        alert.informativeText = "\"\(file)\" could not be read.\n\nSupported formats: PowerPoint (.pptx), PDF, SVG, ZIP of images, PNG / JPEG / WebP / HEIC, and Pluma project files (.json)."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
