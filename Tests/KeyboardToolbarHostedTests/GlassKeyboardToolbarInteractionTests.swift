#if os(iOS)
@testable import KeyboardToolbar
import UIKit
import XCTest

@MainActor final class GlassKeyboardToolbarInteractionTests: XCTestCase {
    func testTapCommitsExactlyOnceForInsideAndOutsideRelease() async throws {
        for event: UIControl.Event in [.touchUpInside, .touchUpOutside] {
            var inserted: [String] = []
            let button = GlassKeyboardToolButton(item: makeItem { inserted.append($0) })
            button.showToolPickerDelay = 0.2
            let window = try await makeWindow(button)
            defer { window.isHidden = true }
            button.sendActions(for: .touchDown)
            XCTAssertNotNil(picker(in: window))
            XCTAssertTrue(inserted.isEmpty)
            button.sendActions(for: event)
            button.sendActions(for: .touchUpInside)
            XCTAssertEqual(inserted, ["("])
            XCTAssertNil(picker(in: window))
        }
    }

    func testHoldExpandsChoicesAndReleasesFirstChoice() async throws {
        var inserted: [String] = []
        let button = GlassKeyboardToolButton(item: makeItem { inserted.append($0) })
        button.showToolPickerDelay = 0.2
        let window = try await makeWindow(button)
        defer { window.isHidden = true }
        button.sendActions(for: .touchDown)
        XCTAssertEqual(choiceLabels(in: window).compactMap(\.text), ["("])
        try await Task.sleep(nanoseconds: 300_000_000)
        let choices = choiceLabels(in: window)
        XCTAssertEqual(choices.compactMap(\.text), ["(", ")", "["])
        XCTAssertTrue(choices.first?.accessibilityTraits.contains(.selected) ?? false)
        XCTAssertTrue(inserted.isEmpty)
        button.sendActions(for: .touchUpInside)
        XCTAssertEqual(inserted, ["("])
        XCTAssertNil(picker(in: window))
    }

    func testClampedPickerSlidesFromFirstChoiceWithoutSkippingInEitherDirection() async throws {
        for x: CGFloat in [110, 205] {
            var inserted: [String] = []
            let symbols = ["(", "{", "[", "]", "}", ")", "<", ">"]
            let button = GlassKeyboardToolButton(item: KeyboardToolGroupItem(
                representativeTool: BlockKeyboardTool(text: "(") {},
                tools: symbols.map { text in BlockKeyboardTool(text: text) { inserted.append(text) } }
            ))
            button.showToolPickerDelay = 0.2
            let window = try await makeWindow(button)
            defer { window.isHidden = true }
            button.frame.origin.x = x
            button.sendActions(for: .touchDown)
            // A finger may drift before the hold opens. That position becomes the
            // origin, including when the picker has been shifted to fit the screen.
            let origin = CGPoint(x: button.bounds.midX + 7, y: button.bounds.midY)
            button.trackTouch(at: origin)
            try await Task.sleep(nanoseconds: 300_000_000)
            let choices = choiceLabels(in: window)
            XCTAssertEqual(choices.count, symbols.count)
            let first = try XCTUnwrap(choices.first)
            let second = try XCTUnwrap(choices.dropFirst().first)
            let visualStep = second.frame.midX - first.frame.midX
            let last = try XCTUnwrap(choices.last)
            let endX = last.convert(last.bounds, to: button).midX
            let step = (endX - origin.x) / CGFloat(symbols.count - 1)
            let firstInWindow = first.convert(first.bounds, to: window).midX
            XCTAssertGreaterThan(abs(firstInWindow - button.convert(origin, to: window).x), abs(visualStep),
                                 "Exercise a picker whose first symbol is displaced by screen fitting")
            button.trackTouch(at: CGPoint(x: origin.x + step * 0.1, y: origin.y))
            XCTAssertTrue(first.accessibilityTraits.contains(.selected), "Small movements must not skip symbols")
            for index in 1..<symbols.count {
                let point = CGPoint(x: origin.x + step * CGFloat(index), y: origin.y)
                XCTAssertTrue(window.bounds.contains(button.convert(point, to: window)), "Every choice must be reachable onscreen")
                button.trackTouch(at: point)
                XCTAssertTrue(choices[index].accessibilityTraits.contains(.selected))
            }
            for index in (1..<(symbols.count - 1)).reversed() {
                let point = CGPoint(x: origin.x + step * CGFloat(index), y: origin.y)
                XCTAssertTrue(window.bounds.contains(button.convert(point, to: window)), "Every choice must be reachable onscreen")
                button.trackTouch(at: point)
                XCTAssertTrue(choices[index].accessibilityTraits.contains(.selected))
            }
            button.sendActions(for: .touchUpOutside)
            XCTAssertEqual(inserted, [symbols[1]])
        }
    }

    func testCancellationAndDetachmentPreventLateActions() async throws {
        for cancellation in 0..<3 {
            var inserted: [String] = []
            let button = GlassKeyboardToolButton(item: makeItem { inserted.append($0) })
            button.showToolPickerDelay = 0.2
            let window = try await makeWindow(button)
            defer { window.isHidden = true }
            button.sendActions(for: .touchDown)
            XCTAssertNotNil(picker(in: window))
            switch cancellation {
            case 0:
                button.sendActions(for: .touchCancel)
            case 1:
                button.cancelInteraction()
            default:
                button.removeFromSuperview()
            }
            XCTAssertNil(picker(in: window))
            try await Task.sleep(nanoseconds: 300_000_000)
            button.sendActions(for: .touchUpOutside)
            XCTAssertTrue(inserted.isEmpty)
            XCTAssertNil(picker(in: window))
        }
    }

    func testDisabledUndoCannotPerformThroughTouchOrAccessibility() async throws {
        var undoCount = 0
        let undo = BlockKeyboardTool(symbolName: "arrow.uturn.backward") { undoCount += 1 }
        let button = GlassKeyboardToolButton(item: KeyboardToolGroupItem(representativeTool: undo))
        button.showToolPickerDelay = 0.2
        let window = try await makeWindow(button)
        defer { window.isHidden = true }
        button.sendActions(for: .touchDown)
        button.update(item: KeyboardToolGroupItem(representativeTool: undo, isEnabled: false))
        button.sendActions(for: .touchUpInside)
        button.sendActions(for: .touchDown)
        button.sendActions(for: .touchUpInside)
        XCTAssertFalse(button.accessibilityActivate())
        XCTAssertEqual(undoCount, 0)
    }

    func testEquivalentGroupRefreshPreservesPressAndUsesCurrentAction() async throws {
        var oldActions: [String] = []
        var newActions: [String] = []
        let button = GlassKeyboardToolButton(item: makeItem { oldActions.append($0) })
        button.showToolPickerDelay = 0.2
        let window = try await makeWindow(button)
        defer { window.isHidden = true }
        button.sendActions(for: .touchDown)
        button.update(item: makeItem { newActions.append($0) })
        button.sendActions(for: .touchUpInside)
        XCTAssertTrue(oldActions.isEmpty)
        XCTAssertEqual(newActions, ["("])
    }

    func testAccessibilityAlternativeCancelsPendingTouch() async throws {
        var inserted: [String] = []
        let button = GlassKeyboardToolButton(item: makeItem { inserted.append($0) })
        button.showToolPickerDelay = 0.2
        let window = try await makeWindow(button)
        defer { window.isHidden = true }
        button.sendActions(for: .touchDown)
        let action = try XCTUnwrap(button.accessibilityCustomActions?[1])
        XCTAssertTrue(try XCTUnwrap(action.actionHandler)(action))
        button.sendActions(for: .touchUpInside)
        XCTAssertEqual(inserted, [")"])
        XCTAssertNil(picker(in: window))
    }

    func testScrollingCancelsPendingPressAndAnExpandedPickerTemporarilyOwnsTheGesture() async throws {
        guard #available(iOS 26, *) else {
            throw XCTSkip("The scrollable keyboard groups use Liquid Glass.")
        }
        let toolbar = GlassKeyboardToolbarView()
        var inserted: [String] = []
        let symbol = makeItem { inserted.append($0) }
        let groups = [
            KeyboardToolGroup(items: [symbol, symbol]),
            KeyboardToolGroup(items: Array(repeating: symbol, count: 6), allowsHorizontalScrolling: true),
            KeyboardToolGroup(items: [symbol]),
            KeyboardToolGroup(items: [symbol])
        ]
        toolbar.groups = groups
        toolbar.showToolPickerDelay = 0.2
        let window = try await makeWindow(toolbar, frame: CGRect(x: 0, y: 600, width: 393, height: 60))
        defer { window.isHidden = true }
        toolbar.layoutIfNeeded()
        let scrollView = try XCTUnwrap(firstScrollView(in: toolbar))
        let firstKey = try XCTUnwrap(scrollView.subviews.compactMap { $0 as? GlassKeyboardToolButton }.first)
        XCTAssertTrue(scrollView.isScrollEnabled)

        firstKey.sendActions(for: .touchDown)
        XCTAssertNotNil(picker(in: window))
        scrollView.delegate?.scrollViewWillBeginDragging?(scrollView)
        firstKey.sendActions(for: .touchUpOutside)
        XCTAssertTrue(inserted.isEmpty)
        XCTAssertNil(picker(in: window))

        firstKey.sendActions(for: .touchDown)
        try await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertFalse(scrollView.isScrollEnabled)
        firstKey.sendActions(for: .touchUpInside)
        XCTAssertEqual(inserted, ["("])
        XCTAssertTrue(scrollView.isScrollEnabled)

        let offset = scrollView.contentSize.width - scrollView.bounds.width
        scrollView.setContentOffset(CGPoint(x: offset, y: 0), animated: false)
        toolbar.groups = groups
        toolbar.layoutIfNeeded()
        XCTAssertEqual(scrollView.contentOffset.x, offset, accuracy: 0.001)
    }

    private func makeItem(action: @escaping (String) -> Void) -> KeyboardToolGroupItem {
        KeyboardToolGroupItem(
            representativeTool: BlockKeyboardTool(text: "(") { action("(") },
            tools: ["(", ")", "["].map { text in BlockKeyboardTool(text: text) { action(text) } }
        )
    }

    private func makeWindow(_ view: UIView, frame: CGRect = CGRect(x: 100, y: 600, width: 44, height: 44)) async throws -> UIWindow {
        // Hosted XCTest can begin before the application's first scene connects.
        let deadline = Date().addingTimeInterval(5)
        while UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).isEmpty,
              Date() < deadline {
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        let scene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first,
            "Keyboard interaction tests require a connected window scene"
        )
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: 0, y: 0, width: 393, height: 852)
        window.rootViewController = UIViewController()
        window.isHidden = false
        view.frame = frame
        window.rootViewController?.view.addSubview(view)
        window.layoutIfNeeded()
        XCTAssertIdentical(view.window, window)
        return window
    }

    private func firstScrollView(in view: UIView) -> UIScrollView? {
        if let scrollView = view as? UIScrollView { return scrollView }
        return view.subviews.lazy.compactMap { self.firstScrollView(in: $0) }.first
    }

    private func picker(in window: UIWindow) -> GlassKeyboardPickerView? {
        window.subviews.compactMap { $0 as? GlassKeyboardPickerView }.first
    }

    private func choiceLabels(in window: UIWindow) -> [UILabel] {
        picker(in: window)?.contentView.subviews.compactMap { $0 as? UILabel } ?? []
    }
}
#endif
