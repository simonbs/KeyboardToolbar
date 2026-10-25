#if os(iOS)
import UIKit

/// Keeps three separate groups when each key can retain at least 32 points of width.
struct GlassKeyboardToolbarLayout {
    let isGrouped: Bool
    let capsuleFrames: [CGRect]
    /// Button frames are relative to their capsule.
    let buttonFrames: [[CGRect]]

    init(bounds: CGRect, safeAreaInsets: UIEdgeInsets, groupCounts: [Int], groupSpacings: [CGFloat] = []) {
        let availableWidth = max(0, bounds.width - safeAreaInsets.left - safeAreaInsets.right - 16)
        let count = groupCounts.reduce(0, +)
        guard count > 0 else {
            isGrouped = false
            capsuleFrames = []
            buttonFrames = []
            return
        }
        let gap: CGFloat = 8
        let padding: CGFloat = 2
        let spacings = groupCounts.indices.map { index in
            index < groupSpacings.count ? max(0, groupSpacings[index]) : 0
        }
        let spacingWidth = zip(groupCounts, spacings).reduce(CGFloat.zero) { $0 + CGFloat(max(0, $1.0 - 1)) * $1.1 }
        let groupOverhead = CGFloat(groupCounts.count) * padding * 2 + CGFloat(max(0, groupCounts.count - 1)) * gap + spacingWidth
        isGrouped = availableWidth >= CGFloat(count) * 32 + groupOverhead
        let overhead = isGrouped ? groupOverhead : padding * 2
        let buttonWidth = min(44, max(1, (availableWidth - overhead) / CGFloat(count)))
        let totalWidth = buttonWidth * CGFloat(count) + overhead
        var x = safeAreaInsets.left + 8 + (availableWidth - totalWidth) / 2
        var frames: [CGRect] = []
        var keys: [[CGRect]] = []
        var keyX = padding
        if !isGrouped {
            frames.append(CGRect(x: x, y: 6, width: totalWidth, height: 48))
        }
        for (groupIndex, groupCount) in groupCounts.enumerated() {
            let spacing = isGrouped ? spacings[groupIndex] : 0
            if isGrouped {
                let width = CGFloat(groupCount) * buttonWidth + CGFloat(max(0, groupCount - 1)) * spacing + 2 * padding
                frames.append(CGRect(x: x, y: 6, width: width, height: 48))
                x += width + gap
                keyX = padding
            }
            keys.append((0..<groupCount).map { _ in
                defer { keyX += buttonWidth + spacing }
                return CGRect(x: keyX, y: 2, width: buttonWidth, height: 44)
            })
        }
        capsuleFrames = frames
        buttonFrames = keys
    }
}

#endif
