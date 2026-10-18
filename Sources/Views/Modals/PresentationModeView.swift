import SwiftUI

public struct PresentationModeView: View {
    @ObservedObject var viewModel: CanvasDocumentViewModel
    @State private var keyMonitor: Any?
    @State private var enteredFullScreen = false
    @State private var showChrome = true
    @State private var chromeHideTask: Task<Void, Never>?

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Centered Canvas Artboard scaled to fit screen
            GeometryReader { geometry in
                let page = viewModel.currentPage
                let padding: CGFloat = 40
                let wRatio = (geometry.size.width - padding) / page.width
                let hRatio = (geometry.size.height - padding) / page.height
                let scale = min(wRatio, hRatio)

                ZStack {
                    if page.isTransparent {
                        TransparencyCheckerboard()
                    } else {
                        switch page.background.type {
                        case .solid, .newsprint:
                            Rectangle().fill(page.background.solidColor.color)
                        case .kraft:
                            Rectangle().fill(page.background.solidColor.color)
                                .overlay(KraftFiberTextureView())
                        case .vintageParchment:
                            Rectangle().fill(page.background.solidColor.color)
                                .overlay(ParchmentTextureView())
                        case .graphPaper:
                            Rectangle().fill(page.background.solidColor.color)
                                .overlay(DraftingGridPatternView())
                        case .linearGradient:
                            let angleRad = page.background.gradientAngle * .pi / 180.0
                            let startPoint = UnitPoint(x: 0.5 - 0.5 * cos(angleRad), y: 0.5 - 0.5 * sin(angleRad))
                            let endPoint = UnitPoint(x: 0.5 + 0.5 * cos(angleRad), y: 0.5 + 0.5 * sin(angleRad))
                            let gradient = Gradient(stops: page.background.gradientStops.map {
                                Gradient.Stop(color: $0.color.color, location: CGFloat($0.location))
                            })
                            Rectangle().fill(LinearGradient(gradient: gradient, startPoint: startPoint, endPoint: endPoint))
                        case .radialGradient:
                            let gradient = Gradient(stops: page.background.gradientStops.map {
                                Gradient.Stop(color: $0.color.color, location: CGFloat($0.location))
                            })
                            Rectangle().fill(RadialGradient(gradient: gradient, center: .center, startRadius: 0, endRadius: max(page.width, page.height) / 1.5))
                        case .glass:
                            Rectangle().fill(page.background.solidColor.color)
                        case .pattern:
                            Rectangle().fill(page.background.solidColor.color)
                                .overlay(PatternFillView(fill: page.background))
                        }
                    }

                    // Elements
                    ForEach(page.elements.sorted(by: { $0.zIndex < $1.zIndex })) { element in
                        if element.isVisible {
                            ElementRendererView(element: element)
                                .position(x: element.x + element.width / 2, y: element.y + element.height / 2)
                        }
                    }
                }
                .frame(width: page.width, height: page.height)
                .clipShape(Rectangle())
                .scaleEffect(scale)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }

            // Click anywhere to advance (Keynote-style)
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { step(1) }
                .onHover { _ in revealChrome() }

            // Controls: fade out after a moment, return on mouse movement
            VStack {
                HStack {
                    Spacer()
                    Button(action: exit) {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.white.opacity(0.15)))
                    }
                    .buttonStyle(.plain)
                    .help("Exit presentation (Esc)")
                    .padding(20)
                }
                Spacer()
                HStack(spacing: 14) {
                    Button(action: { step(-1) }) {
                        Image(systemName: "chevron.left").frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.activePageIndex == 0)

                    Text("\(viewModel.activePageIndex + 1) / \(viewModel.project.pages.count)")
                        .font(PlumaTheme.numeric(13))

                    Button(action: { step(1) }) {
                        Image(systemName: "chevron.right").frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.activePageIndex >= viewModel.project.pages.count - 1)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.white.opacity(0.12)))
                .padding(.bottom, 24)
            }
            .opacity(showChrome ? 1 : 0)
            .animation(.easeInOut(duration: 0.25), value: showChrome)
        }
        .onAppear {
            viewModel.deselectAll()
            installKeyMonitor()
            revealChrome()
            if let window = NSApp.keyWindow, !window.styleMask.contains(.fullScreen) {
                window.toggleFullScreen(nil)
                enteredFullScreen = true
            }
        }
        .onDisappear {
            if let m = keyMonitor { NSEvent.removeMonitor(m) }
            keyMonitor = nil
            chromeHideTask?.cancel()
            if enteredFullScreen, let window = NSApp.keyWindow, window.styleMask.contains(.fullScreen) {
                window.toggleFullScreen(nil)
            }
        }
    }

    private func step(_ delta: Int) {
        let target = viewModel.activePageIndex + delta
        guard viewModel.project.pages.indices.contains(target) else { return }
        withAnimation(.easeInOut(duration: 0.2)) { viewModel.activePageIndex = target }
        revealChrome()
    }

    private func exit() {
        viewModel.isPresentingFullscreen = false
    }

    private func revealChrome() {
        showChrome = true
        chromeHideTask?.cancel()
        chromeHideTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            if !Task.isCancelled { showChrome = false }
        }
    }

    /// The canvas shortcut monitor stands down while presenting; this one
    /// drives the deck: → / Space / Return / PgDn advance, ← / PgUp go back,
    /// Home / End jump, Esc exits.
    private func installKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            switch event.keyCode {
            case 124, 125, 49, 36, 121: step(1); return nil        // → ↓ space return pgdn
            case 123, 126, 116, 51: step(-1); return nil           // ← ↑ pgup delete
            case 115: step(-viewModel.activePageIndex); return nil // home
            case 119: step(viewModel.project.pages.count - 1 - viewModel.activePageIndex); return nil // end
            case 53: exit(); return nil                            // esc
            default: return event
            }
        }
    }
}
