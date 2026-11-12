import SwiftSyntax
import SwiftSyntaxBuilder

public enum PublisherConfiguration {
  case passthrough
  case currentValue(ExprSyntax)
}

public enum PublisherSyntax {
  public static func configuration(
    attributes: AttributeListSyntax, trivia: Trivia
  ) throws -> PublisherConfiguration? {
    let markers = attributes.compactMap { $0.as(AttributeSyntax.self) }
      .filter { FixtureSyntax.attributeName($0) == "MockPublisher" }
    let text = trivia.description
    let hasKind = FixtureSyntax.hasAnnotation(text, named: "publisher")
    let hasInitial = FixtureSyntax.hasAnnotation(text, named: "publisherInitial")
    guard markers.count <= 1, !(hasKind && hasInitial),
      markers.isEmpty || !(hasKind || hasInitial)
    else { throw FixtureDiagnostic("Use only one publisher configuration on each property") }
    if let marker = markers.first {
      guard case .argumentList(let arguments) = marker.arguments else { return .passthrough }
      if arguments.isEmpty { return .passthrough }
      guard arguments.count == 1, let argument = arguments.first, argument.label?.text == "initial"
      else {
        throw FixtureDiagnostic("@MockPublisher accepts no arguments or initial: value")
      }
      return .currentValue(argument.expression)
    }
    if hasKind {
      guard FixtureSyntax.annotation(text, named: "publisher") == "passthrough" else {
        throw FixtureDiagnostic(
          "publisher must be \"passthrough\"; use publisherInitial for a current-value subject")
      }
      return .passthrough
    }
    if hasInitial {
      guard let value = FixtureSyntax.annotation(text, named: "publisherInitial") else {
        throw FixtureDiagnostic("publisherInitial requires a quoted Swift expression")
      }
      let expression = ExprSyntax(stringLiteral: value)
      guard !expression.hasError else {
        throw FixtureDiagnostic("publisherInitial must contain a valid Swift expression")
      }
      return .currentValue(expression)
    }
    return nil
  }

  public static func types(for type: TypeSyntax) throws -> (output: TypeSyntax, failure: TypeSyntax)
  {
    let arguments: GenericArgumentListSyntax?
    if let identifier = type.as(IdentifierTypeSyntax.self), identifier.name.text == "AnyPublisher" {
      arguments = identifier.genericArgumentClause?.arguments
    } else if let member = type.as(MemberTypeSyntax.self), member.name.text == "AnyPublisher",
      member.baseType.trimmedDescription == "Combine"
    {
      arguments = member.genericArgumentClause?.arguments
    } else {
      arguments = nil
    }
    guard let arguments, arguments.count == 2,
      let output = arguments.first?.argument.as(TypeSyntax.self),
      let failure = arguments.last?.argument.as(TypeSyntax.self)
    else {
      throw FixtureDiagnostic(
        "@MockPublisher requires an explicit AnyPublisher<Output, Failure> type")
    }
    return (output, failure)
  }

  public static func validate(_ variable: VariableDeclSyntax) throws {
    guard variable.bindings.count == 1, let binding = variable.bindings.first,
      binding.pattern.is(IdentifierPatternSyntax.self), let type = binding.typeAnnotation?.type
    else {
      throw FixtureDiagnostic("@MockPublisher requires a single property with an explicit type")
    }
    _ = try types(for: type)
    if case .accessors(let accessors) = binding.accessorBlock?.accessors,
      accessors.contains(where: { $0.effectSpecifiers != nil })
    {
      throw FixtureDiagnostic("@MockPublisher requires a synchronous, nonthrowing property")
    }
    if try FixtureSyntax.explicitDefault(
      attributes: variable.attributes, trivia: variable.leadingTrivia, type: type) != nil
    {
      throw FixtureDiagnostic("Choose @MockPublisher or a fixture default for a property, not both")
    }
  }
}
