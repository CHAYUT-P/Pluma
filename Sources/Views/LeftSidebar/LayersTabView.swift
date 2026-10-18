import SwiftUI

public struct LayersTabView: View {
    @ObservedObject var viewModel: CanvasDocumentViewModel
    @State private var editingLayerId: UUID? = nil
    @State private var editingName: String = ""

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("LAYERS (\(viewModel.currentPage.elements.count))")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.primary)
                    .tracking(0.5)

                Spacer()

                if !viewModel.selectedElementIds.isEmpty {
                    Button(action: { viewModel.deleteSelected() }) {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                .hoverHighlight()
                    .help("Delete Selected")
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)

            if viewModel.currentPage.elements.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "square.3.layers.3d.down.right")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary)
                    Text("Clean Sheet")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                List {
                    ForEach(viewModel.currentPage.elements.sorted(by: { $0.zIndex > $1.zIndex })) { element in
                        layerRow(for: element)
                            .listRowInsets(EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6))
                            .listRowBackground(Color.clear)
                    }
                    .onMove(perform: moveLayers)
                }
                .listStyle(.plain)
            }
        }
    }

    private func layerRow(for element: CanvasElement) -> some View {
        let isSelected = viewModel.selectedElementIds.contains(element.id)

        return HStack(spacing: 8) {
            // Drag handle icon
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 10))
                .foregroundColor(.secondary.opacity(0.6))
                .frame(width: 12)

            // Element Type Icon
            Image(systemName: iconForElement(element))
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "#D97706"))
                .frame(width: 16)

            // Layer Name (or rename field)
            if editingLayerId == element.id {
                TextField("Name", text: $editingName, onCommit: {
                    if !editingName.isEmpty {
                        viewModel.updateElement(id: element.id) { $0.name = editingName }
                    }
                    editingLayerId = nil
                })
                .textFieldStyle(.plain)
                .font(.system(size: 11))
            } else {
                Text(element.name)
                    .font(.system(size: 11, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? .primary : .secondary)
                    .lineLimit(1)
                    .onTapGesture(count: 2) {
                        editingLayerId = element.id
                        editingName = element.name
                    }
            }

            Spacer()

            // Quick Layer Up / Down
            HStack(spacing: 2) {
                Button(action: {
                    moveElementUp(id: element.id)
                }) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 20, height: 22)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .hoverHighlight()
                .help("Move Layer Up")

                Button(action: {
                    moveElementDown(id: element.id)
                }) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 20, height: 22)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .hoverHighlight()
                .help("Move Layer Down")
            }

            // Lock Toggle
            Button(action: {
                viewModel.saveHistoryState()
                viewModel.updateElement(id: element.id) { $0.isLocked.toggle() }
            }) {
                Image(systemName: element.isLocked ? "lock.fill" : "lock.open")
                    .font(.system(size: 11))
                    .foregroundColor(element.isLocked ? PlumaTheme.accentWarm : .secondary.opacity(0.5))
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
                .hoverHighlight()

            // Visibility Toggle
            Button(action: {
                viewModel.saveHistoryState()
                viewModel.updateElement(id: element.id) { $0.isVisible.toggle() }
            }) {
                Image(systemName: element.isVisible ? "eye.fill" : "eye.slash")
                    .font(.system(size: 11))
                    .foregroundColor(element.isVisible ? .secondary : PlumaTheme.danger)
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
                .hoverHighlight()
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 8)
        .background(isSelected ? Color(hex: "#C2410C").opacity(0.18) : Color.secondary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? Color(hex: "#C2410C").opacity(0.5) : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            let isShift = NSEvent.modifierFlags.contains(.shift)
            viewModel.selectElement(element, multiSelect: isShift)
        }
    }

    private func moveLayers(from source: IndexSet, to destination: Int) {
        viewModel.saveHistoryState()
        var sorted = viewModel.currentPage.elements.sorted(by: { $0.zIndex > $1.zIndex })
        sorted.move(fromOffsets: source, toOffset: destination)

        let total = sorted.count
        for (i, elem) in sorted.enumerated() {
            if let idx = viewModel.currentPage.elements.firstIndex(where: { $0.id == elem.id }) {
                viewModel.currentPage.elements[idx].zIndex = total - i
            }
        }
    }

    private func moveElementUp(id: UUID) {
        viewModel.saveHistoryState()
        guard let idx = viewModel.currentPage.elements.firstIndex(where: { $0.id == id }) else { return }
        viewModel.currentPage.elements[idx].zIndex += 2
        reindex()
    }

    private func moveElementDown(id: UUID) {
        viewModel.saveHistoryState()
        guard let idx = viewModel.currentPage.elements.firstIndex(where: { $0.id == id }) else { return }
        viewModel.currentPage.elements[idx].zIndex -= 2
        reindex()
    }

    private func reindex() {
        viewModel.currentPage.elements.sort { $0.zIndex < $1.zIndex }
        for i in 0..<viewModel.currentPage.elements.count {
            viewModel.currentPage.elements[i].zIndex = i
        }
    }

    private func iconForElement(_ element: CanvasElement) -> String {
        switch element.payload {
        case .shape: return "seal"
        case .text: return "textformat"
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .image: return "photo"
        case .icon: return "sparkles"
        case .drawing: return "pencil.tip"
        }
    }
}
