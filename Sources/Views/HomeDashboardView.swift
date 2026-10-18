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
    @State private var showEmptyTrashConfirmation: Bool = false
    @State private var customW: Double = 1080
    @State private var customH: Double = 1080
    @State private var selectedProjectIds: Set<UUID> = []
    @State private var isSelectionMode: Bool = false
    @State private var selectedSection: DashboardSection = .home
    @State private var recentsViewMode: RecentsViewMode = .grid
    @State private var recentsSort: RecentsSort = .lastEdited
    @FocusState private var searchFocused: Bool
    @State private var cmdKMonitor: Any? = nil

    private enum DashboardSection { case home, designs, templates, trash }
    private enum RecentsViewMode { case grid, list }
    private enum RecentsSort: String { case lastEdited = "Last Edited", name = "Name A–Z", oldest = "Oldest First" }

    private static let accent = Color(hex: "#C2410C")
    private static let amber = Color(hex: "#D97706")
    private static let paper = PlumaTheme.paper
    private static let ink = PlumaTheme.ink

    public init(activeProject: Binding<CanvasProject?>, isShowingDashboard: Binding<Bool>) {
        self._activeProject = activeProject
        self._isShowingDashboard = isShowingDashboard
    }

    private var filteredProjects: [SavedProjectSummary] {
        var list = storage.savedProjects
        if !searchText.isEmpty {
            list = list.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        switch recentsSort {
        case .lastEdited: list.sort { $0.modifiedAt > $1.modifiedAt }
        case .name: list.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .oldest: list.sort { $0.modifiedAt < $1.modifiedAt }
        }
        return list
    }

    private var filteredTemplates: [CanvasTemplate] {
        guard !searchText.isEmpty else { return TemplateCatalog.templates }
        return TemplateCatalog.templates.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.category.localizedCaseInsensitiveContains(searchText)
        }
    }

    /// Display order for template categories — professional formats first.
    /// Any category not listed still appears (sorted) so nothing is ever hidden.
    private static let templateCategoryOrder = [
        "Presentations & Screens",
        "Resumes & CVs",
        "Print & Documents",
        "Social Media",
        "Whiteboard & Mindmap"
    ]

    /// `filteredTemplates` grouped by category in display order.
    private var groupedTemplates: [(category: String, items: [CanvasTemplate])] {
        let groups = Dictionary(grouping: filteredTemplates, by: \.category)
        let keys = Self.templateCategoryOrder.filter { groups[$0] != nil }
            + groups.keys.filter { !Self.templateCategoryOrder.contains($0) }.sorted()
        return keys.map { ($0, groups[$0] ?? []) }
    }

    /// A diverse starter pick: up to two templates per category.
    private var starterTemplates: [CanvasTemplate] {
        var picks: [CanvasTemplate] = []
        var seen: [String] = []
        for t in TemplateCatalog.templates where !seen.contains(t.category) { seen.append(t.category) }
        let ordered = Self.templateCategoryOrder.filter { seen.contains($0) }
            + seen.filter { !Self.templateCategoryOrder.contains($0) }
        for cat in ordered {
            picks += TemplateCatalog.templates.filter { $0.category == cat }.prefix(2)
        }
        return picks
    }

    private var filteredTrash: [SavedProjectSummary] {
        guard !searchText.isEmpty else { return storage.trashedProjects }
        return storage.trashedProjects.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    // MARK: - Root

    public var body: some View {
        HStack(spacing: 0) {
            sidebar
                .frame(width: 208)
                .frame(maxHeight: .infinity)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    topBar

                    switch selectedSection {
                    case .home:
                        heroBanner
                        createNewSection
                        starterTemplatesStrip
                        recentsSection
                    case .designs:
                        recentsSection
                    case .templates:
                        allTemplatesSection
                    case .trash:
                        trashSection
                    }
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .overlay {
            ImportProgressOverlay()
                .zIndex(200)
        }
        .sheet(isPresented: $showCustomSizeModal) {
            customSizeSheet
        }
        .confirmationDialog(
            "Move \(selectedProjectIds.count) designs to Trash?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Move to Trash (\(selectedProjectIds.count))", role: .destructive) {
                storage.deleteProjects(ids: selectedProjectIds)
                selectedProjectIds.removeAll()
                isSelectionMode = false
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You can restore them later from Trash.")
        }
        .confirmationDialog(
            "Empty Trash?",
            isPresented: $showEmptyTrashConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Forever (\(storage.trashedProjects.count))", role: .destructive) {
                storage.emptyTrash()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes \(storage.trashedProjects.count) projects. This action cannot be undone.")
        }
        .onAppear {
            // Returning from the editor must show fresh recents — autosave
            // writes are async so give them a moment before re-reading disk.
            storage.reloadProjects()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                storage.reloadProjects()
            }
            cmdKMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if event.modifierFlags.contains(.command),
                   event.charactersIgnoringModifiers?.lowercased() == "k" {
                    searchFocused = true
                    return nil
                }
                return event
            }
        }
        .onDisappear {
            if let monitor = cmdKMonitor {
                NSEvent.removeMonitor(monitor)
                cmdKMonitor = nil
            }
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Brand lockup
            HStack(spacing: 10) {
                Image(systemName: "paintpalette.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(LinearGradient(colors: [Self.accent, Self.amber], startPoint: .topLeading, endPoint: .bottomTrailing))
                VStack(alignment: .leading, spacing: 0) {
                    Text("Pluma")
                        .font(.system(size: 20, weight: .bold, design: .serif))
                        .foregroundColor(Self.ink)
                    Text("The Tactile Craft Studio")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Self.accent)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 16)

            VStack(spacing: 2) {
                navItem(title: "Home", icon: "house.fill", section: .home)
                navItem(title: "My Designs", icon: "folder.fill", section: .designs)
                navItem(title: "Templates", icon: "square.grid.2x2.fill", section: .templates)
                navItem(title: "Trash", icon: "trash", section: .trash, badge: storage.trashedProjects.count)
            }
            .padding(.horizontal, 10)

            Spacer()

            HalftoneEdgeStrip(ink: Self.accent, height: 12)
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
        }
        .background(Self.paper)
    }

    private func navItem(title: String, icon: String, section: DashboardSection, badge: Int = 0) -> some View {
        let isActive = selectedSection == section
        return Button(action: {
            selectedSection = section
            selectedProjectIds.removeAll()
            isSelectionMode = false
        }) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .frame(width: 20)
                Text(title)
                    .font(.system(size: 13, weight: isActive ? .semibold : .medium, design: .serif))
                Spacer()
                if badge > 0 {
                    Text("\(badge)")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Self.accent)
                        .clipShape(Capsule())
                }
            }
            .foregroundColor(isActive ? Self.accent : Self.ink.opacity(0.75))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(isActive ? Self.accent.opacity(0.12) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        ZStack {
            // Centered search pill
            HStack {
                Spacer()
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    TextField("Search templates, designs, or keywords…", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .focused($searchFocused)
                    Text("⌘K")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(width: 430)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.secondary.opacity(0.18), lineWidth: 1))
                Spacer()
            }

            // Actions stay pinned right without shifting the centered search
            HStack {
                Spacer()
                Button(action: openCanvaImportPicker) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.down")
                        Text("Import")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Self.accent.opacity(0.1))
                    .foregroundColor(Self.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Self.accent.opacity(0.45), lineWidth: 1))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Import PowerPoint (.pptx), Canva PDF, SVG, ZIP, or Image")

                Button(action: { showCustomSizeModal = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                        Text("Custom Size")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Self.accent)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 6)
    }

    // MARK: - Hero Banner

    private var heroBanner: some View {
        ZStack(alignment: .leading) {
            // Warm paper gradient + halftone press-field on the right edge
            RoundedRectangle(cornerRadius: 18)
                .fill(LinearGradient(
                    colors: [PlumaTheme.dynamic(light: "#FDF9F2", dark: "#262220"), PlumaTheme.dynamic(light: "#F7E7D8", dark: "#33251D")],
                    startPoint: .leading, endPoint: .trailing
                ))
            HalftonePatternView(
                ink: Self.accent.opacity(0.25),
                spacing: 10,
                maxRadius: 2.6,
                ramp: .linear(angle: 180, from: 0.85, to: 0.0)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))

            HStack {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Bring your ideas to life")
                        .font(.system(size: 30, weight: .bold, design: .serif))
                        .foregroundColor(Self.ink)

                    Text("Beautiful templates for thinking, planning, and presenting — all in one place.")
                        .font(.system(size: 13.5))
                        .foregroundColor(Self.ink.opacity(0.65))

                    HStack(spacing: 14) {
                        featureChip(icon: "wifi.slash", label: "Works offline")
                        featureChip(icon: "square.and.arrow.down", label: "Opens PowerPoint & Canva")
                        featureChip(icon: "square.and.arrow.up", label: "PNG · PDF · SVG · PPTX")
                        featureChip(icon: "sparkles", label: "AI bridge for Claude")
                    }
                    .padding(.top, 6)
                }
                .padding(.leading, 30)

                Spacer()

                heroIllustration
                    .padding(.trailing, 34)
            }
        }
        .frame(height: 190)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Self.accent.opacity(0.12), lineWidth: 1))
    }

    private func featureChip(icon: String, label: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Self.accent)
                .frame(width: 24, height: 24)
                .background(Self.accent.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 7))
            Text(label)
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundColor(Self.ink.opacity(0.8))
        }
    }

    /// Three overlapping mini artboards + a hand-drawn annotation — the
    /// "plan → visualize → create" motif from the brand illustration.
    private var heroIllustration: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .frame(width: 110, height: 80)
                .rotationEffect(.degrees(-9))
                .offset(x: -52, y: -6)
                .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
                .overlay(
                    VStack(spacing: 5) {
                        ForEach(0..<3, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(hex: "#E7E2D8"))
                                .frame(width: 60, height: 6)
                        }
                    }
                    .offset(x: -52, y: -6)
                    .rotationEffect(.degrees(-9))
                )

            RoundedRectangle(cornerRadius: 10)
                .fill(Self.accent)
                .frame(width: 110, height: 80)
                .rotationEffect(.degrees(7))
                .offset(x: 44, y: 8)
                .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)

            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .frame(width: 120, height: 86)
                .rotationEffect(.degrees(-2))
                .shadow(color: .black.opacity(0.10), radius: 8, x: 0, y: 4)
                .overlay(
                    VStack(alignment: .leading, spacing: 6) {
                        RoundedRectangle(cornerRadius: 2).fill(Self.accent.opacity(0.8)).frame(width: 40, height: 7)
                        RoundedRectangle(cornerRadius: 2).fill(Color(hex: "#E7E2D8")).frame(width: 74, height: 6)
                        RoundedRectangle(cornerRadius: 2).fill(Color(hex: "#E7E2D8")).frame(width: 58, height: 6)
                        RoundedRectangle(cornerRadius: 2).fill(Self.amber.opacity(0.7)).frame(width: 30, height: 6)
                    }
                    .padding(.leading, 14)
                    .rotationEffect(.degrees(-2))
                    .frame(width: 120, height: 86, alignment: .leading)
                )

            VStack(spacing: 0) {
                Image(systemName: "arrow.down.left")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Self.accent)
                Text("Plan · Visualize · Create")
                    .font(.system(size: 12, weight: .semibold))
                    .italic()
                    .foregroundColor(Self.accent)
            }
            .rotationEffect(.degrees(-5))
            .offset(x: 62, y: -54)
        }
        .frame(width: 230, height: 140)
    }

    // MARK: - Section Headers

    private func sectionHeader(title: String, subtitle: String, linkTitle: String? = nil, linkAction: (() -> Void)? = nil) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 17, weight: .bold, design: .serif))
                    .foregroundColor(Self.ink)
                Text(subtitle)
                    .font(.system(size: 11.5))
                    .foregroundColor(.secondary)
            }
            Spacer()
            if let linkTitle = linkTitle, let linkAction = linkAction {
                Button(action: linkAction) {
                    HStack(spacing: 4) {
                        Text(linkTitle)
                            .font(.system(size: 12, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(Self.accent)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Create New Design

    private var createNewSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                title: "Create New Design",
                subtitle: "Start from a blank canvas in any size.",
                linkTitle: "See all templates",
                linkAction: { selectedSection = .templates }
            )

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
                presetCard(title: "Whiteboard", size: "Infinite canvas", icon: "infinity", w: 3600, h: 2400)
                presetCard(title: "A4 Document", size: "1240 × 1754", icon: "doc.text.fill", w: 1240, h: 1754)
                presetCard(title: "Resume / CV", size: "1240 × 1754", icon: "person.text.rectangle.fill", w: 1240, h: 1754)
                presetCard(title: "Presentation 16:9", size: "1920 × 1080", icon: "tv.fill", w: 1920, h: 1080)
                presetCard(title: "Instagram Post", size: "1080 × 1080", icon: "camera.fill", w: 1080, h: 1080)
                presetCard(title: "Story / TikTok", size: "1080 × 1920", icon: "iphone", w: 1080, h: 1920)
                presetCard(title: "YouTube Thumb", size: "1280 × 720", icon: "play.rectangle.fill", w: 1280, h: 720)
                presetCard(title: "Code Snippet", size: "1200 × 675", icon: "chevron.left.forwardslash.chevron.right", w: 1200, h: 675, isCode: true)
            }
        }
    }

    private func presetCard(title: String, size: String, icon: String, w: Double, h: Double, isCode: Bool = false) -> some View {
        Button(action: {
            // "Blank canvas" means blank — the whiteboard card used to open the
            // Product Strategy mindmap template instead.
            createNewProject(width: w, height: h, name: title, isCode: isCode)
        }) {
            VStack(alignment: .leading, spacing: 0) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(Self.accent)
                    .frame(width: 42, height: 42)
                    .background(Self.accent.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 14)

                Spacer()

                Text(title)
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack {
                    Text(size)
                        .font(.system(size: 9.5, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Self.accent)
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 12)
            .frame(height: 118)
            .frame(maxWidth: .infinity)
            .background(
                ZStack(alignment: .topTrailing) {
                    Color(nsColor: .controlBackgroundColor)
                    HalftonePatternView(
                        ink: Self.accent.opacity(0.16),
                        spacing: 8,
                        maxRadius: 1.8,
                        ramp: .linear(angle: 135, from: 0.75, to: 0.0)
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.16), lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Starter Templates

    private var starterTemplatesStrip: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                title: "Starter Templates",
                subtitle: "Jump-start your work with curated templates.",
                linkTitle: "Browse all templates",
                linkAction: { selectedSection = .templates }
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(starterTemplates) { template in
                        templateCard(template)
                            .frame(width: 190)
                    }
                }
            }
        }
    }

    private var allTemplatesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                title: "All Templates",
                subtitle: "\(filteredTemplates.count) curated templates for boards, resumes, and decks."
            )

            ForEach(groupedTemplates, id: \.category) { group in
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(group.category.uppercased())
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color(hex: "#D97706"))
                            .tracking(1.4)
                        Spacer()
                        Text("\(group.items.count) \(group.items.count == 1 ? "template" : "templates")")
                            .font(.system(size: 10.5, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 190), spacing: 16)], spacing: 18) {
                        ForEach(group.items) { template in
                            templateCard(template)
                        }
                    }
                }
            }
        }
    }

    /// Template card: REAL page thumbnail + title + category.
    private func templateCard(_ template: CanvasTemplate) -> some View {
        Button(action: { openTemplate(template) }) {
            VStack(alignment: .leading, spacing: 7) {
                ZStack {
                    Color.white
                    PageThumbnail(page: template.page, targetWidth: 380)
                        .padding(5)
                }
                .frame(height: 120)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.secondary.opacity(0.16), lineWidth: 1))
                .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)

                Text(template.title)
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(template.category)
                    .font(.system(size: 10.5))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Recent Designs

    private var recentsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Recent Designs")
                        .font(.system(size: 17, weight: .bold, design: .serif))
                        .foregroundColor(Self.ink)
                    Text("Your latest work, ready to continue.")
                        .font(.system(size: 11.5))
                        .foregroundColor(.secondary)
                }

                Spacer()

                if !selectedProjectIds.isEmpty {
                    selectionToolbar
                } else {
                    HStack(spacing: 8) {
                        // Grid / List toggle
                        HStack(spacing: 0) {
                            viewModeButton(icon: "square.grid.2x2", mode: .grid)
                            viewModeButton(icon: "list.bullet", mode: .list)
                        }
                        .background(Color.secondary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                        .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.secondary.opacity(0.14), lineWidth: 1))

                        // Sort menu
                        Menu {
                            ForEach([RecentsSort.lastEdited, .name, .oldest], id: \.self) { mode in
                                Button(action: { recentsSort = mode }) {
                                    HStack {
                                        Text(mode.rawValue)
                                        if recentsSort == mode { Image(systemName: "checkmark") }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Text(recentsSort == .lastEdited ? "All designs" : recentsSort.rawValue)
                                    .font(.system(size: 11.5, weight: .medium))
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 8, weight: .bold))
                            }
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.secondary.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                            .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.secondary.opacity(0.14), lineWidth: 1))
                        }
                        .menuStyle(.borderlessButton)

                        Button(action: { isSelectionMode.toggle() }) {
                            HStack(spacing: 4) {
                                Image(systemName: isSelectionMode ? "checkmark.circle.fill" : "checkmark.circle")
                                Text(isSelectionMode ? "Done" : "Select")
                            }
                            .font(.system(size: 11.5, weight: .medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(isSelectionMode ? Self.accent.opacity(0.15) : Color.secondary.opacity(0.08))
                            .foregroundColor(isSelectionMode ? Self.accent : .secondary)
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if filteredProjects.isEmpty {
                emptyState(icon: "doc.richtext", title: searchText.isEmpty ? "No designs yet" : "No matches", detail: searchText.isEmpty ? "Create your first design above." : "Try a different search.")
            } else if recentsViewMode == .grid {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 210), spacing: 16)], spacing: 18) {
                    ForEach(filteredProjects) { item in
                        projectCard(item)
                    }
                }
            } else {
                VStack(spacing: 8) {
                    ForEach(filteredProjects) { item in
                        projectRow(item)
                    }
                }
            }
        }
    }

    private func viewModeButton(icon: String, mode: RecentsViewMode) -> some View {
        Button(action: { recentsViewMode = mode }) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(recentsViewMode == mode ? Self.accent : .secondary)
                .frame(width: 28, height: 24)
                .background(recentsViewMode == mode ? Self.accent.opacity(0.14) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var selectionToolbar: some View {
        HStack(spacing: 8) {
            Text("\(selectedProjectIds.count) selected")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Self.accent)

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

            Button(action: { showDeleteConfirmation = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "trash.fill")
                    Text("Trash (\(selectedProjectIds.count))")
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
    }

    // MARK: - Project Cards

    private func projectCard(_ item: SavedProjectSummary) -> some View {
        let isSelected = selectedProjectIds.contains(item.id)

        return VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                Color.white
                PageThumbnail(page: item.firstPage, targetWidth: 440)
                    .padding(6)

                selectionCheckbox(isSelected: isSelected) { toggleProjectSelection(item.id) }
                    .padding(8)
            }
            .frame(height: 130)
            .frame(maxWidth: .infinity)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Text("Edited \(item.formattedDate)")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                Spacer()
                projectMenu(item)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Self.accent : Color.secondary.opacity(0.16), lineWidth: isSelected ? 2 : 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
        .contentShape(Rectangle())
        .onTapGesture {
            if isSelectionMode || !selectedProjectIds.isEmpty {
                toggleProjectSelection(item.id)
            } else {
                openProject(id: item.id)
            }
        }
    }

    private func projectRow(_ item: SavedProjectSummary) -> some View {
        let isSelected = selectedProjectIds.contains(item.id)

        return HStack(spacing: 12) {
            ZStack {
                Color.white
                PageThumbnail(page: item.firstPage, targetWidth: 150)
                    .padding(3)
            }
            .frame(width: 72, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.14), lineWidth: 1))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Text("\(item.dimensionsString) · \(item.pageCount) \(item.pageCount == 1 ? "page" : "pages")")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("Edited \(item.formattedDate)")
                .font(.system(size: 10.5))
                .foregroundColor(.secondary)

            selectionCheckbox(isSelected: isSelected) { toggleProjectSelection(item.id) }

            projectMenu(item)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Self.accent : Color.secondary.opacity(0.14), lineWidth: isSelected ? 2 : 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if isSelectionMode || !selectedProjectIds.isEmpty {
                toggleProjectSelection(item.id)
            } else {
                openProject(id: item.id)
            }
        }
    }

    private func selectionCheckbox(isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isSelected ? Self.accent : Color.white.opacity(0.9))
                    .frame(width: 20, height: 20)
                    .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Circle()
                        .stroke(Color.secondary.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 16, height: 16)
                }
            }
            .frame(width: 26, height: 26)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity((isSelectionMode || !selectedProjectIds.isEmpty || isSelected) ? 1.0 : 0.5)
    }

    private func projectMenu(_ item: SavedProjectSummary) -> some View {
        Menu {
            Button("Open") { openProject(id: item.id) }
            Button("Duplicate") { _ = storage.duplicateProject(id: item.id) }
            Button(selectedProjectIds.contains(item.id) ? "Deselect" : "Select") { toggleProjectSelection(item.id) }
            Divider()
            Button("Move to Trash", role: .destructive) { storage.deleteProject(id: item.id) }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .frame(width: 26, height: 26)
                .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
    }

    // MARK: - Trash

    private var trashSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Trash")
                        .font(.system(size: 17, weight: .bold, design: .serif))
                        .foregroundColor(Self.ink)
                    Text("Deleted designs live here until you remove them forever.")
                        .font(.system(size: 11.5))
                        .foregroundColor(.secondary)
                }
                Spacer()
                if !storage.trashedProjects.isEmpty {
                    Button(action: { showEmptyTrashConfirmation = true }) {
                        HStack(spacing: 5) {
                            Image(systemName: "trash.slash")
                            Text("Empty Trash")
                                .font(.system(size: 11.5, weight: .semibold))
                        }
                        .foregroundColor(.red)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }

            if filteredTrash.isEmpty {
                emptyState(icon: "trash", title: "Trash is empty", detail: "Deleted designs will show up here.")
            } else {
                VStack(spacing: 8) {
                    ForEach(filteredTrash) { item in
                        trashRow(item)
                    }
                }
            }
        }
    }

    private func trashRow(_ item: SavedProjectSummary) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Color.white
                PageThumbnail(page: item.firstPage, targetWidth: 150)
                    .padding(3)
            }
            .frame(width: 72, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.14), lineWidth: 1))
            .opacity(0.7)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Text("\(item.dimensionsString) · deleted \(item.formattedDate)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button("Restore") { storage.restoreProject(id: item.id) }
                .font(.system(size: 11, weight: .semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Self.accent.opacity(0.1))
                .foregroundColor(Self.accent)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .buttonStyle(.plain)

            Button("Delete Forever") { storage.deletePermanently(id: item.id) }
                .font(.system(size: 11, weight: .semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.red.opacity(0.1))
                .foregroundColor(.red)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.secondary.opacity(0.14), lineWidth: 1))
    }

    // MARK: - Shared Bits

    private func emptyState(icon: String, title: String, detail: String) -> some View {
        VStack(spacing: 10) {
            HalftonePatternView(
                ink: Self.accent.opacity(0.3),
                spacing: 9,
                maxRadius: 2.4,
                ramp: .uniform(0.55)
            )
            .frame(width: 72, height: 44)
            .mask(Image(systemName: icon).resizable().aspectRatio(contentMode: .fit).frame(width: 40, height: 40))

            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .serif))
                .foregroundColor(.primary)
            Text(detail)
                .font(.system(size: 11.5))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 44)
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
        panel.allowedContentTypes = DocumentImportService.allowedContentTypes
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = "Select a PowerPoint (.pptx), Canva PDF, SVG, ZIP, or Image file to import into Pluma"

        if panel.runModal() == .OK, let url = panel.url {
            DocumentImportService.shared.importDocument(from: url) { project in
                if let project {
                    storage.saveProject(project)
                    self.activeProject = project
                    self.isShowingDashboard = false
                } else {
                    DocumentImportService.shared.showFailureAlert(file: url.lastPathComponent)
                }
            }
        }
    }

    // MARK: - Custom Size Sheet

    private var customSizeSheet: some View {
        VStack(spacing: 16) {
            Text("Custom Size")
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

            let isValid = (16...20000).contains(customW) && (16...20000).contains(customH)
            if !isValid {
                Text("Width and height must be between 16 and 20,000 px.")
                    .font(.system(size: 11))
                    .foregroundColor(PlumaTheme.danger)
            }

            HStack(spacing: 12) {
                Button("Cancel") { showCustomSizeModal = false }
                    .keyboardShortcut(.cancelAction)
                Button("Create Design") {
                    createNewProject(width: customW.rounded(), height: customH.rounded(), name: "Custom \(Int(customW)) × \(Int(customH))")
                    showCustomSizeModal = false
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(!isValid)
            }
        }
        .padding(24)
        .frame(width: 360)
    }
}

/// Async page thumbnail backed by `PageThumbnailService` (fingerprint-keyed
/// cache + off-main render). Re-renders automatically when page content changes.
private struct PageThumbnail: View {
    let page: CanvasPage
    var targetWidth: CGFloat = 340
    @State private var image: NSImage? = nil

    var body: some View {
        Group {
            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                PlumaTheme.workspace
            }
        }
        .task(id: PageThumbnailService.fingerprint(of: page)) {
            PageThumbnailService.shared.thumbnailAsync(for: page, targetWidth: targetWidth) { img in
                self.image = img
            }
        }
    }
}
