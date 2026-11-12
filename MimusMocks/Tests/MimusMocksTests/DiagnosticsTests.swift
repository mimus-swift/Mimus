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

}
