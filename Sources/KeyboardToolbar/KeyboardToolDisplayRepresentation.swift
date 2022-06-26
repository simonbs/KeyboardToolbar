import UIKit

/// The display of a keyboard tool.
///
/// This specifies how an instance of ``KeyboardTool`` is displayed when shown in a ``KeyboardToolbar``.
public enum KeyboardToolDisplayRepresentation {
    /// Configuration of a tool displayed using a string.
    public struct TextConfiguration {
        /// The string to use when displaying the tool.
        ///
        /// It is recommended to limit this to a single character.
        public let text: String
        /// Offset to be applied to the text when shown in a button.
        ///
        /// This can be used to adjust the alignment of the text.
        ///
        /// Defaults to (0, 0).
        public let offset: CGPoint

        /// Initializes a configuration.
        /// - Parameters:
        ///   - text: The string to use when displaying the tool.
        ///   - offset: Offset to be applied to the text when shown in a button. Defaults to (0, 0).
        public init(text: String, offset: CGPoint = .zero) {
            self.text = text
            self.offset = offset
        }
    }

    /// Configuration of a tool displayed using an image.
    public struct ImageConfiguration {
        /// The image to use when displaying the tool.
        public let image: UIImage

        /// Initializes a configuration.
        /// - Parameter image: The image to use when displaying the tool.
        public init(image: UIImage) {
            self.image = image
        }
    }

    /// Display the tool using a string.
    case text(TextConfiguration)
    /// Display the tool using an image.
    case image(ImageConfiguration)

    /// Creates a display representation that displays a tool using a string.
    /// - Parameters:
    ///   - text: The string to use when displaying the tool.
    ///   - offset: Offset to be applied to the text when shown in a button. Defaults to (0, 0).
    /// - Returns: A display representation.
    public static func text(_ text: String, offset: CGPoint = .zero) -> Self {
        return .text(TextConfiguration(text: text, offset: offset))
    }

    /// Creates a display representation that displays a tool using an image.
    /// - Parameter image: The image to use when displaying the tool.
    /// - Returns: A display representation.
    public static func image(_ image: UIImage) -> Self {
        return .image(ImageConfiguration(image: image))
    }

    /// Creates a display representation that displays a tool using a SF Symbol.
    ///
    /// This will throw an error at runtime if the symbol could not be found.
    /// - Parameters:
    ///   - symbolName: The name of the symbol to use when displaying the tool.
    ///   - pointSize: The point size of the symbol.
    /// - Returns: A display representation.
    public static func symbol(named symbolName: String, pointSize: CGFloat) -> Self {
        let configuration = UIImage.SymbolConfiguration(pointSize: pointSize)
        return symbol(named: symbolName, withConfiguration: configuration)
    }

    /// Creates a display representation that displays a tool using a SF Symbol.
    ///
    /// This will throw an error at runtime if the symbol could not be found.
    /// - Parameters:
    ///   - symbolName: The name of the symbol to use when displaying the tool.
    ///   - configuration: The image configuration to be applied to the created image.
    /// - Returns: A display representation.
    public static func symbol(named symbolName: String, withConfiguration configuration: UIImage.Configuration? = nil) -> Self {
        if let image = UIImage(systemName: symbolName, withConfiguration: configuration) {
            return .image(image)
        } else {
            fatalError("SF Symbol named '\(symbolName)' was not found")
        }
    }
}
