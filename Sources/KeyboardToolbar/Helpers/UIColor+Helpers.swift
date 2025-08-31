import UIKit

extension UIColor {
    static var keyboardToolButtonPrimary: UIColor {
        inModule(colorName: "keyboard_tool_button_primary")
    }
    static var keyboardToolButtonSecondary: UIColor {
        inModule(colorName: "keyboard_tool_button_secondary")
    }
    static var keyboardToolPickerForegroundHighlighted: UIColor {
        inModule(colorName: "keyboard_tool_picker_foreground_highlighted")
    }
    static var keyboardToolPickerForeground: UIColor {
        inModule(colorName: "keyboard_tool_picker_foreground")
    }
}

private extension UIColor {
    private static func inModule(colorName: String) -> UIColor {
        UIColor(named: colorName, in: .module, compatibleWith: nil)!
    }
}
