import UIKit

final class KeyboardToolPickerBackgroundView: UIView {
    var handleSize = CGSize(width: 30, height: 30) {
        didSet {
            if handleSize != oldValue {
                setNeedsLayout()
            }
        }
    }
    var preferredHandleXPosition: CGFloat = 0 {
        didSet {
            if preferredHandleXPosition != oldValue {
                setNeedsLayout()
            }
        }
    }
    var fillColor: UIColor {
        get {
            drawingBackgroundView.fillColor
        }
        set {
            drawingBackgroundView.fillColor = newValue
        }
    }
    override var frame: CGRect {
        didSet {
            if frame.size != oldValue.size {
                setNeedsLayout()
            }
        }
    }
    let plateHeight: CGFloat = 54
    var pathConfig: KeyboardToolPickerBackgroundPathConfiguration {
        KeyboardToolPickerBackgroundPathConfiguration(
            bounds: bounds,
            handleSize: handleSize,
            preferredHandleXPosition: preferredHandleXPosition
        )
    }

    private let drawingBackgroundView = DrawingKeyboardToolPickerBackgroundView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        addSubview(drawingBackgroundView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        drawingBackgroundView.pathConfig = pathConfig
        drawingBackgroundView.frame = CGRect(origin: .zero, size: bounds.size)
    }

    func preferredSize(containingContentWidth contentWidth: CGFloat) -> CGSize {
        let width = contentWidth + pathConfig.shadowBlur * 2
        let height = plateHeight + pathConfig.handleSize.height + pathConfig.shadowBlur * 2
        return CGSize(width: width, height: height)
    }
}
