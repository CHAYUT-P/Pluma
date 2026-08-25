import SwiftUI

public struct SmartGuidesOverlayView: View {
    public let guides: [SnappingGuide]
    public let pageSize: CGSize

    public var body: some View {
        Canvas { context, _ in
            for guide in guides {
                var path = Path()
                switch guide.orientation {
                case .horizontal:
                    path.move(to: CGPoint(x: guide.start, y: guide.position))
                    path.addLine(to: CGPoint(x: guide.end, y: guide.position))
                case .vertical:
                    path.move(to: CGPoint(x: guide.position, y: guide.start))
                    path.addLine(to: CGPoint(x: guide.position, y: guide.end))
                }

                context.stroke(
                    path,
                    with: .color(Color(hex: "#EC4899")), // Figma / Canva pink snap guide
                    lineWidth: 1.2
                )
            }
        }
        .frame(width: pageSize.width, height: pageSize.height)
        .allowsHitTesting(false)
    }
}
