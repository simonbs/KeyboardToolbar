import UIKit

final class KeyboardToolButtonBackgroundView: UIView {
    var cornerRadius: CGFloat = 5 {
        didSet {
            if cornerRadius != oldValue {
                setNeedsDisplay()
            }
        }
    }
    var fillColor: UIColor? {
        didSet {
            if fillColor != oldValue {
                setNeedsDisplay()
            }
        }
    }
    var shadowColor: UIColor? = .black.withAlphaComponent(0.2) {
        didSet {
            if shadowColor != oldValue {
                setNeedsDisplay()
            }
        }
    }
    var shadowLength: CGFloat = 1 {
        didSet {
            if shadowLength != oldValue {
                setNeedsDisplay()
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        let context = UIGraphicsGetCurrentContext()
        context?.clear(rect)
        if let fillColor = fillColor {
            let fillRect = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height - shadowLength)
            let fillPath = CGPath(roundedRect: fillRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
            if let shadowColor = shadowColor, shadowLength != 0 {
                var transform = CGAffineTransform(translationX: 0, y: shadowLength)
                if let shadowPath = fillPath.copy(using: &transform) {
                    context?.saveGState()
                    // Draw the shadow
                    context?.addPath(shadowPath)
                    context?.setFillColor(shadowColor.cgColor)
                    context?.fillPath()
                    // Cut the filled rectangle out of the shadow so the shadow underneath isn't visible when the fill color isn't fully opaque.
                    context?.addPath(fillPath)
                    context?.setBlendMode(.clear)
                    context?.setFillColor(UIColor.black.cgColor)
                    context?.fillPath()
                    context?.restoreGState()
                }
            }
            // Draw the rectangle that will be visible.
            context?.addPath(fillPath)
            context?.setFillColor(fillColor.cgColor)
            context?.fillPath()
        }
    }
}
