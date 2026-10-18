import SwiftUI
import AppKit

public struct PagesTabView: View {
    @ObservedObject var viewModel: CanvasDocumentViewModel

    public init(viewModel: CanvasDocumentViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header — layout mode (Slide / Document / Whiteboard) lives in the
            // toolbar layout menu, so it is not duplicated here.
            SidebarPanelHeader("Pages") {
                Text(viewModel.project.pages.count == 1 ? "1 page" : "\(viewModel.project.pages.count) pages")
                    .font(PlumaTheme.numeric(11, weight: .regular))
                    .foregroundColor(.secondary)
            }

            Button(action: {
                viewModel.addPage()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Add Page")
                        .font(PlumaTheme.label(12, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 3)
                .foregroundColor(PlumaTheme.accentOnSoft)
            }
            .buttonStyle(HoverPillButtonStyle(cornerRadius: 7, tint: PlumaTheme.accent))
            .help("Add a page at the end")
            .padding(.horizontal, 14)
            .padding(.top, 8)
            .padding(.bottom, 12)

            Rectangle().fill(PlumaTheme.hairline).frame(height: 1)

            // Page Cards List
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: 10) {
                    ForEach(Array(viewModel.project.pages.enumerated()), id: \.element.id) { index, page in
                        pageCardView(index: index, page: page)
                    }
                }
                .padding(14)
            }
            // Re-render thumbnails shortly after any confirmed change (move/resize/rotate
            // commit, text edit, undo, delete…) so the mini previews always reflect reality.
            // Skipped while a gesture streams: the debounced refresh fires on commit.
            .onChange(of: viewModel.project) { _, _ in
                guard !viewModel.isLiveTransforming else { return }
                scheduleThumbnailRefresh()
            }
            .onChange(of: viewModel.isLiveTransforming) { _, isLive in
                if !isLive {
                    scheduleThumbnailRefresh()
                }
            }
        }
    }

    // MARK: - Thumbnail State & Refresh

    @State private var cardThumbnails: [UUID: NSImage] = [:]
    @State private var cardFingerprints: [UUID: Int] = [:]
    @State private var thumbnailRefreshTask: Task<Void, Never>? = nil

    /// Debounced: waits for transforms to settle (e.g. drag released), then re-renders
    /// only pages whose content actually changed.
    private func scheduleThumbnailRefresh() {
        thumbnailRefreshTask?.cancel()
        thumbnailRefreshTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            for page in viewModel.project.pages {
                let fp = PageThumbnailService.fingerprint(of: page)
                if cardFingerprints[page.id] != fp {
                    requestThumbnail(for: page, fingerprint: fp)
                }
            }
        }
    }

    private func requestThumbnail(for page: CanvasPage, fingerprint: Int? = nil) {
        let fp = fingerprint ?? PageThumbnailService.fingerprint(of: page)
        cardFingerprints[page.id] = fp
        PageThumbnailService.shared.thumbnailAsync(for: page, targetWidth: 210) { img in
            guard let img = img else { return }
            self.cardThumbnails[page.id] = img
        }
    }

    private func pageCardView(index: Int, page: CanvasPage) -> some View {
        let isCurrent = viewModel.activePageIndex == index
        let thumbAspect = page.height / max(1, page.width)
        let thumbH = min(190, max(56, 210 * thumbAspect))

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                // Page Number Badge
                Text("\(index + 1)")
                    .font(PlumaTheme.numeric(11, weight: .semibold))
                    .foregroundColor(isCurrent ? .white : .secondary)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(isCurrent ? PlumaTheme.accent : PlumaTheme.control))

                // Page Name Field
                TextField("Page \(index + 1)", text: Binding(
                    get: { page.name },
                    set: { newName in
                        // renamePage persists; a direct pages[] write never reached disk.
                        viewModel.renamePage(at: index, to: newName)
                    }
                ))
                .textFieldStyle(.plain)
                .font(PlumaTheme.label(12, weight: isCurrent ? .semibold : .regular))

                Spacer()

                // Actions Menu
                HStack(spacing: 2) {
                    // Move Up Button
                    if index > 0 {
                        Button(action: { viewModel.movePageUp(at: index) }) {
                            Image(systemName: "chevron.up")
                                .font(.system(size: 9, weight: .bold))
                                .frame(width: 20, height: 20)
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(HoverIconButtonStyle(side: 20, cornerRadius: 5))
                        .help("Move Page Up")
                    }

                    // Move Down Button
                    if index < viewModel.project.pages.count - 1 {
                        Button(action: { viewModel.movePageDown(at: index) }) {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 9, weight: .bold))
                                .frame(width: 20, height: 20)
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(HoverIconButtonStyle(side: 20, cornerRadius: 5))
                        .help("Move Page Down")
                    }

                    // Duplicate Button
                    Button(action: { viewModel.duplicatePage(at: index) }) {
                        Image(systemName: "plus.square.on.square")
                            .font(.system(size: 10))
                            .frame(width: 20, height: 20)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(HoverIconButtonStyle(side: 20, cornerRadius: 5))
                    .help("Duplicate Page")

                    // Delete Button
                    if viewModel.project.pages.count > 1 {
                        Button(action: { viewModel.deletePage(at: index) }) {
                            Image(systemName: "trash")
                                .font(.system(size: 10))
                                .frame(width: 20, height: 20)
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(HoverIconButtonStyle(side: 20, cornerRadius: 5))
                        .help("Delete Page")
                    }
                }
            }

            // Live page thumbnail (Canva-style mini preview)
            ZStack {
                if let img = cardThumbnails[page.id] {
                    Image(nsImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Rectangle()
                        .fill(PlumaTheme.control)
                        .overlay(
                            ProgressView()
                                .controlSize(.small)
                        )
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: thumbH)
            .background(PlumaTheme.workspace)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(
                        isCurrent ? PlumaTheme.accent.opacity(0.8) : PlumaTheme.hairline,
                        lineWidth: isCurrent ? 2 : 1
                    )
            )

            // Thumbnail / Dimensions info
            HStack {
                Text("\(Int(page.width)) × \(Int(page.height))")
                    .font(PlumaTheme.numeric(10.5, weight: .regular))

                Spacer()

                Text(page.elements.count == 1 ? "1 element" : "\(page.elements.count) elements")
                    .font(PlumaTheme.label(10.5, weight: .regular))
            }
            .foregroundColor(.secondary)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isCurrent ? PlumaTheme.accentSoft : PlumaTheme.control)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            guard hovering else { return }
            requestThumbnail(for: page)
        }
        .onAppear {
            requestThumbnail(for: page)
        }
        .onTapGesture {
            viewModel.scrollToPage(index: index)
        }
    }
}
