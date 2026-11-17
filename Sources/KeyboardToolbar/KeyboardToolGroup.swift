import CoreGraphics
import Foundation

/// A group of items to be displayed in a toolbar.
///
/// Tool groups are evenly distributed in the toolbar. Use ``KeyboardToolGroup/spacing`` to specify the spacing within the group.
public struct KeyboardToolGroup {
    /// The spacing between items in the group.
    ///
    /// The default value is 6. Narrow Liquid Glass layouts compress this spacing
    /// when combining groups into one capsule to preserve usable key widths.
    public let spacing: CGFloat
    /// The items to be displayed in the group.
    public let items: [KeyboardToolGroupItem]
    /// Lets the group page horizontally when its full-size keys cannot fit in the Liquid Glass toolbar.
    public let allowsHorizontalScrolling: Bool
    /// The preferred number of keys per page when a Liquid Glass group overflows.
    /// A narrow layout may fit fewer keys. A wide layout shows every key across the available space.
    public let preferredItemsPerPage: Int?

    /// Initializes a tool group.
    /// - Parameters:
    ///   - spacing: The spacing between items in the group. Defaults to 6.
    ///   - items: The items to be displayed in the group.
    public init(spacing: CGFloat = 6, items: [KeyboardToolGroupItem]) {
        self.init(spacing: spacing, items: items, allowsHorizontalScrolling: false)
    }

    /// Initializes a group that can scroll horizontally on iOS 26 and later.
    public init(spacing: CGFloat = 6, items: [KeyboardToolGroupItem], allowsHorizontalScrolling: Bool,
                preferredItemsPerPage: Int? = nil) {
        self.spacing = spacing
        self.items = items
        self.allowsHorizontalScrolling = allowsHorizontalScrolling
        self.preferredItemsPerPage = preferredItemsPerPage
    }
}
