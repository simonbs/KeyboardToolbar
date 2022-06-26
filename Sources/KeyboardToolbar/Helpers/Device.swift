import UIKit

enum Device {
    case iPhone8
    case iPhone8Plus
    case iPhone11
    case iPhone11ProMax
    case iPhone12mini
    case iPhone12
    case iPhone12Pro
    case iPhone12ProMax
    case unknown

    static var current: Device {
        let bounds = UIScreen.main.nativeBounds
        if bounds.size.width == 750 && bounds.size.height == 1_334 {
            return .iPhone8
        } else if bounds.size.width == 1_242 && bounds.size.height == 2_208 {
            return .iPhone8Plus
        } else if bounds.size.width == 828 && bounds.size.height == 1_792 {
            return .iPhone11
        } else if bounds.size.width == 1_242 && bounds.size.height == 2_688 {
            return .iPhone11ProMax
        } else if bounds.size.width == 1_080 && bounds.size.height == 2_340 {
            return .iPhone12mini
        } else if bounds.size.width == 1_170 && bounds.size.height == 2_532 {
            return .iPhone12
        } else if bounds.size.width == 1_170 && bounds.size.height == 2_532 {
            return .iPhone12Pro
        } else if bounds.size.width == 1_284 && bounds.size.height == 2_778 {
            return .iPhone12ProMax
        } else {
            #if DEBUG
            print(bounds)
            #endif
            return .unknown
        }
    }
}
