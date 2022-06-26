import UIKit

final class KeyboardToolView: UIView {
    var foregroundColor: UIColor? {
        didSet {
            if foregroundColor != oldValue {
                updateForegroundColor()
            }
        }
    }
    var highlightedForegroundColor: UIColor? {
        didSet {
            if foregroundColor != oldValue {
                updateForegroundColor()
            }
        }
    }
    var isHighlighted = false {
        didSet {
            if isHighlighted != oldValue {
                updateForegroundColor()
            }
        }
    }

    private let titleLabel: UILabel = {
        let view = UILabel()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.textAlignment = .center
        return view
    }()
    private let imageView: UIImageView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.contentMode = .center
        return view
    }()

    private var offset: CGPoint = .zero

    override func layoutSubviews() {
        super.layoutSubviews()
        let size = CGSize(width: bounds.size.width - offset.x, height: bounds.size.height - offset.y)
        titleLabel.frame = CGRect(origin: offset, size: size)
        imageView.frame = CGRect(origin: offset, size: size)
    }

    func show(_ displayRepresentation: KeyboardToolDisplayRepresentation, atSize size: KeyboardToolContentSize) {
        prepareForReuse()
        switch displayRepresentation {
        case .text(let configuration):
            offset = configuration.offset
            titleLabel.text = configuration.text
            titleLabel.font = configuration.font(ofSize: size)
            addSubview(titleLabel)
        case .image(let configuration):
            offset = .zero
            imageView.image = configuration.image(ofSize: size)
            addSubview(imageView)
        case .symbol(let configuration):
            offset = .zero
            imageView.image = configuration.image(ofSize: size)
            addSubview(imageView)
        }
    }
}

private extension KeyboardToolView {
    private func prepareForReuse() {
        titleLabel.text = nil
        imageView.image = nil
        titleLabel.removeFromSuperview()
        imageView.removeFromSuperview()
    }

    private func updateForegroundColor() {
        if isHighlighted {
            titleLabel.textColor = highlightedForegroundColor
            imageView.tintColor = highlightedForegroundColor
        } else {
            titleLabel.textColor = foregroundColor
            imageView.tintColor = foregroundColor
        }
    }
}
