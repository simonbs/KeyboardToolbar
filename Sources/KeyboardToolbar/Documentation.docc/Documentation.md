# ``KeyboardToolbar``

Add tools above your keyboard with iOS-like keyboard buttons.

## Overview

Use KeyboardToolbar to add tools as an input accessory view to a UITextField, UITextView, or any other view conforming to UITextInput.

KeyboardToolbar creates buttons with an iOS-like appearance and behavior.

On iOS 26 and later, tool groups appear in native Liquid Glass capsules. When space is limited, the toolbar combines the groups into a single capsule. Earlier iOS versions and visionOS retain keyboard-style buttons and the original picker. Liquid Glass uses the system material and adapts to light and dark mode.

Liquid Glass gives all enabled tools the same foreground emphasis. The legacy `Style.secondary` appearance is deprecated on iOS 26 and ignored by the glass renderer; disabled tools still appear dimmed.

Tap a tool to perform its primary action. Touch and hold to expand its choices, slide to select a choice, and release to perform it. The picker stays within the screen edges, and sliding remains anchored to your finger. VoiceOver users can choose alternatives using accessibility actions.

The hold delay defaults to 0.5 seconds. Set ``KeyboardToolbarView/showToolPickerDelay`` to customize it:

```swift
keyboardToolbarView.showToolPickerDelay = 0.2
```

![Liquid Glass toolbar with expanded bracket choices.](keyboard.png)

## Topics

### Toolbar

- ``KeyboardToolbarView``

### Creating Tools

- ``KeyboardTool``
- ``KeyboardToolDisplayRepresentation``
- ``BlockKeyboardTool``
- ``KeyboardToolGroup``
- ``KeyboardToolGroupItem``
