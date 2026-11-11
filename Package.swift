// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "Mimus",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        .library(
            name: "Mimus",
            targets: ["Mimus"]),
    ],
    dependencies: [],
    targets: [
       .target(
            name: "Mimus",
            dependencies: [],
            exclude: ["Info.plist"]),
        .testTarget(
            name: "MimusTests",
            dependencies: ["Mimus"],
            exclude: ["Info.plist"]),
        .testTarget(
            name: "MimusExamples",
            dependencies: ["Mimus"],
            exclude: ["Info.plist"]),
    ]
)
