import SwiftUI
import AppKit

public struct PagesTabView: View {
    @ObservedObject var viewModel: CanvasDocumentViewModel

    public init(viewModel: CanvasDocumentViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "doc.on.doc.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#C2410C"))

                    Text("PAGES & SECTIONS")
                        .font(.system(size: 11.5, weight: .bold, design: .serif))
                        .tracking(0.8)
                        .foregroundColor(.primary)

                    Spacer()

                    Text("\(viewModel.project.pages.count) Pages")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(.secondary)
                }

                // Layout Mode Picker (Document Flow, Single Slide, Whiteboard)
                HStack(spacing: 3) {
                    layoutModeButton(mode: .continuousVertical, label: "Document", icon: "scroll.fill")
                    layoutModeButton(mode: .singleSlide, label: "Slide", icon: "rectangle.split.1x2.fill")
                    layoutModeButton(mode: .infiniteWhiteboard, label: "Board", icon: "brain.head.profile")
                }
                .padding(3)
                .background(Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // Add Page Quick Button
                Button(action: {
                    viewModel.addPage()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 12))
                        Text("Add New Page")
                            .font(.system(size: 12, weight: .semibold, design: .serif))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .foregroundColor(Color(hex: "#C2410C"))
                }
                .buttonStyle(HoverPillButtonStyle(cornerRadius: 7, tint: Color(hex: "#C2410C")))
            }
            .padding(14)
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

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
            .onChange(of: viewModel.project) { _, _ in
                scheduleThumbnailRefresh()
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
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(isCurrent ? .white : .secondary)
                    .frame(width: 22, height: 22)
                    .background(isCurrent ? Color(hex: "#C2410C") : Color.secondary.opacity(0.15))
                    .clipShape(Circle())

                // Page Name Field
                TextField("Page \(index + 1)", text: Binding(
                    get: { page.name },
                    set: { newName in
                        viewModel.project.pages[index].name = newName
                    }
                ))
                .textFieldStyle(.plain)
                .font(.system(size: 12, weight: isCurrent ? .bold : .medium, design: .serif))

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
                        .fill(Color.secondary.opacity(0.07))
                        .overlay(
                            ProgressView()
                                .controlSize(.small)
                        )
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: thumbH)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(
                        isCurrent ? Color(hex: "#C2410C").opacity(0.8) : Color.secondary.opacity(0.2),
                        lineWidth: isCurrent ? 2 : 1
                    )
            )

            // Thumbnail / Dimensions info
            HStack {
                Text("\(Int(page.width)) × \(Int(page.height)) px")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(page.elements.count) elements")
                    .font(.system(size: 10, design: .serif))
                    .foregroundColor(.secondary)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isCurrent ? Color(hex: "#C2410C").opacity(0.08) : Color.secondary.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isCurrent ? Color(hex: "#C2410C").opacity(0.6) : Color.secondary.opacity(0.15), lineWidth: isCurrent ? 1.5 : 1)
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

    private func layoutModeButton(mode: PageLayoutMode, label: String, icon: String) -> some View {
        let isSelected = viewModel.pageLayoutMode == mode

        return Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) {
                viewModel.pageLayoutMode = mode
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 9.5))
                Text(label)
                    .font(.system(size: 10, weight: isSelected ? .bold : .medium, design: .serif))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5.5)
            .foregroundColor(isSelected ? .white : .secondary)
        }
        .buttonStyle(SegmentedSegmentStyle(isSelected: isSelected))
    }
}
