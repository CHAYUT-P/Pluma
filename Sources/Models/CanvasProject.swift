import Foundation

/// A user-draggable alignment guide (from the rulers).
public struct CanvasGuide: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    /// Canvas coordinate: x for vertical guides, y for horizontal guides.
    public var position: Double
    public var isVertical: Bool

    public init(id: UUID = UUID(), position: Double, isVertical: Bool) {
        self.id = id
        self.position = position
        self.isVertical = isVertical
    }
}

public struct CanvasPage: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public var name: String
    public var width: Double
    public var height: Double
    public var background: FillStyle
    public var isTransparent: Bool
    public var elements: [CanvasElement]
    /// Ruler guides (optional for JSON backward-compatibility).
    public var guides: [CanvasGuide]?

    public init(
        id: UUID = UUID(),
        name: String = "Page 1",
        width: Double = 1080,
        height: Double = 1080,
        background: FillStyle = .solid(.white),
        isTransparent: Bool = false,
        elements: [CanvasElement] = [],
        guides: [CanvasGuide] = []
    ) {
        self.id = id
        self.name = name
        self.width = width
        self.height = height
        self.background = background
        self.isTransparent = isTransparent
        self.elements = elements
        self.guides = guides
    }

    public var bounds: CGRect {
        CGRect(x: 0, y: 0, width: width, height: height)
    }
}

public struct CanvasProject: Identifiable, Codable, Equatable {
    public var id: UUID
    public var name: String
    public var createdAt: Date
    public var modifiedAt: Date
    public var pages: [CanvasPage]

    public init(
        id: UUID = UUID(),
        name: String = "Untitled Project",
        createdAt: Date = Date(),
        modifiedAt: Date = Date(),
        pages: [CanvasPage] = [CanvasPage()]
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.pages = pages
    }

    public func encodeToData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(self)
    }

    public static func decode(from data: Data) throws -> CanvasProject {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(CanvasProject.self, from: data)
    }
}
