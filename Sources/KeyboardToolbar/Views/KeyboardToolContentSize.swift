import UIKit

enum KeyboardToolContentSize {
    case small
    case large
}

extension KeyboardToolDisplayRepresentation.TextConfiguration {
    func font(ofSize size: KeyboardToolContentSize) -> UIFont {
        switch size {
        case .small:
            return .systemFont(ofSize: 20)
        case .large:
            return .systemFont(ofSize: 30)
        }
    }
}

extension KeyboardToolDisplayRepresentation.ImageConfiguration {
    func image(ofSize size: KeyboardToolContentSize) -> UIImage {
        switch size {
        case .small:
            return smallImage
        case .large:
            return largeImage
        }
    }
}

extension KeyboardToolDisplayRepresentation.SymbolConfiguration {
    func image(ofSize size: KeyboardToolContentSize) -> UIImage? {
        switch size {
        case .small:
            let configuration = UIImage.SymbolConfiguration(pointSize: pointSize)
            return UIImage(systemName: symbolName, withConfiguration: configuration)
        case .large:
            let configuration = UIImage.SymbolConfiguration(pointSize: pointSize * 1.5)
            return UIImage(systemName: symbolName, withConfiguration: configuration)
        }
    }
}
