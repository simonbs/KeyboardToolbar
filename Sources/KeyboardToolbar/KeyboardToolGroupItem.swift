import UIKit

/// An item displayed in a tool group.
public struct KeyboardToolGroupItem {
    /// The style of an item.
    public enum Style {
        /// A prominent style.
        ///
        /// Typically used for items that presents the tool picker when long pressed.
        case primary
        /// A faded style.
        ///
        /// Typically used for items that does not present the tool picker when long pressed.
        case secondary
    }

    /// The style of the item.
    public let style: Style
    /// The tool representing the item.
    ///
    /// This tool is the default tool. Selecting the item will perform the action on this tool.
    public let representativeTool: KeyboardTool
    /// Insets applied to a button showing this item.
    public let contentEdgeInsets: NSDirectionalEdgeInsets
    /// Whether this item is enabled or not.
    public let isEnabled: Bool
    /// Whether to include the representative tool in the tool picker that is presented when long pressing the item.
    public let includeRepresentativeToolInPicker: Bool
    /// The items to be displayed in the tool picker that is presented when long pressing the item.
    public let tools: [KeyboardTool]

    var allTools: [KeyboardTool] {
        if includeRepresentativeToolInPicker {
            return [representativeTool] + tools
        } else {
            return tools
        }
    }

    /// Initializes an item.
    /// - Parameters:
    ///   - style: The style of the item.
    ///   - representativeTool: The tool representing the item.
    ///   - contentEdgeInsets: Insets applied to a button showing this item.
    ///   - isEnabled: Whether this item is enabled or not.
    ///   - includeRepresentativeToolInPicker: Whether to include the representative tool in the tool picker that is presented when long pressing the item.
    ///   - tools: The items to be displayed in the tool picker that is presented when long pressing the item.
    public init(style: Style = .primary,
                representativeTool: KeyboardTool,
                contentEdgeInsets: NSDirectionalEdgeInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 1, trailing: 0),
                isEnabled: Bool = true,
                includeRepresentativeToolInPicker: Bool = false,
                tools: [KeyboardTool] = []) {
        self.style = style
        self.representativeTool = representativeTool
        self.contentEdgeInsets = contentEdgeInsets
        self.isEnabled = isEnabled
        self.includeRepresentativeToolInPicker = includeRepresentativeToolInPicker
        self.tools = tools
    }
}
