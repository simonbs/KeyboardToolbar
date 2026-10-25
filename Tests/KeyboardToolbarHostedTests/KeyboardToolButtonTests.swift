#if os(iOS)
@testable import KeyboardToolbar
import UIKit
import XCTest

@MainActor final class KeyboardToolButtonTests: XCTestCase {
    func testInterruptedPressCannotExpandOrCommitLater() async throws {
        for interruption in [Interruption.cancel, .deactivate, .detach] {
            var actions: [String] = []
            let button = KeyboardToolButton(item: makeItem { actions.append($0) })
            button.showToolPickerDelay = 0.03
            let window = try await makeWindow(button)
            defer { window.isHidden = true }
            button.sendActions(for: .touchDown)
            XCTAssertNotNil(picker(in: button))
            switch interruption {
            case .cancel:
                button.sendActions(for: .touchCancel)
            case .deactivate:
                NotificationCenter.default.post(name: UIApplication.willResignActiveNotification, object: nil)
            case .detach:
                button.removeFromSuperview()
            }
            XCTAssertNil(picker(in: button))
            try await Task.sleep(nanoseconds: 80_000_000)
            button.sendActions(for: .touchUpOutside)
            XCTAssertTrue(actions.isEmpty)
            XCTAssertNil(picker(in: button), "An interrupted hold must not reopen its picker")
        }
    }

    func testDisablingAnExpandedToolBlocksTouchAndAccessibility() async throws {
        var actions: [String] = []
        let button = KeyboardToolButton(item: makeItem { actions.append($0) })
        button.showToolPickerDelay = 0
        let window = try await makeWindow(button)
        defer { window.isHidden = true }
        button.sendActions(for: .touchDown)
        XCTAssertEqual(picker(in: button)?.toolCount, 3)
        let previouslyOfferedAction = try XCTUnwrap(button.accessibilityCustomActions?.first)
        button.update(item: makeItem(isEnabled: false) { actions.append($0) })
        button.sendActions(for: .touchUpInside)
        button.sendActions(for: .touchDown)
        button.sendActions(for: .touchUpInside)
        XCTAssertFalse(button.accessibilityActivate())
        XCTAssertFalse(try XCTUnwrap(previouslyOfferedAction.actionHandler)(previouslyOfferedAction))
        XCTAssertTrue(actions.isEmpty)
        XCTAssertNil(picker(in: button))
    }

    func testEquivalentRefreshPreservesExpandedSelectionAndUsesCurrentAction() async throws {
        var oldActions: [String] = []
        var newActions: [String] = []
        let button = KeyboardToolButton(item: makeItem { oldActions.append($0) })
        button.showToolPickerDelay = 0
        let window = try await makeWindow(button)
        defer { window.isHidden = true }
        button.sendActions(for: .touchDown)
        let expandedPicker = try XCTUnwrap(picker(in: button))
        let lastChoice = try XCTUnwrap(choiceViews(in: expandedPicker).last)
        button.trackTouch(at: lastChoice.convert(CGPoint(x: lastChoice.bounds.midX, y: lastChoice.bounds.midY), to: button))
        XCTAssertEqual(expandedPicker.highlightedIndex, 2)
        button.update(item: makeItem { newActions.append($0) })
        XCTAssertIdentical(picker(in: button), expandedPicker)
        XCTAssertEqual(expandedPicker.highlightedIndex, 2)
        button.sendActions(for: .touchUpInside)
        button.sendActions(for: .touchUpInside)
        XCTAssertTrue(oldActions.isEmpty)
        XCTAssertEqual(newActions, ["["])
    }

    func testZeroDelayHandlesNoAlternativesAndCommitsSingleAlternative() async throws {
        for hasAlternative in [false, true] {
            var actions: [String] = []
            let item = KeyboardToolGroupItem(
                representativeTool: BlockKeyboardTool(text: "(") { actions.append("primary") },
                tools: hasAlternative ? [BlockKeyboardTool(text: ")") { actions.append("alternative") }] : []
            )
            let button = KeyboardToolButton(item: item)
            button.showToolPickerDelay = 0
            let window = try await makeWindow(button)
            defer { window.isHidden = true }
            button.sendActions(for: .touchDown)
            XCTAssertTrue(actions.isEmpty)
            button.sendActions(for: .touchUpOutside)
            XCTAssertEqual(actions, [hasAlternative ? "alternative" : "primary"])
            XCTAssertNil(picker(in: button))
        }
    }

    func testScreenFittingDoesNotSkipChoicesAndSlidingCanReverse() async throws {
        let symbols = ["(", "{", "[", "]", "}", ")", "<", ">", "="]
        for buttonX: CGFloat in [110, 205] {
            var actions: [String] = []
            let button = KeyboardToolButton(item: KeyboardToolGroupItem(
                representativeTool: BlockKeyboardTool(text: "(") {},
                tools: symbols.map { symbol in BlockKeyboardTool(text: symbol) { actions.append(symbol) } }
            ))
            button.showToolPickerDelay = 0.03
            let window = try await makeWindow(button)
            defer { window.isHidden = true }
            button.frame = CGRect(x: buttonX, y: 600, width: 32, height: 42)
            button.sendActions(for: .touchDown)
            let origin = CGPoint(x: button.bounds.midX + 7, y: button.bounds.midY)
            button.trackTouch(at: origin)
            try await Task.sleep(nanoseconds: 80_000_000)
            let expandedPicker = try XCTUnwrap(picker(in: button))
            let choices = choiceViews(in: expandedPicker)
            let firstChoice = try XCTUnwrap(choices.first)
            let lastChoice = try XCTUnwrap(choices.last)
            let firstX = firstChoice.convert(CGPoint(x: firstChoice.bounds.midX, y: 0), to: button).x
            let lastX = lastChoice.convert(CGPoint(x: lastChoice.bounds.midX, y: 0), to: button).x
            let step = (lastX - origin.x) / CGFloat(symbols.count - 1)
            XCTAssertGreaterThan(abs(firstX - origin.x), 32, "Exercise a picker shifted by screen fitting")
            button.trackTouch(at: CGPoint(x: origin.x + step * 0.1, y: origin.y))
            XCTAssertEqual(expandedPicker.highlightedIndex, 0, "Small movement must not jump past the first choice")
            let traversal = Array(1..<symbols.count) + Array((1..<(symbols.count - 1)).reversed())
            for index in traversal {
                let point = CGPoint(x: origin.x + step * CGFloat(index), y: origin.y)
                XCTAssertTrue(window.bounds.contains(button.convert(point, to: window)), "Every choice must be reachable onscreen")
                button.trackTouch(at: point)
                XCTAssertEqual(expandedPicker.highlightedIndex, index)
            }
            button.sendActions(for: .touchUpOutside)
            XCTAssertEqual(actions, [symbols[1]])
        }
    }

    func testAccessibilityAlternativeCancelsPendingTouchAndTimer() async throws {
        var actions: [String] = []
        let button = KeyboardToolButton(item: makeItem { actions.append($0) })
        button.showToolPickerDelay = 0.03
        let window = try await makeWindow(button)
        defer { window.isHidden = true }
        button.sendActions(for: .touchDown)
        let action = try XCTUnwrap(button.accessibilityCustomActions?[1])
        XCTAssertTrue(try XCTUnwrap(action.actionHandler)(action))
        try await Task.sleep(nanoseconds: 80_000_000)
        button.sendActions(for: .touchUpInside)
        XCTAssertEqual(actions, [")"])
        XCTAssertNil(picker(in: button))
    }

    private enum Interruption {
        case cancel, deactivate, detach
    }

    private func makeItem(isEnabled: Bool = true, action: @escaping (String) -> Void) -> KeyboardToolGroupItem {
        KeyboardToolGroupItem(
            representativeTool: BlockKeyboardTool(text: "(") { action("(") },
            isEnabled: isEnabled,
            tools: ["(", ")", "["].map { text in BlockKeyboardTool(text: text) { action(text) } }
        )
    }

    private func makeWindow(_ button: UIButton) async throws -> UIWindow {
        // Hosted tests may begin before the application's first scene connects.
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
        button.frame = CGRect(x: 100, y: 600, width: 44, height: 42)
        window.rootViewController?.view.addSubview(button)
        window.layoutIfNeeded()
        XCTAssertIdentical(button.window, window)
        return window
    }

    private func picker(in button: KeyboardToolButton) -> KeyboardToolPickerView? {
        button.subviews.compactMap { $0 as? KeyboardToolPickerView }.first
    }

    private func choiceViews(in picker: KeyboardToolPickerView) -> [KeyboardToolView] {
        picker.subviews.compactMap { $0 as? KeyboardToolView }
    }
}
#endif
