import UIKit

extension UIColor {
    static var keyboardBackground: UIColor {
        return inModule(colorName: "keyboard_background")
    }
    static var keyboardToolButtonPrimary: UIColor {
        return inModule(colorName: "keyboard_tool_button_primary")
    }
    static var keyboardToolButtonSecondary: UIColor {
        return inModule(colorName: "keyboard_tool_button_secondary")
    }
    static var keyboardToolForegroundHighlighted: UIColor {
        return inModule(colorName: "keyboard_tool_foreground_highlighted")
    }
    static var keyboardToolForeground: UIColor {
        return inModule(colorName: "keyboard_tool_foreground")
    }
    static var keyboardToolPicker: UIColor {
        return inModule(colorName: "keyboard_tool_picker")
    }
}

private extension UIColor {
    private static func inModule(colorName: String) -> UIColor {
        return UIColor(named: colorName, in: .module, compatibleWith: nil)!
    }
}
