import SwiftUI
import AppKit
import UniformTypeIdentifiers

public struct HomeDashboardView: View {
    @ObservedObject var storage = ProjectStorage.shared
    @Binding var activeProject: CanvasProject?
    @Binding var isShowingDashboard: Bool

    @State private var searchText: String = ""
    @State private var showCustomSizeModal: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var customW: Double = 1080
    @State private var customH: Double = 1080
    @State private var selectedProjectIds: Set<UUID> = []
    @State private var isSelectionMode: Bool = false

    public init(activeProject: Binding<CanvasProject?>, isShowingDashboard: Binding<Bool>) {
        self._activeProject = activeProject
        self._isShowingDashboard = isShowingDashboard
    }

    private var filteredProjects: [SavedProjectSummary] {
        if searchText.isEmpty { return storage.savedProjects }
        return storage.savedProjects.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // Top Header & Search Bar
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 10) {
                            Image(systemName: "paintpalette.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(LinearGradient(colors: [Color(hex: "#C2410C"), Color(hex: "#D97706")], startPoint: .topLeading, endPoint: .bottomTrailing))

                            VStack(alignment: .leading, spacing: 0) {
                                Text("Pluma")
                                    .font(.system(size: 24, weight: .bold, design: .serif))
                                Text("The Tactile Craft & Visual Studio")
                                    .font(.system(size: 10, weight: .semibold, design: .serif))
                                    .foregroundColor(Color(hex: "#C2410C"))
                            }
                        }

                        Text("Featherlight native performance • 40MB RAM • 120 FPS")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Search input
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search designs...", text: $searchText)
                            .textFieldStyle(.plain)
                            .frame(width: 180)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    // Import Button (PowerPoint / Canva / PDF / SVG)
                    Button(action: openCanvaImportPicker) {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.down")
                            Text("Import")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color(hex: "#C2410C").opacity(0.1))
                        .foregroundColor(Color(hex: "#C2410C"))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#C2410C").opacity(0.45), lineWidth: 1))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help("Import PowerPoint (.pptx), Canva PDF, SVG, ZIP, or Image")

                    // New Custom Design Button
                    Button(action: {
                        showCustomSizeModal = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                            Text("Custom Size")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color(hex: "#C2410C"))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 24)

                // Quick Start Size Presets Carousel
                VStack(alignment: .leading, spacing: 12) {
                    Text("CREATE NEW DESIGN")
                        .font(.system(size: 12, weight: .bold, design: .serif))
                        .foregroundColor(.secondary)
                        .tracking(1.0)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            presetCard(title: "Infinite Whiteboard", size: "Freeform Canvas", icon: "brain.head.profile", w: 3600, h: 2400)
                            presetCard(title: "A4 Document", size: "1240 × 1754", icon: "doc.text.fill", w: 1240, h: 1754)
                            presetCard(title: "Resume / CV", size: "1240 × 1754", icon: "person.text.rectangle.fill", w: 1240, h: 1754)
                            presetCard(title: "Presentation 16:9", size: "1920 × 1080", icon: "tv.fill", w: 1920, h: 1080)
                            presetCard(title: "Instagram Post", size: "1080 × 1080", icon: "camera.fill", w: 1080, h: 1080)
                            presetCard(title: "Story / TikTok", size: "1080 × 1920", icon: "iphone", w: 1080, h: 1920)
                            presetCard(title: "YouTube Thumb", size: "1280 × 720", icon: "play.rectangle.fill", w: 1280, h: 720)
                            presetCard(title: "Code Snippet", size: "1200 × 675", icon: "chevron.left.forwardslash.chevron.right", w: 1200, h: 675, isCode: true)
                            canvaImportPresetCard()
                        }
                    }
                }

                // Templates Showcase
                VStack(alignment: .leading, spacing: 12) {
                    Text("STARTER TEMPLATES")
                        .font(.system(size: 12, weight: .bold, design: .serif))
                        .foregroundColor(.secondary)
                        .tracking(1.0)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(TemplateCatalog.templates) { template in
                                Button(action: {
                                    openTemplate(template)
                                }) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color(hex: template.previewColorHex))
                                                .frame(width: 170, height: 100)

                                            VStack(spacing: 4) {
                                                Text(template.title)
                                                    .font(.system(size: 11, weight: .bold, design: .serif))
                                                    .foregroundColor(.white)
                                                    .multilineTextAlignment(.center)
                                                    .padding(.horizontal, 6)

                                                Text(template.preset.aspectRatioFormatted)
                                                    .font(.system(size: 9, design: .monospaced))
                                                    .foregroundColor(.white.opacity(0.85))
                                            }
                                        }
                                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

                                        Text(template.title)
                                            .font(.system(size: 12, weight: .semibold, design: .serif))
                                            .foregroundColor(.primary)
                                            .lineLimit(1)

                                        Text(template.category)
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(width: 170)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                // Recent Designs Grid & Multi-Selection Toolbar
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 12) {
                        Text("RECENT DESIGNS")
                            .font(.system(size: 12, weight: .bold, design: .serif))
                            .foregroundColor(.secondary)
                            .tracking(1.0)

                        Spacer()

                        // Multi-Selection Controls
                        if !selectedProjectIds.isEmpty {
                            HStack(spacing: 8) {
                                Text("\(selectedProjectIds.count) selected")
                                    .font(.system(size: 11, weight: .semibold, design: .serif))
                                    .foregroundColor(Color(hex: "#C2410C"))

                                Button("Select All") {
                                    selectedProjectIds = Set(filteredProjects.map { $0.id })
                                }
                                .font(.system(size: 11))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                                .buttonStyle(.plain)

                                Button("Deselect All") {
                                    selectedProjectIds.removeAll()
                                    isSelectionMode = false
                                }
                                .font(.system(size: 11))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                                .buttonStyle(.plain)

                                Button(action: {
                                    showDeleteConfirmation = true
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "trash.fill")
                                        Text("Delete (\(selectedProjectIds.count))")
                                    }
                                    .font(.system(size: 11, weight: .bold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                                }
                                .buttonStyle(.plain)
                            }
                        } else {
                            Button(action: {
                                isSelectionMode.toggle()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: isSelectionMode ? "checkmark.circle.fill" : "checkmark.circle")
                                    Text(isSelectionMode ? "Done" : "Select")
                                }
                                .font(.system(size: 11, weight: .medium, design: .serif))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(isSelectionMode ? Color(hex: "#C2410C").opacity(0.15) : Color.secondary.opacity(0.08))
                                .foregroundColor(isSelectionMode ? Color(hex: "#C2410C") : .secondary)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            Text("\(storage.savedProjects.count) Projects")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }

                    if filteredProjects.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "doc.badge.plus")
                                .font(.system(size: 36))
                                .foregroundColor(.secondary)
                            Text("No designs found. Pick a preset above to create your first page!")
                                .font(.system(size: 13, design: .serif))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(filteredProjects) { item in
                                projectCard(item)
                            }
                        }
                    }
                }
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 32)
        }
        .sheet(isPresented: $showCustomSizeModal) {
            customSizeSheet
        }
        .confirmationDialog(
            "Delete \(selectedProjectIds.count) designs?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Selected (\(selectedProjectIds.count))", role: .destructive) {
                storage.deleteProjects(ids: selectedProjectIds)
                selectedProjectIds.removeAll()
                isSelectionMode = false
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to permanently delete \(selectedProjectIds.count) projects? This action cannot be undone.")
        }
    }

    private func presetCard(title: String, size: String, icon: String, w: Double, h: Double, isCode: Bool = false) -> some View {
        Button(action: {
            if title.contains("Whiteboard") {
                openTemplate(WhiteboardTemplates.createProductStrategyMindmapTemplate())
            } else {
                createNewProject(width: w, height: h, name: title, isCode: isCode)
            }
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(Color(hex: "#C2410C"))
                    .frame(height: 32)

                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .serif))
                    .foregroundColor(.primary)

                Text(size)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            .frame(width: 135, height: 110)
            .background(Color.secondary.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.secondary.opacity(0.12), lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Project Card with Multi-Selection

    private func projectCard(_ item: SavedProjectSummary) -> some View {
        let isSelected = selectedProjectIds.contains(item.id)

        return VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                if isSelectionMode || !selectedProjectIds.isEmpty {
                    toggleProjectSelection(item.id)
                } else {
                    openProject(id: item.id)
                }
            }) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color(hex: "#C2410C").opacity(0.1) : Color.secondary.opacity(0.08))
                        .frame(height: 130)

                    VStack(spacing: 6) {
                        Image(systemName: "doc.richtext.fill")
                            .font(.system(size: 28))
                            .foregroundColor(isSelected ? Color(hex: "#C2410C") : Color(hex: "#D97706"))

                        Text(item.dimensionsString)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // Selection Checkbox Button
                    Button(action: {
                        toggleProjectSelection(item.id)
                    }) {
                        ZStack {
                            Circle()
                                .fill(isSelected ? Color(hex: "#C2410C") : Color.white.opacity(0.9))
                                .frame(width: 22, height: 22)
                                .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)

                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            } else {
                                Circle()
                                    .stroke(Color.secondary.opacity(0.4), lineWidth: 1.5)
                                    .frame(width: 18, height: 18)
                            }
                        }
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(8)
                    .opacity((isSelectionMode || !selectedProjectIds.isEmpty || isSelected) ? 1.0 : 0.6)
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color(hex: "#C2410C") : Color.secondary.opacity(0.12), lineWidth: isSelected ? 2 : 1)
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.system(size: 12, weight: .bold, design: .serif))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text("Edited \(item.formattedDate)")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Menu {
                    Button("Open") { openProject(id: item.id) }
                    Button("Duplicate") { _ = storage.duplicateProject(id: item.id) }
                    Button(isSelected ? "Deselect" : "Select") { toggleProjectSelection(item.id) }
                    Divider()
                    Button("Delete", role: .destructive) { storage.deleteProject(id: item.id) }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .frame(width: 26, height: 26)
                        .contentShape(Rectangle())
                }
                .menuStyle(.borderlessButton)
            }
        }
    }

    private func toggleProjectSelection(_ id: UUID) {
        if selectedProjectIds.contains(id) {
            selectedProjectIds.remove(id)
            if selectedProjectIds.isEmpty { isSelectionMode = false }
        } else {
            selectedProjectIds.insert(id)
            isSelectionMode = true
        }
    }

    // MARK: - Project Creation & Loading

    private func createNewProject(width: Double, height: Double, name: String, isCode: Bool = false) {
        var page = CanvasPage(name: "Page 1", width: width, height: height, background: .solid(.white))

        if isCode {
            let codeElem = CanvasElement(
                name: "Code Block",
                payload: .code(CodeContent()),
                x: (width - 700) / 2.0,
                y: (height - 400) / 2.0,
                width: 700,
                height: 400,
                shadow: ShadowEffect.elevated
            )
            page.elements.append(codeElem)
        }

        let newProj = CanvasProject(name: name, pages: [page])
        storage.saveProject(newProj)
        self.activeProject = newProj
        self.isShowingDashboard = false
    }

    private func openProject(id: UUID) {
        if let proj = storage.loadProject(id: id) {
            self.activeProject = proj
            self.isShowingDashboard = false
        }
    }

    private func openTemplate(_ template: CanvasTemplate) {
        let newProj = CanvasProject(name: template.title, pages: template.pages.isEmpty ? [template.page] : template.pages)
        storage.saveProject(newProj)
        self.activeProject = newProj
        self.isShowingDashboard = false
    }

    private func openCanvaImportPicker() {
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
        panel.message = "Select a PowerPoint (.pptx), Canva PDF, SVG, ZIP, or Image file to import into Pluma"

        if panel.runModal() == .OK, let url = panel.url {
            if let project = CanvaDocumentImporter.importDocument(from: url) {
                storage.saveProject(project)
                self.activeProject = project
                self.isShowingDashboard = false
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

    private func canvaImportPresetCard() -> some View {
        Button(action: openCanvaImportPicker) {
            VStack(spacing: 8) {
                Image(systemName: "square.and.arrow.down.on.square.fill")
                    .font(.system(size: 22))
                    .foregroundColor(Color(hex: "#C2410C"))
                    .frame(height: 32)

                Text("Import Canva / PPTX")
                    .font(.system(size: 12, weight: .bold, design: .serif))
                    .foregroundColor(.primary)

                Text("PPTX • PDF • SVG")
                    .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(hex: "#C2410C"))
            }
            .frame(width: 135, height: 110)
            .background(Color(hex: "#C2410C").opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "#C2410C").opacity(0.35), lineWidth: 1.5))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Import PowerPoint (.pptx), Canva PDF, SVG, ZIP, or Image")
    }

    // MARK: - Custom Size Sheet

    private var customSizeSheet: some View {
        VStack(spacing: 16) {
            Text("Create Custom Sheet")
                .font(.system(size: 16, weight: .bold, design: .serif))

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Width (px)").font(.system(size: 11)).foregroundColor(.secondary)
                    TextField("Width", value: $customW, format: .number)
                        .textFieldStyle(.roundedBorder)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Height (px)").font(.system(size: 11)).foregroundColor(.secondary)
                    TextField("Height", value: $customH, format: .number)
                        .textFieldStyle(.roundedBorder)
                }
            }

            HStack(spacing: 12) {
                Button("Cancel") { showCustomSizeModal = false }
                Button("Create Sheet") {
                    createNewProject(width: customW, height: customH, name: "Custom Canvas")
                    showCustomSizeModal = false
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 360)
    }
}
