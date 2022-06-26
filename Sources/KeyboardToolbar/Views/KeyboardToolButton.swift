import UIKit

final class KeyboardToolButton: UIButton {
    private enum ToolPickerDirection {
        case left
        case right
    }

    private enum ToolPickerContentSize {
        case small
        case large

        var fontSize: CGFloat {
            switch self {
            case .small:
                return 20
            case .large:
                return 30
            }
        }
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
            updateColors()
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
        updateColors()
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
            updateColors()
        }
    }
}

private extension KeyboardToolButton {
    private func setupRepresentativeTool() {
        switch item.representativeTool.displayRepresentation {
        case .text(let textConfiguration):
            setTitle(textConfiguration.text, for: .normal)
        case .image(let imageConfiguration):
            setImage(imageConfiguration.image, for: .normal)
        }
    }

    private func setContentHidden(_ isHidden: Bool) {
        imageView?.isHidden = isHidden
        titleLabel?.isHidden = isHidden
    }

    private func updateColors() {
        switch item.style {
        case .primary:
            backgroundView.fillColor = .keyboardToolButtonPrimary
            toolPickerBackgroundView.fillColor = .keyboardToolPicker
        case .secondary:
            backgroundView.fillColor = isHighlighted ? .keyboardToolButtonPrimary : .keyboardToolButtonSecondary
            toolPickerBackgroundView.fillColor = .keyboardToolPicker
        }
    }

    @objc private func touchDown(_ sender: UIButton, event: UIEvent) {
        UIDevice.current.playInputClick()
        cancelToolPickerTimer()
        guard !item.allTools.isEmpty else {
            return
        }
        setContentHidden(true)
        feedbackGenerator.prepare()
        if showToolPickerDelay > 0 {
            presentToolPicker(with: [item.representativeTool], ofContentSize: .large)
            schedulePresentingAllTools()
        } else {
            presentToolPicker(with: item.allTools, ofContentSize: .large)
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
        presentToolPicker(with: item.allTools, ofContentSize: .small)
    }

    private func presentToolPicker(with tools: [KeyboardTool], ofContentSize contentSize: ToolPickerContentSize) {
        if toolPickerBackgroundView.superview == nil {
            addSubview(toolPickerBackgroundView)
        }
        if toolPickerView.superview == nil {
            addSubview(toolPickerView)
        }
        toolPickerView.toolDisplayRepresentations = tools.map(\.displayRepresentation)
        toolPickerView.leadingSpacing = 10
        toolPickerView.trailingSpacing = 10
        toolPickerView.toolSize = frame.size
        toolPickerView.fontSize = contentSize.fontSize
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
        if toolPickerView.toolDisplayRepresentations.count > 1, let touch = event.allTouches?.first {
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
