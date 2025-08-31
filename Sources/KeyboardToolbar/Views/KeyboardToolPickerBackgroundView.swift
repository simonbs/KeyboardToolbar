import UIKit

final class KeyboardToolPickerBackgroundView: UIView {
    var preferredHandleXPosition: CGFloat = 0 {
        didSet {
            if preferredHandleXPosition != oldValue {
                setNeedsDisplay()
            }
        }
    }
    var plateHeight: CGFloat = 54 {
        didSet {
            if plateHeight != oldValue {
                invalidateIntrinsicContentSize()
                setNeedsDisplay()
            }
        }
    }
    var handleSize = CGSize(width: 30, height: 30) {
        didSet {
            if handleSize != oldValue {
                invalidateIntrinsicContentSize()
                setNeedsDisplay()
            }
        }
    }
    var plateRadius: CGFloat = 10 {
        didSet {
            if plateRadius != oldValue {
                setNeedsDisplay()
            }
        }
    }
    var handleRadius: CGFloat = 5 {
        didSet {
            if handleRadius != oldValue {
                setNeedsDisplay()
            }
        }
    }
    var fillColor: UIColor = .white {
        didSet {
            if fillColor != oldValue {
                setNeedsDisplay()
            }
        }
    }
    var strokeColor: UIColor = .separator {
        didSet {
            if strokeColor != oldValue {
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
    var shadowBlur: CGFloat = 5 {
        didSet {
            if shadowBlur != oldValue {
                setNeedsDisplay()
            }
        }
    }
    var handleShadowColor: UIColor? = .black.withAlphaComponent(0.2) {
        didSet {
            if shadowColor != oldValue {
                setNeedsDisplay()
            }
        }
    }
    var handleShadowLength: CGFloat = 1 {
        didSet {
            if handleShadowLength != oldValue {
                setNeedsDisplay()
            }
        }
    }
    override var frame: CGRect {
        didSet {
            if frame.size != oldValue.size {
                setNeedsDisplay()
            }
        }
    }

    private var pathConfig: KeyboardToolPickerBackgroundPathConfiguration {
        KeyboardToolPickerBackgroundPathConfiguration(
            bounds: bounds,
            shadowBlur: shadowBlur,
            handleSize: handleSize,
            preferredHandleXPosition: preferredHandleXPosition,
            handleShadowLength: handleShadowLength,
            plateRadius: plateRadius,
            handleRadius: handleRadius
        )
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
        if let context {
            let path = CGPath.keyboardToolPickerBackground(with: pathConfig)
            drawShadow(of: path, to: context)
            drawHandleShadow(to: context)
            drawFill(of: path, to: context)
            drawStroke(of: path, to: context)
        }
    }

    func preferredSize(containingContentWidth contentWidth: CGFloat) -> CGSize {
        let width = contentWidth + shadowBlur * 2
        let height = plateHeight + handleSize.height + shadowBlur * 2
        return CGSize(width: width, height: height)
    }
}

private extension KeyboardToolPickerBackgroundView {
    private func makeGradientMaskImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: bounds.size)
        return renderer.image { rendererContext in
            let context = rendererContext.cgContext
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors = [
                UIColor.black.withAlphaComponent(1).cgColor,
                UIColor.black.withAlphaComponent(0).cgColor
            ]
            let startLocation = (bounds.height - shadowBlur - pathConfig.handleRect.height / 2) / bounds.height
            let endLocation = (bounds.height - shadowBlur) / bounds.height
            let locations: [CGFloat] = [1 - startLocation, 1 - endLocation]
            let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: locations)!
            let startPoint: CGPoint = .zero
            let endPoint = CGPoint(x: 0, y: bounds.size.height)
            context.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: [])
        }
    }

    private func drawShadow(of path: CGPath, to context: CGContext) {
        if let shadowColor = shadowColor, shadowBlur != 0, let maskImage = makeGradientMaskImage().cgImage {
            let shadowOffset = CGSize(width: 0, height: 2)
            let rect = CGRect(origin: .zero, size: bounds.size)
            context.saveGState()
            context.clip(to: rect, mask: maskImage)
            context.addPath(path)
            context.setFillColor(UIColor.white.cgColor)
            context.setShadow(offset: shadowOffset, blur: shadowBlur, color: shadowColor.cgColor)
            context.setBlendMode(.multiply)
            context.fillPath()
            context.restoreGState()
        }
    }

    private func drawHandleShadow(to context: CGContext) {
        if let handleShadowColor = handleShadowColor, handleShadowLength > 0 {
            let handlePath = UIBezierPath(roundedRect: pathConfig.handleRect, cornerRadius: handleRadius)
            let handleShadowRect = pathConfig.handleRect.offsetBy(dx: 0, dy: handleShadowLength)
            let handleShadowPath = UIBezierPath(roundedRect: handleShadowRect, cornerRadius: handleRadius)
            context.saveGState()
            // Draw the shadow
            context.addPath(handleShadowPath.cgPath)
            context.setFillColor(handleShadowColor.cgColor)
            context.fillPath()
            // Cut the filled rectangle out of the shadow so the shadow underneath isn't visible when the fill color isn't fully opaque.
            context.addPath(handlePath.cgPath)
            context.setBlendMode(.clear)
            context.setFillColor(UIColor.black.cgColor)
            context.fillPath()
            context.restoreGState()
        }
    }

    private func drawFill(of path: CGPath, to context: CGContext) {
        context.addPath(path)
        context.setFillColor(fillColor.cgColor)
        context.fillPath()
    }

    private func drawStroke(of path: CGPath, to context: CGContext) {
        context.saveGState()
        context.setStrokeColor(strokeColor.cgColor)
#if !os(xrOS)
        context.setLineWidth(1 / UIScreen.main.scale)
#else
        context.setLineWidth(1)
#endif
        context.addPath(path)
        context.strokePath()
        context.restoreGState()
    }
}
