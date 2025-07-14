// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "MacAudioCapture",
    platforms: [
        .macOS("14.4")
    ],
    products: [
        .library(name: "MacAudioCapture", type: .dynamic, targets: ["AudioCapture"]),
    ],
    dependencies: [
        .package(url: "https://github.com/LinusU/swift-napi-bindings", from: "1.0.0-alpha.1"),
    ],
    targets: [
        .target(
            name: "Trampoline",
            dependencies: [
                .product(name: "NAPIC", package: "swift-napi-bindings")
            ]
        ),
        .target(
            name: "AudioCapture",
            dependencies: [
                .product(name: "NAPI", package: "swift-napi-bindings"),
                "Trampoline"
            ]
        ),
    ]
)
