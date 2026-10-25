import UIKit

/// Toolbar to be displayed above the keyboard.
///
/// Assign to a text input's `inputAccessoryView`. On iOS 26 and later, groups use
/// native Liquid Glass capsules. Earlier iOS versions and visionOS keep the classic key appearance.
public final class KeyboardToolbarView: UIInputView, UIInputViewAudioFeedback {
    /// Tool groups displayed in order. Empty groups are ignored.
    public var groups: [KeyboardToolGroup] = [] {
        didSet { reloadButtons() }
    }
    /// Duration before a held item expands its alternatives. Zero expands immediately.
    public var showToolPickerDelay: TimeInterval = 0.5 {
        didSet {
            legacyButtons.flatMap { $0 }.forEach { $0.showToolPickerDelay = showToolPickerDelay }
            #if os(iOS)
            glassView?.showToolPickerDelay = showToolPickerDelay
            #endif
        }
    }
    /// Called before a tool picker appears, for example to dismiss an editor's completions.
    public var willPresentToolPicker: (() -> Void)?

    #if !os(visionOS)
    public var enableInputClicksWhenVisible: Bool { true }
    #endif

    private let stackView = UIStackView()
    private var legacyButtons: [[KeyboardToolButton]] = []
    private var previousSize: CGSize = .zero
    #if os(iOS)
    private var glassView: GlassKeyboardToolbarView?
    #endif

    /// Initializes a keyboard accessory with the appropriate system appearance.
    public init() {
        var usesGlass = false
        #if os(iOS)
        if #available(iOS 26, *) { usesGlass = true }
        #endif
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: usesGlass ? 60 : 46),
                   inputViewStyle: usesGlass ? .default : .keyboard)
        backgroundColor = .clear
        autoresizingMask = .flexibleWidth
        #if os(iOS)
        if usesGlass {
            let glassView = GlassKeyboardToolbarView()
            glassView.willPresentToolPicker = { [weak self] in self?.willPresentToolPicker?() }
            self.glassView = glassView
            addSubview(glassView)
        } else {
            configureLegacyStack()
        }
        #else
        configureLegacyStack()
        #endif
        for name in [UIResponder.keyboardWillHideNotification, UIResponder.keyboardWillChangeFrameNotification,
                     UIApplication.willResignActiveNotification] {
            NotificationCenter.default.addObserver(self, selector: #selector(cancelInteractions), name: name, object: nil)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func layoutSubviews() {
        super.layoutSubviews()
        if previousSize != bounds.size {
            cancelInteractions()
            previousSize = bounds.size
        }
        #if os(iOS)
        if let glassView {
            glassView.frame = bounds
            return
        }
        #endif
        let margin = InputToolMargin.rawValue(for: traitCollection)
        stackView.frame = bounds.insetBy(dx: margin, dy: 0)
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil { cancelInteractions() }
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setNeedsLayout()
    }

    /// Discards pending presses without performing an action and closes any picker.
    @objc public func cancelInteractions() {
        legacyButtons.flatMap { $0 }.forEach { $0.cancelInteraction() }
        #if os(iOS)
        glassView?.cancelInteractions()
        #endif
    }

    private func configureLegacyStack() {
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        addSubview(stackView)
    }

    private func reloadButtons() {
        let groups = groups.filter { !$0.items.isEmpty }
        #if os(iOS)
        if let glassView {
            glassView.groups = groups
            return
        }
        #endif
        if legacyButtons.map(\.count) == groups.map({ $0.items.count }) {
            for (index, group) in groups.enumerated() {
                (stackView.arrangedSubviews[index] as? UIStackView)?.spacing = group.spacing
                for (button, item) in zip(legacyButtons[index], group.items) { button.update(item: item) }
            }
        } else {
            cancelInteractions()
            stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
            legacyButtons = groups.map { group in
                let groupStack = UIStackView()
                groupStack.axis = .horizontal
                groupStack.alignment = .center
                groupStack.spacing = group.spacing
                let buttons = group.items.map { item in
                    let button = KeyboardToolButton(item: item)
                    button.translatesAutoresizingMaskIntoConstraints = false
                    button.showToolPickerDelay = showToolPickerDelay
                    button.willPresentToolPicker = { [weak self, weak button] in
                        self?.legacyButtons.flatMap { $0 }.filter { $0 !== button }.forEach { $0.cancelInteraction() }
                        self?.willPresentToolPicker?()
                    }
                    groupStack.addArrangedSubview(button)
                    return button
                }
                stackView.addArrangedSubview(groupStack)
                return buttons
            }
        }
        setNeedsLayout()
    }
}
