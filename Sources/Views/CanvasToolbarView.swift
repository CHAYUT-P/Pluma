import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// Editor title bar: navigation + document identity on the left, creation tools
/// in the middle, view & output actions on the right.
public struct CanvasToolbarView: View {
    @ObservedObject var viewModel: CanvasDocumentViewModel
    var onReturnHome: (() -> Void)?
    @State private var showPenSettings = false

    public init(viewModel: CanvasDocumentViewModel, onReturnHome: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onReturnHome = onReturnHome
    }

    public var body: some View {
        HStack(spacing: 8) {
            leadingCluster
                .layoutPriority(1)

            Spacer(minLength: 8)

            toolsCluster

            Spacer(minLength: 8)

            trailingCluster
                .layoutPriority(1)
        }
        .padding(.horizontal, 12)
        .frame(height: 46)
        .background(PlumaTheme.chrome)
        .overlay(alignment: .bottom) {
            Rectangle().fill(PlumaTheme.hairline).frame(height: 1)
        }
    }

    // MARK: - Leading: home, panels, title, size, history

    private var leadingCluster: some View {
        HStack(spacing: 6) {
            if let onReturnHome = onReturnHome {
                Button(action: onReturnHome) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Home")
                            .font(PlumaTheme.label(12))
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 8)
                    .frame(height: 28)
                }
                .buttonStyle(HoverIconButtonStyle(side: 28))
                .help("Back to Projects (⇧⌘H)")
            }

            panelToggle(
                icon: "sidebar.left",
                isOn: viewModel.isLeftSidebarVisible,
                help: "Toggle Left Panel (⌘1)"
            ) { viewModel.isLeftSidebarVisible.toggle() }

            divider

            TextField("Untitled Design", text: $viewModel.project.name)
                .textFieldStyle(.plain)
                .font(PlumaTheme.title(14))
                .lineLimit(1)
                .frame(minWidth: 80, idealWidth: 220, maxWidth: 280)
                .fixedSize(horizontal: false, vertical: true)
                .help("Rename design")

            Button(action: { viewModel.showPresetPickerModal = true }) {
                HStack(spacing: 4) {
                    Text("\(Int(viewModel.currentPage.width)) × \(Int(viewModel.currentPage.height))")
                        .font(PlumaTheme.numeric(11))
                        .lineLimit(1)
                        .fixedSize()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8, weight: .semibold))
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .frame(height: 24)
                .background(Capsule().fill(PlumaTheme.control))
            }
            .buttonStyle(.plain)
            .hoverHighlight(cornerRadius: 12)
            .help("Resize page")

            divider

            HStack(spacing: 0) {
                Button(action: { viewModel.undo() }) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 12, weight: .medium))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(HoverIconButtonStyle(side: 28))
                .disabled(!viewModel.historyManager.canUndo)
                .opacity(viewModel.historyManager.canUndo ? 1 : 0.35)
                .help("Undo (⌘Z)")

                Button(action: { viewModel.redo() }) {
                    Image(systemName: "arrow.uturn.forward")
                        .font(.system(size: 12, weight: .medium))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(HoverIconButtonStyle(side: 28))
                .disabled(!viewModel.historyManager.canRedo)
                .opacity(viewModel.historyManager.canRedo ? 1 : 0.35)
                .help("Redo (⇧⌘Z)")
            }
        }
    }

    // MARK: - Center: creation tools + layout mode

    private var toolsCluster: some View {
        HStack(spacing: 6) {
            HStack(spacing: 2) {
                toolButton(isSelected: viewModel.activeTool == .select, icon: "cursorarrow", label: "Select (V)") {
                    viewModel.activeTool = .select
                }
                toolButton(isSelected: viewModel.activeTool == .hand, icon: "hand.raised", label: "Hand — pan the canvas (H, or hold Space)") {
                    viewModel.activeTool = .hand
                }
                toolButton(isSelected: false, icon: "textformat", label: "Add Text (T)") {
                    viewModel.addText()
                }
                toolButton(isSelected: false, icon: "square.on.circle", label: "Add Rectangle (R) · Ellipse (O)") {
                    viewModel.addShape(.roundedRectangle)
                }
                toolButton(isSelected: false, icon: "chevron.left.forwardslash.chevron.right", label: "Add Code Block (C)") {
                    viewModel.addCodeBlock()
                }
                toolButton(isSelected: viewModel.activeTool == .draw, icon: "pencil.tip", label: "Pen (P)") {
                    viewModel.activeTool = (viewModel.activeTool == .draw) ? .select : .draw
                }
                penSettingsButton
            }
            .plumaControlGroup()

            layoutModeMenu
        }
    }

    /// Ink swatch + chevron beside the Pen tool: opens width & color settings.
    private var penSettingsButton: some View {
        Button(action: { showPenSettings.toggle() }) {
            HStack(spacing: 2) {
                Circle()
                    .fill(viewModel.drawingColor.color)
                    .frame(width: 9, height: 9)
                    .overlay(Circle().stroke(PlumaTheme.hairline, lineWidth: 1))
                Image(systemName: "chevron.down")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(.secondary)
            }
            .frame(width: 22, height: 26)
        }
        .buttonStyle(ToolToggleButtonStyle(isSelected: false))
        .help("Pen width & color")
        .popover(isPresented: $showPenSettings, arrowEdge: .bottom) {
            PenSettingsPopover(viewModel: viewModel)
        }
    }

    private var layoutModeMenu: some View {
        Menu {
            Picker("Layout", selection: Binding(
                get: { viewModel.pageLayoutMode },
                set: { mode in
                    withAnimation(.easeInOut(duration: 0.2)) { viewModel.pageLayoutMode = mode }
                }
            )) {
                Label("Single Slide", systemImage: "rectangle").tag(PageLayoutMode.singleSlide)
                Label("Document Flow", systemImage: "doc.text").tag(PageLayoutMode.continuousVertical)
                Label("Infinite Whiteboard", systemImage: "square.dashed").tag(PageLayoutMode.infiniteWhiteboard)
            }
            .pickerStyle(.inline)
        } label: {
            HStack(spacing: 5) {
                Image(systemName: layoutIcon)
                    .font(.system(size: 11, weight: .medium))
                Text(layoutTitle)
                    .font(PlumaTheme.label(12))
                    .lineLimit(1)
                    .fixedSize()
            }
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.visible)
        .fixedSize()
        .padding(.horizontal, 8)
        .frame(height: 28)
        .background(RoundedRectangle(cornerRadius: 7).fill(PlumaTheme.control))
        .help("How pages are laid out: one slide at a time, a scrolling document, or an infinite board")
    }

    private var layoutTitle: String {
        switch viewModel.pageLayoutMode {
        case .singleSlide: return "Slide"
        case .continuousVertical: return "Document"
        case .infiniteWhiteboard: return "Whiteboard"
        }
    }

    private var layoutIcon: String {
        switch viewModel.pageLayoutMode {
        case .singleSlide: return "rectangle"
        case .continuousVertical: return "doc.text"
        case .infiniteWhiteboard: return "square.dashed"
        }
    }

    // MARK: - Trailing: zoom, copy, AI bridge, import/export, inspector

    private var trailingCluster: some View {
        HStack(spacing: 6) {
            Menu {
                Button("Copy Page as PNG  ⇧⌘C") { viewModel.copyPageImageToClipboard() }
                Button("Copy as SVG for Figma  ⌥⌘C") { viewModel.copySVGForFigma() }
                Divider()
                Button("Copy AI Bridge (MCP) Setup") { copyMCPConfig() }
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 12, weight: .medium))
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .frame(width: 28, height: 28)
            .hoverHighlight(cornerRadius: 7, opacity: 0.08)
            .help("Copy page as image or SVG")

            // AI bridge status — a quiet dot, details on hover/click.
            Button(action: copyMCPConfig) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(PlumaBridgeServer.shared.isRunning ? PlumaTheme.success : Color.secondary.opacity(0.4))
                        .frame(width: 6, height: 6)
                    Image(systemName: "sparkles")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 6)
                .frame(height: 28)
            }
            .buttonStyle(HoverIconButtonStyle(side: 28))
            .help(PlumaBridgeServer.shared.isRunning
                  ? "AI bridge running on 127.0.0.1:\(PlumaBridgeServer.shared.port) — click to copy the MCP config for Claude / Cursor"
                  : "AI bridge is not running")

            Button(action: openImportPanel) {
                Text("Import")
                    .font(PlumaTheme.label(12))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 10)
                    .frame(height: 28)
                    .background(RoundedRectangle(cornerRadius: 7).fill(PlumaTheme.control))
                    .overlay(RoundedRectangle(cornerRadius: 7).stroke(PlumaTheme.hairline, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .hoverHighlight(cornerRadius: 7, opacity: 0.06)
            .help("Import PowerPoint (.pptx), Canva PDF, SVG, ZIP, or image")

            Button(action: { viewModel.isPresentingFullscreen = true }) {
                Image(systemName: "play.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 30, height: 28)
                    .background(RoundedRectangle(cornerRadius: 7).fill(PlumaTheme.control))
            }
            .buttonStyle(.plain)
            .hoverHighlight(cornerRadius: 7, opacity: 0.06)
            .help("Present full screen (⌥⌘P)")

            Button(action: { viewModel.showExportModal = true }) {
                HStack(spacing: 5) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Export")
                        .font(PlumaTheme.label(12, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .frame(height: 28)
                .background(RoundedRectangle(cornerRadius: 7).fill(PlumaTheme.accent))
            }
            .buttonStyle(.plain)
            .hoverHighlight(cornerRadius: 7, opacity: 0.08)
            .help("Export PNG, JPEG, PDF, SVG, PPTX (⌘E)")

            panelToggle(
                icon: "sidebar.right",
                isOn: viewModel.isRightInspectorVisible,
                help: "Toggle Inspector (⌘2)"
            ) { viewModel.isRightInspectorVisible.toggle() }
        }
    }

    // MARK: - Building blocks

    private var divider: some View {
        Rectangle().fill(PlumaTheme.hairline).frame(width: 1, height: 18)
    }

    private func panelToggle(icon: String, isOn: Bool, help: String, toggle: @escaping () -> Void) -> some View {
        Button(action: { withAnimation(.easeInOut(duration: 0.2)) { toggle() } }) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(isOn ? PlumaTheme.accentOnSoft : .secondary)
                .frame(width: 28, height: 28)
                .background(RoundedRectangle(cornerRadius: 7).fill(isOn ? PlumaTheme.accentSoft : .clear))
        }
        .buttonStyle(HoverIconButtonStyle(side: 28))
        .help(help)
    }

    private func toolButton(isSelected: Bool, icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .frame(width: 30, height: 26)
        }
        .buttonStyle(ToolToggleButtonStyle(isSelected: isSelected))
        .help(label)
    }

    private func copyMCPConfig() {
        let scriptPath = Bundle.main.resourcePath.map { $0 + "/pluma_mcp_server.py" } ?? "~/project/canvas/scripts/pluma_mcp_server.py"
        let config = "{\"mcpServers\":{\"pluma\":{\"command\":\"python3\",\"args\":[\"\(scriptPath)\"]}}}"
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(config, forType: .string)
        viewModel.showTemporaryToast("MCP config copied — paste it into Claude Desktop or Cursor settings")
    }

    private func openImportPanel() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = DocumentImportService.allowedContentTypes
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = "Select a PowerPoint (.pptx), Canva PDF, SVG, ZIP, or Image file to import"

        if panel.runModal() == .OK, let url = panel.url {
            DocumentImportService.shared.importDocument(from: url) { importedProject in
                if let importedProject {
                    // Canonical swap — resets page index, selection, layout
                    // mode, and pan/zoom for the incoming project.
                    viewModel.adoptProject(importedProject)
                    ProjectStorage.shared.saveProject(importedProject)
                    viewModel.showTemporaryToast("Imported \(importedProject.name)")
                } else {
                    DocumentImportService.shared.showFailureAlert(file: url.lastPathComponent)
                }
            }
        }
    }
}
