// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "KeyboardToolbar",
    platforms: [.iOS(.v14)],
    products: [
        .library(name: "KeyboardToolbar", targets: ["KeyboardToolbar"]),
    ],
    dependencies: [
        .package(url: "https://github.com/TimOliver/BlurUIKit.git", from: "1.1.1")
    ],
    targets: [
        .target(
            name: "KeyboardToolbar",
            dependencies: [
                .product(name: "BlurUIKit", package: "BlurUIKit"),
            ],
            resources: [
                .process("Assets.xcassets")
            ]
        )
    ]
)
