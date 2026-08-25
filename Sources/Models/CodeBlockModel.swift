import Foundation
import SwiftUI

public enum CodeLanguage: String, Codable, CaseIterable, Identifiable {
    case swift = "Swift"
    case python = "Python"
    case javascript = "JavaScript"
    case typescript = "TypeScript"
    case rust = "Rust"
    case go = "Go"
    case html = "HTML"
    case css = "CSS"
    case json = "JSON"
    case sql = "SQL"
    case cpp = "C++"
    case bash = "Bash / Shell"

    public var id: String { rawValue }

    public var fileExtension: String {
        switch self {
        case .swift: return "swift"
        case .python: return "py"
        case .javascript: return "js"
        case .typescript: return "ts"
        case .rust: return "rs"
        case .go: return "go"
        case .html: return "html"
        case .css: return "css"
        case .json: return "json"
        case .sql: return "sql"
        case .cpp: return "cpp"
        case .bash: return "sh"
        }
    }
}

public enum CodeTheme: String, Codable, CaseIterable, Identifiable {
    case carbonDark = "Carbon Dark"
    case vsCodeDark = "VS Code Dark"
    case monokai = "Monokai Pro"
    case dracula = "Dracula"
    case xcodeLight = "Xcode Light"
    case paperCream = "Paper Craft"
    case nord = "Nordic Frost"

    public var id: String { rawValue }

    public var backgroundColor: CodableColor {
        switch self {
        case .carbonDark: return CodableColor(hex: "#161618")
        case .vsCodeDark: return CodableColor(hex: "#1E1E1E")
        case .monokai: return CodableColor(hex: "#272822")
        case .dracula: return CodableColor(hex: "#282A36")
        case .xcodeLight: return CodableColor(hex: "#FFFFFF")
        case .paperCream: return CodableColor(hex: "#FAF7F0")
        case .nord: return CodableColor(hex: "#2E3440")
        }
    }

    public var isDark: Bool {
        self != .xcodeLight && self != .paperCream
    }

    public var defaultTextColor: CodableColor {
        isDark ? CodableColor(hex: "#F8F8F2") : CodableColor(hex: "#24292E")
    }

    public var keywordColor: CodableColor {
        switch self {
        case .carbonDark: return CodableColor(hex: "#FF7B72")
        case .vsCodeDark: return CodableColor(hex: "#569CD6")
        case .monokai: return CodableColor(hex: "#F92672")
        case .dracula: return CodableColor(hex: "#FF79C6")
        case .xcodeLight: return CodableColor(hex: "#AD3DA4")
        case .paperCream: return CodableColor(hex: "#C2410C")
        case .nord: return CodableColor(hex: "#81A1C1")
        }
    }

    public var stringColor: CodableColor {
        switch self {
        case .carbonDark: return CodableColor(hex: "#A5D6FF")
        case .vsCodeDark: return CodableColor(hex: "#CE9178")
        case .monokai: return CodableColor(hex: "#E6DB74")
        case .dracula: return CodableColor(hex: "#F1FA8C")
        case .xcodeLight: return CodableColor(hex: "#D12F1B")
        case .paperCream: return CodableColor(hex: "#2D4A3E")
        case .nord: return CodableColor(hex: "#A3BE8C")
        }
    }

    public var commentColor: CodableColor {
        switch self {
        case .carbonDark: return CodableColor(hex: "#8B949E")
        case .vsCodeDark: return CodableColor(hex: "#6A9955")
        case .monokai: return CodableColor(hex: "#75715E")
        case .dracula: return CodableColor(hex: "#6272A4")
        case .xcodeLight: return CodableColor(hex: "#707F8C")
        case .paperCream: return CodableColor(hex: "#8C827A")
        case .nord: return CodableColor(hex: "#616E88")
        }
    }

    public var functionColor: CodableColor {
        switch self {
        case .carbonDark: return CodableColor(hex: "#D2A8FF")
        case .vsCodeDark: return CodableColor(hex: "#DCDCAA")
        case .monokai: return CodableColor(hex: "#A6E22E")
        case .dracula: return CodableColor(hex: "#50FA7B")
        case .xcodeLight: return CodableColor(hex: "#4B21B0")
        case .paperCream: return CodableColor(hex: "#B45309")
        case .nord: return CodableColor(hex: "#88C0D0")
        }
    }
}

public struct CodeContent: Codable, Equatable, Hashable {
    public var code: String
    public var language: CodeLanguage
    public var theme: CodeTheme
    public var showLineNumbers: Bool
    public var showWindowHeader: Bool
    public var windowTitle: String
    public var fontSize: Double
    public var cornerRadius: Double
    public var padding: Double

    public init(
        code: String = """
        import SwiftUI
        import Metal

        // Lightweight Native Canvas Engine ⚡
        struct CanvasEngine {
            let memoryUsage = "42 MB"
            let framerate = 120 // ProMotion FPS
            let isOffline = true

            func render() {
                print("Zero lag. Silky smooth graphics.")
            }
        }
        """,
        language: CodeLanguage = .swift,
        theme: CodeTheme = .vsCodeDark,
        showLineNumbers: Bool = true,
        showWindowHeader: Bool = true,
        windowTitle: String = "CanvasEngine.swift",
        fontSize: Double = 14.0,
        cornerRadius: Double = 12.0,
        padding: Double = 16.0
    ) {
        self.code = code
        self.language = language
        self.theme = theme
        self.showLineNumbers = showLineNumbers
        self.showWindowHeader = showWindowHeader
        self.windowTitle = windowTitle
        self.fontSize = fontSize
        self.cornerRadius = cornerRadius
        self.padding = padding
    }
}
