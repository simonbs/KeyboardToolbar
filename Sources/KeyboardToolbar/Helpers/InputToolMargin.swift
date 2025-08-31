import UIKit

enum InputToolMargin {
    static func rawValue(for traitCollection: UITraitCollection) -> CGFloat {
#if !os(xrOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            return traitCollection.horizontalSizeClass == .regular ? 10 : 6
        } else if UIScreen.main.bounds.height > UIScreen.main.bounds.width {
            if #available(iOS 26, *) {
                return 7
            } else {
                return 3
            }
        } else {
            switch Device.current {
            case .iPhone8:
                return 72
            case .iPhone8Plus:
                return 76
            case .iPhone11, .iPhone11ProMax, .iPhone12ProMax:
                return 120
            case .iPhone12mini, .iPhone12, .iPhone12Pro, .unknown:
                return 78
            }
        }
#else
        return 5
#endif
    }
}
