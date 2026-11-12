import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder

public struct FixtureDiagnostic: Error, CustomStringConvertible {
  public let description: String
  public init(_ description: String) { self.description = description }
}

/// Syntax shared by the compiler macro and the source-declaration adapter.
public enum FixtureSyntax {
  public static func attributeName(_ attribute: AttributeSyntax) -> String {
    attribute.attributeName.trimmedDescription.split(separator: ".").last.map(String.init) ?? ""
  }

  public static func annotation(_ text: String, named name: String) -> String? {
    let pattern =
      "(?:sourcery|mimus):\\s*" + NSRegularExpression.escapedPattern(for: name)
      + #"\s*=\s*("(?:\\.|[^"\\])*")"#
    guard let regex = try? NSRegularExpression(pattern: pattern),
      let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
      let range = Range(match.range(at: 1), in: text)
    else { return nil }
    return ExprSyntax(stringLiteral: String(text[range])).as(StringLiteralExprSyntax.self)?
      .representedLiteralValue
  }

  public static func hasAnnotation(_ text: String, named name: String) -> Bool {
    text.range(
      of: "(?:sourcery|mimus):\\s*" + NSRegularExpression.escapedPattern(for: name)
        + #"(?=\s|,|$)"#,
      options: .regularExpression) != nil
  }

  public static func explicitDefault(
    attributes: AttributeListSyntax, trivia: Trivia, type: TypeSyntax
  ) throws -> ExprSyntax? {
    let defaults = attributes.compactMap { $0.as(AttributeSyntax.self) }
      .filter { attributeName($0) == "MockDefault" }
    guard defaults.count <= 1 else {
      throw FixtureDiagnostic("Use only one @MockDefault on each requirement")
    }
    if let attribute = defaults.first {
      guard case .argumentList(let arguments) = attribute.arguments,
        arguments.count == 1, let argument = arguments.first, argument.label == nil
      else { throw FixtureDiagnostic("@MockDefault requires one default-value expression") }
      if let member = argument.expression.as(MemberAccessExprSyntax.self),
        member.base == nil
          || ["MockDefaultSource", "MimusMocks.MockDefaultSource"].contains(
            member.base!.trimmedDescription)
      {
        if member.declName.baseName.text == "fixture" { return try fixtureDefault(for: type) }
        if member.declName.baseName.text == "nestedMock" { return try nestedMock(for: type) }
      }
      return argument.expression
    }
    let text = trivia.description
    if let value = annotation(text, named: "default") ?? annotation(text, named: "mockValue") {
      let expression = ExprSyntax(stringLiteral: value)
      guard !expression.hasError else {
        throw FixtureDiagnostic("The mock default must be a valid Swift expression")
      }
      return expression
    }
    if hasAnnotation(text, named: "forceMock") { return try nestedMock(for: type) }
    return nil
  }

  /// Optional values and collections retain empty defaults. Other leaf values
  /// use the consumer's .mock() factory; tuple labels and nesting are preserved.
  public static func fixtureDefault(
    for type: TypeSyntax, mockProtocols: [String: String] = [:]
  ) throws -> ExprSyntax {
    if type.is(OptionalTypeSyntax.self) || type.is(ImplicitlyUnwrappedOptionalTypeSyntax.self) {
      return "nil"
    }
    let standardType =
      type.as(IdentifierTypeSyntax.self)?.name.text
      ?? type.as(MemberTypeSyntax.self).flatMap {
        $0.baseType.trimmedDescription == "Swift" ? $0.name.text : nil
      }
    if let standardType, ["Optional", "Array", "Dictionary"].contains(standardType) {
      switch standardType {
      case "Optional": return "nil"
      case "Array": return "[]"
      default: return "[:]"
      }
    }
    if type.is(ArrayTypeSyntax.self) { return "[]" }
    if type.is(DictionaryTypeSyntax.self) { return "[:]" }
    if let tuple = type.as(TupleTypeSyntax.self) {
      let elements = try tuple.elements.map { element in
        let label =
          element.firstName.flatMap {
            $0.text == "_" ? nil : $0.trimmedDescription + ": "
          } ?? ""
        return label
          + (try fixtureDefault(for: element.type, mockProtocols: mockProtocols))
          .trimmedDescription
      }
      return ExprSyntax(stringLiteral: "(" + elements.joined(separator: ", ") + ")")
    }
    if type.as(SomeOrAnyTypeSyntax.self)?.someOrAnySpecifier.text == "any" {
      return try nestedMock(for: type)
    }
    if type.is(FunctionTypeSyntax.self) || type.is(SomeOrAnyTypeSyntax.self)
      || type.is(CompositionTypeSyntax.self)
    {
      throw FixtureDiagnostic("This fixture type needs an explicit @MockDefault expression")
    }
    let protocolName: String
    let generics: String
    if let identifier = type.as(IdentifierTypeSyntax.self) {
      protocolName = identifier.name.text
      generics = identifier.genericArgumentClause?.trimmedDescription ?? ""
    } else if let member = type.as(MemberTypeSyntax.self) {
      protocolName = member.baseType.trimmedDescription + "." + member.name.text
      generics = member.genericArgumentClause?.trimmedDescription ?? ""
    } else {
      protocolName = type.trimmedDescription
      generics = ""
    }
    if let mockName = mockProtocols[protocolName] {
      return ExprSyntax(stringLiteral: mockName + generics + "()")
    }
    return ExprSyntax(stringLiteral: "\(type.trimmedDescription).mock()")
  }

  public static func nestedMock(for type: TypeSyntax) throws -> ExprSyntax {
    let base: TypeSyntax
    if let optional = type.as(OptionalTypeSyntax.self) {
      base = optional.wrappedType
    } else if let identifier = type.as(IdentifierTypeSyntax.self),
      identifier.name.text == "Optional",
      let argument = identifier.genericArgumentClause?.arguments.first,
      let wrapped = argument.argument.as(TypeSyntax.self)
    {
      base = wrapped
    } else if let member = type.as(MemberTypeSyntax.self), member.name.text == "Optional",
      member.baseType.trimmedDescription == "Swift",
      let argument = member.genericArgumentClause?.arguments.first,
      let wrapped = argument.argument.as(TypeSyntax.self)
    {
      base = wrapped
    } else if let existential = type.as(SomeOrAnyTypeSyntax.self) {
      base = existential.constraint
    } else if let tuple = type.as(TupleTypeSyntax.self), tuple.elements.count == 1,
      let element = tuple.elements.first, element.firstName == nil
    {
      return try nestedMock(for: element.type)
    } else {
      base = type
    }
    if base.id != type.id { return try nestedMock(for: base) }
    let name: String
    let generics: String
    if let identifier = base.as(IdentifierTypeSyntax.self) {
      name = identifier.name.text
      generics = identifier.genericArgumentClause?.trimmedDescription ?? ""
    } else if let member = base.as(MemberTypeSyntax.self) {
      name = member.name.text
      generics = member.genericArgumentClause?.trimmedDescription ?? ""
    } else {
      throw FixtureDiagnostic("This nested mock type needs an explicit @MockDefault expression")
    }
    return ExprSyntax(stringLiteral: "Mock\(name)\(generics)()")
  }
}
