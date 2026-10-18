import Foundation
import CoreGraphics

public struct SnappingResult {
    public var snappedOrigin: CGPoint
    public var activeGuides: [SnappingGuide]

    public init(snappedOrigin: CGPoint, activeGuides: [SnappingGuide]) {
        self.snappedOrigin = snappedOrigin
        self.activeGuides = activeGuides
    }
}

public enum SnappingEngine {
    public static let snapThreshold: Double = 6.0

    public static func snap(
        rect: CGRect,
        against others: [CGRect],
        canvasSize: CGSize,
        enableCanvasSnap: Bool = true,
        enableElementSnap: Bool = true,
        rulerGuides: [CanvasGuide] = [],
        threshold: Double = snapThreshold
    ) -> SnappingResult {
        var snappedX = rect.origin.x
        var snappedY = rect.origin.y
        var guides: [SnappingGuide] = []

        // Horizontal guides check (Y-axis snapping)
        var horizontalTargets: [Double] = []
        if enableCanvasSnap {
            horizontalTargets.append(0)
            horizontalTargets.append(canvasSize.height / 2.0)
            horizontalTargets.append(canvasSize.height)
        }
        for g in rulerGuides where !g.isVertical {
            horizontalTargets.append(g.position)
        }
        if enableElementSnap {
            for other in others {
                horizontalTargets.append(other.minY)
                horizontalTargets.append(other.midY)
                horizontalTargets.append(other.maxY)
            }
        }

        // Test Y snapping for top, center, bottom
        let currentTops = [
            (pos: rect.minY, offset: 0.0),
            (pos: rect.midY, offset: rect.height / 2.0),
            (pos: rect.maxY, offset: rect.height)
        ]

        var bestYDist = threshold
        var snappedYPos: Double? = nil
        var bestYGuidePos: Double? = nil

        for item in currentTops {
            for target in horizontalTargets {
                let dist = abs(item.pos - target)
                if dist < bestYDist {
                    bestYDist = dist
                    snappedYPos = target - item.offset
                    bestYGuidePos = target
                }
            }
        }

        if let sY = snappedYPos, let gY = bestYGuidePos {
            snappedY = CGFloat(sY)
            guides.append(SnappingGuide(orientation: .horizontal, position: gY, start: 0, end: canvasSize.width))
        }

        // Vertical guides check (X-axis snapping)
        var verticalTargets: [Double] = []
        if enableCanvasSnap {
            verticalTargets.append(0)
            verticalTargets.append(canvasSize.width / 2.0)
            verticalTargets.append(canvasSize.width)
        }
        for g in rulerGuides where g.isVertical {
            verticalTargets.append(g.position)
        }
        if enableElementSnap {
            for other in others {
                verticalTargets.append(other.minX)
                verticalTargets.append(other.midX)
                verticalTargets.append(other.maxX)
            }
        }

        let currentLefts = [
            (pos: rect.minX, offset: 0.0),
            (pos: rect.midX, offset: rect.width / 2.0),
            (pos: rect.maxX, offset: rect.width)
        ]

        var bestXDist = threshold
        var snappedXPos: Double? = nil
        var bestXGuidePos: Double? = nil

        for item in currentLefts {
            for target in verticalTargets {
                let dist = abs(item.pos - target)
                if dist < bestXDist {
                    bestXDist = dist
                    snappedXPos = target - item.offset
                    bestXGuidePos = target
                }
            }
        }

        if let sX = snappedXPos, let gX = bestXGuidePos {
            snappedX = CGFloat(sX)
            guides.append(SnappingGuide(orientation: .vertical, position: gX, start: 0, end: canvasSize.height))
        }

        return SnappingResult(snappedOrigin: CGPoint(x: snappedX, y: snappedY), activeGuides: guides)
    }
}
