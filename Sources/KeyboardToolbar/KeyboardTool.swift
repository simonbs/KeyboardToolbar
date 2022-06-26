import Foundation

/// A tool to be dispayed in an instance of ``KeyboardToolbarView``.
///
/// Tools belong to an instance of ``KeyboardToolGroupItem``. The ``KeyboardTool/performAction()`` function is called when the toolbar is selected.
///
/// The instance of ``KeyboardToolDisplayRepresentation`` specifies the appearance of the tool in the toolbar.
///
/// The KeyboardTool protocol can be used to encapsulate advanced actions in your codebase. Consider using ``BlockKeyboardTool`` for simple actions.
public protocol KeyboardTool {
    /// Specifies how the tool should be displayed in the toolbar.
    var displayRepresentation: KeyboardToolDisplayRepresentation { get }
    /// The function to be called when the tool is selected.
    func performAction()
}
