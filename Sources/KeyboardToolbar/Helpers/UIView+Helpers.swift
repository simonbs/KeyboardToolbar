import UIKit

extension UIView {
    func color(at point: CGPoint) -> UIColor? {
        guard let window = window else {
            return nil
        }
        let buttonFrame = window.convert(frame, from: superview)
        let bounds = CGRect(x: buttonFrame.minX + point.x, y: buttonFrame.minY, width: 1, height: 1)
        let imageRenderer = UIGraphicsImageRenderer(bounds: bounds)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let image = imageRenderer.image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: false)
        }
        return image.firstPixelColor
    }
}
