import UIKit

final class MainView: UIView {
    let textView: UITextView = {
        let this = UITextView()
        this.translatesAutoresizingMaskIntoConstraints = false
        this.font = .preferredFont(forTextStyle: .body)
        this.textColor = UIColor(named: "textColor")
        this.isFindInteractionEnabled = true
        this.backgroundColor = UIColor(named: "background")
        return this
    }()

    init() {
        super.init(frame: .zero)
        setupView()
        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        backgroundColor = UIColor(named: "background")
        addSubview(textView)
    }

    private func setupLayout() {
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: trailingAnchor),
            textView.topAnchor.constraint(equalTo: topAnchor),
            textView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
