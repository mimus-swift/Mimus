import MockableMacro
import SwiftSyntaxMacrosTestSupport
import XCTest

final class DiagnosticsTests: XCTestCase {

  func testRejectsNonProtocols() {
    assertMacroExpansion(
      "@Mockable\nstruct Service {}",
      expandedSource: "struct Service {}",
      diagnostics: [
        DiagnosticSpec(message: "@Mockable can only be applied to a protocol", line: 1, column: 1)
      ],
      macros: ["Mockable": MockableMacro.self]
    )
  }

  func testDiagnosesInheritedRequirements() {
    assertMacroExpansion(
      "@Mockable\nprotocol Child: Parent {}",
      expandedSource: "protocol Child: Parent {}",
      diagnostics: [
        DiagnosticSpec(
          message:
            "@Mockable cannot inspect inherited requirements of 'Parent'. Flatten the protocol into a mocks target before applying the macro.",
          line: 1, column: 1
        )
      ],
      macros: ["Mockable": MockableMacro.self]
    )
  }

  func testDiagnosesNonLiteralOptions() {
    assertMacroExpansion(
      "@Mockable(baseClassName: selectedBase)\nprotocol Service {}",
      expandedSource: "protocol Service {}",
      diagnostics: [
        DiagnosticSpec(message: "baseClassName must be a string literal", line: 1, column: 1)
      ],
      macros: ["Mockable": MockableMacro.self]
    )
  }

  func testDiagnosesInvalidFixturePolicy() {
    assertMacroExpansion(
      "@Mockable(defaults: true)\nprotocol Service {}",
      expandedSource: "protocol Service {}",
      diagnostics: [
        DiagnosticSpec(message: "defaults must be .none or .fixtures", line: 1, column: 1)
      ],
      macros: ["Mockable": MockableMacro.self]
    )
  }

  func testDiagnosesInvalidStubbingPolicy() {
    assertMacroExpansion(
      "@Mockable(stubbing: true)\nprotocol Service {}",
      expandedSource: "protocol Service {}",
      diagnostics: [
        DiagnosticSpec(message: "stubbing must be .simple or .rules", line: 1, column: 1)
      ],
      macros: ["Mockable": MockableMacro.self]
    )
  }

  func testDiagnosesReservedRuleBuilderNames() {
    for member in [
      "func stub()", "var stub: String { get }", "associatedtype Stubber",
      "typealias StaticStubber = Int",
    ] {
      assertMacroExpansion(
        "@Mockable(stubbing: .rules)\nprotocol Service {\n  \(member)\n}",
        expandedSource: "protocol Service {\n  \(member)\n}",
        diagnostics: [
          DiagnosticSpec(
            message: "A protocol member conflicts with the generated stub() API", line: 1, column: 1
          )
        ],
        macros: ["Mockable": MockableMacro.self]
      )
    }
  }

  func testRejectsDefaultMarkersOnTypes() {
    assertMacroExpansion(
      "@MockDefault(42)\nstruct Service {}",
      expandedSource: "struct Service {}",
      diagnostics: [
        DiagnosticSpec(
          message: "@MockDefault applies to a property, method, or subscript", line: 1, column: 1)
      ],
      macros: ["MockDefault": MockDefaultMacro.self]
    )
  }

  func testRejectsDefaultsOnVoidRequirements() {
    assertMacroExpansion(
      """
      @Mockable
      protocol Service {
        @MockDefault(42)
        func perform()
      }
      """,
      expandedSource: """
        protocol Service {
          @MockDefault(42)
          func perform()
        }
        """,
      diagnostics: [
        DiagnosticSpec(
          message: "Void requirements do not accept a mock default", line: 1, column: 1)
      ],
      macros: ["Mockable": MockableMacro.self]
    )
  }

}
