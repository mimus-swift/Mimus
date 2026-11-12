import SwiftSyntax

public enum OverrideSyntax {
  public static func isEnabled(
    attributes: AttributeListSyntax, trivia: Trivia, baseClassName: String?
  ) throws -> Bool {
    let markers = attributes.compactMap { $0.as(AttributeSyntax.self) }
      .filter { FixtureSyntax.attributeName($0) == "MockOverride" }
    guard markers.count <= 1 else {
      throw FixtureDiagnostic("Use only one @MockOverride on each requirement")
    }
    if let marker = markers.first, case .argumentList(let arguments) = marker.arguments,
      !arguments.isEmpty
    {
      throw FixtureDiagnostic("@MockOverride accepts no arguments")
    }
    let explicit =
      !markers.isEmpty || FixtureSyntax.hasAnnotation(trivia.description, named: "override")
    if explicit && baseClassName == nil {
      throw FixtureDiagnostic("@MockOverride requires a mock base class")
    }
    let definedIn = FixtureSyntax.annotation(trivia.description, named: "definedIn")
    let legacy =
      baseClassName != nil && definedIn != nil
      && (definedIn == baseClassName
        || definedIn == baseClassName?.split(separator: ".").last.map(String.init))
    return explicit || legacy
  }
}
