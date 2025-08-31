import BlurUIKit
import UIKit

/// Toolbar to be displayed above the keyboard.
///
/// Set an instance of this view as the `inputAccessoryView` on a text view or text field to display tools above the keyboard.
public final class KeyboardToolbarView: UIInputView, UIInputViewAudioFeedback {
    /// Tool groups to be displayed in the toolbar.
    public var groups: [KeyboardToolGroup] = [] {
        didSet {
            reloadButtons()
        }
    }
    /// Duration a user should long press an item to present the tool picker.
    public var showToolPickerDelay: TimeInterval = 0.5 {
        didSet {
            if showToolPickerDelay != oldValue {
                let toolButtons = collectToolButtons(from: stackView)
                for button in toolButtons {
                    button.showToolPickerDelay = showToolPickerDelay
                }
            }
        }
    }
#if !os(xrOS)
    /// Enables clicks when selecting a tool.
    public var enableInputClicksWhenVisible: Bool {
        return true
    }
#endif

    @available(iOS 26, *)
    private var blurView: VariableBlurView {
        if let blurView = _blurView {
            return blurView
        } else {
            let blurView = VariableBlurView()
            blurView.direction = .up
            blurView.dimmingTintColor = .black.withAlphaComponent(0.1)
            _blurView = blurView
            return blurView
        }
    }
    private var _blurView: VariableBlurView?
    private let stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.alignment = .center
        view.distribution = .equalSpacing
        return view
    }()

    /// Initializes a new toolbar to be shown above a keyboard.
    public init() {
        var height: CGFloat = 46
        if #available(iOS 26, *) {
            height += 20 // Accomodates for bottom distance to keyboard and spacing above and below stack view
        }
        let frame = CGRect(x: 0, y: 0, width: 0, height: height)
        super.init(frame: frame, inputViewStyle: .keyboard)
        backgroundColor = .clear
        if #available(iOS 26, *) {
            addSubview(blurView)
            addSubview(stackView)
        } else {
            addSubview(stackView)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let sideMargin = InputToolMargin.rawValue(for: traitCollection)
        if #available(iOS 26, *) {
            blurView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height + 20) // Expand beyond rounded corners
        }
        stackView.frame = CGRect(
            x: sideMargin,
            y: 0,
            width: bounds.width - sideMargin * 2,
            height: bounds.height
        )
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setNeedsLayout()
    }
}

private extension KeyboardToolbarView {
    private func reloadButtons() {
        for view in stackView.arrangedSubviews {
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        for group in groups {
            let groupStack = UIStackView()
            groupStack.axis = .horizontal
            groupStack.alignment = .center
            groupStack.distribution = .fill
            groupStack.spacing = group.spacing
            for item in group.items {
                let button = KeyboardToolButton(item: item)
                button.translatesAutoresizingMaskIntoConstraints = false
                button.showToolPickerDelay = showToolPickerDelay
                groupStack.addArrangedSubview(button)
            }
            stackView.addArrangedSubview(groupStack)
        }
    }
}

private extension KeyboardToolbarView {
    func collectToolButtons(from view: UIView) -> [KeyboardToolButton] {
        var results: [KeyboardToolButton] = []
        if let button = view as? KeyboardToolButton {
            results.append(button)
        }
        for subview in view.subviews {
            results.append(contentsOf: collectToolButtons(from: subview))
        }
        return results
    }
}
