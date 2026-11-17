#if os(iOS)
import UIKit

/// Pages within one glass capsule. A swipe can take over a key press until the picker opens.
final class GlassKeyboardGroupScrollView: UIScrollView, UIScrollViewDelegate {
    var onBeginDragging: (() -> Void)?
    var isPickerExpanded = false {
        didSet { updateScrollingAvailability() }
    }

    private var pages: [UIView] = []
    private var currentPage = 0
    private let pageFeedback = UISelectionFeedbackGenerator()

    init() {
        super.init(frame: .zero)
        delegate = self
        contentInsetAdjustmentBehavior = .never
        delaysContentTouches = false
        decelerationRate = .fast
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        bounces = false
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func layoutButtons(_ buttons: [GlassKeyboardToolButton], frames: [CGRect],
                       pagination: GlassKeyboardToolbarLayout.Pagination) {
        if pages.count != pagination.pageCount {
            pages.dropFirst(pagination.pageCount).forEach { $0.removeFromSuperview() }
            pages = Array(pages.prefix(pagination.pageCount))
            while pages.count < pagination.pageCount {
                let page = UIView()
                addSubview(page)
                pages.append(page)
            }
        }
        for (index, page) in pages.enumerated() {
            page.frame = CGRect(x: CGFloat(index) * bounds.width, y: 0, width: bounds.width, height: bounds.height)
        }
        for (index, button) in buttons.enumerated() {
            let page = pages[index / pagination.capacity]
            if button.superview !== page { page.addSubview(button) }
            button.frame = frames[index]
        }
        let contentSize = CGSize(width: CGFloat(pages.count) * bounds.width, height: bounds.height)
        if self.contentSize != contentSize {
            self.contentSize = contentSize
            currentPage = clampedPage(currentPage)
            setContentOffset(offset(for: currentPage), animated: false)
        }
        updatePageAccessibility()
        updateScrollingAvailability()
    }

    override func touchesShouldCancel(in view: UIView) -> Bool {
        view is GlassKeyboardToolButton || super.touchesShouldCancel(in: view)
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        onBeginDragging?()
        pageFeedback.prepare()
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint,
                                   targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard bounds.width > 0 else { return }
        let proposed = targetContentOffset.pointee.x / bounds.width
        let rounding: FloatingPointRoundingRule
        if velocity.x == 0 {
            rounding = .toNearestOrAwayFromZero
        } else {
            rounding = velocity.x > 0 ? .up : .down
        }
        let page = clampedPage(Int(proposed.rounded(rounding)))
        targetContentOffset.pointee = offset(for: page)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate { settleAtNearestPage() }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        settleAtNearestPage()
    }

    override func accessibilityScroll(_ direction: UIAccessibilityScrollDirection) -> Bool {
        let nextPage: Int
        switch direction {
        case .left: nextPage = currentPage + 1
        case .right: nextPage = currentPage - 1
        default: return false
        }
        guard pages.indices.contains(nextPage), !isPickerExpanded else { return false }
        settle(on: nextPage, animated: true)
        return true
    }

    private func settleAtNearestPage() {
        guard bounds.width > 0 else { return }
        settle(on: clampedPage(Int((contentOffset.x / bounds.width).rounded())), animated: false)
    }

    private func settle(on page: Int, animated: Bool) {
        let didChangePage = page != currentPage
        currentPage = page
        setContentOffset(offset(for: page), animated: animated)
        updatePageAccessibility()
        if didChangePage {
            pageFeedback.selectionChanged()
            UIAccessibility.post(notification: .pageScrolled, argument: nil)
        }
    }

    private func offset(for page: Int) -> CGPoint {
        CGPoint(x: CGFloat(page) * bounds.width, y: 0)
    }

    private func clampedPage(_ page: Int) -> Int {
        min(max(0, page), max(0, pages.count - 1))
    }

    private func updatePageAccessibility() {
        for (index, page) in pages.enumerated() {
            page.accessibilityElementsHidden = index != currentPage
        }
    }

    private func updateScrollingAvailability() {
        let canScroll = pages.count > 1 && !isPickerExpanded
        if isScrollEnabled != canScroll { isScrollEnabled = canScroll }
    }
}
#endif
