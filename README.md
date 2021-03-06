# KeyboardToolbar

![](Sources/KeyboardToolbar/Documentation.docc/Resources/keyboard.png#gh-light-mode-only)
![](Sources/KeyboardToolbar/Documentation.docc/Resources/keyboard~dark.png#gh-dark-mode-only)

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fsimonbs%2FKeyboardToolbar%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/simonbs/KeyboardToolbar)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fsimonbs%2FKeyboardToolbar%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/simonbs/KeyboardToolbar)
[![](https://img.shields.io/badge/twitter-@simonbs-blue.svg?style=flat)]([https://swiftpackageindex.com/simonbs/Runestone](https://twitter.com/simonbs))

## 👀 Overview

Use KeyboardToolbar to add tools as an input accessory view to a UITextField, UITextView, or any other view conforming to UITextInput.

KeyboardToolbar creates buttons with an iOS-like appearance and behavior.

## 📖 Documentation

The public interface is documented in the Swift files and can be found in [KeyboardToolbar/Sources/KeyboardToolbar](https://github.com/simonbs/KeyboardToolbar/tree/main/Sources/KeyboardToolbar). You can also [read the documention on Swift Package Index](https://swiftpackageindex.com/simonbs/KeyboardToolbar).

Lastly, you can also build the documentation yourself by opening the Swift package in Xcode and selecting Product > Build Documentation in the menu bar.

## 📦 Adding the Package

KeyboardToolbar is distributed using the [Swift Package Manager](https://www.swift.org/package-manager/). Install it in a project by adding it as a dependency in your Package.swift manifest or through “Package Dependencies” in project settings.

```swift
let package = Package(
    dependencies: [
        .package(url: "git@github.com:simonbs/KeyboardToolbar.git", from: "0.1.0")
    ]
)
```

## 🚀 Getting Started

The best way to understand how KeyboardToolbar is integrated into your project is by having a look at the [Example project](Example/Example) in this repository.

At a high level there are two steps required to setting up the keyboard toolbar.

1. Create an instance of [KeyboardToolbarView](https://github.com/simonbs/KeyboardToolbar/blob/main/Sources/KeyboardToolbar/KeyboardToolbarView.swift) and assign it to [inputAccessoryView](https://developer.apple.com/documentation/uikit/uitextfield/1619627-inputaccessoryview) on a UITextField, UITextView, or any other view that conforms to the UITextInput protocol.
2. Assign an array of [KeyboardToolGroup](https://github.com/simonbs/KeyboardToolbar/blob/main/Sources/KeyboardToolbar/KeyboardToolGroup.swift) items to the `groups` property on your instance of KeyboardToolbarView.

The below code snippet shows how the two steps can be performed.

```swift
/// Create our instance of KeyboardToolbarView and pass it to an instance of UITextView.
let keyboardToolbarView = KeyboardToolbarView()
textView.inputAccessoryView = keyboardToolbarView
// Setup our tool groups.
let canUndo = textView.undoManager?.canUndo ?? false
let canRedo = textView.undoManager?.canRedo ?? false
keyboardToolbarView.groups = [
    // Tools for undoing and redoing text in the text view.
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
    // Tools for inserting characters into our text view.
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
        // Tool to present the find navigator.
        KeyboardToolGroupItem(style: .secondary, representativeTool: BlockKeyboardTool(symbolName: "magnifyingglass") { [weak self] in
            self?.textView.findInteraction?.presentFindNavigator(showingReplace: false)
        }),
        // Tool to dismiss the keyboard.
        KeyboardToolGroupItem(style: .secondary, representativeTool: BlockKeyboardTool(symbolName: "keyboard.chevron.compact.down") { [weak self] in
            self?.textView.resignFirstResponder()
        })
    ])
]
```
