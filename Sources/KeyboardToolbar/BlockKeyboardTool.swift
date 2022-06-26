import UIKit

/// A tool that performs a block-based action when selected.
///
/// This isn implementation of ``KeyboardTool`` that performs a block when the tool is selected in the toolbar.
///
/// Consider using this for simple actions only and implement objects conforming to ``KeyboardTool`` for complex actions.
public struct BlockKeyboardTool: KeyboardTool {
    /// Specifies how the tool should be displayed in the toolbar.
    public let displayRepresentation: KeyboardToolDisplayRepresentation
    /// The block to be called when the tool is selected.
    public let actionHandler: () -> Void

    /// Initializes a keyboard tool.
    /// - Parameters:
    ///   - displayRepresentation: Specifies how the tool should be displayed in the toolbar.
    ///   - actionHandler: The block to be called when the tool is selected.
    public init(displayRepresentation: KeyboardToolDisplayRepresentation, action actionHandler: @escaping () -> Void) {
        self.displayRepresentation = displayRepresentation
        self.actionHandler = actionHandler
    }

    /// Initializes a tool that displays a text.
    /// - Parameters:
    ///   - text: The string to use when displaying the tool.
    ///   - offset: Offset to be applied to the text when shown in a button. Defaults to (0, 0).
    ///   - actionHandler: The block to be called when the tool is selected.
    public init(text: String, offset: CGPoint = .zero, action actionHandler: @escaping () -> Void) {
        let displayRepresentation: KeyboardToolDisplayRepresentation = .text(text, offset: offset)
        self.init(displayRepresentation: displayRepresentation, action: actionHandler)
    }

    /// Initializes a tool that displays an image.
    /// - Parameters:
    ///   - image: he image to use when displaying the tool.
    ///   - actionHandler: The block to be called when the tool is selected.
    public init(image: UIImage, action actionHandler: @escaping () -> Void) {
        let displayRepresentation: KeyboardToolDisplayRepresentation = .image(image)
        self.init(displayRepresentation: displayRepresentation, action: actionHandler)
    }

    /// Initializes a tool that displays a SF Symbol.
    /// - Parameters:
    ///   - symbolName: The name of the symbol to use when displaying the tool.
    ///   - pointSize: The point size of the symbol.
    ///   - actionHandler: The block to be called when the tool is selected.
    public init(symbolName: String, pointSize: CGFloat = 14, action actionHandler: @escaping () -> Void) {
        let displayRepresentation: KeyboardToolDisplayRepresentation = .symbol(named: symbolName, pointSize: pointSize)
        self.init(displayRepresentation: displayRepresentation, action: actionHandler)
    }

    /// Initializes a tool that displays a SF Symbol.
    /// - Parameters:
    ///   - symbolName: The name of the symbol to use when displaying the tool.
    ///   - configuration: The image configuration to be applied to the created image.
    ///   - actionHandler: The block to be called when the tool is selected.
    public init(symbolName: String, withConfiguration configuration: UIImage.Configuration?, action actionHandler: @escaping () -> Void) {
        let displayRepresentation: KeyboardToolDisplayRepresentation = .symbol(named: symbolName, withConfiguration: configuration)
        self.init(displayRepresentation: displayRepresentation, action: actionHandler)
    }

    /// Called when selecting the tool in the toolbar.
    ///
    /// Calling this function will call ``actionHandler``.
    public func performAction() {
        actionHandler()
    }
}
