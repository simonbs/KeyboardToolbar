import UIKit

final class DrawingKeyboardToolPickerBackgroundView: UIView {
    var pathConfig = KeyboardToolPickerBackgroundPathConfiguration(
        bounds: .zero,
        handleSize: .zero,
        preferredHandleXPosition: 0
    ) {
        didSet {
            if pathConfig != oldValue {
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

    private let shadowColor: UIColor = .black.withAlphaComponent(0.2)
    private let handleShadowLength: CGFloat = 1
    private let strokeColor: UIColor = .separator

    init() {
        super.init(frame: .zero)
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

    private func makeGradientMaskImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: bounds.size)
        return renderer.image { rendererContext in
            let context = rendererContext.cgContext
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors = [
                UIColor.black.withAlphaComponent(1).cgColor,
                UIColor.black.withAlphaComponent(0).cgColor
            ]
            let startLocation = (bounds.height - pathConfig.shadowBlur - pathConfig.handleRect.height / 2) / bounds.height
            let endLocation = (bounds.height - pathConfig.shadowBlur) / bounds.height
            let locations: [CGFloat] = [1 - startLocation, 1 - endLocation]
            let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: locations)!
            let startPoint: CGPoint = .zero
            let endPoint = CGPoint(x: 0, y: bounds.size.height)
            context.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: [])
        }
    }

    private func drawShadow(of path: CGPath, to context: CGContext) {
        guard pathConfig.shadowBlur != 0, let maskImage = makeGradientMaskImage().cgImage else {
            return
        }
        let shadowOffset = CGSize(width: 0, height: 2)
        let rect = CGRect(origin: .zero, size: bounds.size)
        context.saveGState()
        context.clip(to: rect, mask: maskImage)
        context.addPath(path)
        context.setFillColor(UIColor.white.cgColor)
        context.setShadow(offset: shadowOffset, blur: pathConfig.shadowBlur, color: shadowColor.cgColor)
        context.setBlendMode(.multiply)
        context.fillPath()
        context.restoreGState()
    }

    private func drawHandleShadow(to context: CGContext) {
        guard handleShadowLength > 0 else {
            return
        }
        let handlePath = UIBezierPath(roundedRect: pathConfig.handleRect, cornerRadius: pathConfig.handleRadius)
        let handleShadowRect = pathConfig.handleRect.offsetBy(dx: 0, dy: handleShadowLength)
        let handleShadowPath = UIBezierPath(roundedRect: handleShadowRect, cornerRadius: pathConfig.handleRadius)
        context.saveGState()
        // Draw the shadow
        context.addPath(handleShadowPath.cgPath)
        context.setFillColor(shadowColor.cgColor)
        context.fillPath()
        // Cut the filled rectangle out of the shadow so the shadow underneath isn't visible when the fill color isn't fully opaque.
        context.addPath(handlePath.cgPath)
        context.setBlendMode(.clear)
        context.setFillColor(UIColor.black.cgColor)
        context.fillPath()
        context.restoreGState()
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

