import SwiftUI

public struct VisualFontPickerPopover: View {
    @ObservedObject var viewModel: CanvasDocumentViewModel
    let selectedFont: String
    var onSelectFont: ((String) -> Void)? = nil
    @State private var searchText: String = ""
    @State private var selectedFilter: FontLicenseTier? = nil
    @Environment(\.dismiss) private var dismiss

    public init(viewModel: CanvasDocumentViewModel, selectedFont: String, onSelectFont: ((String) -> Void)? = nil) {
        self.viewModel = viewModel
        self.selectedFont = selectedFont
        self.onSelectFont = onSelectFont
    }

    private var filteredFonts: [FontItem] {
        FontCatalog.allFonts.filter { item in
            let matchesSearch = searchText.isEmpty || item.name.localizedCaseInsensitiveContains(searchText) || item.category.localizedCaseInsensitiveContains(searchText)
            let matchesFilter = (selectedFilter == nil) || item.license == selectedFilter
            return matchesSearch && matchesFilter
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Search Header
            VStack(spacing: 6) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    TextField("Search typefaces...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11.5))
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(6)
                .background(Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.12), lineWidth: 1))

                // License Filter Pills
                HStack(spacing: 4) {
                    filterPill(title: "All", count: FontCatalog.allFonts.count, filter: nil)
                    filterPill(title: "Commercial", count: FontCatalog.commercialFonts.count, filter: .commercial)
                    filterPill(title: "Personal", count: FontCatalog.personalFonts.count, filter: .personal)
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 10)

            Divider()

            // Scrollable List where each font name is rendered IN ITS OWN FONT
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(filteredFonts) { font in
                        Button(action: {
                            if let onSelect = onSelectFont {
                                onSelect(font.name)
                            } else {
                                viewModel.updateSelectedElement { elem in
                                    if case .text(var t) = elem.payload {
                                        t.fontFamily = font.name
                                        elem.payload = .text(t)
                                    }
                                }
                            }
                            dismiss()
                        }) {
                            HStack(alignment: .center, spacing: 8) {
                                VStack(alignment: .leading, spacing: 2) {
                                    // Render font name in its own typeface!
                                    Text(font.name)
                                        .font(.custom(font.name, size: 15))
                                        .foregroundColor(selectedFont == font.name ? Color(hex: "#C2410C") : .primary)
                                        .lineLimit(1)

                                    Text(font.category)
                                        .font(.system(size: 9, design: .serif))
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                // License Badge
                                Text(font.license.badgeLabel)
                                    .font(.system(size: 8.5, weight: .bold))
                                    .foregroundColor(font.license == .commercial ? Color(hex: "#10B981") : Color(hex: "#D97706"))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(font.license == .commercial ? Color(hex: "#10B981").opacity(0.12) : Color(hex: "#D97706").opacity(0.12))
                                    .clipShape(Capsule())

                                if selectedFont == font.name {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(Color(hex: "#C2410C"))
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(selectedFont == font.name ? Color(hex: "#C2410C").opacity(0.08) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 10)
            }
        }
        .frame(width: 290, height: 380)
    }

    private func filterPill(title: String, count: Int, filter: FontLicenseTier?) -> some View {
        Button(action: { selectedFilter = filter }) {
            Text("\(title) (\(count))")
                .font(.system(size: 9.5, weight: selectedFilter == filter ? .bold : .regular))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(selectedFilter == filter ? Color(hex: "#C2410C") : Color.secondary.opacity(0.08))
                .foregroundColor(selectedFilter == filter ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
