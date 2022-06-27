import UIKit

final class KeyboardToolButton: UIButton {
    private enum ToolPickerDirection {
        case left
        case right
    }

    var showToolPickerDelay: TimeInterval = 0.5

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
    private let feedbackGenerator = UISelectionFeedbackGenerator()
    private let item: KeyboardToolGroupItem
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
        addTarget(self, action: #selector(touchUp), for: .touchCancel)
        addTarget(self, action: #selector(touchDragged(_:event:)), for: .touchDragInside)
        addTarget(self, action: #selector(touchDragged(_:event:)), for: .touchDragOutside)
        setupRepresentativeTool()
        updateBackgroundColor()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        isEnabled = item.isEnabled
    }

    override func layoutSubviews() {
        super.layoutSubviews()
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

    @objc private func touchDown(_ sender: UIButton, event: UIEvent) {
        toolPickerBackgroundView.fillColor = toolPickerBackgroundColor
        UIDevice.current.playInputClick()
        cancelToolPickerTimer()
        guard !item.allTools.isEmpty else {
            return
        }
        setContentHidden(true)
        feedbackGenerator.prepare()
        if showToolPickerDelay > 0 {
            presentToolPicker(with: [item.representativeTool], atSize: .large)
            schedulePresentingAllTools()
        } else {
            presentToolPicker(with: item.allTools, atSize: .large)
        }
    }

    @objc private func touchUp() {
        setContentHidden(false)
        cancelToolPickerTimer()
        backgroundView.isHidden = false
        toolPickerView.removeFromSuperview()
        toolPickerBackgroundView.removeFromSuperview()
        if let highlightedIndex = toolPickerView.highlightedIndex {
            let tool = item.allTools[highlightedIndex]
            tool.performAction()
        } else {
            item.representativeTool.performAction()
        }
    }

    @objc private func touchDragged(_ sender: UIButton, event: UIEvent) {
        updateHiglightedTool(for: event)
    }

    private func schedulePresentingAllTools() {
        let delay = showToolPickerDelay
        let selector = #selector(toolPickerTimerTriggered)
        let timer = Timer(timeInterval: delay, target: self, selector: selector, userInfo: nil, repeats: false)
        toolPickerTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func cancelToolPickerTimer() {
        toolPickerTimer?.invalidate()
        toolPickerTimer = nil
    }

    @objc private func toolPickerTimerTriggered() {
        feedbackGenerator.selectionChanged()
        cancelToolPickerTimer()
        presentToolPicker(with: item.allTools, atSize: .small)
    }

    private func presentToolPicker(with tools: [KeyboardTool], atSize contentSize: KeyboardToolContentSize) {
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
        toolPickerBackgroundView.preferredHandleXPosition = toolPickerLayout.handleXPosition
        toolPickerBackgroundView.frame = toolPickerLayout.backgroundFrame
        backgroundView.isHidden = true
        if tools.count > 1 {
            toolPickerView.highlightTool(at: 0)
        } else {
            toolPickerView.clearHighlightedTool()
        }
    }

    private func updateHiglightedTool(for event: UIEvent) {
        if toolPickerView.toolCount > 1, let touch = event.allTouches?.first {
            let location = touch.location(in: toolPickerView)
            let oldHighlightedIndex = toolPickerView.highlightedIndex
            toolPickerView.highlightTool(closestTo: location)
            if toolPickerView.highlightedIndex != oldHighlightedIndex {
                feedbackGenerator.selectionChanged()
            }
        } else {
            toolPickerView.clearHighlightedTool()
        }
    }

    private func toolPickerLayout(forShowingNumberOfTools toolCount: Int) -> KeyboardToolPickerLayout {
        if toolCount == 1 {
            return KeyboardToolPickerFrameCalculator.singleToolLayout(forPresenting: toolPickerView, and: toolPickerBackgroundView, from: self)
        } else {
            return KeyboardToolPickerFrameCalculator.multipleToolsLayout(forPresenting: toolPickerView, and: toolPickerBackgroundView, from: self)
        }
    }
}

private extension UIEdgeInsets {
    init(_ edgeInsets: NSDirectionalEdgeInsets) {
        self.init(top: edgeInsets.top, left: edgeInsets.leading, bottom: edgeInsets.bottom, right: edgeInsets.trailing)
    }
}
