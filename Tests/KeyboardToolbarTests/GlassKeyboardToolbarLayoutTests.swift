#if os(iOS)
@testable import KeyboardToolbar
import UIKit
import XCTest

final class GlassKeyboardToolbarLayoutTests: XCTestCase {
    func testThreeGroupsFitPhoneWidthsAndLandscapeSafeArea() {
        for (width, insets) in [
            (CGFloat(375), UIEdgeInsets.zero),
            (393, .zero),
            (440, .zero),
            (852, UIEdgeInsets(top: 0, left: 59, bottom: 21, right: 59))
        ] {
            let bounds = CGRect(x: 0, y: 0, width: width, height: 60)
            let layout = GlassKeyboardToolbarLayout(bounds: bounds, safeAreaInsets: insets, groupCounts: [2, 5, 2])
            XCTAssertTrue(layout.isGrouped)
            XCTAssertEqual(layout.capsuleFrames.count, 3)
            for (left, right) in zip(layout.capsuleFrames, layout.capsuleFrames.dropFirst()) {
                XCTAssertLessThan(left.maxX, right.minX, "Groups need a visible gap")
            }
            assertKeysFit(layout, bounds: bounds.inset(by: insets), minimumKeyWidth: 32)
        }
    }

    func testCustomGroupSpacingFitsAndCompressesOnlyInNarrowFallback() {
        let wide = GlassKeyboardToolbarLayout(bounds: CGRect(x: 0, y: 0, width: 440, height: 60),
                                             safeAreaInsets: .zero, groupCounts: [2, 5, 2], groupSpacings: [3, 6, 9])
        XCTAssertTrue(wide.isGrouped)
        for (group, spacing) in zip(wide.buttonFrames, [CGFloat(3), 6, 9]) {
            XCTAssertEqual(group[1].minX - group[0].maxX, spacing, accuracy: 0.001)
        }
        assertKeysFit(wide, bounds: CGRect(x: 0, y: 0, width: 440, height: 60), minimumKeyWidth: 32)
        let narrow = GlassKeyboardToolbarLayout(bounds: CGRect(x: 0, y: 0, width: 320, height: 60),
                                               safeAreaInsets: .zero, groupCounts: [2, 5, 2], groupSpacings: [3, 6, 9])
        XCTAssertFalse(narrow.isGrouped)
        assertKeysFit(narrow, bounds: CGRect(x: 0, y: 0, width: 320, height: 60), minimumKeyWidth: 32)
    }

    func testNarrowPhoneFallsBackToOneCapsuleWithoutLosingControls() {
        let bounds = CGRect(x: 0, y: 0, width: 320, height: 60)
        let layout = GlassKeyboardToolbarLayout(bounds: bounds, safeAreaInsets: .zero, groupCounts: [2, 5, 2])
        XCTAssertFalse(layout.isGrouped)
        XCTAssertEqual(layout.capsuleFrames.count, 1)
        assertKeysFit(layout, bounds: bounds, minimumKeyWidth: 32)
    }

    func testPickerFitsEdgesAndPreservesDirectionalSelection() {
        for width: CGFloat in [320, 375, 393, 440] {
            let available = CGRect(x: 8, y: 24, width: width - 16, height: 700)
            for trailing in [false, true] {
                let anchor = CGRect(x: trailing ? available.maxX - 44 : available.minX,
                                    y: 500, width: 44, height: 44)
                for count in [4, 6, 7, 8] {
                    let layout = GlassKeyboardPickerLayout(anchor: anchor, available: available, count: count)
                    XCTAssertEqual(layout.reversed, trailing)
                    XCTAssertGreaterThanOrEqual(layout.frame.minX, available.minX)
                    XCTAssertLessThanOrEqual(layout.frame.maxX, available.maxX + 0.001)
                    XCTAssertLessThan(layout.frame.maxY, anchor.minY)
                    for index in 0..<count {
                        let cell = layout.cellFrame(at: index)
                        XCTAssertTrue(CGRect(origin: .zero, size: layout.frame.size).contains(cell))
                        for y: CGFloat in [-1_000, 1_000] {
                            XCTAssertEqual(layout.nearestIndex(to: CGPoint(x: cell.midX, y: y)), index)
                        }
                    }
                    XCTAssertEqual(layout.nearestIndex(to: CGPoint(x: trailing ? 1_000 : -1_000, y: 0)), 0)
                    XCTAssertEqual(layout.nearestIndex(to: CGPoint(x: trailing ? -1_000 : 1_000, y: 0)), count - 1)
                }
            }
            let preview = GlassKeyboardPickerLayout(anchor: CGRect(x: 0, y: 30, width: 44, height: 44),
                                                    available: available, count: 1)
            XCTAssertFalse(preview.reversed)
            XCTAssertEqual(preview.frame.minX, available.minX)
            XCTAssertEqual(preview.frame.minY, available.minY)
        }
    }

    private func assertKeysFit(_ layout: GlassKeyboardToolbarLayout, bounds: CGRect, minimumKeyWidth: CGFloat,
                               file: StaticString = #filePath, line: UInt = #line) {
        let keys = layout.buttonFrames.enumerated().flatMap { groupIndex, buttons in
            let capsule = layout.capsuleFrames[layout.isGrouped ? groupIndex : 0]
            XCTAssertGreaterThanOrEqual(capsule.minX, bounds.minX, file: file, line: line)
            XCTAssertLessThanOrEqual(capsule.maxX, bounds.maxX, file: file, line: line)
            return buttons.map { button -> CGRect in
                XCTAssertGreaterThanOrEqual(button.width, minimumKeyWidth, file: file, line: line)
                XCTAssertGreaterThanOrEqual(button.height, 44, file: file, line: line)
                let frame = button.offsetBy(dx: capsule.minX, dy: capsule.minY)
                XCTAssertTrue(capsule.contains(frame), file: file, line: line)
                return frame
            }
        }
        XCTAssertEqual(keys.count, 9, file: file, line: line)
        for (left, right) in zip(keys, keys.dropFirst()) {
            XCTAssertLessThanOrEqual(left.maxX, right.minX + 0.001, file: file, line: line)
        }
    }
}
#endif
