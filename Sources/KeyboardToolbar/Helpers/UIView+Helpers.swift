import UIKit

extension UIView {
    func color(at point: CGPoint) -> UIColor? {
        guard let window = window else {
            return nil
        }
        let rect = window.convert(frame, from: superview)
        let image = UIGraphicsImageRenderer(bounds: rect).image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        return image.color(at: point)
    }
}

private extension UIImage {
    func color(at point: CGPoint) -> UIColor? {
        guard let pixelData = cgImage?.dataProvider?.data else {
            return nil
        }
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        let pixelInfo = ((Int(size.width) * Int(point.y)) + Int(point.x)) * 4
        let r = CGFloat(data[pixelInfo]) / CGFloat(255)
        let g = CGFloat(data[pixelInfo + 1]) / CGFloat(255)
        let b = CGFloat(data[pixelInfo + 2]) / CGFloat(255)
        let a = CGFloat(data[pixelInfo + 3]) / CGFloat(255)
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}
