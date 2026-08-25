import SwiftUI

public enum DashPattern: String, Codable, CaseIterable {
    case solid = "Solid"
    case dashed = "Dashed"
    case dotted = "Dotted"

    public var lineDash: [CGFloat] {
        switch self {
        case .solid: return []
        case .dashed: return [8, 6]
        case .dotted: return [2, 4]
        }
    }
}

public struct StrokeStyle: Codable, Equatable, Hashable {
    public var isEnabled: Bool
    public var color: CodableColor
    public var lineWidth: Double
    public var dashPattern: DashPattern

    public init(
        isEnabled: Bool = false,
        color: CodableColor = .black,
        lineWidth: Double = 2.0,
        dashPattern: DashPattern = .solid
    ) {
        self.isEnabled = isEnabled
        self.color = color
        self.lineWidth = lineWidth
        self.dashPattern = dashPattern
    }

    public static let none = StrokeStyle(isEnabled: false)
    public static let thinBlack = StrokeStyle(isEnabled: true, color: .black, lineWidth: 1.0)
    public static let modernWhite = StrokeStyle(isEnabled: true, color: .white, lineWidth: 2.0)
}
