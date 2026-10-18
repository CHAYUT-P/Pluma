import SwiftUI

/// Inspector content when nothing is selected: page size, background, guides.
public struct PageSettingsSection: View {
    @ObservedObject var viewModel: CanvasDocumentViewModel
    /// Background color drags fire continuously — record one undo step per drag.
    @State private var lastColorEdit: Date = .distantPast

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Page")
                .font(PlumaTheme.title(15))

            section("Size") {
                HStack(spacing: 8) {
                    dimensionField("W", value: viewModel.currentPage.width) { viewModel.setCurrentPageSize(width: $0) }
                    dimensionField("H", value: viewModel.currentPage.height) { viewModel.setCurrentPageSize(height: $0) }
                }
                Button("Choose a preset size…") { viewModel.showPresetPickerModal = true }
                    .buttonStyle(.link)
                    .font(PlumaTheme.label(11))
            }

            section("Background") {
                Toggle("Transparent", isOn: Binding(
                    get: { viewModel.currentPage.isTransparent },
                    set: { val in
                        viewModel.saveHistoryState()
                        viewModel.currentPage.isTransparent = val
                    }
                ))
                .font(PlumaTheme.label(12, weight: .regular))

                if !viewModel.currentPage.isTransparent {
                    HStack(spacing: 8) {
                        CanvaColorButton(
                            color: Binding(
                                get: { viewModel.currentPage.background.solidColor },
                                set: { col in
                                    if Date().timeIntervalSince(lastColorEdit) > 0.8 { viewModel.saveHistoryState() }
                                    lastColorEdit = Date()
                                    viewModel.currentPage.background = .solid(col)
                                }
                            ),
                            size: 22
                        )
                        Text(viewModel.currentPage.background.solidColor.hexString)
                            .font(PlumaTheme.numeric(11))
                            .foregroundColor(.secondary)
                    }
                }
            }

            section("Guides") {
                Toggle("Smart guides & snapping", isOn: $viewModel.enableSnapping)
                Toggle("Grid", isOn: $viewModel.showGridOverlay)
                Toggle("Rulers", isOn: $viewModel.showRulers)
            }
            .font(PlumaTheme.label(12, weight: .regular))

            section("Document") {
                infoRow("Pages", "\(viewModel.project.pages.count)")
                infoRow("Elements on this page", "\(viewModel.currentPage.elements.count)")
            }
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        InspectorSection(title, key: "page.\(title.lowercased())", content: content)
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundColor(.secondary)
            Spacer()
            Text(value).font(PlumaTheme.numeric(12))
        }
        .font(PlumaTheme.label(12, weight: .regular))
    }

    private func dimensionField(_ label: String, value: Double, commit: @escaping (Double) -> Void) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(PlumaTheme.label(10, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(width: 12)
            TextField("", value: Binding(get: { value }, set: commit), format: .number.grouping(.never))
                .textFieldStyle(.plain)
                .font(PlumaTheme.numeric(12))
                .padding(.horizontal, 6)
                .frame(height: 24)
                .background(RoundedRectangle(cornerRadius: 5).fill(PlumaTheme.field))
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(PlumaTheme.hairline, lineWidth: 1))
        }
    }
}
