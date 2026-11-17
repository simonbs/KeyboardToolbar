#if os(iOS)
import UIKit

/// Keeps groups separate when the fixed keys and a viewport for each scrolling group can fit.
struct GlassKeyboardToolbarLayout {
    struct Pagination {
        let capacity: Int
        let pageCount: Int
    }

    let isGrouped: Bool
    let capsuleFrames: [CGRect]
    /// Button frames are relative to their capsule or to their page in a scrolling capsule.
    let buttonFrames: [[CGRect]]
    let pagination: [Int: Pagination]

    init(bounds: CGRect, safeAreaInsets: UIEdgeInsets, groupCounts: [Int], groupSpacings: [CGFloat] = [],
         scrollableGroups: Set<Int> = [], preferredItemsPerPage: [Int: Int] = [:]) {
        let availableWidth = max(0, bounds.width - safeAreaInsets.left - safeAreaInsets.right - 16)
        let count = groupCounts.reduce(0, +)
        guard count > 0 else {
            isGrouped = false
            capsuleFrames = []
            buttonFrames = []
            pagination = [:]
            return
        }
        let gap: CGFloat = 8
        let padding: CGFloat = 2
        let fullKeyWidth: CGFloat = 44
        let minimumKeyWidth: CGFloat = 32
        let spacings = groupCounts.indices.map { index in
            index < groupSpacings.count ? max(0, groupSpacings[index]) : 0
        }
        let spacingWidths = zip(groupCounts, spacings).map { count, spacing in CGFloat(max(0, count - 1)) * spacing }
        let scrollable = groupCounts.indices.filter { scrollableGroups.contains($0) && groupCounts[$0] > 0 }
        let fixedCount = count - scrollable.reduce(0) { $0 + groupCounts[$1] }
        let fixedSpacingWidth = groupCounts.indices.filter { !scrollableGroups.contains($0) }
            .reduce(CGFloat.zero) { $0 + spacingWidths[$1] }
        let groupOverhead = CGFloat(groupCounts.count) * padding * 2
            + CGFloat(max(0, groupCounts.count - 1)) * gap + fixedSpacingWidth
        // Reserve one key's worth of space for each scrolling group before distributing spare width.
        let visibleSlots = fixedCount + scrollable.count
        isGrouped = availableWidth >= CGFloat(visibleSlots) * minimumKeyWidth + groupOverhead
        let overhead = isGrouped ? groupOverhead : padding * 2
        let slots = CGFloat(isGrouped ? visibleSlots : count)
        let preferredWidths = isGrouped ? Dictionary(uniqueKeysWithValues: scrollable.compactMap { index -> (Int, CGFloat)? in
            guard let preferred = preferredItemsPerPage[index], preferred > 0 else { return nil }
            let keysPerPage = min(preferred, groupCounts[index])
            return (index, CGFloat(keysPerPage) * fullKeyWidth + CGFloat(keysPerPage - 1) * spacings[index])
        }) : [:]
        let fullToolbarWidth = CGFloat(count) * fullKeyWidth + groupOverhead
            + scrollable.reduce(CGFloat.zero) { $0 + spacingWidths[$1] }
        let showsAllKeys = !preferredWidths.isEmpty && availableWidth >= fullToolbarWidth
        let preferredKeyCount = preferredWidths.keys.reduce(0) { $0 + groupCounts[$1] }
        let extraWidthPerKey = showsAllKeys ? (availableWidth - fullToolbarWidth) / CGFloat(preferredKeyCount) : 0
        let ordinarySlots = slots - CGFloat(preferredWidths.count)
        let naturalButtonWidth = min(fullKeyWidth, max(1, (availableWidth - overhead) / slots))
        let buttonWidth: CGFloat
        if !showsAllKeys, !preferredWidths.isEmpty, ordinarySlots > 0 {
            // Give preferred pages room to fit whole keys while preserving each fixed button's minimum width.
            let remaining = availableWidth - overhead - preferredWidths.values.reduce(0, +)
            buttonWidth = min(naturalButtonWidth, max(minimumKeyWidth, remaining / ordinarySlots))
        } else {
            buttonWidth = naturalButtonWidth
        }
        let reservedWidth = buttonWidth * slots + overhead
        let scrollWidths: [Int: CGFloat] = isGrouped ? Dictionary(uniqueKeysWithValues: scrollable.map { index in
            let naturalWidth = CGFloat(groupCounts[index]) * fullKeyWidth + spacingWidths[index]
            guard let preferredWidth = preferredWidths[index] else { return (index, naturalWidth) }
            let wideWidth = naturalWidth + CGFloat(groupCounts[index]) * extraWidthPerKey
            return (index, showsAllKeys ? wideWidth : preferredWidth)
        }) : [:]
        let availableExtra = max(0, availableWidth - reservedWidth)
        let preferredExtra = preferredWidths.keys.reduce(CGFloat.zero) { total, index in
            total + (scrollWidths[index] ?? buttonWidth) - buttonWidth
        }
        let usedPreferredExtra = min(preferredExtra, availableExtra)
        let preferredFraction = preferredExtra > 0 ? usedPreferredExtra / preferredExtra : 0
        let ordinaryExtra = scrollWidths.reduce(CGFloat.zero) { total, group in
            preferredWidths[group.key] == nil ? total + group.value - buttonWidth : total
        }
        let usedOrdinaryExtra = min(ordinaryExtra, max(0, availableExtra - usedPreferredExtra))
        let ordinaryFraction = ordinaryExtra > 0 ? usedOrdinaryExtra / ordinaryExtra : 0
        let totalWidth = reservedWidth + usedPreferredExtra + usedOrdinaryExtra
        var x = safeAreaInsets.left + 8 + (availableWidth - totalWidth) / 2
        var frames: [CGRect] = []
        var keys: [[CGRect]] = []
        var pagedGroups: [Int: Pagination] = [:]
        var keyX = padding
        if !isGrouped {
            frames.append(CGRect(x: x, y: 6, width: totalWidth, height: 48))
        }
        for (groupIndex, groupCount) in groupCounts.enumerated() {
            let spacing = isGrouped ? spacings[groupIndex] : 0
            if isGrouped {
                let width: CGFloat
                if let contentWidth = scrollWidths[groupIndex] {
                    let hasPreferredPageSize = preferredWidths[groupIndex] != nil
                    let extraFraction = hasPreferredPageSize ? preferredFraction : ordinaryFraction
                    width = buttonWidth + (contentWidth - buttonWidth) * extraFraction + 2 * padding
                    let usableWidth = width - 2 * padding
                    let pagedKeyWidth: CGFloat
                    let capacity: Int
                    if showsAllKeys && hasPreferredPageSize {
                        pagedKeyWidth = (usableWidth - spacingWidths[groupIndex]) / CGFloat(groupCount)
                        capacity = groupCount
                    } else {
                        pagedKeyWidth = min(fullKeyWidth, usableWidth)
                        capacity = max(1, Int(((usableWidth + spacing + 0.001) / (pagedKeyWidth + spacing)).rounded(.down)))
                    }
                    let pageCount = (groupCount + capacity - 1) / capacity
                    pagedGroups[groupIndex] = Pagination(capacity: capacity, pageCount: pageCount)
                    keys.append((0..<groupCount).map { index in
                        let keyX = padding + CGFloat(index % capacity) * (pagedKeyWidth + spacing)
                        return CGRect(x: keyX, y: 2, width: pagedKeyWidth, height: 44)
                    })
                } else {
                    width = CGFloat(groupCount) * buttonWidth + spacingWidths[groupIndex] + 2 * padding
                }
                frames.append(CGRect(x: x, y: 6, width: width, height: 48))
                x += width + gap
                keyX = padding
            }
            if pagedGroups[groupIndex] != nil { continue }
            keys.append((0..<groupCount).map { _ in
                defer { keyX += buttonWidth + spacing }
                return CGRect(x: keyX, y: 2, width: buttonWidth, height: 44)
            })
        }
        capsuleFrames = frames
        buttonFrames = keys
        pagination = pagedGroups
    }
}

#endif
