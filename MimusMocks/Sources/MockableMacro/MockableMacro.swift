import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

public struct MockableMacro: PeerMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard let protocolDeclaration = declaration.as(ProtocolDeclSyntax.self) else {
      throw MockableDiagnostic("@Mockable can only be applied to a protocol")
    }
    var baseClassName: String?
    var excludedMethods = Set<String>()
    var publicMock = false
    var inheritedRequirementsAreDeclared = false
    if case .argumentList(let arguments) = node.arguments {
      for argument in arguments {
        if ["publicMock", "inheritedRequirementsAreDeclared"].contains(argument.label?.text ?? "") {
          guard let literal = argument.expression.as(BooleanLiteralExprSyntax.self) else {
            throw MockableDiagnostic("\(argument.label!.text) must be a Boolean literal")
          }
          if argument.label?.text == "publicMock" {
            publicMock = literal.literal.text == "true"
          } else {
            inheritedRequirementsAreDeclared = literal.literal.text == "true"
          }
          continue
        }
        if argument.label?.text == "excluding" {
          guard let array = argument.expression.as(ArrayExprSyntax.self) else {
            throw MockableDiagnostic("excluding must be an array of method-name string literals")
          }
          for element in array.elements {
            guard
              let literal = element.expression.as(StringLiteralExprSyntax.self)?
                .representedLiteralValue
            else {
              throw MockableDiagnostic("excluding must contain method-name string literals")
            }
            excludedMethods.insert(literal)
          }
          continue
        }
        guard argument.label?.text == "baseClassName" else { continue }
        if argument.expression.is(NilLiteralExprSyntax.self) { continue }
        guard let literal = argument.expression.as(StringLiteralExprSyntax.self),
          let value = literal.representedLiteralValue
        else {
          throw MockableDiagnostic("baseClassName must be a string literal")
        }
        baseClassName = value
      }
    }
    return [
      try MockBuilder(
        protocolDeclaration, baseClassName: baseClassName, excluding: excludedMethods,
        publicMock: publicMock, inheritedRequirementsAreDeclared: inheritedRequirementsAreDeclared
      ).build()
    ]
  }
}

struct MockableDiagnostic: Error, CustomStringConvertible {
  let description: String
  init(_ description: String) { self.description = description }
}
