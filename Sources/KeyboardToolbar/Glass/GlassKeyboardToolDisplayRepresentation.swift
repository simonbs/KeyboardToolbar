import UIKit

extension KeyboardToolDisplayRepresentation {
    var spokenName: String {
        switch self {
        case .text(let configuration):
            let names = [
                "{": "Opening brace", "}": "Closing brace", "(": "Opening parenthesis", ")": "Closing parenthesis",
                "[": "Opening bracket", "]": "Closing bracket", "\"": "Double quote", "'": "Single quote",
                "=": "Equals", "+": "Plus", "-": "Minus", "*": "Multiply", "/": "Slash", "%": "Percent",
                "<": "Less than", ">": "Greater than", "!": "Exclamation mark", "&": "Ampersand", "|": "Vertical bar",
                ".": "Dot", ",": "Comma", ";": "Semicolon", "?": "Question mark", "#": "Number sign",
                "$": "Dollar sign", "\\": "Backslash", "@": "At sign", "~": "Tilde"
            ]
            return names[configuration.text] ?? configuration.text
        case .symbol(let configuration):
            let names = [
                "arrow.uturn.backward": "Undo", "arrow.uturn.forward": "Redo",
                "arrow.right.to.line": "Indent", "arrow.left.to.line": "Outdent",
                "arrow.up.to.line": "Move selected lines up", "arrow.down.to.line": "Move selected lines down",
                "magnifyingglass": "Search", "keyboard.chevron.compact.down": "Dismiss keyboard"
            ]
            return names[configuration.symbolName] ?? configuration.symbolName
        case .image(let configuration):
            return configuration.smallImage.accessibilityLabel ?? "Keyboard tool"
        }
    }

    var identifier: String {
        switch self {
        case .text(let configuration):
            return configuration.text
        case .symbol(let configuration):
            return configuration.symbolName
        case .image:
            return spokenName
        }
    }

    func image(isPreview: Bool = false) -> UIImage? {
        switch self {
        case .text:
            return nil
        case .symbol(let configuration):
            let size = isPreview ? configuration.pointSize * 1.5 : configuration.pointSize
            return UIImage(systemName: configuration.symbolName,
                           withConfiguration: UIImage.SymbolConfiguration(pointSize: size, weight: .medium))
        case .image(let configuration):
            return isPreview ? configuration.largeImage : configuration.smallImage
        }
    }

    func matches(_ other: Self) -> Bool {
        switch (self, other) {
        case let (.text(left), .text(right)):
            return left.text == right.text && left.offset == right.offset
        case let (.symbol(left), .symbol(right)):
            return left.symbolName == right.symbolName && left.pointSize == right.pointSize
        case let (.image(left), .image(right)):
            return left.smallImage.isEqual(right.smallImage) && left.largeImage.isEqual(right.largeImage)
        default:
            return false
        }
    }
}
