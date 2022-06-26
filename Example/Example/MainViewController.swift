import KeyboardToolbar
import UIKit

final class MainViewController: UIViewController {
    private let contentView = MainView()
    private let keyboardToolbarView = KeyboardToolbarView()
    private var textView: UITextView {
        return contentView.textView
    }

    override func loadView() {
        view = contentView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Text View"
        textView.delegate = self
        textView.inputAccessoryView = keyboardToolbarView
        setupKeyboardTools()
    }
}

private extension MainViewController {
    private func setupKeyboardTools() {
        let canUndo = textView.undoManager?.canUndo ?? false
        let canRedo = textView.undoManager?.canRedo ?? false
        keyboardToolbarView.groups = [
            KeyboardToolGroup(items: [
                KeyboardToolGroupItem(style: .secondary, representativeTool: BlockKeyboardTool(symbolName: "arrow.uturn.backward") { [weak self] in
                    self?.textView.undoManager?.undo()
                    self?.setupKeyboardTools()
                }, isEnabled: canUndo),
                KeyboardToolGroupItem(style: .secondary, representativeTool: BlockKeyboardTool(symbolName: "arrow.uturn.forward") { [weak self] in
                    self?.textView.undoManager?.redo()
                    self?.setupKeyboardTools()
                }, isEnabled: canRedo)
            ]),
            KeyboardToolGroup(items: [
                KeyboardToolGroupItem(representativeTool: InsertTextKeyboardTool(text: "(", textView: textView), tools: [
                    InsertTextKeyboardTool(text: "(", textView: textView),
                    InsertTextKeyboardTool(text: "{", textView: textView),
                    InsertTextKeyboardTool(text: "[", textView: textView),
                    InsertTextKeyboardTool(text: "]", textView: textView),
                    InsertTextKeyboardTool(text: "}", textView: textView),
                    InsertTextKeyboardTool(text: ")", textView: textView)
                ]),
                KeyboardToolGroupItem(representativeTool: InsertTextKeyboardTool(text: ".", textView: textView), tools: [
                    InsertTextKeyboardTool(text: ".", textView: textView),
                    InsertTextKeyboardTool(text: ",", textView: textView),
                    InsertTextKeyboardTool(text: ";", textView: textView),
                    InsertTextKeyboardTool(text: "!", textView: textView),
                    InsertTextKeyboardTool(text: "&", textView: textView),
                    InsertTextKeyboardTool(text: "|", textView: textView)
                ]),
                KeyboardToolGroupItem(representativeTool: InsertTextKeyboardTool(text: "=", textView: textView), tools: [
                    InsertTextKeyboardTool(text: "=", textView: textView),
                    InsertTextKeyboardTool(text: "+", textView: textView),
                    InsertTextKeyboardTool(text: "-", textView: textView),
                    InsertTextKeyboardTool(text: "/", textView: textView),
                    InsertTextKeyboardTool(text: "*", textView: textView),
                    InsertTextKeyboardTool(text: "<", textView: textView),
                    InsertTextKeyboardTool(text: ">", textView: textView)
                ]),
                KeyboardToolGroupItem(representativeTool: InsertTextKeyboardTool(text: "#", textView: textView), tools: [
                    InsertTextKeyboardTool(text: "#", textView: textView),
                    InsertTextKeyboardTool(text: "\"", textView: textView),
                    InsertTextKeyboardTool(text: "'", textView: textView),
                    InsertTextKeyboardTool(text: "$", textView: textView),
                    InsertTextKeyboardTool(text: "\\", textView: textView),
                    InsertTextKeyboardTool(text: "@", textView: textView),
                    InsertTextKeyboardTool(text: "%", textView: textView),
                    InsertTextKeyboardTool(text: "~", textView: textView)
                ])
            ]),
            KeyboardToolGroup(items: [
                KeyboardToolGroupItem(style: .secondary, representativeTool: BlockKeyboardTool(symbolName: "magnifyingglass") { [weak self] in
                    self?.textView.findInteraction?.presentFindNavigator(showingReplace: false)
                }),
                KeyboardToolGroupItem(style: .secondary, representativeTool: BlockKeyboardTool(symbolName: "keyboard.chevron.compact.down") { [weak self] in
                    self?.textView.resignFirstResponder()
                })
            ])
        ]
    }
}

extension MainViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        setupKeyboardTools()
    }
}
