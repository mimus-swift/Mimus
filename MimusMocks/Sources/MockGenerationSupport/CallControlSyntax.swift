import SwiftSyntax

public enum CallControlSyntax {
  public static func isEnabled(attributes: AttributeListSyntax, trivia: Trivia) throws -> Bool {
    let markers = attributes.compactMap { $0.as(AttributeSyntax.self) }
      .filter { FixtureSyntax.attributeName($0) == "MockCallControl" }
    guard markers.count <= 1 else {
      throw FixtureDiagnostic("Use only one @MockCallControl on each method")
    }
    if let marker = markers.first, case .argumentList(let arguments) = marker.arguments,
      !arguments.isEmpty
    {
      throw FixtureDiagnostic("@MockCallControl accepts no arguments")
    }
    let text = trivia.description
    return !markers.isEmpty || FixtureSyntax.hasAnnotation(text, named: "callControl")
      || FixtureSyntax.hasAnnotation(text, named: "includeExpectation")
  }
}
