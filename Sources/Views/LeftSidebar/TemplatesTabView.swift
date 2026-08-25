import SwiftUI

public struct TemplatesTabView: View {
    @ObservedObject var viewModel: CanvasDocumentViewModel
    @State private var selectedCategory: String = "All"

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

    private var availableCategories: [String] {
        if isWhiteboard {
            return ["All", "Mindmaps", "Flowcharts", "Sticky Boards"]
        } else if isA4OrPortraitDocument {
            return ["All", "Resumes & CVs", "Documents & Reports", "Creative & Editorial"]
        } else if isPresentation16x9 {
            return ["All", "Decks & Keynotes", "Portfolios", "Exhibitions"]
        } else if isSquare {
            return ["All", "Editorial Zine", "Quotes & Passes", "Scrapbook"]
        } else if isStory {
            return ["All", "Story & Reel", "Countdowns", "Tips"]
        } else {
            return ["All"]
        }
    }

    private var matchingTemplates: [CanvasTemplate] {
        var baseList: [CanvasTemplate] = []

        if isWhiteboard {
            baseList = TemplateCatalog.templates.filter { $0.docType == .whiteboard }
        } else if isA4OrPortraitDocument {
            // Strictly include only A4 and Resume templates
            baseList = TemplateCatalog.templates.filter {
                $0.docType == .a4 || $0.docType == .resume || ($0.page.width == 1240 && $0.page.height == 1754)
            }
        } else if isPresentation16x9 {
            baseList = TemplateCatalog.templates.filter { $0.docType == .presentation }
        } else if isSquare {
            baseList = TemplateCatalog.templates.filter { $0.docType == .square }
        } else if isStory {
            baseList = TemplateCatalog.templates.filter { $0.docType == .story }
        } else {
            baseList = TemplateCatalog.templates
        }

        if selectedCategory == "All" {
            return baseList
        }

        if selectedCategory == "Resumes & CVs" {
            return baseList.filter {
                $0.category == "Resumes & CVs" || $0.docType == .resume || $0.id.contains("resume")
            }
        } else if selectedCategory == "Documents & Reports" {
            return baseList.filter {
                $0.category != "Resumes & CVs" && !$0.id.contains("resume")
            }
        }

        return baseList.filter { $0.category == selectedCategory || $0.themeName == selectedCategory }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("STUDIO TEMPLATES")
                        .font(.system(size: 11, weight: .bold, design: .serif))
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
                        .font(.system(size: 10.5, weight: .semibold, design: .serif))
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
                            HStack(spacing: 4) {
                                if category == "Resumes & CVs" {
                                    Image(systemName: "person.text.rectangle.fill")
                                        .font(.system(size: 9))
                                } else if category == "Documents & Reports" {
                                    Image(systemName: "doc.plaintext.fill")
                                        .font(.system(size: 9))
                                }

                                Text(category)
                                    .font(.system(size: 10, weight: selectedCategory == category ? .bold : .medium, design: .serif))
                            }
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

            // Templates Grid List
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: 12) {
                    ForEach(matchingTemplates) { template in
                        templateCard(template)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 20)
            }
        }
    }

    // MARK: - Template Card View

    private func templateCard(_ template: CanvasTemplate) -> some View {
        Button(action: {
            applyTemplate(template)
        }) {
            VStack(alignment: .leading, spacing: 8) {
                // Miniature Artboard Preview
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: template.previewColorHex).opacity(0.12))
                        .frame(height: 120)

                    VStack(spacing: 4) {
                        Image(systemName: template.category == "Resumes & CVs" || template.id.contains("resume") ? "person.text.rectangle.fill" : "doc.text.fill")
                            .font(.system(size: 26))
                            .foregroundColor(Color(hex: template.previewColorHex))

                        Text(template.title)
                            .font(.system(size: 11, weight: .bold, design: .serif))
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
                            .font(.system(size: 11.5, weight: .bold, design: .serif))
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        Text(template.themeName)
                            .font(.system(size: 10, design: .serif))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text("Use")
                        .font(.system(size: 10.5, weight: .bold, design: .serif))
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
        viewModel.saveHistoryState()
        viewModel.project.name = template.title
        viewModel.project.pages = template.pages
        viewModel.activePageIndex = 0
        viewModel.selectedElementIds.removeAll()
        viewModel.editingTextElementId = nil
        viewModel.editingCodeElementId = nil
        viewModel.showTemporaryToast("Applied \(template.title)")
    }
}
