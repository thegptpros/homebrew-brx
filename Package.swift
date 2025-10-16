// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BRX",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "BRX", targets: ["BRX"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0")
    ],
    targets: [
        .executableTarget(
            name: "BRX",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Sources/BRX",
            swiftSettings: [
                .define("BRX_BUILD_TS", .when(configuration: .release))
            ]
        ),
        .testTarget(
            name: "BRXTests",
            dependencies: ["BRX"],
            path: "Tests"
        )
    ]
)

