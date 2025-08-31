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

    private let keyboardContentLayoutGuide = UILayoutGuide()
    private var keyboardContentLayoutGuideLeadingConstraint: NSLayoutConstraint?
    private var keyboardContentLayoutGuideTrailingConstraint: NSLayoutConstraint?
    private let backgroundView: UIView = {
        let this = UIView()
        this.translatesAutoresizingMaskIntoConstraints = false
        return this
    }()
    private let stackView: UIStackView = {
        let this = UIStackView()
        this.translatesAutoresizingMaskIntoConstraints = false
        this.axis = .horizontal
        this.alignment = .center
        this.distribution = .equalSpacing
        return this
    }()

    private var toolButtons: [KeyboardToolButton] {
        return collectToolButtons(from: stackView)
    }

    /// Initializes a new toolbar to be shown above a keyboard.
    public init() {
        let frame = CGRect(x: 0, y: 0, width: 0, height: 46)
        super.init(frame: frame, inputViewStyle: .keyboard)
        setupView()
        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        backgroundColor = .clear
        addLayoutGuide(keyboardContentLayoutGuide)
        addSubview(backgroundView)
        addSubview(stackView)
    }

    private func setupLayout() {
        keyboardContentLayoutGuideLeadingConstraint = keyboardContentLayoutGuide.leadingAnchor.constraint(equalTo: leadingAnchor)
        keyboardContentLayoutGuideTrailingConstraint = keyboardContentLayoutGuide.trailingAnchor.constraint(equalTo: trailingAnchor)
        NSLayoutConstraint.activate([
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),

            keyboardContentLayoutGuideLeadingConstraint!,
            keyboardContentLayoutGuideTrailingConstraint!,
            keyboardContentLayoutGuide.topAnchor.constraint(equalTo: topAnchor),
            keyboardContentLayoutGuide.bottomAnchor.constraint(equalTo: bottomAnchor),

            stackView.leadingAnchor.constraint(equalTo: keyboardContentLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: keyboardContentLayoutGuide.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: keyboardContentLayoutGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: keyboardContentLayoutGuide.bottomAnchor)
        ])
    }

    public override func updateConstraints() {
        super.updateConstraints()
        keyboardContentLayoutGuideLeadingConstraint?.constant = InputToolMargin.rawValue
        keyboardContentLayoutGuideTrailingConstraint?.constant = InputToolMargin.rawValue * -1
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setNeedsUpdateConstraints()
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
