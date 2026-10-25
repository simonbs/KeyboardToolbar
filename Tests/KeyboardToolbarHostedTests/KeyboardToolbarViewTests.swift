#if os(iOS)
@testable import KeyboardToolbar
import UIKit
import XCTest

@MainActor final class KeyboardToolbarViewTests: XCTestCase {
    func testDefaultDelayAndImmediateExpansionUseCurrentAlternatives() async throws {
        guard #available(iOS 26, *) else { throw XCTSkip("Native glass requires iOS 26") }
        let toolbar = KeyboardToolbarView()
        var actions: [String] = []
        let primary = BlockKeyboardTool(text: "=") { actions.append("primary") }
        toolbar.groups = [KeyboardToolGroup(items: [KeyboardToolGroupItem(
            representativeTool: primary, includeRepresentativeToolInPicker: true,
            tools: [BlockKeyboardTool(text: "==", accessibilityLabel: "Equality") { actions.append("equal") }],
            accessibilityLabel: "Assignment", accessibilityIdentifier: "assignment"
        )])]
        let window = try await makeWindow(toolbar)
        defer { window.isHidden = true }
        let button = try XCTUnwrap(descendants(toolbar).compactMap { $0 as? GlassKeyboardToolButton }.first)
        XCTAssertEqual(button.accessibilityLabel, "Assignment")
        XCTAssertEqual(button.accessibilityIdentifier, "assignment")
        XCTAssertEqual(button.accessibilityCustomActions?.last?.name, "Equality")
        button.sendActions(for: .touchDown)
        try await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertEqual(choiceCount(window), 1, "The default hold delay remains 0.5 seconds")
        try await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertEqual(choiceCount(window), 2)
        let picker = try XCTUnwrap(window.subviews.compactMap { $0 as? GlassKeyboardPickerView }.first)
        XCTAssertEqual(picker.contentView.subviews.compactMap { $0 as? UILabel }.last?.accessibilityLabel, "Equality")
        toolbar.cancelInteractions()
        button.sendActions(for: .touchUpInside)
        XCTAssertTrue(actions.isEmpty)
        toolbar.showToolPickerDelay = 0
        button.sendActions(for: .touchDown)
        XCTAssertEqual(choiceCount(window), 2)
        button.sendActions(for: .touchUpInside)
        XCTAssertEqual(actions, ["primary"])
    }

    func testPresentationCallbackCanCancelAndEmptyGroupsAreIgnored() async throws {
        guard #available(iOS 26, *) else { throw XCTSkip("Native glass requires iOS 26") }
        var actionCount = 0
        var presentationCount = 0
        let toolbar = KeyboardToolbarView()
        let tool = BlockKeyboardTool(text: "a") { actionCount += 1 }
        toolbar.groups = [KeyboardToolGroup(items: []), KeyboardToolGroup(items: [
            KeyboardToolGroupItem(representativeTool: tool),
            KeyboardToolGroupItem(representativeTool: tool, tools: [tool])
        ])]
        toolbar.willPresentToolPicker = { [weak toolbar] in
            presentationCount += 1
            toolbar?.cancelInteractions()
        }
        let window = try await makeWindow(toolbar)
        defer { window.isHidden = true }
        let buttons = descendants(toolbar).compactMap { $0 as? GlassKeyboardToolButton }
        XCTAssertEqual(buttons.count, 2)
        buttons[0].sendActions(for: .touchDown)
        buttons[0].sendActions(for: .touchUpInside)
        XCTAssertEqual(presentationCount, 0)
        XCTAssertEqual(actionCount, 1)
        buttons[1].sendActions(for: .touchDown)
        buttons[1].sendActions(for: .touchUpInside)
        XCTAssertEqual(presentationCount, 1)
        XCTAssertEqual(actionCount, 1)
        XCTAssertEqual(choiceCount(window), 0)
    }

    private func descendants(_ view: UIView) -> [UIView] {
        view.subviews.flatMap { [$0] + descendants($0) }
    }

    private func choiceCount(_ window: UIWindow) -> Int {
        window.subviews.compactMap { $0 as? GlassKeyboardPickerView }.first?
            .contentView.subviews.compactMap { $0 as? UILabel }.count ?? 0
    }

    private func makeWindow(_ toolbar: KeyboardToolbarView) async throws -> UIWindow {
        let deadline = Date().addingTimeInterval(5)
        while UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).isEmpty,
              Date() < deadline { try await Task.sleep(nanoseconds: 50_000_000) }
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: 0, y: 0, width: 393, height: 852)
        window.rootViewController = UIViewController()
        window.isHidden = false
        toolbar.frame = CGRect(x: 0, y: 600, width: 393, height: 60)
        window.rootViewController?.view.addSubview(toolbar)
        window.layoutIfNeeded()
        toolbar.layoutIfNeeded()
        return window
    }
}
#endif
