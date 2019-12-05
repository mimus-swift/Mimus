// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "Mimus",
    products: [
        .library(
            name: "Mimus",
            targets: ["Mimus"]),
    ],
    dependencies: [],
    targets: [
       .target(
            name: "Mimus",
            dependencies: []),
        .testTarget(
            name: "MimusTests",
            dependencies: ["Mimus"]),
        .testTarget(
            name: "MimusExamples",
            dependencies: ["Mimus"]),
    ]
)
