import UIKit

final class KeyboardToolPickerBackgroundView: UIView {
    enum Style: Equatable {
        case solidColor(UIColor)
        case blurEffect(UIBlurEffect.Style)
    }

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
    var style: Style = .solidColor(.white) {
        didSet {
            if style != oldValue {
                switch style {
                case .solidColor(let color):
                    visualEffectBackgroundView.removeFromSuperview()
                    drawingBackgroundView.fillColor = color
                    if drawingBackgroundView.superview == nil {
                        addSubview(drawingBackgroundView)
                    }
                case .blurEffect(let style):
                    drawingBackgroundView.removeFromSuperview()
                    visualEffectBackgroundView.effect = UIBlurEffect(style: style)
                    if visualEffectBackgroundView.superview == nil {
                        addSubview(visualEffectBackgroundView)
                    }
                }
            }
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
    private let visualEffectBackgroundView = UIVisualEffectView()
    private let visualEffectBackgroundMaskLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        switch style {
        case .solidColor:
            drawingBackgroundView.pathConfig = pathConfig
            drawingBackgroundView.frame = CGRect(origin: .zero, size: bounds.size)
        case .blurEffect:
            visualEffectBackgroundMaskLayer.path = CGPath.keyboardToolPickerBackground(with: pathConfig)
            visualEffectBackgroundMaskLayer.frame = CGRect(origin: .zero, size: bounds.size)
            visualEffectBackgroundView.frame = CGRect(origin: .zero, size: bounds.size)
            visualEffectBackgroundView.layer.mask = visualEffectBackgroundMaskLayer
        }
    }

    func preferredSize(containingContentWidth contentWidth: CGFloat) -> CGSize {
        let width = contentWidth + pathConfig.shadowBlur * 2
        let height = plateHeight + pathConfig.handleSize.height + pathConfig.shadowBlur * 2
        return CGSize(width: width, height: height)
    }
}
