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

    func testScrollingSymbolsKeepFullSizeKeysAndLeaveOtherGroupsVisible() {
        for (width, capacity) in [(CGFloat(320), 1), (375, 2), (402, 3), (540, 6)] {
            let bounds = CGRect(x: 0, y: 0, width: width, height: 60)
            let layout = GlassKeyboardToolbarLayout(bounds: bounds, safeAreaInsets: .zero,
                                                    groupCounts: [2, 6, 1, 1], groupSpacings: [6, 6, 6, 6],
                                                    scrollableGroups: [1])
            XCTAssertTrue(layout.isGrouped)
            XCTAssertEqual(layout.capsuleFrames.count, 4)
            XCTAssertEqual(layout.buttonFrames.map(\.count), [2, 6, 1, 1])
            XCTAssertEqual(Set(layout.pagination.keys), [1])
            XCTAssertEqual(layout.pagination[1]?.capacity, capacity)
            XCTAssertEqual(layout.pagination[1]?.pageCount, 6 / capacity)
            XCTAssertTrue(layout.buttonFrames.flatMap { $0 }.allSatisfy { $0.width == 44 })
            guard layout.capsuleFrames.count == 4 else { continue }
            for capsule in layout.capsuleFrames {
                XCTAssertGreaterThanOrEqual(capsule.minX, 8)
                XCTAssertLessThanOrEqual(capsule.maxX, width - 8 + 0.001)
            }
            for index in layout.capsuleFrames.indices {
                for key in layout.buttonFrames[index] {
                    XCTAssertTrue(CGRect(origin: .zero, size: layout.capsuleFrames[index].size).contains(key))
                }
            }
            XCTAssertEqual(layout.buttonFrames[1][0], layout.buttonFrames[1][6 - capacity])
        }
    }

    func testPreferredPageSizeKeepsFourGroupsAndFitsWholeSymbolKeys() {
        for (width, capacity) in [(CGFloat(320), 3), (375, 4), (402, 4)] {
            let layout = GlassKeyboardToolbarLayout(
                bounds: CGRect(x: 0, y: 0, width: width, height: 60), safeAreaInsets: .zero,
                groupCounts: [2, 6, 1, 1], scrollableGroups: [1], preferredItemsPerPage: [1: 4]
            )
            XCTAssertEqual(layout.capsuleFrames.count, 4)
            XCTAssertEqual(layout.pagination[1]?.capacity, capacity)
            XCTAssertEqual(layout.pagination[1]?.pageCount, 2)
            guard layout.capsuleFrames.count == 4 else { continue }
            XCTAssertGreaterThanOrEqual(layout.capsuleFrames[0].minX, 8)
            XCTAssertLessThanOrEqual(layout.capsuleFrames[3].maxX, width - 8 + 0.001)
            for (index, keys) in layout.buttonFrames.enumerated() {
                let page = CGRect(origin: .zero, size: layout.capsuleFrames[index].size)
                for key in keys {
                    XCTAssertTrue(page.contains(key))
                    if index == 1 { XCTAssertEqual(key.width, 44) }
                    else { XCTAssertGreaterThanOrEqual(key.width, 32) }
                }
            }
        }
    }

    func testEightSymbolKeysUseTwoPagesInPortraitAndFillWideCapsule() throws {
        let configurations: [(width: CGFloat, inset: CGFloat, expectedPages: Int)] = [
            (402, 0, 2), (583, 0, 2), (584, 0, 1), (852, 59, 1)
        ]
        for (width, inset, expectedPages) in configurations {
            let layout = GlassKeyboardToolbarLayout(
                bounds: CGRect(x: 0, y: 0, width: width, height: 60),
                safeAreaInsets: UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset),
                groupCounts: [2, 8, 1, 1], scrollableGroups: [1], preferredItemsPerPage: [1: 4]
            )
            XCTAssertEqual(layout.capsuleFrames.count, 4)
            XCTAssertEqual(layout.pagination[1]?.pageCount, expectedPages)
            XCTAssertEqual(layout.pagination[1]?.capacity, expectedPages == 1 ? 8 : 4)
            let symbols = layout.buttonFrames[1]
            XCTAssertEqual(symbols.count, 8)
            XCTAssertTrue(symbols.allSatisfy { $0.width >= 44 })
            if expectedPages == 1 {
                let first = try XCTUnwrap(symbols.first)
                let last = try XCTUnwrap(symbols.last)
                XCTAssertEqual(first.minX, 2)
                XCTAssertEqual(last.maxX, layout.capsuleFrames[1].width - 2, accuracy: 0.001)
                XCTAssertEqual(last.width, first.width)
                XCTAssertEqual(layout.capsuleFrames[0].minX, inset + 8, accuracy: 0.001)
                XCTAssertEqual(layout.capsuleFrames[3].maxX, width - inset - 8, accuracy: 0.001)
            }
        }
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
