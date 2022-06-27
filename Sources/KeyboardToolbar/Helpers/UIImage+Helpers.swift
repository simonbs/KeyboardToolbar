import UIKit

extension UIImage {
    var firstPixelColor: UIColor? {
        guard let inputImage = CIImage(image: self) else {
            return nil
        }
        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull as Any])
        let bounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        context.render(inputImage, toBitmap: &bitmap, rowBytes: 4, bounds: bounds, format: .RGBA8, colorSpace: nil)
        let red = CGFloat(bitmap[0]) / 255
        let green = CGFloat(bitmap[1]) / 255
        let blue = CGFloat(bitmap[2]) / 255
        let alpha = CGFloat(bitmap[3]) / 255
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}
