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
    private var glassBackgroundView: UIVisualEffectView {
        if let glassBackgroundView = _glassBackgroundView {
            return glassBackgroundView
        } else {
            let effect = UIGlassEffect(style: .regular)
            let glassBackgroundView = UIVisualEffectView(effect: effect)
            _glassBackgroundView = glassBackgroundView
            return glassBackgroundView
        }
    }
    private let glassBackgroundMaskView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 13
        view.layer.cornerCurve = .continuous
        view.backgroundColor = .black
        return view
    }()
    private let stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.alignment = .center
        view.distribution = .equalSpacing
        return view
    }()

    private var _glassBackgroundView: UIVisualEffectView?

    /// Initializes a new toolbar to be shown above a keyboard.
    public init() {
        var height: CGFloat = 46
        if #available(iOS 26, *) {
            height += 20 // Accomodates for bottom distance to keyboard and spacing above and below stack view
        }
        let frame = CGRect(x: 0, y: 0, width: 0, height: height)
        let inputViewStyle: UIInputView.Style = if #available(iOS 16, *) {
            .default
        } else {
            .keyboard
        }
        super.init(frame: frame, inputViewStyle: inputViewStyle)
        backgroundColor = .clear
        if #available(iOS 26, *) {
            glassBackgroundView.mask = glassBackgroundMaskView
            addSubview(glassBackgroundView)
            addSubview(stackView)
            updateGlassBackgroundColor()
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
            let bottomMargin: CGFloat = 10
            let stackViewMargin: CGFloat = 7
            let glassMaskMargin = max(max(sideMargin - stackViewMargin, 0), 5)
            glassBackgroundView.frame = CGRect(origin: .zero, size: bounds.size)
            glassBackgroundMaskView.frame = CGRect(
                x: glassMaskMargin,
                y: 0,
                width: bounds.width - glassMaskMargin * 2,
                height: bounds.height - bottomMargin
            )
            stackView.frame = CGRect(
                x: (glassMaskMargin + stackViewMargin),
                y: 0,
                width: bounds.width - (glassMaskMargin + stackViewMargin) * 2,
                height: bounds.height - bottomMargin
            )
        } else {
            stackView.frame = CGRect(
                x: sideMargin,
                y: 0,
                width: bounds.width - sideMargin * 2,
                height: bounds.height
            )
        }
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setNeedsLayout()
        if #available(iOS 26, *) {
            updateGlassBackgroundColor()
        }
    }
}

private extension KeyboardToolbarView {
    @available(iOS 26, *)
    private func updateGlassBackgroundColor() {
        let effect = UIGlassEffect(style: .regular)
        if traitCollection.userInterfaceStyle == .dark {
            effect.tintColor = .black.withAlphaComponent(0.95)
        } else {
            effect.tintColor = .black.withAlphaComponent(0.02)
        }
        glassBackgroundView.effect = effect
    }

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
