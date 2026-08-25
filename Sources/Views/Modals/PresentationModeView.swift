import SwiftUI

public struct PresentationModeView: View {
    @ObservedObject var viewModel: CanvasDocumentViewModel
    @Environment(\.dismiss) private var dismiss

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
                        case .glass, .pattern:
                            Rectangle().fill(page.background.solidColor.color)
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

            // Top-right close button
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        viewModel.isPresentingFullscreen = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(20)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.escape, modifiers: [])
                }
                Spacer()
            }
        }
    }
}
