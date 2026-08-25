import Foundation
import CoreGraphics

public enum GuideOrientation {
    case horizontal
    case vertical
}

public struct SnappingGuide: Identifiable, Equatable {
    public var id = UUID()
    public var orientation: GuideOrientation
    public var position: Double // coordinate (Y for horizontal, X for vertical)
    public var start: Double    // span start
    public var end: Double      // span end

    public init(orientation: GuideOrientation, position: Double, start: Double = 0, end: Double = 2000) {
        self.orientation = orientation
        self.position = position
        self.start = start
        self.end = end
    }
}
