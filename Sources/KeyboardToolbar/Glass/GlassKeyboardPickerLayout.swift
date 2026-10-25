#if os(iOS)
import UIKit

/// A directional row fitted to the keyboard window, selected by horizontal touch position.
struct GlassKeyboardPickerLayout {
    let frame: CGRect
    let cellWidth: CGFloat
    let count: Int
    let reversed: Bool

    init(anchor: CGRect, available: CGRect, count: Int) {
        self.count = max(1, count)
        let spacing: CGFloat = 6
        let fittedWidth = (available.width - 10 - spacing * CGFloat(self.count - 1)) / CGFloat(self.count)
        cellWidth = min(44, max(1, fittedWidth))
        let width = cellWidth * CGFloat(self.count) + spacing * CGFloat(self.count - 1) + 10
        let left = anchor.midX + cellWidth / 2 + 5 - width
        let right = anchor.midX - cellWidth / 2 - 5
        if self.count == 1 {
            reversed = false
        } else if left >= available.minX {
            reversed = true
        } else if right + width <= available.maxX {
            reversed = false
        } else {
            reversed = anchor.midX - available.minX > available.maxX - anchor.midX
        }
        let proposedX = self.count == 1 ? anchor.midX - width / 2 : (reversed ? left : right)
        frame = CGRect(
            x: min(max(proposedX, available.minX), available.maxX - width),
            y: max(available.minY, anchor.minY - cellWidth - 16), width: width, height: cellWidth + 10
        )
    }

    func cellFrame(at index: Int) -> CGRect {
        let visualIndex = reversed ? count - index - 1 : index
        return CGRect(x: 5 + CGFloat(visualIndex) * (cellWidth + 6), y: 5, width: cellWidth, height: cellWidth)
    }

    func nearestIndex(to point: CGPoint) -> Int {
        (0..<count).min { left, right in
            abs(cellFrame(at: left).midX - point.x) < abs(cellFrame(at: right).midX - point.x)
        } ?? 0
    }
}

#endif
