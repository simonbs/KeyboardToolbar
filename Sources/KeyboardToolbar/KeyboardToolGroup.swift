import Foundation

/// A group of items to be displayed in a toolbar.
///
/// Tool groups are evenly distributed in the toolbar. Use ``KeyboardToolGroup/spacing`` to specify the spacing within the group.
public struct KeyboardToolGroup {
    /// The items to be displayed in the group.
    public let items: [KeyboardToolGroupItem]
    /// The spacing between items in the group.
    ///
    /// The default value is 6.
    public let spacing: CGFloat

    /// Initializes a tool group.
    /// - Parameters:
    ///   - items: The items to be displayed in the group.
    ///   - spacing: The spacing between items in the group. Defaults to 6.
    public init(items: [KeyboardToolGroupItem], spacing: CGFloat = 6) {
        self.items = items
        self.spacing = spacing
    }
}
