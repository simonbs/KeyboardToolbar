#if os(iOS)
import UIKit

/// Native glass presentation used by KeyboardToolbarView on iOS 26 and later.
@available(visionOS, unavailable)
final class GlassKeyboardToolbarView: UIView, UIScrollViewDelegate {
    var groups: [KeyboardToolGroup] = [] {
        didSet { updateButtons() }
    }

    var showToolPickerDelay: TimeInterval = 0.5 {
        didSet { buttons.flatMap { $0 }.forEach { $0.showToolPickerDelay = showToolPickerDelay } }
    }
    var willPresentToolPicker: (() -> Void)?

    private let container: UIVisualEffectView
    private var capsules: [UIVisualEffectView] = []
    private var scrollViews: [Int: GlassKeyboardGroupScrollView] = [:]
    private var buttons: [[GlassKeyboardToolButton]] = []
    private var previousSize: CGSize = .zero

    init() {
        if #available(iOS 26, *) {
            let effect = UIGlassContainerEffect()
            effect.spacing = 4
            container = UIVisualEffectView(effect: effect)
        } else {
            container = UIVisualEffectView(effect: nil)
        }
        super.init(frame: .zero)
        backgroundColor = .clear
        autoresizingMask = .flexibleWidth
        semanticContentAttribute = .forceLeftToRight
        addSubview(container)
        for name in [UIResponder.keyboardWillHideNotification, UIResponder.keyboardWillChangeFrameNotification,
                     UIApplication.willResignActiveNotification] {
            NotificationCenter.default.addObserver(self, selector: #selector(cancelInteractions), name: name, object: nil)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if previousSize != bounds.size {
            cancelInteractions()
            previousSize = bounds.size
        }
        container.frame = bounds
        let scrollableGroups = Set(groups.indices.filter { groups[$0].allowsHorizontalScrolling })
        let layout = GlassKeyboardToolbarLayout(bounds: bounds, safeAreaInsets: safeAreaInsets,
                                                groupCounts: buttons.map(\.count), groupSpacings: groups.map(\.spacing),
                                                scrollableGroups: scrollableGroups)
        if capsules.count != layout.capsuleFrames.count {
            cancelInteractions()
            capsules.forEach { $0.removeFromSuperview() }
            scrollViews.removeAll()
            capsules = layout.capsuleFrames.map { _ in makeCapsule() }
        }
        for (index, capsule) in capsules.enumerated() {
            capsule.frame = layout.capsuleFrames[index]
        }
        for (groupIndex, group) in buttons.enumerated() {
            let capsuleIndex = layout.isGrouped ? groupIndex : 0
            let capsuleContent = capsules[capsuleIndex].contentView
            let buttonContainer: UIView
            if let width = layout.scrollContentWidths[groupIndex] {
                let scrollView = scrollView(for: groupIndex, in: capsuleContent)
                scrollView.frame = CGRect(origin: .zero, size: layout.capsuleFrames[capsuleIndex].size)
                scrollView.contentSize = CGSize(width: width, height: scrollView.bounds.height)
                scrollView.updateScrollingAvailability()
                buttonContainer = scrollView
            } else {
                scrollViews.removeValue(forKey: groupIndex)?.removeFromSuperview()
                buttonContainer = capsuleContent
            }
            for (buttonIndex, button) in group.enumerated() {
                if button.superview !== buttonContainer {
                    buttonContainer.addSubview(button)
                }
                button.frame = layout.buttonFrames[groupIndex][buttonIndex]
            }
        }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil {
            cancelInteractions()
        }
    }

    @objc func cancelInteractions() {
        buttons.flatMap { $0 }.forEach { $0.cancelInteraction() }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        cancelInteractions()
    }

    private func updateButtons() {
        if buttons.map(\.count) == groups.map({ $0.items.count }) {
            for (group, items) in zip(buttons, groups) {
                for (button, item) in zip(group, items.items) {
                    button.update(item: item)
                }
            }
        } else {
            cancelInteractions()
            buttons.flatMap { $0 }.forEach { $0.removeFromSuperview() }
            buttons = groups.enumerated().map { index, group in
                group.items.map { item in
                    let button = GlassKeyboardToolButton(item: item)
                    button.showToolPickerDelay = showToolPickerDelay
                    button.willPresentToolPicker = { [weak self] in self?.willPresentToolPicker?() }
                    button.willPresent = { [weak self, weak button] in
                        self?.buttons.flatMap { $0 }.filter { $0 !== button }.forEach { $0.cancelInteraction() }
                    }
                    button.pickerExpansionDidChange = { [weak self] expanded in
                        self?.scrollViews[index]?.isPickerExpanded = expanded
                    }
                    return button
                }
            }
        }
        setNeedsLayout()
    }

    private func scrollView(for groupIndex: Int, in capsuleContent: UIView) -> GlassKeyboardGroupScrollView {
        if let scrollView = scrollViews[groupIndex] {
            return scrollView
        }
        let scrollView = GlassKeyboardGroupScrollView()
        scrollView.delegate = self
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.delaysContentTouches = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.bounces = false
        capsuleContent.addSubview(scrollView)
        scrollViews[groupIndex] = scrollView
        return scrollView
    }

    private func makeCapsule() -> UIVisualEffectView {
        let capsule: UIVisualEffectView
        if #available(iOS 26, *) {
            capsule = UIVisualEffectView(effect: UIGlassEffect(style: .regular))
            capsule.cornerConfiguration = .capsule()
        } else {
            capsule = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
            capsule.layer.cornerRadius = 24
            capsule.clipsToBounds = true
        }
        capsule.accessibilityIdentifier = "keyboard-toolbar-capsule"
        container.contentView.addSubview(capsule)
        return capsule
    }
}

/// A swipe can take over a pending key press until a hold expands its picker.
private final class GlassKeyboardGroupScrollView: UIScrollView {
    var isPickerExpanded = false {
        didSet { updateScrollingAvailability() }
    }

    func updateScrollingAvailability() {
        let canScroll = contentSize.width > bounds.width + 0.001 && !isPickerExpanded
        if isScrollEnabled != canScroll { isScrollEnabled = canScroll }
    }

    override func touchesShouldCancel(in view: UIView) -> Bool {
        view is GlassKeyboardToolButton || super.touchesShouldCancel(in: view)
    }
}

#endif
