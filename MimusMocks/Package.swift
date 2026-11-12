// swift-tools-version: 6.2
import CompilerPluginSupport
import PackageDescription

#if compiler(>=6.3)
  let syntaxVersion: Version = "603.0.2"
#else
  let syntaxVersion: Version = "602.0.0"
#endif

let runtime = Package.Dependency.package(name: "Mimus", path: "..")

let package = Package(
  name: "MimusMocks",
  platforms: [.macOS(.v14), .iOS(.v13), .tvOS(.v13), .watchOS(.v6)],
  products: [
    .library(name: "MimusMocks", targets: ["MimusMocks"]),
    .executable(name: "MimusMockDeclarations", targets: ["MimusMockDeclarations"]),
    .plugin(name: "MimusMocksPlugin", targets: ["MimusMocksPlugin"]),
  ],
  dependencies: [
    .package(url: "https://github.com/swiftlang/swift-syntax.git", exact: syntaxVersion),
    runtime,
  ],
  targets: [
    .macro(
      name: "MockableMacro",
      dependencies: [
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
      ]),
    .target(name: "MimusMocks", dependencies: ["MockableMacro"]),
    .executableTarget(
      name: "MimusMockDeclarations",
      dependencies: [
        .product(name: "SwiftParser", package: "swift-syntax"),
        .product(name: "SwiftSyntax", package: "swift-syntax"),
      ]),
    .plugin(
      name: "MimusMocksPlugin", capability: .buildTool(), dependencies: ["MimusMockDeclarations"]),
    .target(name: "FixtureContracts", path: "Tests/Fixtures/Contracts"),
    .target(
      name: "FixtureMocks",
      dependencies: [
        "FixtureContracts", "MimusMocks", .product(name: "Mimus", package: "Mimus"),
      ], path: "Tests/Fixtures/Mocks", plugins: [.plugin(name: "MimusMocksPlugin")]),
    .testTarget(
      name: "MimusMocksTests",
      dependencies: [
        "FixtureContracts", "FixtureMocks",
        "MockableMacro", "MimusMocks", .product(name: "Mimus", package: "Mimus"),
        .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
      ]),
  ],
  swiftLanguageModes: [.v6]
)
