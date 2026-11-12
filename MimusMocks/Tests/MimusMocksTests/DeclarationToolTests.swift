import Foundation
import XCTest

final class DeclarationToolTests: XCTestCase {
  private func run(_ source: String) throws -> (status: Int32, error: String) {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let input = directory.appendingPathComponent("Contract.swift")
    try source.write(to: input, atomically: true, encoding: .utf8)
    var location = Bundle(for: Self.self).bundleURL
    var executable: URL?
    for _ in 0..<8 {
      for name in ["MimusMockDeclarations", "MimusMockDeclarations-tool"] {
        let candidate = location.appendingPathComponent(name)
        if FileManager.default.isExecutableFile(atPath: candidate.path) {
          executable = candidate
          break
        }
      }
      if executable != nil { break }
      location.deleteLastPathComponent()
    }
    let process = Process()
    process.executableURL = try XCTUnwrap(executable)
    process.arguments = [
      "--module", "Contracts", "--input", "Contracts=" + input.path,
      "--output", directory.appendingPathComponent("Mocks.swift").path,
    ]
    let errors = Pipe()
    process.standardError = errors
    process.standardOutput = FileHandle.nullDevice
    try process.run()
    process.waitUntilExit()
    return (
      process.terminationStatus,
      String(decoding: errors.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
    )
  }

  func testReportsUnavailableInheritedSource() throws {
    let result = try run("// mimus: mockable\npublic protocol Service: ExternalParent {}")
    XCTAssertNotEqual(result.status, 0)
    XCTAssertTrue(result.error.contains("Cannot resolve inherited protocol 'ExternalParent'"))
  }

  func testReportsConditionalProtocols() throws {
    let result = try run("#if DEBUG\n// mimus: mockable\npublic protocol Service {}\n#endif")
    XCTAssertNotEqual(result.status, 0)
    XCTAssertTrue(result.error.contains("nested or conditional protocol 'Service'"))
  }

  func testReportsInheritanceCycles() throws {
    let result = try run(
      "public protocol Parent: Service {}\n// mimus: mockable\npublic protocol Service: Parent {}")
    XCTAssertNotEqual(result.status, 0)
    XCTAssertTrue(result.error.contains("inheritance cycle"))
  }

  func testReportsInvalidFixturePolicies() throws {
    let result = try run(
      "// mimus: mockable\n// mimus: defaults = \"unknown\"\npublic protocol Service {}")
    XCTAssertNotEqual(result.status, 0)
    XCTAssertTrue(result.error.contains("Mock defaults must be 'none' or 'fixtures'"))
  }

  func testReportsInvalidPublisherConfigurations() throws {
    let result = try run(
      """
      // mimus: mockable
      public protocol Service {
        // mimus: publisher = "unknown"
        var events: AnyPublisher<Int, Never> { get }
      }
      """)
    XCTAssertNotEqual(result.status, 0)
    XCTAssertTrue(result.error.contains("publisher must be \"passthrough\""))
  }

  func testReportsPublisherCommentsOnMethods() throws {
    let result = try run(
      """
      // mimus: mockable
      public protocol Service {
        // mimus: publisher = "passthrough"
        func events() -> AnyPublisher<Int, Never>
      }
      """)
    XCTAssertNotEqual(result.status, 0)
    XCTAssertTrue(result.error.contains("Publisher helpers apply only to protocol properties"))
  }
}
