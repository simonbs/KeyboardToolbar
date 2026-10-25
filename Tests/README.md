# Testing

Geometry tests live in the Swift package test target. Touch and accessibility tests need a connected UIKit window scene, so the hosted suite uses the Example app.

With Xcode 26 or later and XcodeGen installed, generate the test host from the repository root:

```sh
xcodegen generate --spec Tests/Host/project.yml
set -o pipefail
xcodebuild test \
  -project Tests/Host/KeyboardToolbarTests.xcodeproj \
  -scheme KeyboardToolbarTests \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -parallel-testing-enabled NO \
  CODE_SIGNING_ALLOWED=NO 2>&1 | xcsift -f toon
```

Choose an installed simulator with `xcrun simctl list devices available`. The generated test project is ignored. The hosted suite includes geometry, glass interaction, legacy interaction, and public toolbar integration coverage. The legacy button suite runs directly even on current systems; verify older-system appearance separately on an older simulator or device. Glass wrapper tests are skipped before iOS 26.
