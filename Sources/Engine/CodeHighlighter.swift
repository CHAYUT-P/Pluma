import SwiftUI
import AppKit

public struct CodeToken: Identifiable {
    public let id = UUID()
    public let text: String
    public let color: Color

    public init(text: String, color: Color) {
        self.text = text
        self.color = color
    }
}

public struct HighlightedLine: Identifiable {
    public let id = UUID()
    public let lineNumber: Int
    public let tokens: [CodeToken]

    public init(lineNumber: Int, tokens: [CodeToken]) {
        self.lineNumber = lineNumber
        self.tokens = tokens
    }
}

public enum CodeHighlighter {
    private static let swiftKeywords: Set<String> = [
        "import", "struct", "class", "enum", "protocol", "func", "let", "var",
        "return", "if", "else", "guard", "switch", "case", "for", "in", "while",
        "public", "private", "fileprivate", "internal", "final", "static", "mutating",
        "init", "self", "Self", "true", "false", "nil", "try", "await", "async", "throw", "throws"
    ]

    private static let pythonKeywords: Set<String> = [
        "import", "from", "def", "class", "return", "if", "elif", "else", "for",
        "while", "in", "try", "except", "finally", "with", "as", "lambda", "yield",
        "True", "False", "None", "async", "await", "pass", "break", "continue"
    ]

    private static let jsKeywords: Set<String> = [
        "import", "export", "from", "const", "let", "var", "function", "return",
        "if", "else", "switch", "case", "for", "while", "class", "extends", "new",
        "this", "true", "false", "null", "undefined", "async", "await", "try", "catch"
    ]

    private static let rustKeywords: Set<String> = [
        "use", "fn", "let", "mut", "struct", "enum", "impl", "trait", "pub",
        "return", "if", "else", "match", "for", "in", "while", "loop", "true", "false",
        "self", "Self", "async", "await", "move", "where"
    ]

    // MARK: - Memoization (highlighting runs on EVERY render pass otherwise)

    private static let cacheLock = NSLock()
    private static var highlightCache: [String: [HighlightedLine]] = [:]
    private static let cacheLimit = 256

    public static func highlight(code: String, language: CodeLanguage, theme: CodeTheme) -> [HighlightedLine] {
        let key = "\(language.rawValue)|\(theme.rawValue)|\(code)"
        cacheLock.lock()
        if let hit = highlightCache[key] {
            cacheLock.unlock()
            return hit
        }
        cacheLock.unlock()

        let result = performHighlight(code: code, language: language, theme: theme)

        cacheLock.lock()
        if highlightCache.count >= cacheLimit {
            highlightCache.removeAll()
        }
        highlightCache[key] = result
        cacheLock.unlock()
        return result
    }

    private static func performHighlight(code: String, language: CodeLanguage, theme: CodeTheme) -> [HighlightedLine] {
        let lines = code.components(separatedBy: .newlines)
        var result: [HighlightedLine] = []

        let keywords: Set<String>
        switch language {
        case .swift: keywords = swiftKeywords
        case .python: keywords = pythonKeywords
        case .javascript, .typescript: keywords = jsKeywords
        case .rust: keywords = rustKeywords
        default: keywords = swiftKeywords
        }

        let kwColor = theme.keywordColor.color
        let strColor = theme.stringColor.color
        let commentColor = theme.commentColor.color
        let defColor = theme.defaultTextColor.color
        let funcColor = theme.functionColor.color

        for (index, rawLine) in lines.enumerated() {
            var tokens: [CodeToken] = []

            // Check if comment line
            let trimmed = rawLine.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("//") || trimmed.hasPrefix("#") {
                tokens.append(CodeToken(text: rawLine, color: commentColor))
                result.append(HighlightedLine(lineNumber: index + 1, tokens: tokens))
                continue
            }

            // Word-by-word simple tokenizer
            let scanner = Scanner(string: rawLine)
            scanner.charactersToBeSkipped = nil

            var currentText = ""
            var inString = false
            var stringChar: Character = "\""

            while !scanner.isAtEnd {
                if let str = scanner.scanUpToCharacters(from: CharacterSet(charactersIn: "\"'/ ()[]{},:;.<>=!+-*")) {
                    currentText += str
                }

                if let char = scanner.scanCharacter() {
                    if char == "\"" || char == "'" {
                        if inString && char == stringChar {
                            currentText.append(char)
                            tokens.append(CodeToken(text: currentText, color: strColor))
                            currentText = ""
                            inString = false
                        } else if !inString {
                            if !currentText.isEmpty {
                                tokens.append(tokenizeWord(currentText, keywords: keywords, kwColor: kwColor, defColor: defColor, funcColor: funcColor))
                                currentText = ""
                            }
                            inString = true
                            stringChar = char
                            currentText.append(char)
                        } else {
                            currentText.append(char)
                        }
                    } else if char == "/" && (scanner.scanString("/") != nil) {
                        if !currentText.isEmpty {
                            tokens.append(tokenizeWord(currentText, keywords: keywords, kwColor: kwColor, defColor: defColor, funcColor: funcColor))
                            currentText = ""
                        }
                        let restOfLine = scanner.string[scanner.currentIndex...]
                        tokens.append(CodeToken(text: "//" + String(restOfLine), color: commentColor))
                        break
                    } else {
                        if inString {
                            currentText.append(char)
                        } else {
                            if !currentText.isEmpty {
                                tokens.append(tokenizeWord(currentText, keywords: keywords, kwColor: kwColor, defColor: defColor, funcColor: funcColor))
                                currentText = ""
                            }
                            tokens.append(CodeToken(text: String(char), color: defColor))
                        }
                    }
                }
            }

            if !currentText.isEmpty {
                if inString {
                    tokens.append(CodeToken(text: currentText, color: strColor))
                } else {
                    tokens.append(tokenizeWord(currentText, keywords: keywords, kwColor: kwColor, defColor: defColor, funcColor: funcColor))
                }
            }

            if tokens.isEmpty {
                tokens.append(CodeToken(text: " ", color: defColor))
            }

            result.append(HighlightedLine(lineNumber: index + 1, tokens: tokens))
        }

        return result
    }

    private static func tokenizeWord(_ word: String, keywords: Set<String>, kwColor: Color, defColor: Color, funcColor: Color) -> CodeToken {
        if keywords.contains(word) {
            return CodeToken(text: word, color: kwColor)
        } else if Int(word) != nil || Double(word) != nil {
            return CodeToken(text: word, color: Color(hex: "#D97706"))
        } else if word.first?.isUppercase == true {
            return CodeToken(text: word, color: funcColor)
        } else {
            return CodeToken(text: word, color: defColor)
        }
    }
}
