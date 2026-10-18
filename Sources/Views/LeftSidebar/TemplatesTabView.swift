import SwiftUI

public struct TemplatesTabView: View {
    @ObservedObject var viewModel: CanvasDocumentViewModel
    @State private var selectedCategory: String = "All"
    /// Template awaiting a replace/append decision (only asked when the
    /// design already has content — one click used to wipe every page).
    @State private var pendingTemplate: CanvasTemplate?

    private var isWhiteboard: Bool {
        (viewModel.currentPage.width >= 2400 && viewModel.currentPage.height >= 1800) || (viewModel.currentPage.width == 3200 && viewModel.currentPage.height == 2000)
    }

    private var isA4OrPortraitDocument: Bool {
        if isWhiteboard { return false }
        let aspect = viewModel.currentPage.width / viewModel.currentPage.height
        return aspect < 0.85 || (viewModel.currentPage.width == 1240 && viewModel.currentPage.height == 1754)
    }

    private var isPresentation16x9: Bool {
        if isWhiteboard { return false }
        let aspect = viewModel.currentPage.width / viewModel.currentPage.height
        return abs(aspect - (16.0 / 9.0)) < 0.1 && viewModel.currentPage.width >= 1500
    }

    private var isSquare: Bool {
        let aspect = viewModel.currentPage.width / viewModel.currentPage.height
        return abs(aspect - 1.0) < 0.1
    }

    private var isStory: Bool {
        let aspect = viewModel.currentPage.width / viewModel.currentPage.height
        return abs(aspect - (9.0 / 16.0)) < 0.1
    }

    private var currentFormatTitle: String {
        if isWhiteboard { return "Whiteboard & Mindmap (Boundless)" }
        if isA4OrPortraitDocument { return "A4 Documents & Resumes" }
        if isPresentation16x9 { return "Presentation (16:9)" }
        if isSquare { return "Instagram / Square" }
        if isStory { return "Story / Reel (9:16)" }
        return "\(Int(viewModel.currentPage.width)) × \(Int(viewModel.currentPage.height))"
    }

    /// Templates matching the current canvas format, in catalog order.
    private var baseTemplates: [CanvasTemplate] {
        if isWhiteboard {
            return TemplateCatalog.templates.filter { $0.docType == .whiteboard }
        } else if isA4OrPortraitDocument {
            // Strictly include only A4 and Resume templates
            return TemplateCatalog.templates.filter {
                $0.docType == .a4 || $0.docType == .resume || ($0.page.width == 1240 && $0.page.height == 1754)
            }
        } else if isPresentation16x9 {
            return TemplateCatalog.templates.filter { $0.docType == .presentation }
        } else if isSquare {
            return TemplateCatalog.templates.filter { $0.docType == .square }
        } else if isStory {
            return TemplateCatalog.templates.filter { $0.docType == .story }
        }
        return TemplateCatalog.templates
    }

    /// Real categories present in the current format's templates — never drifts
    /// out of sync when the catalog grows.
    private var availableCategories: [String] {
        var seen: [String] = []
        for t in baseTemplates where !seen.contains(t.category) {
            seen.append(t.category)
        }
        return ["All"] + seen
    }

    /// Templates grouped by category (catalog order), honouring the active pill.
    /// Falls back to "All" if the selection isn't present in this format.
    private var groupedTemplates: [(category: String, items: [CanvasTemplate])] {
        let valid = selectedCategory == "All" || availableCategories.contains(selectedCategory)
        let list = !valid || selectedCategory == "All"
            ? baseTemplates
            : baseTemplates.filter { $0.category == selectedCategory }
        var order: [String] = []
        var groups: [String: [CanvasTemplate]] = [:]
        for t in list {
            if groups[t.category] == nil {
                order.append(t.category)
                groups[t.category] = []
            }
            groups[t.category]?.append(t)
        }
        return order.map { ($0, groups[$0] ?? []) }
    }

    private var matchingTemplates: [CanvasTemplate] {
        groupedTemplates.flatMap(\.items)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("STUDIO TEMPLATES")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: "#D97706"))
                        .tracking(1.0)
                    Spacer()
                    Text("\(matchingTemplates.count) templates")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 5) {
                    Image(systemName: isA4OrPortraitDocument ? "doc.text.fill" : (isPresentation16x9 ? "tv.fill" : "square.fill"))
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "#C2410C"))

                    Text("Active Canvas: \(currentFormatTitle)")
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)

            // Category Filter Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 5) {
                    ForEach(availableCategories, id: \.self) { category in
                        Button(action: {
                            selectedCategory = category
                        }) {
                            Text(category)
                                .font(.system(size: 10, weight: selectedCategory == category ? .bold : .medium))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4.5)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(selectedCategory == category ? Color(hex: "#C2410C").opacity(0.18) : Color.secondary.opacity(0.08))
                            )
                            .foregroundColor(selectedCategory == category ? Color(hex: "#C2410C") : .secondary)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(selectedCategory == category ? Color(hex: "#C2410C").opacity(0.4) : Color.clear, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                .hoverHighlight()
                    }
                }
                .padding(.horizontal, 14)
            }

            Divider()

            // Templates Grid List — grouped by category
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(groupedTemplates, id: \.category) { group in
                        if selectedCategory == "All" {
                            HStack(alignment: .firstTextBaseline) {
                                Text(group.category.uppercased())
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Color(hex: "#D97706"))
                                    .tracking(1.2)
                                Spacer()
                                Text("\(group.items.count)")
                                    .font(.system(size: 9.5, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 6)
                        }
                        ForEach(group.items) { template in
                            templateCard(template)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 20)
            }
        }
        .confirmationDialog(
            "Use “\(pendingTemplate?.title ?? "")”?",
            isPresented: Binding(get: { pendingTemplate != nil }, set: { if !$0 { pendingTemplate = nil } }),
            titleVisibility: .visible
        ) {
            Button("Add as New Pages") {
                if let t = pendingTemplate { viewModel.appendTemplatePages(t) }
                pendingTemplate = nil
            }
            Button("Replace Current Design", role: .destructive) {
                if let t = pendingTemplate { applyTemplate(t) }
                pendingTemplate = nil
            }
            Button("Cancel", role: .cancel) { pendingTemplate = nil }
        } message: {
            Text("Your design already has content. Replacing it can be undone with ⌘Z.")
        }
    }

    // MARK: - Template Card View

    private func templateCard(_ template: CanvasTemplate) -> some View {
        Button(action: {
            if viewModel.hasDesignContent {
                pendingTemplate = template
            } else {
                applyTemplate(template)
            }
        }) {
            VStack(alignment: .leading, spacing: 8) {
                // Miniature Artboard Preview
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: template.previewColorHex).opacity(0.12))
                        .frame(height: 120)

                    let accent = CodableColor(hex: template.previewColorHex)
                    HalftonePatternView(
                        ink: (accent.isLight ? Color(hex: "#C2410C") : accent.color).opacity(0.35),
                        spacing: 9,
                        maxRadius: 2.2,
                        ramp: .linear(angle: 225, from: 0.8, to: 0.0)
                    )
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(spacing: 4) {
                        Image(systemName: template.category == "Resumes & CVs" || template.id.contains("resume") ? "person.text.rectangle.fill" : "doc.text.fill")
                            .font(.system(size: 26))
                            .foregroundColor(Color(hex: template.previewColorHex))

                        Text(template.title)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        Text("\(template.pages.count) \(template.pages.count > 1 ? "Pages" : "Page") • \(Int(template.page.width)) × \(Int(template.page.height))")
                            .font(.system(size: 9.5, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    .padding(8)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.18), lineWidth: 1)
                )

                // Template Details
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(template.title)
                            .font(.system(size: 11.5, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        Text(template.themeName)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text("Use")
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundColor(Color(hex: "#C2410C"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(hex: "#C2410C").opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            .padding(8)
            .background(Color.secondary.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
                .hoverHighlight()
    }

    private func applyTemplate(_ template: CanvasTemplate) {
        // Canonical path lives on the view model — it also persists the change,
        // syncs the page layout mode, and handles single-page templates.
        viewModel.applyTemplate(template)
    }
}
