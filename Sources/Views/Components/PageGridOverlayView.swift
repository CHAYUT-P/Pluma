import SwiftUI
import AppKit

// MARK: - Page Overview Grid (Canva-style page thumbnails)
//
// A floating panel showing a scrollable grid of live page thumbnails.
// • Click a thumbnail to jump to that page
// • Hover reveals duplicate / delete quick actions
// • Drag a card onto another to reorder pages
// • Double-click the caption to rename inline
// Opened from the floating page navigation dock (or ⌘K → "Page Grid").

public struct PageGridOverlayView: View {
    @ObservedObject var viewModel: CanvasDocumentViewModel
    let onClose: () -> Void

    @State private var thumbnails: [UUID: NSImage] = [:]
    @State private var fingerprints: [UUID: Int] = [:]
    @State private var hoveringPageID: UUID? = nil
    @State private var draggingPageID: UUID? = nil
    @State private var dropTargetIndex: Int? = nil
    @State private var renamingPageID: UUID? = nil

    private let thumbWidth: CGFloat = 132

    public init(viewModel: CanvasDocumentViewModel, onClose: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            thumbnailGrid
        }
        .frame(width: 620, height: 480)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.secondary.opacity(0.25), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.25), radius: 28, x: 0, y: 12)
        .onAppear(perform: renderThumbnails)
        .onChange(of: viewModel.project) { _, _ in
            // Skip per-tick work while a gesture streams; refresh on commit.
            guard !viewModel.isLiveTransforming else { return }
            renderThumbnails()
        }
        .onChange(of: viewModel.isLiveTransforming) { _, isLive in
            if !isLive {
                renderThumbnails()
            }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "square.grid.2x2.fill")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#C2410C"))

            Text("PAGES")
                .font(.system(size: 12, weight: .bold))
                .tracking(1)
                .foregroundColor(.primary)

            Text("\(viewModel.project.pages.count)")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.secondary)

            Spacer()

            Button(action: { withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { viewModel.addPage() } }) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .bold))
                    Text("Add")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(Color(hex: "#C2410C"))
            }
            .buttonStyle(HoverPillButtonStyle(cornerRadius: 6, tint: Color(hex: "#C2410C")))
            .help("Add New Page")

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(HoverIconButtonStyle(side: 24, cornerRadius: 6))
            .help("Close (Esc)")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var thumbnailGrid: some View {
        ScrollView([.vertical, .horizontal], showsIndicators: true) {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: thumbWidth), spacing: 14)],
                spacing: 16
            ) {
                ForEach(Array(viewModel.project.pages.enumerated()), id: \.element.id) { index, page in
                    pageThumbnailCard(index: index, page: page)
                        .onDrag {
                            draggingPageID = page.id
                            return NSItemProvider(object: page.id.uuidString as NSString)
                        }
                        .onDrop(
                            of: [.text],
                            delegate: PageReorderDropDelegate(
                                grid: self,
                                targetIndex: index
                            )
                        )
                }

                addPageTile
            }
            .padding(16)
        }
    }

    private var addPageTile: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                viewModel.addPage()
            }
        }) {
            VStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold))
                Text("Add page")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundColor(Color(hex: "#C2410C"))
            .frame(width: thumbWidth, height: thumbnailHeight(for: viewModel.currentPage))
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color(hex: "#C2410C").opacity(0.45), style: SwiftUI.StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                    .background(Color(hex: "#C2410C").opacity(0.03))
            )
        }
        .buttonStyle(.plain)
    }

    private func thumbnailHeight(for page: CanvasPage) -> CGFloat {
        let aspect = page.height / max(1, page.width)
        return min(220, max(60, thumbWidth * aspect))
    }

    private func pageThumbnailCard(index: Int, page: CanvasPage) -> some View {
        let isCurrent = viewModel.activePageIndex == index
        let isHovering = hoveringPageID == page.id
        let isDragging = draggingPageID == page.id
        let isDropTarget = dropTargetIndex == index
        let h = thumbnailHeight(for: page)

        return VStack(alignment: .leading, spacing: 6) {
            thumbnailImage(page: page, height: h, isCurrent: isCurrent, isHovering: isHovering, index: index)

            caption(index: index, page: page, isCurrent: isCurrent)
        }
        .opacity(isDragging ? 0.45 : 1.0)
        .scaleEffect(isDropTarget ? 1.04 : 1.0)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(hex: "#C2410C"), lineWidth: 2.5)
                .opacity(isDropTarget ? 0.9 : 0)
        )
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isDropTarget)
    }

    private func thumbnailImage(page: CanvasPage, height h: CGFloat, isCurrent: Bool, isHovering: Bool, index: Int) -> some View {
        ZStack {
            if let img = thumbnails[page.id] {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.secondary.opacity(0.08))
                    .overlay(ProgressView().controlSize(.small))
            }
        }
        .frame(width: thumbWidth, height: h)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(
                    isCurrent ? Color(hex: "#C2410C") : Color.secondary.opacity(0.25),
                    lineWidth: isCurrent ? 2.5 : 1
                )
        )
        .overlay(alignment: .topTrailing) {
            if isHovering && viewModel.project.pages.count > 1 {
                Button(action: { viewModel.deletePage(at: index) }) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(Color.red.opacity(0.9)))
                }
                .buttonStyle(.plain)
                .padding(5)
                .help("Delete Page")
                .transition(.opacity)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if isHovering {
                Button(action: { viewModel.duplicatePage(at: index) }) {
                    Image(systemName: "plus.square.on.square.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(Color.black.opacity(0.65)))
                }
                .buttonStyle(.plain)
                .padding(5)
                .help("Duplicate Page")
                .transition(.opacity)
            }
        }
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) {
                hoveringPageID = hovering ? page.id : (hoveringPageID == page.id ? nil : hoveringPageID)
            }
        }
        .onTapGesture {
            if renamingPageID != page.id {
                viewModel.scrollToPage(index: index)
                onClose()
            }
        }
    }

    @ViewBuilder
    private func caption(index: Int, page: CanvasPage, isCurrent: Bool) -> some View {
        HStack(spacing: 6) {
            Text("\(index + 1)")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(isCurrent ? .white : .secondary)
                .frame(width: 17, height: 17)
                .background(Circle().fill(isCurrent ? Color(hex: "#C2410C") : Color.secondary.opacity(0.15)))

            if renamingPageID == page.id {
                TextField(
                    "Name",
                    text: Binding(
                        get: { page.name },
                        set: { viewModel.renamePage(at: index, to: $0) }
                    ),
                    onCommit: { renamingPageID = nil }
                )
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 10.5, weight: .semibold))
            } else {
                Text(page.name)
                    .font(.system(size: 10.5, weight: isCurrent ? .bold : .medium))
                    .lineLimit(1)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        renamingPageID = page.id
                    }
                    .help("Double-click to rename")
            }
        }
    }

    private func renderThumbnails() {
        for page in viewModel.project.pages {
            let pageID = page.id
            let fp = PageThumbnailService.fingerprint(of: page)
            guard fingerprints[pageID] != fp || thumbnails[pageID] == nil else { continue }
            fingerprints[pageID] = fp
            PageThumbnailService.shared.thumbnailAsync(for: page, targetWidth: thumbWidth) { img in
                if let img = img {
                    thumbnails[pageID] = img
                }
            }
        }
    }

    // MARK: - Drag-to-Reorder

    struct PageReorderDropDelegate: DropDelegate {
        let grid: PageGridOverlayView
        let targetIndex: Int

        func dropEntered(info: DropInfo) {
            guard let sourceID = grid.draggingPageID,
                  let sourceIndex = grid.viewModel.project.pages.firstIndex(where: { $0.id == sourceID }),
                  sourceIndex != targetIndex else {
                grid.dropTargetIndex = targetIndex
                return
            }
            // Live-reorder while hovering (Figma-style preview)
            grid.viewModel.movePage(from: sourceIndex, to: targetIndex)
            grid.dropTargetIndex = targetIndex
        }

        func dropUpdated(info: DropInfo) -> DropProposal? {
            DropProposal(operation: .move)
        }

        func performDrop(info: DropInfo) -> Bool {
            grid.draggingPageID = nil
            grid.dropTargetIndex = nil
            return true
        }

        func dropExited(info: DropInfo) {
            if grid.dropTargetIndex == targetIndex {
                grid.dropTargetIndex = nil
            }
        }
    }
}
