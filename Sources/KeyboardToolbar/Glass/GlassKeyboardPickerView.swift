#if os(iOS)
import UIKit

/// A nonmodal key preview. The originating button retains the touch until release.
@available(visionOS, unavailable)
final class GlassKeyboardPickerView: UIVisualEffectView {
    private let selection = UIView()
    private var choices: [UIView] = []
    private var pickerLayout: GlassKeyboardPickerLayout?
    private var selectionTranslationScale: CGFloat = 1

    init() {
        if #available(iOS 26.0, *) {
            super.init(effect: UIGlassEffect(style: .regular))
            cornerConfiguration = .capsule()
        } else {
            super.init(effect: UIBlurEffect(style: .systemMaterial))
            clipsToBounds = true
        }
        isUserInteractionEnabled = false
        accessibilityIdentifier = "keyboard-toolbar-picker"
        selection.backgroundColor = .label.withAlphaComponent(0.12)
        contentView.addSubview(selection)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if #unavailable(iOS 26.0) {
            layer.cornerRadius = bounds.height / 2
        }
    }

    func show(_ representations: [KeyboardToolDisplayRepresentation], layout: GlassKeyboardPickerLayout,
              selectedIndex: Int?, accessibilityLabels: [String?] = []) {
        pickerLayout = layout
        frame = layout.frame
        choices.forEach { $0.removeFromSuperview() }
        choices = representations.enumerated().map { index, representation in
            let view: UIView
            switch representation {
            case .text(let configuration):
                let label = UILabel()
                label.text = configuration.text
                label.textAlignment = .center
                label.textColor = .label
                label.font = .monospacedSystemFont(ofSize: representations.count == 1 ? 26 : 19, weight: .medium)
                label.adjustsFontSizeToFitWidth = true
                label.minimumScaleFactor = 0.7
                view = label
            case .symbol, .image:
                let imageView = UIImageView(image: representation.image(isPreview: representations.count == 1))
                imageView.contentMode = .center
                imageView.tintColor = .label
                view = imageView
            }
            view.frame = layout.cellFrame(at: index)
            if case .text(let configuration) = representation {
                view.frame = view.frame.offsetBy(dx: configuration.offset.x, dy: configuration.offset.y)
            }
            view.isAccessibilityElement = true
            view.accessibilityLabel = (accessibilityLabels.indices.contains(index) ? accessibilityLabels[index] : nil)
                ?? representation.spokenName
            view.accessibilityIdentifier = "keyboard-toolbar-choice-" + representation.identifier
            contentView.addSubview(view)
            return view
        }
        select(selectedIndex)
    }

    func select(_ index: Int?) {
        selection.isHidden = index == nil
        if let index, let pickerLayout {
            let cell = pickerLayout.cellFrame(at: index)
            let diameter = min(cell.width, cell.height)
            selection.frame = CGRect(
                x: cell.midX - diameter / 2, y: cell.midY - diameter / 2, width: diameter, height: diameter
            )
            selection.layer.cornerRadius = diameter / 2
        }
        for (choiceIndex, choice) in choices.enumerated() {
            choice.accessibilityTraits = choiceIndex == index ? [.staticText, .selected] : .staticText
        }
    }

    func beginSelection(at point: CGPoint) {
        guard let pickerLayout, pickerLayout.count > 1 else {
            selectionTranslationScale = 1
            return
        }
        let firstX = pickerLayout.cellFrame(at: 0).midX
        let lastX = pickerLayout.cellFrame(at: pickerLayout.count - 1).midX
        let availableTravel = pickerLayout.reversed ? point.x - lastX : lastX - point.x
        // Fit the entire choice range between the initial finger and the last
        // visible symbol, so screen-edge clamping cannot make choices unreachable.
        selectionTranslationScale = abs(lastX - firstX) / max(1, availableTravel)
    }

    func index(forHorizontalTranslation translation: CGFloat) -> Int {
        guard let pickerLayout else {
            return 0
        }
        let position = pickerLayout.cellFrame(at: 0).midX + translation * selectionTranslationScale
        return pickerLayout.nearestIndex(to: CGPoint(x: position, y: 0))
    }
}

#endif
