import UIKit

final class KeyboardToolButton: UIButton {
    var showToolPickerDelay: TimeInterval = 0.5
    var willPresentToolPicker: (() -> Void)?

    override var isEnabled: Bool {
        didSet {
            if !isEnabled { cancelInteraction() }
        }
    }

    override var intrinsicContentSize: CGSize {
        let imageWidth = imageView?.image?.size.width ?? 0
        let paddedImageWidth = imageWidth + imagePadding * 2
        let width = max(paddedImageWidth, 32)
        return CGSize(width: width, height: 42)
    }
    override var isHighlighted: Bool {
        didSet {
            updateBackgroundColor()
        }
    }

    private let backgroundView: KeyboardToolButtonBackgroundView = {
        let view = KeyboardToolButtonBackgroundView()
        view.isUserInteractionEnabled = false
        return view
    }()
    private let toolPickerView = KeyboardToolPickerView()
    private let toolPickerBackgroundView = KeyboardToolPickerBackgroundView()
    private var toolPickerTimer: Timer?
    #if !os(xrOS)
    private let feedbackGenerator = UISelectionFeedbackGenerator()
    #endif
    private var item: KeyboardToolGroupItem
    private var trackingPress = false
    private var selectedIndex: Int?
    private var touchX: CGFloat = 0
    private var expandedTouchX: CGFloat?
    private var selectionTravel: CGFloat = 1
    private var presentedAnchor: CGRect?
    private var imagePadding: CGFloat = 5
    private var backgroundInsets: UIEdgeInsets = .zero {
        didSet {
            if backgroundInsets != oldValue {
                setNeedsLayout()
            }
        }
    }
    private var toolPickerBackgroundColor: UIColor {
        // Get the background color from a screenshot to ensure we get the right color for all keyboards.
        // This is in particular relevant when using dark keyboards where both the keyboard and the buttons are transulcent.
        let colorSamplePoint = CGPoint(x: frame.size.width / 2, y: 0)
        return color(at: colorSamplePoint) ?? .black
    }

    init(item: KeyboardToolGroupItem) {
        self.item = item
        super.init(frame: .zero)
        if #available(iOS 15, *) {
            configuration = .plain()
            configuration?.contentInsets = item.contentEdgeInsets
        } else {
            contentEdgeInsets = UIEdgeInsets(item.contentEdgeInsets)
        }
        tintColor = .label
        setTitleColor(.label, for: .normal)
        adjustsImageSizeForAccessibilityContentSizeCategory = true
        if #available(iOS 15, *) {
            maximumContentSizeCategory = .extraExtraLarge
        }
        addSubview(backgroundView)
        addTarget(self, action: #selector(touchDown(_:event:)), for: .touchDown)
        addTarget(self, action: #selector(touchUp), for: .touchUpInside)
        addTarget(self, action: #selector(touchUp), for: .touchUpOutside)
        addTarget(self, action: #selector(cancelInteraction), for: .touchCancel)
        addTarget(self, action: #selector(touchDragged(_:event:)), for: .touchDragInside)
        addTarget(self, action: #selector(touchDragged(_:event:)), for: .touchDragOutside)
        NotificationCenter.default.addObserver(self, selector: #selector(cancelInteraction),
                                               name: UIApplication.willResignActiveNotification, object: nil)
        update(item: item)

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if superview == nil { cancelInteraction() }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil { cancelInteraction() }
    }

    func update(item: KeyboardToolGroupItem) {
        let oldTools = self.item.allTools
        let newTools = item.allTools
        let sameChoices = oldTools.count == newTools.count && zip(oldTools, newTools).allSatisfy {
            $0.displayRepresentation.matches($1.displayRepresentation)
        }
        if !item.isEnabled || !sameChoices || self.item.style != item.style ||
            self.item.contentEdgeInsets != item.contentEdgeInsets ||
            !self.item.representativeTool.displayRepresentation.matches(item.representativeTool.displayRepresentation) {
            cancelInteraction()
        }
        self.item = item
        isEnabled = item.isEnabled
        if #available(iOS 15, *) {
            configuration?.contentInsets = item.contentEdgeInsets
        } else {
            contentEdgeInsets = UIEdgeInsets(item.contentEdgeInsets)
        }
        setupRepresentativeTool()
        updateBackgroundColor()
        accessibilityLabel = item.accessibilityLabel ?? item.representativeTool.accessibilityLabel
            ?? item.representativeTool.displayRepresentation.spokenName
        accessibilityIdentifier = item.accessibilityIdentifier
            ?? "keyboard-toolbar-" + item.representativeTool.displayRepresentation.identifier
        accessibilityHint = newTools.isEmpty ? nil : "Touch and hold, then slide to choose a tool."
        accessibilityCustomActions = newTools.enumerated().map { index, tool in
            UIAccessibilityCustomAction(name: tool.accessibilityLabel ?? tool.displayRepresentation.spokenName) { [weak self] _ in
                guard let self, self.isEnabled, self.item.allTools.indices.contains(index) else { return false }
                self.cancelInteraction()
                self.item.allTools[index].performAction()
                return true
            }
        }
        invalidateIntrinsicContentSize()
    }

    func trackTouch(at location: CGPoint) {
        touchX = location.x
        guard trackingPress, let expandedTouchX, toolPickerView.toolCount > 1 else { return }
        let direction: CGFloat = toolPickerView.showReversed ? -1 : 1
        let progress = max(0, min(1, direction * (touchX - expandedTouchX) / selectionTravel))
        let index = Int((progress * CGFloat(toolPickerView.toolCount - 1)).rounded())
        if index != selectedIndex {
            selectedIndex = index
            // Use the picker's hit-testing path so it also clears the previous tool's highlight.
            let visualIndex = toolPickerView.showReversed ? toolPickerView.toolCount - index - 1 : index
            let x = toolPickerView.leadingSpacing + toolPickerView.toolSize.width / 2
                + CGFloat(visualIndex) * (toolPickerView.toolSize.width + toolPickerView.toolSpacing)
            toolPickerView.highlightTool(closestTo: CGPoint(x: x, y: toolPickerView.bounds.midY))
            #if !os(xrOS)
            feedbackGenerator.selectionChanged()
            #endif
        }
    }

    override func accessibilityActivate() -> Bool {
        guard isEnabled else { return false }
        cancelInteraction()
        item.representativeTool.performAction()
        return true
    }

    /// Interrupted touches and editor detachment must never commit a tool.
    @objc func cancelInteraction() {
        trackingPress = false
        selectedIndex = nil
        expandedTouchX = nil
        presentedAnchor = nil
        isHighlighted = false
        setContentHidden(false)
        cancelToolPickerTimer()
        backgroundView.isHidden = false
        toolPickerView.clearHighlightedTool()
        toolPickerView.removeFromSuperview()
        toolPickerBackgroundView.removeFromSuperview()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if let presentedAnchor, let window, convert(bounds, to: window) != presentedAnchor {
            cancelInteraction()
        }
        sendSubviewToBack(backgroundView)
        let backgroundWidth = bounds.width - backgroundInsets.left - backgroundInsets.right
        let backgroundHeight = bounds.height - backgroundInsets.top - backgroundInsets.bottom
        backgroundView.frame = CGRect(x: backgroundInsets.left, y: backgroundInsets.top, width: backgroundWidth, height: backgroundHeight)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateBackgroundColor()
        }
    }
}

private extension KeyboardToolButton {
    private func setupRepresentativeTool() {
        setTitle(nil, for: .normal)
        setImage(nil, for: .normal)
        switch item.representativeTool.displayRepresentation {
        case .text(let configuration):
            titleLabel?.font = configuration.font(ofSize: .small)
            setTitle(configuration.text, for: .normal)
        case .image(let configuration):
            setImage(configuration.image(ofSize: .small), for: .normal)
        case .symbol(let configuration):
            setImage(configuration.image(ofSize: .small), for: .normal)
        }
    }

    private func setContentHidden(_ isHidden: Bool) {
        imageView?.isHidden = isHidden
        titleLabel?.isHidden = isHidden
    }

    private func updateBackgroundColor() {
        switch item.style {
        case .primary:
            backgroundView.fillColor = .keyboardToolButtonPrimary
        case .secondary:
            backgroundView.fillColor = isHighlighted ? .keyboardToolButtonPrimary : .keyboardToolButtonSecondary
        }
    }

    @objc private func touchDown(_ sender: UIButton, event: UIEvent?) {
        cancelInteraction()
        guard isEnabled, window != nil else { return }
        trackingPress = true
        isHighlighted = true
        touchX = event?.touches(for: self)?.first?.location(in: self).x ?? bounds.midX
        toolPickerBackgroundView.fillColor = toolPickerBackgroundColor
        #if !os(xrOS)
        UIDevice.current.playInputClick()
        #endif
        guard item.style == .primary || !item.allTools.isEmpty else { return }
        willPresentToolPicker?()
        guard trackingPress, isEnabled, window != nil else { return }
        setContentHidden(true)
        #if !os(xrOS)
        feedbackGenerator.prepare()
        #endif
        presentToolPicker(with: [item.representativeTool], atSize: .large)
        guard !item.allTools.isEmpty else { return }
        if showToolPickerDelay > 0 {
            schedulePresentingAllTools()
        } else {
            toolPickerTimerTriggered()
        }
    }

    @objc private func touchUp() {
        guard trackingPress, isEnabled, window != nil else {
            cancelInteraction()
            return
        }
        let tool = selectedIndex.flatMap { item.allTools.indices.contains($0) ? item.allTools[$0] : nil }
            ?? item.representativeTool
        cancelInteraction()
        tool.performAction()
    }

    @objc private func touchDragged(_ sender: UIButton, event: UIEvent) {
        guard trackingPress, let touch = event.touches(for: self)?.first ?? event.allTouches?.first else { return }
        trackTouch(at: touch.location(in: self))
    }

    private func schedulePresentingAllTools() {
        let timer = Timer(timeInterval: showToolPickerDelay, repeats: false) { [weak self] _ in
            self?.toolPickerTimerTriggered()
        }
        toolPickerTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func cancelToolPickerTimer() {
        toolPickerTimer?.invalidate()
        toolPickerTimer = nil
    }

    @objc private func toolPickerTimerTriggered() {
        cancelToolPickerTimer()
        guard trackingPress, isEnabled, let window, !item.allTools.isEmpty else { return }
        selectedIndex = 0
        expandedTouchX = touchX
        presentToolPicker(with: item.allTools, atSize: .small)
        toolPickerView.highlightTool(at: 0)
        // Anchor at the finger at expansion. Fitting the popup to the screen must
        // not move selection, and every option must be reachable without leaving it.
        let fingerX = convert(CGPoint(x: touchX, y: bounds.midY), to: window).x
        let finalVisualIndex = toolPickerView.showReversed ? 0 : toolPickerView.toolCount - 1
        let finalX = toolPickerView.leadingSpacing + toolPickerView.toolSize.width / 2
            + CGFloat(finalVisualIndex) * (toolPickerView.toolSize.width + toolPickerView.toolSpacing)
        let farthestX = toolPickerView.convert(CGPoint(x: finalX, y: 0), to: window).x
        let direction: CGFloat = toolPickerView.showReversed ? -1 : 1
        let availableTravel = direction < 0
            ? fingerX - window.bounds.minX - max(8, window.safeAreaInsets.left)
            : window.bounds.maxX - max(8, window.safeAreaInsets.right) - fingerX
        selectionTravel = max(1, min(max(1, direction * (farthestX - fingerX)), availableTravel))
        #if !os(xrOS)
        feedbackGenerator.selectionChanged()
        #endif
    }

    private func presentToolPicker(with tools: [KeyboardTool], atSize contentSize: KeyboardToolContentSize) {
        guard let window, !tools.isEmpty else { return }
        presentedAnchor = convert(bounds, to: window)
        if toolPickerBackgroundView.superview == nil {
            addSubview(toolPickerBackgroundView)
        }
        if toolPickerView.superview == nil {
            addSubview(toolPickerView)
        }
        let displayRepresentations = tools.map(\.displayRepresentation)
        toolPickerView.show(displayRepresentations, atSize: contentSize)
        toolPickerView.leadingSpacing = 10
        toolPickerView.trailingSpacing = 10
        toolPickerView.toolSize = frame.size
        toolPickerBackgroundView.handleSize = KeyboardToolPickerFrameCalculator.handleSize(from: self)
        let toolPickerLayout = toolPickerLayout(forShowingNumberOfTools: tools.count)
        toolPickerView.showReversed = toolPickerLayout.isReverse
        toolPickerView.frame = toolPickerLayout.pickerFrame
        toolPickerView.layoutIfNeeded()
        toolPickerBackgroundView.preferredHandleXPosition = toolPickerLayout.handleXPosition
        toolPickerBackgroundView.frame = toolPickerLayout.backgroundFrame
        backgroundView.isHidden = true
        if tools.count > 1 {
            toolPickerView.highlightTool(at: 0)
        } else {
            toolPickerView.clearHighlightedTool()
        }
    }

    private func toolPickerLayout(forShowingNumberOfTools toolCount: Int) -> KeyboardToolPickerLayout {
        if toolCount == 1 {
            return KeyboardToolPickerFrameCalculator.singleToolLayout(
                forPresenting: toolPickerView,
                and: toolPickerBackgroundView,
                from: self
            )
        } else {
            return KeyboardToolPickerFrameCalculator.multipleToolsLayout(
                forPresenting: toolPickerView,
                and: toolPickerBackgroundView,
                from: self
            )
        }
    }

}

private extension UIEdgeInsets {
    init(_ edgeInsets: NSDirectionalEdgeInsets) {
        self.init(top: edgeInsets.top, left: edgeInsets.leading, bottom: edgeInsets.bottom, right: edgeInsets.trailing)
    }
}
