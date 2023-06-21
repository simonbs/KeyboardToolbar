import UIKit

/// Toolbar to be displayed above the keyboard.
///
/// Set an instance of this view as the `inputAccessoryView` on a text view or text field to display tools above the keyboard.
public final class KeyboardToolbarView: UIInputView, UIInputViewAudioFeedback {
    /// Tool groups to be displayed in the toolbar.
    public var groups: [KeyboardToolGroup] = [] {
        didSet {
            reloadBarButtonItems()
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
    private let toolbar: UIToolbar = {
        let this = UIToolbar()
        this.translatesAutoresizingMaskIntoConstraints = false
        this.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        this.setShadowImage(UIImage(), forToolbarPosition: .any)
        return this
    }()
    private var toolButtons: [KeyboardToolButton] {
        let items = toolbar.items ?? []
        return items.compactMap { barButtonItem in
            return barButtonItem.customView as? KeyboardToolButton
        }
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
        addSubview(toolbar)
    }

    private func setupLayout() {
        keyboardContentLayoutGuideLeadingConstraint = keyboardContentLayoutGuide.leadingAnchor.constraint(equalTo: leadingAnchor)
        keyboardContentLayoutGuideTrailingConstraint = keyboardContentLayoutGuide.trailingAnchor.constraint(equalTo: trailingAnchor)
        NSLayoutConstraint.activate([
            keyboardContentLayoutGuideLeadingConstraint!,
            keyboardContentLayoutGuideTrailingConstraint!,
            keyboardContentLayoutGuide.topAnchor.constraint(equalTo: topAnchor),
            keyboardContentLayoutGuide.bottomAnchor.constraint(equalTo: bottomAnchor),

            toolbar.leadingAnchor.constraint(equalTo: keyboardContentLayoutGuide.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: keyboardContentLayoutGuide.trailingAnchor),
            toolbar.topAnchor.constraint(equalTo: keyboardContentLayoutGuide.topAnchor),
            toolbar.bottomAnchor.constraint(equalTo: keyboardContentLayoutGuide.bottomAnchor)
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
    private func reloadBarButtonItems() {
        let toolbarEdgePadding: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 20 : 16
        var barButtonItems: [UIBarButtonItem] = [.fixedSpace(-toolbarEdgePadding)]
        for (idx, group) in groups.enumerated() {
            for (idx, item) in group.items.enumerated() {
                let button = KeyboardToolButton(item: item)
                button.translatesAutoresizingMaskIntoConstraints = false
                button.showToolPickerDelay = showToolPickerDelay
                barButtonItems += [UIBarButtonItem(customView: button)]
                if group.spacing != 0 && idx < group.items.count - 1 {
                    barButtonItems += [.fixedSpace(group.spacing)]
                }
            }
            if idx < groups.count - 1 {
                barButtonItems += [.flexibleSpace()]
            }
        }
        barButtonItems += [.fixedSpace(-toolbarEdgePadding)]
        toolbar.items = barButtonItems
    }
}
