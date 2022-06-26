import KeyboardToolbar
import UIKit

struct InsertTextKeyboardTool: KeyboardTool {
    let displayRepresentation: KeyboardToolDisplayRepresentation

    private let text: String
    private weak var textView: UITextInput?

    init(text: String, textView: UITextInput) {
        self.displayRepresentation = .text(text)
        self.text = text
        self.textView = textView
    }

    func performAction() {
        textView?.insertText(text)
    }
}
