import UIKit

private enum KeyboardToolPickerDirection {
    case left
    case right
}

struct KeyboardToolPickerLayout {
    let backgroundFrame: CGRect
    let pickerFrame: CGRect
    let handleXPosition: CGFloat
    let isReverse: Bool
}

struct KeyboardToolPickerFrameCalculator {
    static func handleSize(from handleView: UIView) -> CGSize {
        return CGSize(width: handleView.frame.width, height: handleView.frame.height + 10)
    }

    static func singleToolLayout(forPresenting toolPickerView: KeyboardToolPickerView,
                                 and toolPickerBackgroundView: KeyboardToolPickerBackgroundView,
                                 from presentingView: UIView) -> KeyboardToolPickerLayout {
        let handleSize = handleSize(from: presentingView)
        let backgroundSize = toolPickerBackgroundView.preferredSize(containingContentWidth: toolPickerView.intrinsicContentSize.width)
        let frameInWindow = presentingView.superview?.convert(presentingView.frame, to: presentingView.window) ?? presentingView.frame
        let containerWidth = presentingView.window?.frame.width ?? presentingView.superview?.frame.width ?? 0
        var backgroundXPosition = (backgroundSize.width - handleSize.width) / 2 * -1
        let distanceToLeadingEdge = frameInWindow.minX + backgroundXPosition
        let distanceToTrailingEdge = containerWidth - frameInWindow.minX - backgroundXPosition - backgroundSize.width
        if distanceToLeadingEdge < 0 {
            backgroundXPosition = toolPickerBackgroundView.shadowBlur * -1
        }
        if distanceToTrailingEdge < 0 {
            backgroundXPosition = (backgroundSize.width - handleSize.width - toolPickerBackgroundView.shadowBlur) * -1
        }
        return layout(forPresenting: toolPickerView,
                      and: toolPickerBackgroundView,
                      from: presentingView,
                      handleXPosition: backgroundXPosition * -1,
                      backgroundXPosition: backgroundXPosition,
                      isReverse: false)
    }

    static func multipleToolsLayout(forPresenting toolPickerView: KeyboardToolPickerView,
                                    and toolPickerBackgroundView: KeyboardToolPickerBackgroundView,
                                    from presentingView: UIView) -> KeyboardToolPickerLayout {
        let handleSize = handleSize(from: presentingView)
        let backgroundSize = toolPickerBackgroundView.preferredSize(containingContentWidth: toolPickerView.intrinsicContentSize.width)
        let direction = direction(forPresentingViewOfWidth: backgroundSize.width, from: presentingView)
        let frameInWindow = presentingView.superview?.convert(presentingView.frame, to: presentingView.window) ?? presentingView.frame
        let containerWidth = presentingView.window?.frame.width ?? presentingView.superview?.frame.width ?? 0
        var backgroundXPosition: CGFloat
        switch direction {
        case .left:
            backgroundXPosition = backgroundSize.width * -1 + handleSize.width + toolPickerView.leadingSpacing + toolPickerBackgroundView.shadowBlur
            let distanceToLeftEdge = frameInWindow.minX + backgroundXPosition
            if distanceToLeftEdge < 0 {
                backgroundXPosition -= distanceToLeftEdge
            }
        case .right:
            backgroundXPosition = (toolPickerView.leadingSpacing + toolPickerBackgroundView.shadowBlur) * -1
            let distanceToRightEdge = containerWidth - frameInWindow.minX - backgroundXPosition - backgroundSize.width
            if distanceToRightEdge < 0 {
                backgroundXPosition += distanceToRightEdge
            }
        }
        return layout(forPresenting: toolPickerView,
                      and: toolPickerBackgroundView,
                      from: presentingView,
                      handleXPosition: backgroundXPosition * -1,
                      backgroundXPosition: backgroundXPosition,
                      isReverse: direction == .left)
    }
}

private extension KeyboardToolPickerFrameCalculator {
    private static func layout(forPresenting toolPickerView: KeyboardToolPickerView,
                               and toolPickerBackgroundView: KeyboardToolPickerBackgroundView,
                               from presentingView: UIView,
                               handleXPosition: CGFloat,
                               backgroundXPosition: CGFloat,
                               isReverse: Bool) -> KeyboardToolPickerLayout {
        let toolPickerSize = toolPickerView.intrinsicContentSize
        let plateHeight = toolPickerBackgroundView.plateHeight
        let backgroundSize = toolPickerBackgroundView.preferredSize(containingContentWidth: toolPickerSize.width)
        let backgroundShadowBlur = toolPickerBackgroundView.shadowBlur
        let backgroundYPosition = (backgroundSize.height - presentingView.frame.height) * -1 + backgroundShadowBlur
        let backgroundOrigin = CGPoint(x: backgroundXPosition, y: backgroundYPosition)
        let backgroundFrame = CGRect(origin: backgroundOrigin, size: backgroundSize)
        let pickerXPosition = backgroundXPosition + backgroundShadowBlur
        let pickerYPosition = backgroundYPosition + (plateHeight - toolPickerSize.height) / 2 + backgroundShadowBlur
        let pickerOrigin = CGPoint(x: pickerXPosition, y: pickerYPosition)
        let pickerFrame = CGRect(origin: pickerOrigin, size: toolPickerSize)
        return KeyboardToolPickerLayout(backgroundFrame: backgroundFrame,
                                        pickerFrame: pickerFrame,
                                        handleXPosition: handleXPosition,
                                        isReverse: isReverse)
    }

    private static func direction(forPresentingViewOfWidth width: CGFloat, from presentingView: UIView) -> KeyboardToolPickerDirection {
        let containerWidth = presentingView.window?.frame.width ?? presentingView.superview?.frame.width ?? 0
        let frameInWindow = presentingView.superview?.convert(presentingView.frame, to: presentingView.window) ?? presentingView.frame
        let distanceToLeft = frameInWindow.minX
        let distanceToRight = containerWidth - frameInWindow.minX
        if distanceToLeft >= width {
            return .left
        } else if distanceToRight >= width {
            return .right
        } else if distanceToLeft >= distanceToRight {
            return .left
        } else {
            return .right
        }
    }
}
