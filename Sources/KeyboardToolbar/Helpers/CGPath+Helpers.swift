import UIKit

struct KeyboardToolPickerBackgroundPathConfiguration: Equatable {
    let bounds: CGRect
    let handleSize: CGSize
    let preferredHandleXPosition: CGFloat
    let shadowBlur: CGFloat = 5
    let handleShadowLength: CGFloat = 1
    let plateRadius: CGFloat = 10
    let handleRadius: CGFloat = 5

    init(bounds: CGRect, handleSize: CGSize, preferredHandleXPosition: CGFloat) {
        self.bounds = bounds
        self.handleSize = handleSize
        self.preferredHandleXPosition = preferredHandleXPosition
    }

    fileprivate var insetBounds: CGRect {
         bounds.inset(by: UIEdgeInsets(top: shadowBlur, left: shadowBlur, bottom: 0, right: shadowBlur))
    }
    var handleRect: CGRect {
        let handleXPosition = preferredHandleXPosition
        let handleOrigin = CGPoint(x: handleXPosition, y: insetBounds.maxY - handleSize.height - shadowBlur - handleShadowLength)
        return CGRect(origin: handleOrigin, size: handleSize)
    }
}

extension CGPath {
    static func keyboardToolPickerBackground(with config: KeyboardToolPickerBackgroundPathConfiguration) -> CGPath {
        let drawingTechniqueBufferDistance = config.handleSize.width * 0.8

        let pPlateTopLeftCorner = CGPoint(x: config.insetBounds.minX, y: config.insetBounds.minY)
        let pPlateTopRightCorner = CGPoint(x: config.insetBounds.maxX, y: config.insetBounds.minY)
        let pPlateBottomRightCorner = CGPoint(x: config.insetBounds.maxX, y: config.handleRect.minY)
        let pPlateBottomLeftCorner = CGPoint(x: config.insetBounds.minX, y: config.handleRect.minY)

        let pHandleTopRightCorner = CGPoint(x: config.handleRect.maxX, y: config.handleRect.minY)
        let pHandleBottomRightCorner = CGPoint(x: config.handleRect.maxX, y: config.handleRect.maxY)
        let pHandleBottomLeftCorner = CGPoint(x: config.handleRect.minX, y: config.handleRect.maxY)
        let pHandleTopLeftCorner = CGPoint(x: config.handleRect.minX, y: config.handleRect.minY)

        let path = CGMutablePath()
        path.move(to: CGPoint(x: config.insetBounds.minX, y: config.insetBounds.minY + config.plateRadius))

        path.addArc(corner: pPlateTopLeftCorner, radius: config.plateRadius, circleComponent: .topLeft)
        path.addArc(corner: pPlateTopRightCorner, radius: config.plateRadius, circleComponent: .topRight)

        // Choose drawing technique depending on the distance between the handle's right-hand side and the plate's right-hand side.
        if config.insetBounds.width - config.handleRect.maxX <= drawingTechniqueBufferDistance {
            path.addLine(to: pPlateBottomRightCorner.offsetting(y: -config.plateRadius))
            path.addCurve(to: pHandleTopRightCorner.offsetting(y: config.plateRadius), control1: pPlateBottomRightCorner, control2: pHandleTopRightCorner)
        } else {
            path.addArc(corner: pPlateBottomRightCorner, radius: config.plateRadius, circleComponent: .bottomRight)
            path.addLine(to: pHandleTopRightCorner.offsetting(x: config.plateRadius))
            path.addQuadCurve(to: pHandleTopRightCorner.offsetting(y: config.plateRadius), control: pHandleTopRightCorner)
        }

        path.addArc(corner: pHandleBottomRightCorner, radius: config.handleRadius, circleComponent: .bottomRight)
        path.addArc(corner: pHandleBottomLeftCorner, radius: config.handleRadius, circleComponent: .bottomLeft)

        // Choose drawing technique depending on the distance between the handle's left-hand side and the plate's left-hand side.
        if config.handleRect.minX <= drawingTechniqueBufferDistance {
            path.addLine(to: pHandleTopLeftCorner.offsetting(y: config.plateRadius))
            path.addCurve(to: pPlateBottomLeftCorner.offsetting(y: -config.plateRadius), control1: pHandleTopLeftCorner, control2: pPlateBottomLeftCorner)
        } else {
            path.addLine(to: pHandleTopLeftCorner.offsetting(y: config.plateRadius))
            path.addQuadCurve(to: pHandleTopLeftCorner.offsetting(x: -config.plateRadius), control: pHandleTopLeftCorner)
            path.addArc(corner: pPlateBottomLeftCorner, radius: config.plateRadius, circleComponent: .bottomLeft)
        }

        path.closeSubpath()
        return path
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

private extension CGPoint {
    func offsetting(x dx: CGFloat = 0, y dy: CGFloat = 0) -> CGPoint {
        CGPoint(x: x + dx, y: y + dy)
    }
}
