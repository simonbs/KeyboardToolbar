// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "KeyboardToolbar",
    platforms: [.iOS(.v14)],
    products: [
        .library(name: "KeyboardToolbar", targets: ["KeyboardToolbar"]),
    ],
    targets: [
        .target(name: "KeyboardToolbar", resources: [.process("Assets.xcassets")])
    ]
)

#if swift(>=5.6)
// Add the documentation compiler plugin if possible
package.dependencies.append(
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
)
#endif