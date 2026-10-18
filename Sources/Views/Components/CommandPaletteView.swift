import SwiftUI
import AppKit

// MARK: - Command Palette (⌘K)
//
// Figma/Spotlight-style fuzzy command launcher: run any app action by typing a
// few letters. Arrow keys navigate, Enter runs, Esc closes.

public struct CommandPaletteView: View {
    @ObservedObject var viewModel: CanvasDocumentViewModel
    let onClose: () -> Void

    @State private var query: String = ""
    @State private var selectedIndex: Int = 0
    @FocusState private var searchFocused: Bool

    struct Command: Identifiable {
        // Stable identity: a fresh UUID per render made every row "new" on each
        // hover, so the list re-diffed constantly.
        var id: String { category + "/" + title }
        let title: String
        let icon: String
        let category: String
        let action: () -> Void
    }

    private var commands: [Command] {
        var list: [Command] = []

        // --- Tools ---
        list.append(Command(title: "Select Tool", icon: "cursorarrow.rays", category: "Tools") { viewModel.activeTool = .select })
        list.append(Command(title: "Hand / Pan Tool", icon: "hand.raised.fill", category: "Tools") { viewModel.activeTool = .hand })
        list.append(Command(title: "Pen / Draw Tool", icon: "pencil.tip", category: "Tools") { viewModel.activeTool = .draw })

        // --- Insert ---
        list.append(Command(title: "Add Text", icon: "textformat", category: "Insert") { viewModel.addText() })
        list.append(Command(title: "Add Sticky Note", icon: "note.text", category: "Insert") { viewModel.addStickyNote() })
        list.append(Command(title: "Add Rectangle", icon: "rectangle", category: "Insert") { viewModel.addShape(.roundedRectangle) })
        list.append(Command(title: "Add Circle", icon: "circle", category: "Insert") { viewModel.addShape(.circle) })
        list.append(Command(title: "Add Star", icon: "star", category: "Insert") { viewModel.addShape(.star) })
        list.append(Command(title: "Add Arrow", icon: "arrow.right", category: "Insert") { viewModel.addShape(.arrow) })
        list.append(Command(title: "Add Code Block", icon: "chevron.left.forwardslash.chevron.right", category: "Insert") { viewModel.addCodeBlock() })
        list.append(Command(title: "Add QR Code…", icon: "qrcode", category: "Insert") { viewModel.addQRCode(url: "https://pluma.design") })
        list.append(Command(title: "Add Database Cylinder", icon: "cylinder.fill", category: "Insert") { viewModel.addShape(.database) })

        // --- Dev ---
        list.append(Command(title: "Insert Terminal Window", icon: "terminal.fill", category: "Dev") { viewModel.insertElements(DevKitPresets.terminalWindow(), name: "Terminal") })
        list.append(Command(title: "Insert Browser Window", icon: "safari.fill", category: "Dev") { viewModel.insertElements(DevKitPresets.browserWindow(), name: "Browser") })
        list.append(Command(title: "Insert API Endpoint Chip", icon: "network", category: "Dev") { viewModel.insertElements(DevKitPresets.apiChip(), name: "API Chip") })
        list.append(Command(title: "Insert CI Badge", icon: "checkmark.seal.fill", category: "Dev") { viewModel.insertElements(DevKitPresets.statusBadge(), name: "Badge") })
        list.append(Command(title: "Diagram: Request Flow", icon: "arrow.triangle.swap", category: "Dev") { viewModel.insertElements(DevKitPresets.requestFlowDiagram(), name: "Request Flow") })
        list.append(Command(title: "Diagram: CI/CD Pipeline", icon: "gearshape.2.fill", category: "Dev") { viewModel.insertElements(DevKitPresets.cicdPipeline(), name: "CI/CD Pipeline") })
        list.append(Command(title: "Diagram: Kanban Board", icon: "rectangle.3.group.fill", category: "Dev") { viewModel.insertElements(DevKitPresets.kanbanBoard(), name: "Kanban") })
        list.append(Command(title: "Diagram: Git Branch Flow", icon: "point.topleft.down.to.point.bottomright.curvepath.fill", category: "Dev") { viewModel.insertElements(DevKitPresets.gitFlow(), name: "Git Flow") })
        if viewModel.selectedElementIds.count >= 2 {
            list.append(Command(title: "Connect Selected Elements", icon: "arrow.triangle.turn.up.right.diamond", category: "Insert") { viewModel.connectSelectedElements() })
        }

        // --- Edit ---
        if !viewModel.selectedElementIds.isEmpty {
            list.append(Command(title: "Duplicate Selection", icon: "plus.square.on.square", category: "Edit") { viewModel.duplicateSelected() })
            list.append(Command(title: "Delete Selection", icon: "trash", category: "Edit") { viewModel.deleteSelected() })
            list.append(Command(title: "Bring to Front", icon: "square.3.layers.3d.top.filled", category: "Edit") { viewModel.bringToFront() })
            list.append(Command(title: "Send to Back", icon: "square.3.layers.3d.bottom.filled", category: "Edit") { viewModel.sendToBack() })
            list.append(Command(title: "Flip Horizontal", icon: "arrow.left.and.right.righttriangle.left.righttriangle.right", category: "Edit") { viewModel.flipSelected(horizontal: true) })
            list.append(Command(title: "Flip Vertical", icon: "arrow.up.and.down.righttriangle.up.righttriangle.down", category: "Edit") { viewModel.flipSelected(horizontal: false) })
        }
        list.append(Command(title: "Undo", icon: "arrow.uturn.backward", category: "Edit") { viewModel.undo() })
        list.append(Command(title: "Redo", icon: "arrow.uturn.forward", category: "Edit") { viewModel.redo() })
        list.append(Command(title: viewModel.enableSnapping ? "Disable Snapping" : "Enable Snapping", icon: "squareshape.split.2x2.dotted", category: "Edit") { viewModel.enableSnapping.toggle() })

        // --- View / Layout ---
        list.append(Command(title: "Zoom to Selection / Fit Page (F)", icon: "arrow.up.left.and.arrow.down.right", category: "View") { viewModel.zoomToSelection(viewportSize: viewModel.lastViewportSize) })
        list.append(Command(title: "Zoom to 100%", icon: "1.magnifyingglass", category: "View") { viewModel.zoomTo100() })
        list.append(Command(title: viewModel.showRulers ? "Hide Rulers & Guides" : "Show Rulers & Guides", icon: "ruler", category: "View") { viewModel.showRulers.toggle() })
        if viewModel.activeGuidesForPage.count > 0 {
            list.append(Command(title: "Clear All Guides on This Page", icon: "ruler.fill", category: "View") { viewModel.clearGuides() })
        }
        list.append(Command(title: "Layout: Continuous Document", icon: "scroll.fill", category: "View") { viewModel.pageLayoutMode = .continuousVertical })
        list.append(Command(title: "Layout: Single Slide", icon: "rectangle.split.1x2.fill", category: "View") { viewModel.pageLayoutMode = .singleSlide })
        list.append(Command(title: "Layout: Infinite Whiteboard", icon: "brain.head.profile", category: "View") { viewModel.pageLayoutMode = .infiniteWhiteboard })
        list.append(Command(title: "Toggle Left Sidebar (⌘1)", icon: "sidebar.left", category: "View") { viewModel.isLeftSidebarVisible.toggle() })
        list.append(Command(title: "Toggle Inspector (⌘2)", icon: "sidebar.right", category: "View") { viewModel.isRightInspectorVisible.toggle() })
        list.append(Command(title: "Toggle Grid Overlay", icon: "grid", category: "View") { viewModel.showGridOverlay.toggle() })
        list.append(Command(title: viewModel.isPresentingFullscreen ? "Exit Presentation" : "Present Fullscreen", icon: "play.rectangle", category: "View") { viewModel.isPresentingFullscreen.toggle() })

        // --- Pages ---
        for (idx, page) in viewModel.project.pages.enumerated() {
            list.append(Command(title: "Go to Page \(idx + 1): \(page.name)", icon: "doc.on.doc", category: "Pages") {
                viewModel.scrollToPage(index: idx)
            })
        }

        // --- Export / Import ---
        list.append(Command(title: "Export Design… (⌘E)", icon: "square.and.arrow.up", category: "File") { viewModel.showExportModal = true })
        list.append(Command(title: "Copy HD Image to Clipboard", icon: "doc.on.clipboard", category: "File") { viewModel.copyPageImageToClipboard() })
        list.append(Command(title: "Copy Vector SVG for Figma", icon: "paintpalette.fill", category: "File") { viewModel.copySVGForFigma() })
        if !viewModel.selectedElementIds.isEmpty {
            list.append(Command(title: "Copy Selected Element as Image", icon: "photo.on.rectangle", category: "File") { viewModel.copySelectedElementAsImage() })
        }

        return list
    }

    private var filtered: [Command] {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return commands }
        return commands.filter {
            $0.title.localizedCaseInsensitiveContains(q) || $0.category.localizedCaseInsensitiveContains(q)
        }
    }

    public var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.black.opacity(0.25))
                .contentShape(Rectangle())
                .onTapGesture(perform: onClose)

            VStack(spacing: 0) {
                // Halftone press strip across the top of the palette
                HalftonePatternView(
                    ink: Color(hex: "#C2410C").opacity(0.5),
                    spacing: 7,
                    maxRadius: 1.7,
                    ramp: .linear(angle: 90, from: 0.9, to: 0.0)
                )
                .frame(height: 5)

                // Search field
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    TextField("Type a command… (add text, export, go to page, zoom…)", text: $query)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                        .focused($searchFocused)
                        .onSubmit { runSelected() }
                    Text("ESC")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().strokeBorder(Color.secondary.opacity(0.3)))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)

                Divider()

                // Results
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: true) {
                        LazyVStack(spacing: 1) {
                            ForEach(Array(filtered.enumerated()), id: \.element.id) { index, command in
                                commandRow(index: index, command: command)
                                    .id(index)
                            }
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                    }
                    .frame(maxHeight: 340)
                    .onChange(of: selectedIndex) { _, newValue in
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                    .onChange(of: query) { _, _ in selectedIndex = 0 }
                }

                // Footer hint
                HStack(spacing: 12) {
                    Label("↑↓ navigate", systemImage: "arrow.up.arrow.down")
                    Label("↵ run", systemImage: "return")
                    Spacer()
                    Text("\(filtered.count) commands")
                }
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
            }
            .frame(width: 560)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.secondary.opacity(0.3), lineWidth: 1))
            .shadow(color: Color.black.opacity(0.3), radius: 30, x: 0, y: 14)
            .padding(.top, -120)
        }
        .onAppear {
            searchFocused = true
            installKeyMonitor()
        }
        .onDisappear {
            if let monitor = keyMonitor {
                NSEvent.removeMonitor(monitor)
                keyMonitor = nil
            }
        }
    }

    @State private var keyMonitor: Any? = nil

    /// Local key monitor: arrows navigate results, Enter runs the selection,
    /// everything else flows to the search field normally.
    private func installKeyMonitor() {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            switch event.keyCode {
            case 126: // up
                guard !filtered.isEmpty else { return event }
                selectedIndex = max(0, selectedIndex - 1)
                return nil
            case 125: // down
                guard !filtered.isEmpty else { return event }
                selectedIndex = min(filtered.count - 1, selectedIndex + 1)
                return nil
            case 36: // return
                runSelected()
                return nil
            case 53: // esc (backup for when the field isn't focused)
                onClose()
                return nil
            default:
                return event
            }
        }
    }

    private func commandRow(index: Int, command: Command) -> some View {
        let isSelected = index == selectedIndex
        return HStack(spacing: 10) {
            Image(systemName: command.icon)
                .font(.system(size: 12))
                .foregroundColor(isSelected ? Color(hex: "#C2410C") : .secondary)
                .frame(width: 20)
            Text(command.title)
                .font(.system(size: 12.5, weight: isSelected ? .semibold : .regular))
                .lineLimit(1)
            Spacer()
            Text(command.category)
                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                .foregroundColor(.secondary.opacity(0.7))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 7)
                .fill(isSelected ? Color(hex: "#C2410C").opacity(0.12) : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            if hovering { selectedIndex = index }
        }
        .onTapGesture {
            run(command)
        }
    }

    private func runSelected() {
        guard filtered.indices.contains(selectedIndex) else { return }
        run(filtered[selectedIndex])
    }

    private func run(_ command: Command) {
        onClose()
        command.action()
    }
}
