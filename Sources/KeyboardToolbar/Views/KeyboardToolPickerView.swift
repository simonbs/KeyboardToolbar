import UIKit

final class KeyboardToolPickerView: UIView {
    var leadingSpacing: CGFloat = 0 {
        didSet {
            if trailingSpacing != oldValue {
                invalidateIntrinsicContentSize()
                setNeedsLayout()
            }
        }
    }
    var trailingSpacing: CGFloat = 0 {
        didSet {
            if trailingSpacing != oldValue {
                invalidateIntrinsicContentSize()
                setNeedsLayout()
            }
        }
    }
    var toolSize = CGSize(width: 25, height: 25) {
        didSet {
            if toolSize != oldValue {
                invalidateIntrinsicContentSize()
                setNeedsLayout()
            }
        }
    }
    var toolSpacing: CGFloat = 6 {
        didSet {
            if toolSpacing != oldValue {
                invalidateIntrinsicContentSize()
                setNeedsLayout()
            }
        }
    }
    var toolDisplayRepresentations: [KeyboardToolDisplayRepresentation] = [] {
        didSet {
            highlightedIndex = nil
            removeToolViews()
            addToolViews()
        }
    }
    private(set) var highlightedIndex: Int?
    var showReversed = false {
        didSet {
            if showReversed != oldValue {
                setNeedsLayout()
            }
        }
    }
    var fontSize: CGFloat = 20 {
        didSet {
            for toolView in toolViews {
                toolView.fontSize = fontSize
            }
        }
    }
    override var intrinsicContentSize: CGSize {
        let totalViewWidth = CGFloat(toolDisplayRepresentations.count) * toolSize.width
        let totalSpacing = max(CGFloat(toolDisplayRepresentations.count - 1), 0) * toolSpacing
        let width = leadingSpacing + trailingSpacing + totalViewWidth + totalSpacing
        return CGSize(width: width, height: toolSize.height)
    }

    private var toolViews: [KeyboardToolView] = []
    private let highlightBackgroundView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 5
        view.isHidden = true
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        highlightBackgroundView.backgroundColor = .systemBlue
        addSubview(highlightBackgroundView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutToolViews()
        layoutHighlightBackgroundView()
    }

    func highlightTool(closestTo location: CGPoint) {
        if let index = indexOfTool(closestTo: location) {
            highlightTool(at: index)
        }
    }

    func highlightTool(at index: Int) {
        highlightedIndex = index
        highlightBackgroundView.isHidden = highlightedIndex == nil
        layoutHighlightBackgroundView()
        toolViews[index].isHighlighted = true
    }

    func clearHighlightedTool() {
        highlightedIndex = nil
        highlightBackgroundView.isHidden = true
    }
}

private extension KeyboardToolPickerView {
    private func removeToolViews() {
        for toolView in toolViews {
            toolView.removeFromSuperview()
        }
        toolViews = []
    }

    private func addToolViews() {
        for toolDisplay in toolDisplayRepresentations {
            let toolView = KeyboardToolView()
            toolView.foregroundColor = .keyboardToolForeground
            toolView.highlightedForegroundColor = .keyboardToolForegroundHighlighted
            toolView.fontSize = fontSize
            toolView.show(toolDisplay)
            addSubview(toolView)
            toolViews.append(toolView)
        }
    }

    private func layoutToolViews() {
        for (idx, toolView) in toolViews.enumerated() {
            toolView.frame = frameForTool(at: idx)
        }
    }

    private func layoutHighlightBackgroundView() {
        if let highlightedIndex = highlightedIndex {
            highlightBackgroundView.frame = frameForTool(at: highlightedIndex)
        }
    }

    private func frameForTool(at index: Int) -> CGRect {
        let adjustedIndex = showReversed ? toolDisplayRepresentations.count - index - 1 : index
        let xPosition = leadingSpacing + CGFloat(adjustedIndex) * (toolSize.width + toolSpacing)
        let yPosition = (bounds.height - toolSize.height) / 2
        let origin = CGPoint(x: xPosition, y: yPosition)
        return CGRect(origin: origin, size: toolSize)
    }

    private func indexOfTool(closestTo location: CGPoint) -> Int? {
        var candidateIndex: Int?
        var candidateDistance: CGFloat = .greatestFiniteMagnitude
        for (idx, toolView) in toolViews.enumerated() {
            toolView.isHighlighted = false
            let distance = abs(toolView.frame.midX - location.x)
            if distance < candidateDistance {
                candidateIndex = idx
                candidateDistance = distance
            }
        }
        return candidateIndex
    }
}
