# Changelog

## 1.0.0 — Unreleased

- Native Liquid Glass group capsules on iOS 26 and later, with a single capsule fallback when space is limited. Earlier iOS and visionOS retain the classic keyboard-key appearance.
- Deprecate secondary styling on iOS 26: Liquid Glass uses uniform emphasis for enabled tools and only dims disabled tools.
- Remove BlurUIKit; there is no custom toolbar background blur.
- Preserve the existing tool models, group spacing, item insets, text offsets, image variants, and symbol sizing. Narrow glass layouts compress group spacing to keep keys usable.
- Keep the default hold delay at 0.5 seconds through `showToolPickerDelay`; zero expands choices immediately.
- Anchor expanded selection to the finger and fit its travel to the visible choices, so screen-edge clamping cannot skip or hide reachable alternatives.
- Cancel pending actions on interrupted touches, detachment, keyboard changes, and app deactivation. This deliberately changes the old behavior that committed on touch cancellation.
- Keep current actions during equivalent group updates; disabled tools cannot activate through touch or accessibility.
- Add `cancelInteractions()`, `willPresentToolPicker`, and optional custom accessibility labels and identifiers.
- Add focused geometry and hosted interaction tests and refreshed light/dark README images.

Requires Xcode 26 or later to build with the Liquid Glass SDK. The package still supports iOS 14 and later and visionOS. This branch prepares 1.0; no release or tag has been published.
