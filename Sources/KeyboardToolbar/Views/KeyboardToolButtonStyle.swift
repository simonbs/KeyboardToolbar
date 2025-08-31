import CoreGraphics

enum KeyboardToolButtonStyle {
    static var cornerRadius: CGFloat {
        if #available(iOS 26, *) {
            9
        } else {
            5
        }
    }
    static var shadowLength: CGFloat {
        if #available(iOS 26, *) {
            0
        } else {
            1
        }
    }
}
