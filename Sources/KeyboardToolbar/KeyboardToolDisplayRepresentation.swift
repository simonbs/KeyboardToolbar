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
        public let smallImage: UIImage
        /// The image to use when momentarily displaying the tool picker.
        public let largeImage: UIImage

        /// Initializes a configuration.
        /// - Parameter smallImage: The image to use when displaying the tool.
        /// - Parameter largeImage: The image to use when momentarily displaying the tool picker.
        public init(smallImage: UIImage, largeImage: UIImage) {
            self.smallImage = smallImage
            self.largeImage = largeImage
        }
    }

    /// Configuration of a tool displayed using an SF symbol.
    public struct SymbolConfiguration {
        /// The name of the symbol to use when displaying the tool.
        public let symbolName: String
        /// The point size of the symbol.
        public let pointSize: CGFloat

        /// Initializes a configuration.
        /// - Parameters:
        ///   - symbolName: The name of the symbol to use when displaying the tool.
        ///   - pointSize: The point size of the symbol. Defaults to 14.
        public init(symbolName: String, pointSize: CGFloat = 14) {
            self.symbolName = symbolName
            self.pointSize = pointSize
        }
    }

    /// Display the tool using a string.
    case text(TextConfiguration)
    /// Display the tool using an image.
    case image(ImageConfiguration)
    /// Display the tool using an SF symbol.
    case symbol(SymbolConfiguration)

    /// Creates a display representation that displays a tool using a string.
    /// - Parameters:
    ///   - text: The string to use when displaying the tool.
    ///   - offset: Offset to be applied to the text when shown in a button. Defaults to (0, 0).
    /// - Returns: A display representation.
    public static func text(_ text: String, offset: CGPoint = .zero) -> Self {
        return .text(TextConfiguration(text: text, offset: offset))
    }

    /// Creates a display representation that displays a tool using an image.
    /// - Parameter smallImage: The image to use when displaying the tool.
    /// - Parameter largeImage: The image to use when momentarily displaying the tool picker.
    /// - Returns: A display representation.
    public static func image(small smallImage: UIImage, large largeImage: UIImage) -> Self {
        return .image(ImageConfiguration(smallImage: smallImage, largeImage: largeImage))
    }

    /// Creates a display representation that displays a tool using an SF Symbol.
    /// - Parameters:
    ///   - symbolName: The name of the symbol to use when displaying the tool.
    ///   - pointSize: The point size of the symbol. Defaults to 14.
    /// - Returns: A display representation.
    public static func symbol(named symbolName: String, pointSize: CGFloat = 14) -> Self {
        return .symbol(SymbolConfiguration(symbolName: symbolName, pointSize: pointSize))
    }
}
