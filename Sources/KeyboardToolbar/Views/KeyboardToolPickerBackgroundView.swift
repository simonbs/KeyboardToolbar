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

    private var insetBounds: CGRect {
        return bounds.inset(by: UIEdgeInsets(top: shadowBlur, left: shadowBlur, bottom: 0, right: shadowBlur))
    }
    private var handleRect: CGRect {
        let handleXPosition = preferredHandleXPosition
        let handleOrigin = CGPoint(x: handleXPosition, y: insetBounds.maxY - handleSize.height - shadowBlur - handleShadowLength)
        return CGRect(origin: handleOrigin, size: handleSize)
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
        if let context = context {
            let path = makeBackgroundPath()
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
            let startLocation = (bounds.height - shadowBlur - handleRect.height / 2) / bounds.height
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
            let handlePath = UIBezierPath(roundedRect: handleRect, cornerRadius: handleRadius)
            let handleShadowRect = handleRect.offsetBy(dx: 0, dy: handleShadowLength)
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
        context.setLineWidth(1 / UIScreen.main.scale)
        context.addPath(path)
        context.strokePath()
        context.restoreGState()
    }

    private func makeBackgroundPath() -> CGPath {
        let drawingTechniqueBufferDistance = handleSize.width * 0.8

        let pPlateTopLeftCorner = CGPoint(x: insetBounds.minX, y: insetBounds.minY)
        let pPlateTopRightCorner = CGPoint(x: insetBounds.maxX, y: insetBounds.minY)
        let pPlateBottomRightCorner = CGPoint(x: insetBounds.maxX, y: handleRect.minY)
        let pPlateBottomLeftCorner = CGPoint(x: insetBounds.minX, y: handleRect.minY)

        let pHandleTopRightCorner = CGPoint(x: handleRect.maxX, y: handleRect.minY)
        let pHandleBottomRightCorner = CGPoint(x: handleRect.maxX, y: handleRect.maxY)
        let pHandleBottomLeftCorner = CGPoint(x: handleRect.minX, y: handleRect.maxY)
        let pHandleTopLeftCorner = CGPoint(x: handleRect.minX, y: handleRect.minY)

        let path = CGMutablePath()
        path.move(to: CGPoint(x: insetBounds.minX, y: insetBounds.minY + plateRadius))

        path.addArc(corner: pPlateTopLeftCorner, radius: plateRadius, circleComponent: .topLeft)
        path.addArc(corner: pPlateTopRightCorner, radius: plateRadius, circleComponent: .topRight)

        // Choose drawing technique depending on the distance between the handle's right-hand side and the plate's right-hand side.
        if insetBounds.width - handleRect.maxX <= drawingTechniqueBufferDistance {
            path.addLine(to: pPlateBottomRightCorner.offsetting(y: -plateRadius))
            path.addCurve(to: pHandleTopRightCorner.offsetting(y: plateRadius), control1: pPlateBottomRightCorner, control2: pHandleTopRightCorner)
        } else {
            path.addArc(corner: pPlateBottomRightCorner, radius: plateRadius, circleComponent: .bottomRight)
            path.addLine(to: pHandleTopRightCorner.offsetting(x: plateRadius))
            path.addQuadCurve(to: pHandleTopRightCorner.offsetting(y: plateRadius), control: pHandleTopRightCorner)
        }

        path.addArc(corner: pHandleBottomRightCorner, radius: handleRadius, circleComponent: .bottomRight)
        path.addArc(corner: pHandleBottomLeftCorner, radius: handleRadius, circleComponent: .bottomLeft)

        // Choose drawing technique depending on the distance between the handle's left-hand side and the plate's left-hand side.
        if handleRect.minX <= drawingTechniqueBufferDistance {
            path.addLine(to: pHandleTopLeftCorner.offsetting(y: plateRadius))
            path.addCurve(to: pPlateBottomLeftCorner.offsetting(y: -plateRadius), control1: pHandleTopLeftCorner, control2: pPlateBottomLeftCorner)
        } else {
            path.addLine(to: pHandleTopLeftCorner.offsetting(y: plateRadius))
            path.addQuadCurve(to: pHandleTopLeftCorner.offsetting(x: -plateRadius), control: pHandleTopLeftCorner)
            path.addArc(corner: pPlateBottomLeftCorner, radius: plateRadius, circleComponent: .bottomLeft)
        }

        path.closeSubpath()
        return path
    }
}

private extension CGPoint {
    func offsetting(x dx: CGFloat = 0, y dy: CGFloat = 0) -> CGPoint {
        return CGPoint(x: x + dx, y: y + dy)
    }
}

private extension CGMutablePath {
    enum CircleComponent {
        case topRight
        case bottomRight
        case bottomLeft
        case topLeft

        var startAngle: CGFloat {
            switch self {
            case .topRight:
                return 3 * .pi / 2
            case .bottomRight:
                return 2 * .pi
            case .bottomLeft:
                return .pi / 2
            case .topLeft:
                return .pi
            }
        }

        var endAngle: CGFloat {
            switch self {
            case .topRight:
                return 2 * .pi
            case .bottomRight:
                return .pi / 2
            case .bottomLeft:
                return .pi
            case .topLeft:
                return 3 * .pi / 2
            }
        }
    }

    func addArc(corner: CGPoint, radius: CGFloat, circleComponent: CircleComponent, clockwise: Bool = false) {
        let center: CGPoint
        switch circleComponent {
        case .topRight:
            center = CGPoint(x: corner.x - radius, y: corner.y + radius)
        case .bottomRight:
            center = CGPoint(x: corner.x - radius, y: corner.y - radius)
        case .bottomLeft:
            center = CGPoint(x: corner.x + radius, y: corner.y - radius)
        case .topLeft:
            center = CGPoint(x: corner.x + radius, y: corner.y + radius)
        }
        addArc(center: center, radius: radius, circleComponent: circleComponent, clockwise: clockwise)
    }

    func addArc(center: CGPoint, radius: CGFloat, circleComponent: CircleComponent, clockwise: Bool = false) {
        addArc(center: center, radius: radius, startAngle: circleComponent.startAngle, endAngle: circleComponent.endAngle, clockwise: clockwise)
    }
}
