// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "FailureReporting",
    platforms: [.macOS(.v14)],
    dependencies: [.package(name: "Mimus", path: "../..")],
    targets: [
        .target(name: "ReportingProtocols"),
        .testTarget(
            name: "FailureReportingTests",
            dependencies: ["ReportingProtocols", .product(name: "Mimus", package: "Mimus")]
        ),
    ]
)
