import MockableMacro
import SwiftSyntaxMacrosTestSupport
import XCTest

final class PublisherDiagnosticsTests: XCTestCase {
  private func assertInvalid(_ members: String, message: String) {
    let indented = members.split(separator: "\n").map { "  " + $0 }.joined(separator: "\n")
    assertMacroExpansion(
      "@Mockable\nprotocol Service {\n\(indented)\n}",
      expandedSource: "protocol Service {\n\(indented)\n}",
      diagnostics: [DiagnosticSpec(message: message, line: 1, column: 1)],
      macros: ["Mockable": MockableMacro.self])
  }

  func testRejectsOtherPropertyTypes() {
    assertInvalid(
      "@MockPublisher\nvar value: Int { get }",
      message: "@MockPublisher requires an explicit AnyPublisher<Output, Failure> type")
  }

  func testRejectsConflictingFixtureDefaults() {
    assertInvalid(
      "@MockPublisher(initial: 0)\n@MockDefault(7)\nvar value: AnyPublisher<Int, Never> { get }",
      message: "Choose @MockPublisher or a fixture default for a property, not both")
  }

  func testRejectsHelperNameCollisions() {
    assertInvalid(
      "@MockPublisher\nvar events: AnyPublisher<Int, Never> { get }\nvar eventsSubject: String { get }",
      message: "Generated subject 'eventsSubject' conflicts with another requirement")
  }

  func testRejectsEffectfulPublisherProperties() {
    assertInvalid(
      "@MockPublisher\nvar events: AnyPublisher<Int, Never> { get async throws }",
      message: "@MockPublisher requires a synchronous, nonthrowing property")
  }

  func testRejectsPublisherMarkersOnMethods() {
    assertInvalid(
      "@MockPublisher\nfunc events() -> AnyPublisher<Int, Never>",
      message: "@MockPublisher applies to a protocol property")
  }

  func testRejectsDuplicatePublisherMarkers() {
    assertInvalid(
      "@MockPublisher\n@MockPublisher(initial: 0)\nvar events: AnyPublisher<Int, Never> { get }",
      message: "Use only one publisher configuration on each property")
  }

  func testRejectsPublisherMarkersOnTypes() {
    assertMacroExpansion(
      "@MockPublisher\nstruct Service {}",
      expandedSource: "struct Service {}",
      diagnostics: [
        DiagnosticSpec(message: "@MockPublisher applies to a protocol property", line: 1, column: 1)
      ],
      macros: ["MockPublisher": MockPublisherMacro.self])
  }
}
