#if os(iOS)
import UIKit

// Interaction adapted from simonbs/KeyboardToolbar and Scriptable's glass keyboard toolbar.
@available(visionOS, unavailable)
final class GlassKeyboardToolButton: UIButton {
    var showToolPickerDelay: TimeInterval = 0.5
    var willPresentToolPicker: (() -> Void)?
    var willPresent: (() -> Void)?

    private var item: KeyboardToolGroupItem
    private var timer: Timer?
    private var picker: GlassKeyboardPickerView?
    private var selectedIndex: Int?
    private var trackingPress = false
    private var touchX: CGFloat = 0
    private var expandedTouchX: CGFloat?
    private var presentedAnchor: CGRect?
    private let feedback = UISelectionFeedbackGenerator()
    private let selectionIndicator = UIView()

    private var tools: [KeyboardTool] {
        Self.tools(for: item)
    }

    init(item: KeyboardToolGroupItem) {
        self.item = item
        super.init(frame: .zero)
        selectionIndicator.backgroundColor = .label.withAlphaComponent(0.12)
        selectionIndicator.isUserInteractionEnabled = false
        selectionIndicator.isHidden = true
        addSubview(selectionIndicator)
        setTitleColor(.label, for: .normal)
        tintColor = .label
        titleLabel?.font = .monospacedSystemFont(ofSize: 19, weight: .medium)
        titleLabel?.adjustsFontSizeToFitWidth = true
        titleLabel?.minimumScaleFactor = 0.7
        update(item: item)
        addTarget(self, action: #selector(press(_:event:)), for: .touchDown)
        addTarget(self, action: #selector(releasePress), for: [.touchUpInside, .touchUpOutside])
        addTarget(self, action: #selector(cancelInteraction), for: .touchCancel)
        addTarget(self, action: #selector(drag(_:event:)), for: [.touchDragInside, .touchDragOutside])
        NotificationCenter.default.addObserver(self, selector: #selector(cancelInteraction),
                                               name: UIApplication.willResignActiveNotification, object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(item: KeyboardToolGroupItem) {
        let oldTools = tools
        let newTools = Self.tools(for: item)
        let sameChoices = oldTools.count == newTools.count && zip(oldTools, newTools).allSatisfy { oldTool, newTool in
            oldTool.displayRepresentation.matches(newTool.displayRepresentation)
        }
        if !item.isEnabled || !sameChoices ||
            !self.item.representativeTool.displayRepresentation.matches(item.representativeTool.displayRepresentation) {
            cancelInteraction()
        }
        self.item = item
        isEnabled = item.isEnabled
        alpha = isEnabled ? 1 : 0.3
        contentEdgeInsets = UIEdgeInsets(top: item.contentEdgeInsets.top, left: item.contentEdgeInsets.leading,
                                        bottom: item.contentEdgeInsets.bottom, right: item.contentEdgeInsets.trailing)
        let representation = item.representativeTool.displayRepresentation
        if case .text(let configuration) = representation {
            setTitle(configuration.text, for: .normal)
        } else {
            setTitle(nil, for: .normal)
        }
        setImage(representation.image(), for: .normal)
        let foreground: UIColor = item.style == .secondary ? .secondaryLabel : .label
        setTitleColor(foreground, for: .normal)
        tintColor = foreground
        accessibilityLabel = item.accessibilityLabel ?? item.representativeTool.accessibilityLabel ?? representation.spokenName
        accessibilityIdentifier = item.accessibilityIdentifier ?? "keyboard-toolbar-" + representation.identifier
        accessibilityHint = tools.isEmpty ? nil : "Touch and hold, then slide to choose a tool."
        accessibilityCustomActions = tools.enumerated().map { index, tool in
            UIAccessibilityCustomAction(name: tool.accessibilityLabel ?? tool.displayRepresentation.spokenName) { [weak self] _ in
                guard let self, self.isEnabled, self.tools.indices.contains(index) else {
                    return false
                }
                self.cancelInteraction()
                self.tools[index].performAction()
                return true
            }
        }
    }

    override func accessibilityActivate() -> Bool {
        guard isEnabled else {
            return false
        }
        cancelInteraction()
        item.representativeTool.performAction()
        return true
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil { cancelInteraction() }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if let presentedAnchor, let window, convert(bounds, to: window) != presentedAnchor {
            cancelInteraction()
        }
        let diameter = min(44, bounds.width, bounds.height)
        selectionIndicator.frame = CGRect(
            x: bounds.midX - diameter / 2, y: bounds.midY - diameter / 2, width: diameter, height: diameter
        )
        selectionIndicator.layer.cornerRadius = diameter / 2
        if case .text(let configuration) = item.representativeTool.displayRepresentation {
            titleLabel?.frame = (titleLabel?.frame ?? .zero).offsetBy(dx: configuration.offset.x, dy: configuration.offset.y)
        }
        sendSubviewToBack(selectionIndicator)
    }

    /// Cancellation never performs a tool action, including interrupted touches and editor detachment.
    @objc func cancelInteraction() {
        trackingPress = false
        isSelected = false
        timer?.invalidate()
        timer = nil
        picker?.removeFromSuperview()
        picker = nil
        selectedIndex = nil
        expandedTouchX = nil
        presentedAnchor = nil
        selectionIndicator.isHidden = true
    }

    @objc private func press(_ sender: UIButton, event: UIEvent?) {
        cancelInteraction()
        guard isEnabled, window != nil else {
            return
        }
        willPresent?()
        trackingPress = true
        touchX = event?.touches(for: self)?.first?.location(in: self).x ?? bounds.midX
        isSelected = true
        selectionIndicator.isHidden = false
        UIDevice.current.playInputClick()
        guard !tools.isEmpty else {
            return
        }
        willPresentToolPicker?()
        guard trackingPress, isEnabled, window != nil else { return }
        feedback.prepare()
        present([item.representativeTool], selectedIndex: nil)
        if showToolPickerDelay <= 0 {
            expand()
            return
        }
        let timer = Timer(timeInterval: showToolPickerDelay, target: self, selector: #selector(expand), userInfo: nil, repeats: false)
        self.timer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    @objc private func expand() {
        timer?.invalidate()
        timer = nil
        guard trackingPress, isEnabled, window != nil, !tools.isEmpty else {
            return
        }
        selectedIndex = 0
        expandedTouchX = touchX
        present(tools, selectedIndex: 0)
        if let picker {
            picker.beginSelection(at: convert(CGPoint(x: touchX, y: bounds.midY), to: picker))
        }
        feedback.selectionChanged()
    }

    @objc private func drag(_ sender: UIButton, event: UIEvent) {
        guard let touch = event.touches(for: self)?.first ?? event.allTouches?.first else {
            return
        }
        trackTouch(at: touch.location(in: self))
    }

    func trackTouch(at location: CGPoint) {
        touchX = location.x
        guard let expandedTouchX, let picker else {
            return
        }
        // Screen-edge fitting can move the first choice away from the finger. Start
        // from that choice and apply only movement since expansion, avoiding a jump.
        let index = picker.index(forHorizontalTranslation: touchX - expandedTouchX)
        if selectedIndex != index {
            selectedIndex = index
            picker.select(index)
            feedback.selectionChanged()
        }
    }

    @objc private func releasePress() {
        guard trackingPress, isEnabled, window != nil else {
            cancelInteraction()
            return
        }
        let tool = selectedIndex.flatMap { tools.indices.contains($0) ? tools[$0] : nil } ?? item.representativeTool
        cancelInteraction()
        tool.performAction()
    }

    private func present(_ tools: [KeyboardTool], selectedIndex: Int?) {
        guard let window else {
            return
        }
        let anchor = convert(bounds, to: window)
        presentedAnchor = anchor
        let available = window.bounds.inset(by: UIEdgeInsets(
            top: window.safeAreaInsets.top, left: max(8, window.safeAreaInsets.left),
            bottom: 0, right: max(8, window.safeAreaInsets.right)
        ))
        let picker = self.picker ?? GlassKeyboardPickerView()
        self.picker = picker
        picker.overrideUserInterfaceStyle = traitCollection.userInterfaceStyle
        window.addSubview(picker)
        picker.show(tools.map(\.displayRepresentation),
                    layout: GlassKeyboardPickerLayout(anchor: anchor, available: available, count: tools.count),
                    selectedIndex: selectedIndex, accessibilityLabels: tools.map(\.accessibilityLabel))
    }

    private static func tools(for item: KeyboardToolGroupItem) -> [KeyboardTool] {
        item.includeRepresentativeToolInPicker ? [item.representativeTool] + item.tools : item.tools
    }
}

#endif
